defmodule Talon.App.Engine do
  alias Talon.Infra.Docker, as: DockerClient
  alias Talon.Infra.Git, as: GitClient
  alias Talon.App.Process.Data, as: ProcessData

  @spec prepare_container(ProcessData.t()) :: {:ok, String.t()} | {:error, String.t()}
  def prepare_container(data) do
    exists = DockerClient.container_exists?(data.config.name)
    handle_preparation(%{exists: exists, data: data})
  end

  @spec handle_preparation(%{exists: boolean(), data: ProcessData.t()}) :: {:ok, String.t()} | {:error, String.t()}
  defp handle_preparation(%{exists: true, data: data}) do
    case DockerClient.container_inspect(data.config.name) do
      {:ok, %{Id: container_id}} -> {:ok, container_id}
      error -> error
    end
  end

  defp handle_preparation(%{exists: false, data: %{source_type: :image} = data}) do
    DockerClient.container_create(data.config)
  end

  defp handle_preparation(%{exists: false, data: %{source_type: :dockerfile} = data}) do
    with {:ok, _path} <- GitClient.clone(data.repository, data.config.name),
         {:ok, nil} <- DockerClient.image_build(data.config.name, "latest") do
      DockerClient.container_create(%{data.config | image: "#{data.config.name}:latest"})
    else
      error -> error
    end
  end
end
