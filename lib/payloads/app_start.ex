defmodule Talon.Payloads.App.Start do
  import Talon.Payloads.Validator

  defstruct [:app_id]

  defp validate_raw(payload) do
    validate(payload, [
      required(payload, ["app_id"]).
      validate_string(payload, "app_id")
    ])
  end

  @type t() :: %__MODULE__{
    app_id: String.t()
  }

  def from_map(map) do
    with {:ok, _map} <- validate_raw(map) do
      %__MODULE__{
        app_id: map["app_id"]
      }
    end
  end
end
