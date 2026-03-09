defmodule Talon.Infra.Docker do
  use Agent

  alias DockerEngineAPI.Api.Image
  alias DockerEngineAPI.Model
  alias DockerEngineAPI.Api.Container
  alias Talon.Infra.Docker.ContainerConfig

  @version "v1.51"

  def start_link(_opts) do
    Agent.start_link(&build_state/0, name: __MODULE__)
  end

  defp build_state do
    host = Application.get_env(:talon, :docker_host, "http://localhost:2375/")

    base_url = "#{host}#{@version}/"
    base_path = Application.get_env(:talon, :repo_directory, "./talon/")

    connection = DockerEngineAPI.Connection.new(base_url: base_url, recv_timeout: 300_000)

    %{
      connection: connection,
      base_path: base_path
    }
  end

  defp get_connection do
    Agent.get(__MODULE__, & &1.connection)
  end

  defp get_base_path do
    Agent.get(__MODULE__, & &1.base_path)
  end

  @spec container_create(ContainerConfig.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def container_create(config) do
    body = %Model.ContainerCreateRequest{
      Image: "#{config.image}:#{config.tag}",
      HostConfig: %Model.HostConfig{
        Memory: trunc(config.memory * 1024 * 1024),
        NanoCpus: trunc(config.cpu * 1_000_000_000),
        PortBindings: %{
          "#{config.port}/tcp" => [%{"HostIp" => "0.0.0.0", "HostPort" => "#{config.port}"}]
        }
      },
      Env: config.env,
      Labels: %{
        "talon.managed" => "true",
        "talon.name" => config.name,
        "talon.id" => config.app_id
      }
    }

    unless image_pulled?(config.image, config.tag) do
      image_pull(config.image, config.tag)
    end

    opts = [name: "#{config.name}_#{config.app_id}"]

    case Container.container_create(get_connection(), body, opts) do
      {:ok, %Model.ContainerCreateResponse{Id: container_id}} ->
        {:ok, container_id}

      {:ok, %Model.ErrorResponse{message: reason}} ->
        {:error, "Cannot create container with name #{config.name}.\n REASON: #{reason}"}

      {:error, reason} ->
        {:error, "Unexpected ocurred during container creation: #{inspect(reason)}"}
    end
  end

  @spec container_exists?(String.t()) :: boolean()
  def container_exists?(name) do
    case Container.container_inspect(get_connection(), name) do
      {:ok, %Model.ContainerInspectResponse{}} -> true
      _ -> false
    end
  end

  @spec container_inspect(String.t()) ::
          {:ok, Model.ContainerInspectResponse.t()} | {:error, String.t()}
  def container_inspect(reference) do
    case Container.container_inspect(get_connection(), reference) do
      {:ok, %Model.ErrorResponse{message: reason}} -> {:error, reason}
      {:ok, payload} -> {:ok, payload}
      _ -> {:error, "Unexpected error ocurred during container inspect."}
    end
  end

  @spec container_start(String.t()) :: {:ok, nil} | {:error, String.t()}
  def container_start(reference) do
    case Container.container_start(get_connection(), reference) do
      {:ok, %Model.ErrorResponse{message: reason}} ->
        {:error, reason}

      {:ok, nil} ->
        {:ok, nil}

      _ ->
        {:error, "Unexpected error ocurred during container start."}
    end
  end

  @spec container_stop(String.t()) :: {:ok, nil} | {:error, String.t()}
  def container_stop(reference) do
    case Container.container_stop(get_connection(), reference) do
      {:ok, %Model.ErrorResponse{message: reason}} -> {:error, reason}
      {:ok, nil} -> {:ok, nil}
      _ -> {:error, "Unexpected error ocurred during container stop."}
    end
  end

  @spec container_delete(String.t()) :: {:ok, nil} | {:error, String.t()}
  def container_delete(reference) do
    case Container.container_delete(get_connection(), reference) do
      {:ok, %Model.ErrorResponse{message: reason}} -> {:error, reason}
      {:ok, nil} -> {:ok, nil}
      _ -> {:error, "Unexpected error ocurred during container delete."}
    end
  end

  @spec container_update(String.t(), String.t(), any()) :: {:ok, nil} | {:error, String.t()}
  def container_update(reference, field, value) do
    data =
      case field do
        "memory" -> %Model.ContainerUpdateRequest{Memory: trunc(value * 1024 * 1024)}
        "cpu" -> %Model.ContainerUpdateRequest{NanoCpus: trunc(value * 1_000_000_000)}
        _ -> %Model.ContainerUpdateRequest{}
      end

    case Container.container_update(get_connection(), reference, data) do
      {:ok, %Model.ErrorResponse{message: reason}} ->
        {:error, reason}

      {:ok, _response} ->
        {:ok, nil}

      {:error, reason} ->
        {:error, "Unexpected error ocurred during container update: #{inspect(reason)}"}
    end
  end

  @spec image_build(String.t(), String.t()) :: {:ok, nil} | {:error, String.t()}
  def image_build(name, tag) do
    with {:ok, tar_binary} <- File.read("#{get_base_path()}/#{name}.tar"),
         {:ok, nil} <-
           Image.image_build(get_connection(),
             t: "#{name}:#{tag}",
             body: tar_binary,
             dockerfile: "Dockerfile"
           ) do
      {:ok, nil}
    else
      {:ok, %Model.ErrorResponse{message: reason}} -> {:error, reason}
      {:error, reason} -> {:error, "Unexpected error during image build: #{inspect(reason)}"}
    end
  end

  @spec image_delete(String.t(), String.t()) :: {:ok, nil} | {:error, String.t()}
  def image_delete(name, tag) do
    case Image.image_delete(get_connection(), "#{name}:#{tag}", force: true) do
      {:ok, %Model.ErrorResponse{message: reason}} -> {:error, reason}
      {:ok, nil} -> {:ok, nil}
      _ -> {:error, "Unexpected error during image delete."}
    end
  end

  @spec image_pull(String.t(), String.t()) :: {:ok, nil} | {:error, String.t()}
  def image_pull(image, tag) do
    opts = [fromImage: image, tag: tag]

    case Image.image_create(get_connection(), opts) do
      {:ok, %Model.ErrorResponse{message: reason}} -> {:error, reason}
      {:ok, nil} -> {:ok, nil}
      _ -> {:error, "Unexpected error during image pull."}
    end
  end

  @spec image_pulled?(String.t(), String.t()) :: boolean()
  def image_pulled?(image, tag) do
    filters = Jason.encode!(%{reference: ["#{image}:#{tag}"]})

    case Image.image_list(get_connection(), filters: filters) do
      {:ok, result} -> length(result) > 0
      {:error, _reason} -> false
    end
  end
end
