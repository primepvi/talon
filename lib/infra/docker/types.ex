defmodule Talon.Infra.Docker.Types do
  @type container_state() :: :created | :running | :paused | :restarting | :exited | :removing | :dead
  @type container_in_list() :: %{
    id: String.t(),
    names: [String.t()],
    image: String.t(),
    image_id: String.t(),
    command: String.t(),
    created: integer(),
    state: container_state(),
    status: String.t(),
  }

  @type container_inpect() :: %{
    id: String.t(),
    name: String.t(),
    created: String.t(),
    path: String.t(),
    args: [String.t()],
    state: %{ status: container_state() },
    image: String.t(),
  }
end
