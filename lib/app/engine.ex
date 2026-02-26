defmodule Talon.App.Engine do
  alias Talon.Infra.Docker, as: DockerClient
  alias Talon.Infra.Git, as: GitClient
  alias Talon.Payloads.App
  alias Talon.App.Supervisor
  alias Talon.App.Process

  @spec handle_app_create(App.Create.t()) :: {:ok, String.t()} | {:error, String.t()}
  def handle_app_create(payload) do
    Supervisor.create_process(%Process.State{
      app: payload
    })
  end

  @spec handle_app_deploy(App.Deploy.t()) :: {:ok, nil} | {:error, String.t()}
  def handle_app_deploy(payload) do
    with %Process.State{app: app} <- Process.inspect(payload.app_id),
         {:ok, container_id} <- ensure_container(app) do
      Process.deploy(app.app_id, payload.deploy_id, container_id)
      {:ok, nil}
    else
      error -> error
    end
  end

  @spec ensure_container(App.Create.t()) :: {:ok, String.t()} | {:error, String.t()}
  def ensure_container(%{strategy: :registry} = app) do
    [image, tag] = String.split(app.image, ":")

    %DockerClient.ContainerConfig{
      name: app.name,
      image: image,
      tag: tag,
      cpu: app.resources["cpu"],
      memory: app.resources["memory"],
      env:
        app.env
        |> Map.to_list()
        |> Enum.map(&"#{elem(&1, 0)}=#{elem(&1, 1)}")
    }
    |> DockerClient.container_create()
  end

  def ensure_container(%{strategy: :dockerfile} = app) do
    with {:ok, _path} <- GitClient.clone(app.repo, app.name),
         {:ok, nil} <- DockerClient.image_build(app.name, app.commit) do
      %DockerClient.ContainerConfig{
        name: app.name,
        image: app.name,
        tag: app.commit,
        cpu: app.resources["cpu"],
        memory: app.resources["memory"],
        env:
          app.env
          |> Map.to_list()
          |> Enum.map(&"#{elem(&1, 0)}=#{elem(&1, 1)}")
      }
      |> DockerClient.container_create()
    else
      error -> error
    end
  end
end
