defmodule Talon.Models.Deploy.Buildpack do
  alias Talon.Models.Deploy.BuildpackArgument
  use Talon.Schema

  field(:name, :string, required: true)
  field(:arguments, :list, of: :schema, schema: BuildpackArgument, required: true)

  @type t() :: %{
          name: String.t(),
          arguments: list(BuildpackArgument.t())
        }
end
