defmodule Talon.App.Engine do
  alias Talon.Panel.Connection
  alias Talon.Infra.Docker, as: DockerClient
  alias Talon.Infra.Git, as: GitClient

  alias Talon.Payloads
  alias Talon.App

  @spec handle_node_sync(String.t(), Payloads.Node.Sync.t()) :: {:ok, nil} | {:error, String.t()}
  def handle_node_sync(correlation_id, payload) do
    {:ok, _task_pid} =
      Task.Supervisor.start_child(Talon.TaskSupervisor, fn ->
        ready_apps =
          Enum.map(payload.apps, fn app ->
            {container_id, status} =
              case DockerClient.container_inspect("#{app.name}_#{app.app_id}") do
                {:ok,
                 %DockerEngineAPI.Model.ContainerInspectResponse{
                   Id: container_id,
                   State: %{Status: status}
                 }} ->
                  {container_id,
                   case String.downcase(status) do
                     "created" -> :stopped
                     "restarting" -> :starting
                     "running" -> :running
                     "removing" -> :stopping
                     "paused" -> :stopped
                     "exited" -> :stopped
                     "dead" -> :error
                     _ -> :unknown
                   end}

                _ ->
                  {nil, :unknown}
              end

            case App.Supervisor.get_process(app.app_id) do
              {:error, _reason} ->
                App.Supervisor.create_process(%App.Process.State{
                  app: app,
                  container_id: container_id,
                  status: status,
                  deploy: payload.deploy
                })
            end

            %{id: app.app_id, status: status}
          end)

        Connection.send_message(%{
          type: "node.ready",
          correlation_id: correlation_id,
          payload: %{
            apps: ready_apps
          }
        })
      end)

    {:ok, nil}
  end

  @spec handle_app_create(String.t(), Models.App.t()) :: {:ok, nil} | {:error, String.t()}
  def handle_app_create(_correlation_id, payload) do
    with {:ok, _pid} <-
           App.Supervisor.create_process(%App.Process.State{
             app: payload
           }) do
      {:ok, nil}
    end
  end

  @spec handle_start_app_deploy(integer(), Payloads.App.Deploy.t()) ::
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

  @spec handle_app_update(String.t(), Payloads.App.Update.t()) :: {:ok, nil} | {:error, String.t()}
  def handle_app_update(correlation_id, payload) do
    with {:ok, port} <- Talon.App.PortManager.allocate() do
      App.Process.update(correlation_id, payload, port)
      {:ok, nil}
    end
  end

  @spec handle_start_app_update(integer(), Payloads.App.Deploy.t(), App.Process.State.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def handle_start_app_update(port, app, state) do
    with {:ok, container_id} <- handle_start_app_deploy(port, app),
         {:ok, nil} <- DockerClient.container_stop(state.container_id),
         {:ok, nil} <- DockerClient.container_delete(state.container_id),
         :ok <- Talon.App.PortManager.release(state.container_port) do
      {:ok, container_id}
    end
  end

  @spec handle_app_action(atom(), String.t(), Payloads.App.Action.t()) :: {:ok, nil} | {:error, String.t()}
  def handle_app_action(action, correlation_id, payload) do
    with {:ok, _pid} <- Talon.App.Supervisor.get_process(payload.app_id) do
      App.Process.action(correlation_id, payload, action)
      {:ok, nil}
    end
  end

  @spec handle_start_app_action(atom(), String.t()) ::
          {:ok, Models.App.status()} | {:error, String.t()}
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
        :stop -> {:ok, :stopped}
        :destroy -> {:ok, :unknown}
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
