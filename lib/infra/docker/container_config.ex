defmodule Talon.Infra.Docker.ContainerConfig do
  defstruct [:name, :image, :memory, :cpu, :port, tag: "latest", env: %{}]

  @type t() :: %__MODULE__{
    name: String.t(),
    image: String.t(),
    tag: String.t(),
    cpu: float(),
    memory: integer(),
    env: list(String.t()),
    port: integer()
  }
end
