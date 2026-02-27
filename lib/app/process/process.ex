defmodule Talon.App.Process do
  use GenServer

  alias Talon.Infra.Docker, as: DockerClient
  alias Talon.App.Process.State, as: ProcessState
  alias Talon.Payloads.App
  alias Talon.App.Engine
  alias Talon.Panel.Connection

  @spec start_link(ProcessState.t()) :: any()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: via_tuple(state.app.app_id))
  end

  defp via_tuple(id) do
    {:via, Registry, {Talon.App.Process.Registry, id}}
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

  @spec deploy(String.t(), App.Deploy.t(), String.t()) :: :ok
  def deploy(correlation_id, payload, port) do
    id_tuple = via_tuple(payload.app_id)
    GenServer.cast(id_tuple, {:deploy, correlation_id, payload, port})
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
  def handle_cast({:deploy, correlation_id, payload, port}, state) do
    id_tuple = via_tuple(payload.app_id)

    {:ok, _task_pid} =
      Task.Supervisor.start_child(Talon.TaskSupervisor, fn ->
        case Engine.handle_start_app_deploy(port, state.app) do
          {:ok, container_id} ->
            GenServer.cast(
              id_tuple,
              {:finalize_deploy, %{container_id: container_id, status: :running}}
            )

            Connection.send_app_state(correlation_id, %App.State{
              app_id: payload.app_id,
              deploy_id: payload.deploy_id,
              state: :running
            })

          {:error, reason} ->
            GenServer.cast(id_tuple, {:finalize_deploy, %{status: :failed}})

            Connection.send_app_state(correlation_id, %App.State{
              app_id: payload.app_id,
              deploy_id: payload.deploy_id,
              state: :failed
            })
        end
      end)

    {:noreply, %{state | deploy_id: payload.deploy_id, status: :deploying}}
  end

  @impl true
  def handle_cast({:finalize_deploy, new_state}, state) do
    {:noreply, Map.merge(state, new_state)}
  end

  @impl true
  def handle_call(:inspect, _from, state) do
    {:reply, state, state}
  end
end
