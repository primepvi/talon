defmodule Talon.App.Engine do
  alias Talon.Panel.Connection
  alias Talon.Infra.Docker, as: DockerClient
  alias Talon.Infra.Git, as: GitClient

  alias Talon.Payloads.App
  alias Talon.Payloads.Node

  alias Talon.App.Supervisor
  alias Talon.App.Process, as: AppProcess

  @spec handle_app_create(App.Create.t()) :: {:ok, pid()} | {:error, String.t()}
  def handle_app_create(payload) do
    Supervisor.create_process(%AppProcess.State{
      app: payload
    })
  end

  @spec handle_app_deploy(String.t(), App.Deploy.t()) :: {:ok, nil} | {:error, String.t()}
  def handle_app_deploy(correlation_id, payload) do
    with {:ok, port} <- Talon.App.PortManager.allocate() do
      AppProcess.deploy(correlation_id, payload, port)
      {:ok, nil}
    end
  end

  @spec handle_node_sync(String.t(), Node.Sync.t()) :: {:ok, nil} | {:error, String.t()}
  def handle_node_sync(correlation_id, payload) do
    {:ok, _task_pid} =
      Task.Supervisor.start_child(Talon.TaskSupervisor, fn ->
        ready_apps = []

        Enum.each(payload.apps, fn app ->
          {container_id, status} =
            case DockerClient.container_inspect("#{app.name}_#{app.app_id}") do
              {:ok,
               %DockerEngineAPI.Model.ContainerInspectResponse{Id: container_id, State: %{Status: status}}} ->
                {container_id,
                 case String.downcase(status) do
                   "created" -> :idle
                   "restarting" -> :redeploying
                   "running" -> :running
                   "removing" -> :deploying
                   "paused" -> :idle
                   "exited" -> :failed
                   "dead" -> :crashed
                   _ -> :empty
                 end}

              _ ->
                {nil, :destroyed}
            end

          Supervisor.create_process(%AppProcess.State{
            app: app,
            container_id: container_id,
            status: status
          })

          ready_apps = [%{app_id: app.app_id, status: status} | ready_apps]
        end)

        Connection.send_message(%Talon.Panel.Message{
          type: "node.ready",
          correlation_id: correlation_id,
          payload: %Talon.Payloads.Node.Ready{
            apps: ready_apps
          }
        })
      end)

    {:ok, nil}
  end

  @spec handle_start_app_deploy(integer(), App.Create.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def handle_start_app_deploy(port, %{strategy: :registry} = app) do
    [image, tag] = String.split(app.image, ":")

    with {:ok, container_id} <-
           DockerClient.container_create(%DockerClient.ContainerConfig{
             app_id: app.app_id,
             name: app.name,
             image: image,
             tag: tag,
             cpu: app.resources["cpu"],
             memory: app.resources["memory"],
             port: port,
             env:
               app.env
               |> Map.to_list()
               |> Enum.map(&"#{elem(&1, 0)}=#{elem(&1, 1)}")
           }),
         {:ok, nil} <- DockerClient.container_start(container_id),
         :ok <- healthcheck(port) do
      {:ok, container_id}
    end
  end

  def handle_start_app_deploy(port, %{strategy: :dockerfile} = app) do
    with {:ok, _path} <- GitClient.clone(app.repo, app.name),
         {:ok, nil} <- DockerClient.image_build(app.name, app.commit),
         {:ok, container_id} <-
           DockerClient.container_create(%DockerClient.ContainerConfig{
             app_id: app.app_id,
             name: app.name,
             image: app.name,
             tag: app.commit,
             cpu: app.resources["cpu"],
             memory: app.resources["memory"],
             port: port,
             env:
               app.env
               |> Map.to_list()
               |> Enum.map(&"#{elem(&1, 0)}=#{elem(&1, 1)}")
           }),
         {:ok, nil} <- DockerClient.container_start(container_id),
         :ok <- healthcheck(port) do
      {:ok, container_id}
    end
  end

  @spec handle_app_redeploy(String.t(), App.Redeploy.t()) :: {:ok, nil} | {:error, String.t()}
  def handle_app_redeploy(correlation_id, payload) do
    with {:ok, port} <- Talon.App.PortManager.allocate() do
      AppProcess.redeploy(correlation_id, payload, port)
      {:ok, nil}
    end
  end

  @spec handle_start_app_redeploy(integer(), App.Create.t(), AppProcess.State.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def handle_start_app_redeploy(port, app, state) do
    with {:ok, container_id} <- handle_start_app_deploy(port, app),
         {:ok, nil} <- DockerClient.container_stop(state.container_id),
         {:ok, nil} <- DockerClient.container_delete(state.container_id),
         :ok <- Talon.App.PortManager.release(state.container_port) do
      {:ok, container_id}
    end
  end

  @spec handle_app_action(atom(), String.t(), struct()) :: {:ok, nil} | {:error, String.t()}
  def handle_app_action(action, correlation_id, payload) do
    with {:ok, _pid} <- Talon.App.Supervisor.get_process(payload.app_id) do
      AppProcess.action(correlation_id, payload, action)
      {:ok, nil}
    end
  end

  @spec handle_start_app_action(atom(), String.t()) ::
          {:ok, AppProcess.State.status()} | {:error, String.t()}
  def handle_start_app_action(action, container_id) do
    result =
      case action do
        :start -> DockerClient.container_start(container_id)
        :stop -> DockerClient.container_stop(container_id)
        :destroy -> DockerClient.container_delete(container_id)
        _ -> {:error, "Invalid container action has provided."}
      end

    with {:ok, nil} <- result do
      case action do
        :start -> {:ok, :running}
        :stop -> {:ok, :idle}
        :destroy -> {:ok, :destroyed}
      end
    end
  end

  defp healthcheck(port, timeout \\ 30_000, interval \\ 1_000) do
    deadline = System.monotonic_time(:millisecond) + timeout
    exec_healthcheck(port, deadline, interval)
  end

  defp exec_healthcheck(port, deadline, interval) do
    if System.monotonic_time(:millisecond) >= deadline do
      {:error, "Reached healthcheck timeout."}
    else
      case :gen_tcp.connect(~c"127.0.0.1", port, [:binary, active: false], 2_000) do
        {:ok, socket} ->
          :gen_tcp.close(socket)
          :ok

        {:error, _} ->
          Process.sleep(interval)
          exec_healthcheck(port, deadline, interval)
      end
    end
  end
end
