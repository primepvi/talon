defmodule Talon.Server.Engine do
  alias Talon.Infra.Docker, as: DockerClient
  alias Talon.Infra.Git, as: GitClient
  alias Talon.Server.Process.Data, as: ProcessData

  @spec prepare_container(ProcessData.t()) :: {:ok, String.t()} | {:error, String.t()}
  def prepare_container(%{source_type: :image} = data) do
    data.name
    |> DockerClient.container_exists?()
    |> handle_preparation(data)
  end

  def prepare_container(%{source_type: :dockerfile} = data) do
    data.name
    |> DockerClient.container_exists?()
    |> handle_preparation(data)
  end

  defp handle_preparation(true, %{source_type: :image} = data) do
    case DockerClient.container_inspect(data.name) do
      {:ok, %{Id: container_id}} -> {:ok, container_id}
      error -> error
    end
  end

  defp handle_preparation(false, %{source_type: :image} = data) do
    DockerClient.container_create(data.name, data.image, data.tag)
  end

  defp handle_preparation(false, %{source_type: :dockerfile} = data) do
    with {:ok, _path} <- GitClient.clone(data.repository, data.name),
         {:ok, nil} <- DockerClient.image_build(data.name) do
      DockerClient.container_create(data.name, data.name)
    end
  end
end
