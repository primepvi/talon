defmodule Talon.Panel.Connection do
  use WebSockex

  alias Talon.Panel.MessageHandler
  alias Talon.Panel.Message

  @backoff_intervals [1_000, 2_000, 4_000, 8_000, 30_000]

  def start_link(_opts \\ []) do
    url = Application.get_env(:talon, :panel_url)
    token = Application.get_env(:talon, :panel_token)

    WebSockex.start_link(url, __MODULE__, %{retry_count: 0},
      name: __MODULE__,
      extra_headers: [{"Authorization", "Bearer #{token}"}]
    )
  end

  def send_message(message) do
    WebSockex.cast(__MODULE__, {:send, message})
  end

  @impl true
  def handle_connect(_conn, state) do
    send(self(), :register)
    {:ok, %{state | retry_count: 0}}
  end

  @impl true
  def handle_frame({:text, data}, state) do
    data
    |> Jason.decode!()
    |> MessageHandler.dispatch()

    {:ok, state}
  end

  def handle_frame({:ping, _}, state) do
    {:reply, {:pong, ""}, state}
  end

  def handle_frame(_frame, state) do
    {:ok, state}
  end

  @impl true
  def handle_cast(:register, _state) do
    message = %Message{
      type: "node.register",
      correlation_id: UUID.uuid4(),
      payload: %Talon.Payloads.Node.Register{
        node_id: "banana",
        version: "v0.1"
      }
    }

    {:reply, {:text, Jason.encode!(message)}}
  end

  @impl true
  def handle_disconnect(%{reason: reason}, state) do
    interval =
      @backoff_intervals
      |> Enum.at(state.retry_count, List.last(@backoff_intervals))
      |> jitter()

    Process.sleep(interval)
    {:reconnect, %{state | retry_count: state.retry_count + 1}}
  end

  defp jitter(interval) do
    :rand.uniform(div(interval, 2)) + interval
  end
end
