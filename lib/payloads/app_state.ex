defmodule Talon.Payloads.App.State do
  defstruct [:app_id, :deploy_id, :state, reason: nil]

  @type t() :: %__MODULE__{
    app_id: String.t(),
    deploy_id: String.t(),
    state: Talon.App.Process.State.status(),
    reason: String.t() | nil
  }
end
