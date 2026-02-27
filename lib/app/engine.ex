defmodule Talon.App.Engine do
  alias Talon.Infra.Docker, as: DockerClient
  alias Talon.Infra.Git, as: GitClient
  alias Talon.Payloads.App
  alias Talon.App.Supervisor
  alias Talon.App.Process, as: AppProcess

  @spec handle_app_create(App.Create.t()) :: {:ok, pid()} | {:error, String.t()}
  def handle_app_create(payload) do
    Supervisor.create_process(%AppProcess.State{
      app: payload
    })
  end

  @spec handle_app_deploy(App.Deploy.t()) :: {:ok, nil} | {:error, String.t()}
  def handle_app_deploy(payload) do
    with {:ok, port} <- port_allocate(),
         %AppProcess.State{app: app} <- AppProcess.inspect(payload.app_id),
         {:ok, container_id} <- ensure_container(port, app) do
      AppProcess.update(app.app_id, %{
        deploy_id: payload.deploy_id,
        container_id: container_id,
        port: port,
        status: :running
      })

      {:ok, nil}
    else
      error -> error
    end
  end

  @spec handle_app_redeploy(App.Redeploy.t()) :: {:ok, nil} | {:error, String.t()}
  def handle_app_redeploy(payload) do
  end

  @spec ensure_container(integer(), App.Create.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp ensure_container(port, %{strategy: :registry} = app) do
    [image, tag] = String.split(app.image, ":")

    with {:ok, container_id} <-
           DockerClient.container_create(%DockerClient.ContainerConfig{
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
         :ok <- healthcheck(port) do
      {:ok, container_id}
    else
      error ->
        AppProcess.update(app.app_id, %{status: :crashed})
        error
    end
  end

  defp ensure_container(port, %{strategy: :dockerfile} = app) do
    with {:ok, _path} <- GitClient.clone(app.repo, app.name),
         {:ok, nil} <- DockerClient.image_build(app.name, app.commit),
         {:ok, container_id} <-
           DockerClient.container_create(%DockerClient.ContainerConfig{
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
         :ok <- healthcheck(port) do
      {:ok, container_id}
    else
      error ->
        AppProcess.update(app.app_id, %{status: :crashed})
        error
    end
  end

  defp port_allocate() do
    49_152..65_535
    |> Enum.shuffle()
    |> Enum.find(&port_available?/1)
    |> case do
      nil -> {:error, "No available ports."}
      port -> {:ok, port}
    end
  end

  defp port_available?(port) do
    case :gen_tcp.listen(port, [:binary, reuseaddr: true]) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        true

      {:error, _} ->
        false
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
