defmodule Talon.Models.BuildpackParam do
  use Talon.Schema

  field(:name, :string, required: true)
  field(:required, :boolean, default: false)
  field(:default, :any, default: nil)

  @type t() :: %{
          name: String.t(),
          required: boolean(),
          default: any()
        }
end
