defmodule Talon.Panel.MessageHandler do
  alias Talon.Panel.Connection
  alias Talon.App.Supervisor

  def dispatch(%{"type" => "app.deploy"} = message) do
    %{"correlation_id" => correlation_id, "payload" => payload} = message
    ack(correlation_id, {:rejected, "todo"})
  end

  defp ack(correlation_id, :accepted) do
    Connection.send_message(%{
      type: "ack",
      correlation_id: correlation_id,
      payload: %{status: "accepted"}
    })
  end

  defp ack(correlation_id, {:rejected, reason}) do
    Connection.send_message(%{
      type: "ack",
      correlation_id: correlation_id,
      payload: %{status: "rejected", reason: reason}
    })
  end
end
