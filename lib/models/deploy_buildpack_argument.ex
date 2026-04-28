defmodule Talon.Models.Deploy.BuildpackArgument do
  use Talon.Schema

  field(:name, :string, required: true)
  field(:value, :any, required: true)

  @type t() :: %{
          name: String.t(),
          value: any()
        }
end
