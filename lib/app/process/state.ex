defmodule Talon.App.Process.State do
  defstruct [:app, :status, container_id: nil, deploy_id: nil]

  @type status() :: :empty | :idle | :running | :crashed

  @type t() :: %__MODULE__{
    app: Talon.Payloads.App.Create.t(),
    status: status(),
    container_id: String.t() | nil,
    deploy_id: String.t() | nil
  }
end
