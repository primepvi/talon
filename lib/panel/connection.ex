defmodule Talon.Panel.Connection do
  use WebSockex

  alias Talon.Panel.MessageHandler

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
    WebSockex.cast(__MODULE__, {:send, {:text, Jason.encode!(message)}})
  end

  @impl true
  def handle_connect(_conn, state) do
    %{
      type: "node.register",
      correlation_id: UUID.uuid4(),
      payload: %{
        node_id: "banana",
        version: "v0.1"
      }
    }
    |> send_message

    {:ok, %{state | retry_count: 0}}
  end

  @impl true
  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    msg
    |> Jason.decode!
    |> MessageHandler.dispatch

    {:ok, state}
  end

  @impl true
  def handle_disconnect(%{reason: reason}, state) do
    IO.inspect(reason, label: "Disconnected.")
    {:ok, state}
  end
end
