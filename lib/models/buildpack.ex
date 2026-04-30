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

  defmodule Env do
    use Talon.Schema

    field(:name, :string, required: true)
    field(:value, :string)
    field(:from_param, :string)

    @type t() :: %{
            name: String.t(),
            value: String.t() | nil,
            from_param: String.t() | nil
          }
  end

  defmodule Step do
    use Talon.Schema

    field(:type, :string, required: true)
    field(:src, :string)
    field(:dest, :string)
    field(:path, :string)
    field(:command, :list, of: :string)

    @type t() :: %{
            type: String.t(),
            src: String.t() | nil,
            dest: String.t() | nil,
            path: String.t() | nil,
            command: list(String.t()) | nil
          }
  end

  field(:name, :string, required: true)
  field(:image, :string, required: true)
  field(:params, :list, of: :schema, schema: Param, required: true)
  field(:env, :list, of: :schema, schema: Env, default: [], required: true)
  field(:steps, :list, of: :schema, schema: Step, default: [], required: true)

  @type t() :: %{
          name: String.t(),
          image: String.t(),
          params: list(Param.t()),
          env: list(Env.t()),
          steps: list(Step.t())
        }
end
