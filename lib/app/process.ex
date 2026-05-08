defmodule Talon.App.Process do
  use GenServer

  alias Talon.Panel.Connection
  alias Talon.App.Engine
  alias Talon.Payloads
  alias Talon.Models

  defmodule State do
    defstruct [:app, status: :unkown, container_id: nil, container_port: nil, deploy: nil]

    @type t() :: %__MODULE__{
            app: Models.App.t(),
            status: Models.App.status(),
            deploy: Models.Deploy.t() | nil,
            container_id: String.t() | nil,
            container_port: integer() | nil
          }
  end

  @spec start_link(State.t()) :: any()
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: via_tuple(state.app.app_id))
  end

  defp via_tuple(id) do
    {:via, Registry, {Talon.App.Process.Registry, id}}
  end

  @spec init(State.t()) :: {:ok, State.t()}
  @impl true
  def init(state) do
    {:ok, %{state | status: :unknown}}
  end

  @spec deploy(String.t(), Models.Deploy.t(), integer()) :: :ok
  def deploy(correlation_id, payload, port) do
    id_tuple = via_tuple(payload.app_id)
    GenServer.cast(id_tuple, {:deploy, correlation_id, payload, port})
  end

  @spec update(String.t(), Payloads.App.Update.t(), integer()) :: :ok
  def update(correlation_id, payload, port) do
    id_tuple = via_tuple(payload.id)
    GenServer.cast(id_tuple, {:update, correlation_id, payload, port})
  end

  @spec action(String.t(), Payloads.App.Action.t(), atom()) :: :ok
  def action(correlation_id, payload, action) do
    id_tuple = via_tuple(payload.id)
    GenServer.cast(id_tuple, {:action, correlation_id, payload, action})
  end

  @spec inspect(String.t()) :: State.t()
  def inspect(id) do
    id_tuple = via_tuple(id)
    GenServer.call(id_tuple, :inspect)
  end

  @impl true
  def handle_cast({:deploy, correlation_id, payload, port}, state) do
    id_tuple = via_tuple(payload.app_id)

    {:ok, _task_pid} =
      Task.Supervisor.start_child(Talon.TaskSupervisor, fn ->
        case Engine.handle_start_app_deploy(port, state.app, payload) do
          {:ok, container_id} ->
            GenServer.cast(
              id_tuple,
              {:finalize_deploy,
               %{
                 container_id: container_id,
                 container_port: port,
                 deploy: payload,
                 status: :running
               }}
            )

            Connection.send_app_state(correlation_id, %{
              app_id: payload.app_id,
              deploy_id: payload.id,
              state: :running
            })

          {:error, reason} ->
            GenServer.cast(
              id_tuple,
              {:finalize_deploy, %{deploy: payload, status: :error}}
            )

            Connection.send_app_state(correlation_id, %{
              app_id: payload.app_id,
              deploy_id: payload.id,
              state: :error,
              reason: reason
            })
        end
      end)

    {:noreply, %{state | deploy: payload, status: :starting}}
  end

  @impl true
  def handle_cast({:action, correlation_id, payload, action}, state) do
    {:ok, _task_pid} =
      Task.Supervisor.start_child(Talon.TaskSupervisor, fn ->
        case Engine.handle_start_app_action(action, state.container_id) do
          {:ok, status} ->
            Connection.send_app_state(correlation_id, %{
              id: payload.id,
              deploy_id: state.deploy.id,
              state: status
            })

            if status == :unknown do
              GenServer.stop(self(), :normal)
            end

          {:error, reason} ->
            Connection.send_app_state(correlation_id, %{
              id: payload.id,
              deploy_id: nil,
              state: :error,
              reason: reason
            })
        end
      end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:update, correlation_id, payload, port}, state) do
    id_tuple = via_tuple(payload.app_id)

    updated_app =
      Enum.reduce(payload.keys, state.app, fn key, acc ->
        Map.put(acc, String.to_existing_atom(key), Map.get(payload.data, String.to_existing_atom(key)))
      end)

    previous_state = %State{
      app: state.app,
      deploy: state.deploy,
      container_id: state.container_id,
      container_port: state.container_port,
      status: state.status
    }

    {:ok, _task_pid} =
      Task.Supervisor.start_child(Talon.TaskSupervisor, fn ->
        case Engine.handle_start_app_update(port, updated_app, state) do
          {:ok, container_id} ->
            GenServer.cast(
              id_tuple,
              {:finalize_deploy,
               %{
                 container_id: container_id,
                 container_port: port,
                 deploy: state.deploy,
                 status: :running
               }}
            )

            Connection.send_app_state(correlation_id, %{
              app_id: state.app.id,
              deploy_id: state.deploy.id,
              state: :running
            })

          {:error, reason} ->
            GenServer.cast(
              id_tuple,
              {:finalize_deploy, previous_state}
            )

            Connection.send_app_state(correlation_id, %{
              app_id: state.app.id,
              deploy_id: state.deploy.id,
              state: :error,
              reason: reason
            })
        end
      end)

    {:noreply, %{state | status: :starting}}
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
