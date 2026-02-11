defmodule Talon.Server.Process.State do
  defstruct [:id, :name, status: :idle]

  @type process_status() :: :idle | :running | :error

  @type t() :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    status: process_status()
  }
end
