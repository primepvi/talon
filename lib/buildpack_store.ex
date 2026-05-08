defmodule Talon.BuildpackStore do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def put(buildpack) do
    GenServer.call(__MODULE__, {:put, buildpack})
  end

  def get(name) do
    GenServer.call(__MODULE__, {:get, name})
  end

  def all do
    GenServer.call(__MODULE__, :all)
  end

  def delete(name) do
    GenServer.call(__MODULE__, {:delete, name})
  end

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:put, buildpack}, _from, state) do
    {:reply, :ok, Map.put(state, buildpack.name, buildpack)}
  end

  def handle_call({:get, name}, _from, state) do
    {:reply, Map.fetch(state, name), state}
  end

  def handle_call(:all, _from, state) do
    {:reply, Map.values(state), state}
  end

  def handle_call({:delete, name}, _from, state) do
    {:reply, :ok, Map.delete(state, name)}
  end
end
