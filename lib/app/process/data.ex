defmodule Talon.App.Process.Data do
  alias Talon.Infra.Docker.ContainerConfig

  defstruct [:config, :repository, :source_type]

  @type source_type() :: :image | :dockerfile
  @type t() :: %__MODULE__{
    config: ContainerConfig.t(),
    repository: String.t(),
    source_type: source_type()
  }
end
