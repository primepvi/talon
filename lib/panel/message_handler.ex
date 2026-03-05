defmodule Talon.Panel.MessageHandler do
  alias Talon.Panel.Connection
  alias Talon.Payloads
  alias Talon.App.Engine
  alias Talon.Panel.Message

  @spec dispatch(Message.t(map())) :: :ok
  def dispatch(%{"type" => "node.sync"} = message) do
    %{"correlation_id" => correlation_id, "payload" => raw_payload} = message

    with {:ok, payload} <- Payloads.Node.Sync.from_map(raw_payload),
         {:ok, nil} <- Engine.handle_node_sync(correlation_id, payload) do
      ack(correlation_id, :accepted)
    else
      {:error, reason} -> ack(correlation_id, {:rejected, reason})
    end
  end

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
         {:ok, nil} <- Engine.handle_app_deploy(correlation_id, payload) do
      ack(correlation_id, :accepted)
    else
      {:error, reason} -> ack(correlation_id, {:rejected, reason})
    end
  end

  def dispatch(%{"type" => "app.redeploy"} = message) do
    %{"correlation_id" => correlation_id, "payload" => raw_payload} = message

    with {:ok, payload} <- Payloads.App.Redeploy.from_map(raw_payload),
         {:ok, _pid} <- Talon.App.Supervisor.get_process(payload.app_id),
         {:ok, nil} <- Engine.handle_app_redeploy(correlation_id, payload) do
      ack(correlation_id, :accepted)
    else
      {:error, reason} -> ack(correlation_id, {:rejected, reason})
    end
  end

  def dispatch(%{"type" => "app.start"} = message) do
    %{"correlation_id" => correlation_id, "payload" => raw_payload} = message

    with {:ok, payload} <- Payloads.App.Start.from_map(raw_payload),
         {:ok, _pid} <- Talon.App.Supervisor.get_process(payload.app_id),
         {:ok, nil} <- Engine.handle_app_action(:start, correlation_id, payload) do
      ack(correlation_id, :accepted)
    else
      {:error, reason} -> ack(correlation_id, {:rejected, reason})
    end
  end

  def dispatch(%{"type" => "app.stop"} = message) do
    %{"correlation_id" => correlation_id, "payload" => raw_payload} = message

    with {:ok, payload} <- Payloads.App.Start.from_map(raw_payload),
         {:ok, _pid} <- Talon.App.Supervisor.get_process(payload.app_id),
         {:ok, nil} <- Engine.handle_app_action(:stop, correlation_id, payload) do
      ack(correlation_id, :accepted)
    else
      {:error, reason} ->
        ack(correlation_id, {:rejected, reason})
    end
  end

  def dispatch(%{"type" => "app.destroy"} = message) do
    %{"correlation_id" => correlation_id, "payload" => raw_payload} = message

    with {:ok, payload} <- Payloads.App.Start.from_map(raw_payload),
         {:ok, _pid} <- Talon.App.Supervisor.get_process(payload.app_id),
         {:ok, nil} <- Engine.handle_app_action(:destroy, correlation_id, payload) do
      ack(correlation_id, :accepted)
    else
      {:error, reason} -> ack(correlation_id, {:rejected, reason})
    end
  end

  @spec ack(String.t(), :accepted) :: :ok
  defp ack(correlation_id, :accepted) do
    Connection.send_message(%Message{
      type: "ack",
      correlation_id: correlation_id,
      payload: %Payloads.Ack{status: "accepted"}
    })
  end

  @spec ack(String.t(), {:rejected, String.t()}) :: :ok
  defp ack(correlation_id, {:rejected, reason}) do
    Connection.send_message(%Message{
      type: "ack",
      correlation_id: correlation_id,
      payload: %Payloads.Ack{status: "rejected", reason: reason}
    })
  end
end
