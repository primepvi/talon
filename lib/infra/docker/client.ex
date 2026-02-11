defmodule Talon.Infra.Docker.Client do
  alias DockerEngineAPI.Model
  alias DockerEngineAPI.Api.Image
  alias DockerEngineAPI.Api.Container

  @version "v1.51"
  @base_url "http://localhost:2375/#{@version}/"
  @connection DockerEngineAPI.Connection.new(base_url: @base_url, recv_timeout: 300_000)

  def container_create(name, image, tag) do
    body = %Model.ContainerCreateRequest{
      Image: "#{image}:#{tag}",
      HostConfig: %Model.HostConfig{}
    }

    opts = [name: name]
    case Container.container_create(@connection, body, opts) do
      {:ok, %Model.ContainerCreateResponse { Id: container_id }} -> {:ok, container_id}
      {:ok, %Model.ErrorResponse { message: reason }} -> {:error, "Cannot create container with name #{name}.\n REASON: #{reason}"}
      {:error, _} -> {:error, "Unexpected error has occured."}
    end
  end

  def container_list() do
    Container.container_list(@connection)
  end

  def container_start(id) do
    Container.container_start(@connection, id)
  end

  def image_pull(image, tag) do
    opts = [fromImage: image, tag: tag]
    Image.image_create(@connection, opts)
  end

  def image_pulled?(image, tag) do
    filters = Jason.encode!(%{reference: ["#{image}:#{tag}"]})
    case Image.image_list(@connection, filters: filters) do
      {:ok, result } -> length(result) > 0
      {:error, _reason} -> false
    end
  end
end
