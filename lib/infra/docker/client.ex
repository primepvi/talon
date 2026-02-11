defmodule Talon.Infra.Docker.Client do
  alias DockerEngineAPI.Model
  alias DockerEngineAPI.Api.Container

  @version "v1.51"
  @base_url Application.compile_env(:talon, :docker_host, "http://localhost:2375/") <>
              @version <> "/"
  @connection DockerEngineAPI.Connection.new(base_url: @base_url, recv_timeout: 300_000)

  @spec container_create(String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def container_create(name, image, tag \\ "latest") do
    body = %Model.ContainerCreateRequest{
      Image: "#{image}:#{tag}",
      HostConfig: %Model.HostConfig{},
      Labels: %{"talon.container_name" => name}
    }

    opts = [name: name]

    case Container.container_create(@connection, body, opts) do
      {:ok, %Model.ContainerCreateResponse{Id: container_id}} ->
        {:ok, container_id}

      {:ok, %Model.ErrorResponse{message: reason}} ->
        {:error, "Cannot create container with name #{name}.\n REASON: #{reason}"}

      {:error, reason} ->
        {:error, "Unexpected error has occured: #{inspect(reason)}"}
    end
  end

  @spec container_exists?(String.t()) :: boolean()
  def container_exists?(name) do
    case Container.container_inspect(@connection, name) do
      {:ok, %Model.ContainerInspectResponse{}} -> true
      _ -> false
    end
  end

  @spec container_inspect(String.t()) :: {:ok, Model.ContainerInspectResponse.t()} | {:error, String.t()}
  def container_inspect(reference) do
    case Container.container_inspect(@connection, reference) do
      {:ok, %Model.ErrorResponse{message: reason}} -> {:error, reason}
      {:ok, payload} -> {:ok, payload}
      _ -> {:error, "Unexpected error during container inspect."}
    end
  end

  @spec container_start(String.t()) :: any()
  def container_start(reference) do
    Container.container_start(@connection, reference)
  end
end
