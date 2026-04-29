defmodule Talon.Payloads.App.Update do
  use Talon.Schema

  field(:id, :string, required: true)
  field(:keys, :list, of: :string, required: true)
  field(:data, :map, required: true)

  @type t() :: %{
          id: String.t(),
          keys: list(String.t()),
          data: map()
        }
end
