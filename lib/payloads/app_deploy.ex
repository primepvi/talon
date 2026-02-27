defmodule Talon.Payloads.App.Deploy do
  import Talon.Payloads.Validator

  defstruct [:app_id, :deploy_id]

  defp validate_raw(payload) do
    validate(payload, [
      required(payload, [:app_id, :deploy_id]),
      validate_string(payload, :app_id),
      validate_string(payload, :deploy_id)
    ])
  end

  @type t() :: %__MODULE__{
          app_id: String.t(),
          deploy_id: String.t()
        }

  def from_map(map) do
    case validate_raw(map) do
      {:ok, _map} ->
        {:ok,
         %__MODULE__{
           app_id: map["app_id"],
           deploy_id: map["deploy_id"]
         }}

      error ->
        error
    end
  end
end
