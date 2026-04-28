defmodule Talon.Models.Buildpack do
  alias Talon.Models.BuildpackParam
  use Talon.Schema

  field(:name, :string, required: true)
  field(:image, :string, required: true)
  field(:params, :list, of: :schema, schema: BuildpackParam, required: true)

  @type t() :: %{
          name: String.t(),
          image: String.t(),
          params: list(BuildpackParam.t())
        }
end
