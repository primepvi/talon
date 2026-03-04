defmodule Talon.Infra.Docker.ContainerConfig do
  defstruct [:app_id, :name, :image, :memory, :cpu, :port, tag: "latest", env: %{}]

  @type t() :: %__MODULE__{
    app_id: String.t(),
    name: String.t(),
    image: String.t(),
    tag: String.t(),
    cpu: float(),
    memory: integer(),
    env: list(String.t()),
    port: integer()
  }
end
