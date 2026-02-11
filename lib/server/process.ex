defmodule Talon.Server.Process do
  use GenServer
  alias Talon.Infra.Docker.Client, as: DockerClient

  def start_link(container_id) do
    GenServer.start_link(__MODULE__, %{id: container_id, status: :idle})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def start(pid) do
    GenServer.cast(pid, :start)
  end

  def inspect(pid) do
    GenServer.call(pid, :inspect)
  end

  @impl true
  def handle_cast(:start, state) do
    if state[:status] == :idle do
      DockerClient.container_start(state[:id])
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
