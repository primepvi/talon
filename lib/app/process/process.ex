defmodule Talon.App.Process do
  use GenServer

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

  @spec deploy(String.t(), App.Deploy.t(), integer()) :: :ok
  def deploy(correlation_id, payload, port) do
    id_tuple = via_tuple(payload.app_id)
    GenServer.cast(id_tuple, {:deploy, correlation_id, payload, port})
  end

  @spec redeploy(String.t(), App.Redeploy.t(), integer()) :: :ok
  def redeploy(correlation_id, payload, port) do
    id_tuple = via_tuple(payload.app_id)
    GenServer.cast(id_tuple, {:redeploy, correlation_id, payload, port})
  end

  @spec action(String.t(), struct(), atom()) :: :ok
  def action(correlation_id, payload, action) do
    id_tuple = via_tuple(payload.app_id)
    GenServer.cast(id_tuple, {:action, correlation_id, payload, action})
  end

  @spec inspect(String.t()) :: ProcessState.t()
  def inspect(id) do
    id_tuple = via_tuple(id)
    {:reply, state, _state} = GenServer.call(id_tuple, :inspect)
    state
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
              {:finalize_deploy,
               %{
                 container_id: container_id,
                 container_port: port,
                 deploy_id: payload.deploy_id,
                 status: :running
               }}
            )

            Connection.send_app_state(correlation_id, %App.State{
              app_id: payload.app_id,
              deploy_id: payload.deploy_id,
              state: :running
            })

          {:error, reason} ->
            GenServer.cast(
              id_tuple,
              {:finalize_deploy, %{deploy_id: payload.deploy_id, status: :failed}}
            )

            Connection.send_app_state(correlation_id, %App.State{
              app_id: payload.app_id,
              deploy_id: payload.deploy_id,
              state: :failed,
              reason: reason
            })
        end
      end)

    {:noreply, %{state | deploy_id: payload.deploy_id, status: :deploying}}
  end

  @impl true
  def handle_cast({:action, correlation_id, payload, action}, state) do

    {:ok, _task_pid} =
      Task.Supervisor.start_child(Talon.TaskSupervisor, fn ->
        case Engine.handle_start_app_action(action, state.container_id) do
          {:ok, status} ->
            Connection.send_app_state(correlation_id, %App.State{
              app_id: payload.app_id,
              deploy_id: nil,
              state: status
            })

          {:error, reason} ->
            Connection.send_app_state(correlation_id, %App.State{
              app_id: payload.app_id,
              deploy_id: nil,
              state: :failed,
              reason: reason
            })
        end
      end)

      {:noreply, state}
  end

  @impl true
  def handle_cast({:redeploy, correlation_id, payload, port}, state) do
    id_tuple = via_tuple(payload.app_id)


    updated_app = Enum.reduce(payload.changes, state.app, fn key, acc ->
      Map.put(acc, String.to_existing_atom(key), Map.get(payload, String.to_existing_atom(key)))
    end)

    previous_state = %ProcessState{
      app: state.app,
      deploy_id: state.deploy_id,
      container_id: state.container_id,
      container_port: state.container_port,
      status: :running
    }

    {:ok, _task_pid} =
      Task.Supervisor.start_child(Talon.TaskSupervisor, fn ->
        case Engine.handle_start_app_redeploy(port, updated_app, state) do
          {:ok, container_id} ->
            GenServer.cast(
              id_tuple,
              {:finalize_deploy,
               %{
                 container_id: container_id,
                 container_port: port,
                 deploy_id: payload.deploy_id,
                 status: :running
               }}
            )

            Connection.send_app_state(correlation_id, %App.State{
              app_id: payload.app_id,
              deploy_id: payload.deploy_id,
              state: :running
            })

          {:error, reason} ->
            GenServer.cast(
              id_tuple,
              {:finalize_deploy, previous_state}
            )

            Connection.send_app_state(correlation_id, %App.State{
              app_id: payload.app_id,
              deploy_id: payload.deploy_id,
              state: :failed,
              reason: reason
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
