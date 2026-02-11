defmodule Talon.Server.Process.Data do
  defstruct [:name, :image, tag: "latest"]

  @type t() :: %__MODULE__{
    name: String.t(),
    image: String.t(),
    tag: String.t()
  }
end
