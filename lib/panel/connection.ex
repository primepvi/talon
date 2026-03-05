defmodule Talon.Panel.Connection do
  use WebSockex

  alias Talon.Panel.Message
  alias Talon.Panel.MessageHandler
  alias Talon.Payloads.App
  alias Talon.Payloads.Node

  # @backoff_intervals [1_000, 2_000, 4_000, 8_000, 30_000]

  def start_link(_opts \\ []) do
    url = Application.get_env(:talon, :panel_url)
    token = Application.get_env(:talon, :panel_token)

    WebSockex.start_link(url, __MODULE__, %{retry_count: 0},
      name: __MODULE__,
      extra_headers: [{"Authorization", "Bearer #{token}"}]
    )
  end

  @spec send_message(Message.t(any())) :: :ok
  def send_message(message) do
    data = %{
      type: message.type,
      correlation_id: message.correlation_id,
      payload: Map.from_struct(message.payload)
    }

    WebSockex.cast(__MODULE__, {:send, {:text, Jason.encode!(data)}})
  end

  @spec send_app_state(String.t(), App.State.t()) :: :ok
  def send_app_state(correlation_id, payload) do
    send_message(%Message{
      type: "app.state",
      correlation_id: correlation_id,
      payload: payload
    })
  end

  defp send_node_register() do
    %Message{
      type: "node.register",
      correlation_id: UUID.uuid4(),
      payload: %Node.Register{
        node_id: Application.get_env(:talon, :node_id, "banana"),
        version: "v0.1"
      }
    }
    |> send_message
  end

  @impl true
  def handle_connect(_conn, state) do
    send_node_register()
    {:ok, %{state | retry_count: 0}}
  end

  @impl true
  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    response = msg
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
