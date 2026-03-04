defmodule Talon.Payloads.Node.Sync do
  alias Talon.Payloads.App

  defstruct [:apps]

  @type t() :: %__MODULE__{
    apps: list(App.Create.t())
  }

  def from_map(map) do
    %__MODULE__{
      apps: map["apps"]
    }
  end
end
