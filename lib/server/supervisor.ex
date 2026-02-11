defmodule Talon.Server.Supervisor do
  use DynamicSupervisor

  alias Talon.Server.Process.Data, as: ProcessData
  alias Talon.Server.Process.State, as: ProcessState
  alias Talon.Infra.Docker.Client, as: DockerClient

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_process(data) do
    DockerClient.container_exists?(data.name)
    |> ensure_container(data)
    |> start_child(data.name)
  end

  @spec ensure_container(boolean(), ProcessData.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp ensure_container(true, data) do
    case DockerClient.container_inspect(data.name) do
      {:ok, %{Id: container_id}} -> {:ok, container_id}
      error -> error
    end
  end

  defp ensure_container(false, data) do
    case DockerClient.container_create(data.name, data.image, data.tag) do
      {:ok, %{Id: container_id}} -> {:ok, container_id}
      error -> error
    end
  end

  @spec start_child({:ok, String.t()} | {:error, String.t()}, String.t()) :: {:ok, pid()} | {:error, String.t()}
  defp start_child({:ok, container_id}, name) do
    spec = {Talon.Server.Process, %ProcessState{id: container_id, name: name}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  defp start_child({:error, reason}, _name) do
    IO.puts(reason)
    {:error, reason}
  end
end
