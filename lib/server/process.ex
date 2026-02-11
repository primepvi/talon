defmodule Talon.Server.Process do
  use GenServer

  alias Talon.Infra.Docker.Client, as: DockerClient
  alias Talon.Server.Process.State, as: ProcessState

  @spec start_link(ProcessState.t()) :: any()
  def start_link(%ProcessState{name: name} = state) do
    GenServer.start_link(__MODULE__, state, name: via_tuple(name))
  end

  defp via_tuple(name) do
    {:via, Registry, {Talon.Server.ProcessRegistry, name}}
  end

  @spec init(ProcessState.t()) :: {:ok, ProcessState.t()}
  @impl true
  def init(state) do
    {:ok, state}
  end

  @spec start(String.t()) :: {:noreply, ProcessState.t()}
  def start(name) do
    name_tuple = via_tuple(name)
    GenServer.cast(name_tuple, :start)
  end

  @spec inspect(String.t()) :: {:reply, ProcessState.t(), ProcessState.t()}
  def inspect(name) do
    name_tuple = via_tuple(name)
    GenServer.call(name_tuple, :inspect)
  end

  @impl true
  def handle_cast(:start, %ProcessState{id: id, status: status} = state) do
    if status == :idle do
      DockerClient.container_start(id)
      {:noreply, %{state | status: :running}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_call(:inspect, _from, state) do
    {:reply, state, state}
  end
end
