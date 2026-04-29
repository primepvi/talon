defmodule Talon.Payloads.App.Action do
  use Talon.Schema

  field(:id, :string, required: true)

  @type t() :: %{
          id: String.t()
        }
end
