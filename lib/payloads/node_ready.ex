defmodule Talon.Payloads.Node.Ready do
  defstruct [:apps]

  @type t() :: %__MODULE__{
          apps: list(%{app_id: String.t(), status: atom()})
        }
end
