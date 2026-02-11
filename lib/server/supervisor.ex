defmodule Talon.Server.Supervisor do
  use DynamicSupervisor

  alias Talon.Infra.Docker.Client, as: DockerClient

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_process(name, image, tag) do
    case DockerClient.container_create(name, image, tag) do
      {:ok, container_id} ->
        spec = {Talon.Server.Process, container_id}
        DynamicSupervisor.start_child(__MODULE__, spec)

      {:error, reason} ->
        IO.puts(reason)
	{:error, reason}
    end
  end
end
