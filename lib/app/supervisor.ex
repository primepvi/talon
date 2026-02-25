defmodule Talon.App.Supervisor do
  use DynamicSupervisor

  alias Talon.App.Process.State, as: ProcessState

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec create_process(ProcessState.t()) :: {:ok, pid()} | {:error, String.t()}
  def create_process(state) do
    spec = {Talon.App.Process, state}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
