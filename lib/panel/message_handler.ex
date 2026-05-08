defmodule Talon.Panel.MessageHandler do
  alias Talon.App.Engine
  alias Talon.Panel.Connection
  alias Talon.Payloads
  alias Talon.Models

  @spec dispatch(Models.Message.t(map())) :: :ok
  def dispatch(%{"type" => "node.sync"} = message) do
    %{"correlation_id" => correlation_id, "payload" => raw_payload} = message

    with {:ok, payload} <- Payloads.Node.Sync.validate(raw_payload),
         {:ok, nil} <- Engine.handle_node_sync(correlation_id, payload) do
      Enum.each(payload.buildpacks, &Talon.BuildpackStore.put/1)
      ack(correlation_id, :ok)
    else
      {:error, reason} -> ack(correlation_id, {:error, reason})
    end
  end

  def dispatch(%{"type" => "app.create"} = message) do
    %{"correlation_id" => correlation_id, "payload" => raw_payload} = message

    with {:ok, payload} <- Models.App.validate(raw_payload),
         {:ok, nil} <- Engine.handle_app_create(correlation_id, payload) do
      ack(correlation_id, :ok)
    else
      {:error, reason} -> ack(correlation_id, {:error, reason})
    end
  end

  def dispatch(%{"type" => "app.update"} = message) do
    %{"correlation_id" => correlation_id, "payload" => raw_payload} = message

    with {:ok, payload} <- Payloads.App.Update.validate(raw_payload),
         {:ok, nil} <- Engine.handle_app_update(correlation_id, payload) do
      ack(correlation_id, :ok)
    else
      {:error, reason} -> ack(correlation_id, {:error, reason})
    end
  end

  def dispatch(%{"type" => "app.deploy"} = message) do
    %{"correlation_id" => correlation_id, "payload" => raw_payload} = message

    with {:ok, payload} <- Models.Deploy.validate(raw_payload),
         {:ok, nil} <- Engine.handle_app_deploy(correlation_id, payload) do
      ack(correlation_id, :ok)
    else
      {:error, reason} -> ack(correlation_id, {:error, reason})
    end
  end

  @spec ack(String.t(), :ok) :: :ok
  defp ack(correlation_id, :ok) do
    {:ok, payload} = Payloads.Ack.validate(%{error: false})

    Connection.send_message(%{
      type: "ack",
      correlation_id: correlation_id,
      payload: payload
    })
  end

  @spec ack(String.t(), {:error, String.t()}) :: :ok
  defp ack(correlation_id, {:error, reason}) do
    {:ok, payload} = Payloads.Ack.validate(%{error: true, reason: reason})

    Connection.send_message(%{
      type: "ack",
      correlation_id: correlation_id,
      payload: payload
    })
  end
end
