defmodule Talon.Panel.MessageHandler do
  alias Talon.Panel.Connection
  alias Talon.Payloads
  alias Talon.App.Engine

  @spec dispatch(Talon.Panel.Message.t()) :: :ok
  def dispatch(%{"type" => "app.create"} = message) do
    %{"correlation_id" => correlation_id, "payload" => raw_payload} = message

    with {:ok, payload} <- Payloads.App.Create.from_map(raw_payload),
         {:ok, _pid} <- Engine.handle_app_create(payload) do
      ack(correlation_id, :accepted)
    else
      {:error, reason} -> ack(correlation_id, {:rejected, reason})
    end
  end

  def dispatch(%{"type" => "app.deploy"} = message) do
    %{"correlation_id" => correlation_id, "payload" => raw_payload} = message

    with {:ok, payload} <- Payloads.App.Deploy.from_map(raw_payload),
         {:ok, _pid} <- Talon.App.Supervisor.get_process(payload.app_id),
         {:ok, nil} <- Engine.handle_app_deploy(payload) do
      ack(correlation_id, :accepted)
    else
      {:error, reason} -> ack(correlation_id, {:rejected, reason})
    end
  end

  @spec ack(String.t(), :accepted) :: :ok
  defp ack(correlation_id, :accepted) do
    Connection.send_message(%{
      type: "ack",
      correlation_id: correlation_id,
      payload: %{status: "accepted"}
    })
  end

  @spec ack(String.t(), {:rejected, String.t()}) :: :ok
  defp ack(correlation_id, {:rejected, reason}) do
    Connection.send_message(%{
      type: "ack",
      correlation_id: correlation_id,
      payload: %{status: "rejected", reason: reason}
    })
  end
end
