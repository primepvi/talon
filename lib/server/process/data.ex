defmodule Talon.Server.Process.Data do
  defstruct [:name, :image, :repository, :source_type, tag: "latest"]

  @type source_type() :: :image | :dockerfile
  @type t() :: %__MODULE__{
    name: String.t(),
    image: String.t(),
    tag: String.t(),
    repository: String.t(),
    source_type: source_type()
  }
end
