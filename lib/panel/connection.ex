defmodule Talon.Panel.Connection do
  use WebSockex
  require Logger

  alias Talon.Panel.MessageHandler
  alias Talon.Models

  @backoff_intervals [1_000, 2_000, 4_000, 8_000, 30_000]

  def start_link(_opts \\ []) do
    url = Application.get_env(:talon, :panel_url)
    token = Application.get_env(:talon, :panel_token)

    WebSockex.start_link(url, __MODULE__, %{retry_count: 0},
      name: __MODULE__,
      extra_headers: [{"Authorization", "Bearer #{token}"}],
      handle_initial_conn_failure: true
    )
  end

  @spec send_message(Models.Message.t(map())) :: :ok
  def send_message(message) do
    IO.puts("ENVIADO")
    IO.inspect(message)
   
    {:ok, message} = Models.Message.validate(message)
    WebSockex.cast(__MODULE__, {:send, {:text, Jason.encode!(message)}})
  end

  @spec send_app_state(String.t(), Models.AppState.t()) :: :ok
  def send_app_state(correlation_id, state) do
    {:ok, payload} = Models.AppState.validate(state)
    
    send_message(%{
      type: "app.state",
      correlation_id: correlation_id,
      payload: payload
    })
  end

  defp send_node_register() do
    %{
      type: "node.register",
      correlation_id: UUID.uuid4(),
      payload: %{
        node_id: Application.get_env(:talon, :node_id),
        version: Application.get_env(:talon, :node_version)
      }
    }
    |> send_message
  end

  @impl true
  def handle_connect(_conn, state) do
    send_node_register()

    Logger.info("[talon] connected to panel.")
    {:ok, %{state | retry_count: 0}}
  end

  @impl true
  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    result = msg
    |> Jason.decode!()

    IO.puts("RECEBIDO")
    IO.inspect(result)
    
    result
    |> MessageHandler.dispatch()

    {:ok, state}
  end

  @impl true
  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning("[talon] disconnected: #{inspect(reason)}")

    interval =
      @backoff_intervals
      |> Enum.at(state.retry_count, List.last(@backoff_intervals))
      |> jitter()

    Logger.info("[talon] reconnecting in #{interval}ms.")

    Process.sleep(interval)
    {:reconnect, %{state | retry_count: state.retry_count + 1}}
  end

  defp jitter(interval) do
    interval + :rand.uniform(div(interval, 2))
  end
end
