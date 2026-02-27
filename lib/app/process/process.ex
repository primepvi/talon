defmodule Talon.App.Process do
  use GenServer

  alias Talon.Infra.Docker, as: DockerClient
  alias Talon.App.Process.State, as: ProcessState

  @spec start_link(ProcessState.t()) :: any()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: via_tuple(state.app.app_id))
  end

  defp via_tuple(id) do
    {:via, Registry, {Talon.App.ProcessRegistry, id}}
  end

  @spec init(ProcessState.t()) :: {:ok, ProcessState.t()}
  @impl true
  def init(state) do
    {:ok, %{state | status: :empty}}
  end

  @spec start(String.t()) :: :ok
  def start(id) do
    id_tuple = via_tuple(id)
    GenServer.cast(id_tuple, :start)
  end

  @spec update(String.t(), map()) :: :ok
  def update(id, new_state) do
    id_tuple = via_tuple(id)
    GenServer.cast(id_tuple, {:update, new_state})
  end

  @spec inspect(String.t()) :: {:reply, ProcessState.t(), ProcessState.t()}
  def inspect(id) do
    id_tuple = via_tuple(id)
    GenServer.call(id_tuple, :inspect)
  end

  @impl true
  def handle_cast(:start, %ProcessState{container_id: id} = state) do
    DockerClient.container_start(id)
    {:noreply, %{state | status: :running}}
  end

  @impl true
  def handle_cast({:update, new_state}, state) do
    {:noreply, Map.merge(state, new_state)}
  end

  @impl true
  def handle_call(:inspect, _from, state) do
    {:reply, state, state}
  end
end
