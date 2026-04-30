defmodule Talon.App.Supervisor do
  use DynamicSupervisor

  alias Talon.App.Process

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec create_process(Process.State.t()) :: {:ok, pid()} | {:error, String.t()}
  def create_process(state) do
    spec = {Process, state}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @spec get_process(String.t()) :: {:ok, pid()} | {:error, String.t()}
  def get_process(app_id) do
    case Registry.lookup(Process.Registry, app_id) do
      [{pid, _}] -> {:ok, pid}
      _ -> {:error, "Invalid app_id has provided."}
    end
  end
end
