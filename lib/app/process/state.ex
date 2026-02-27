defmodule Talon.App.Process.State do
  defstruct [:app, status: :empty, container_id: nil, deploy_id: nil]

  @type status() :: :empty | :idle | :deploying | :running  | :failed | :crashed

  @type t() :: %__MODULE__{
    app: Talon.Payloads.App.Create.t(),
    status: status(),
    container_id: String.t() | nil,
    deploy_id: String.t() | nil
  }
end
