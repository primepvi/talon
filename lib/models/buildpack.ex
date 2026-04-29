defmodule Talon.Models.Buildpack do
  use Talon.Schema

  defmodule Param do
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

  field(:name, :string, required: true)
  field(:image, :string, required: true)
  field(:params, :list, of: :schema, schema: Param, required: true)

  @type t() :: %{
          name: String.t(),
          image: String.t(),
          params: list(Param.t())
        }
end
