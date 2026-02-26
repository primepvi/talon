defmodule Talon.App.Process.State do
  defstruct [:app, container_id: nil, deploy_id: nil]

  @type t() :: %__MODULE__{
    app: Talon.Payloads.App.Create.t(),
    container_id: String.t() | nil,
    deploy_id: String.t() | nil
  }
end
