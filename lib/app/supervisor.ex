defmodule Talon.App.Supervisor do
  use DynamicSupervisor

  alias Talon.App.Process.Data, as: ProcessData
  alias Talon.App.Process.State, as: ProcessState
  alias Talon.App.Engine

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec create_process(ProcessData.t()) :: {:ok, pid()} | {:error, String.t()}
  def create_process(data) do
    data
    |> Engine.prepare_container
    |> start_child(data.config.name)
  end

  @spec start_child({:ok, String.t()} | {:error, String.t()}, String.t()) :: {:ok, pid()} | {:error, String.t()}
  defp start_child({:ok, container_id}, name) do
    spec = {Talon.App.Process, %ProcessState{id: container_id, name: name}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  defp start_child({:error, reason}, _name) do
    IO.puts(reason)
    {:error, reason}
  end
end
