defmodule Talon.App.PortManager do
  use GenServer

  @port_range 49_152..65_535

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @spec allocate() :: {:ok, integer()} | {:error, String.t()}
  def allocate do
    GenServer.call(__MODULE__, :allocate)
  end

  @spec release(integer()) :: :ok
  def release(port) do
    GenServer.cast(__MODULE__, {:release, port})
  end

  @impl true
  def init(_) do
    state = %{
      allocated: MapSet.new()
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:allocate, _from, state) do
    case find_available_port(state.allocated) do
      nil ->
        {:reply, {:error, "No available ports."}, state}

      port ->
        new_state = %{state | allocated: MapSet.put(state.allocated, port)}
        {:reply, {:ok, port}, new_state}
    end
  end

  @impl true
  def handle_cast({:release, port}, state) do
    new_state = %{state | allocated: MapSet.delete(state.allocated, port)}
    {:noreply, new_state}
  end

  defp find_available_port(allocated) do
    @port_range
    |> Enum.shuffle()
    |> Enum.find(fn port ->
      not MapSet.member?(allocated, port) and port_available?(port)
    end)
  end

  defp port_available?(port) do
    case :gen_tcp.listen(port, [:binary, reuseaddr: true]) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        true

      {:error, _} ->
        false
    end
  end
end
