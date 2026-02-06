defmodule Talon.Infra.Docker.Adapter do
  alias Talon.Infra.Docker.Client, as: Client
  alias Talon.Infra.Docker.Types, as: Types

  @spec list_containers() :: [Types.container_in_list()]
  def list_containers() do
    {:ok, raw} = Client.request(:get, "containers/json")

    Enum.map(raw, fn raw ->
      %{
        id: raw["Id"],
        names: raw["Names"],
        image: raw["Image"],
        image_id: raw["ImageID"],
        command: raw["Command"],
        created: raw["Created"],
        state: raw["State"],
        status: raw["Status"]
      }
    end)
  end

  @spec inspect_container(String.t()) :: Types.container_inpect()
  def inspect_container(id) do
    {:ok, raw} = Client.request(:get, "containers/#{id}/json")

    %{
      id: raw["Id"],
      name: raw["Name"],
      created: raw["Created"],
      path: raw["Path"],
      args: raw["Args"],
      state: %{status: raw["State"]["Status"]},
      image: raw["Image"]
    }
  end
end
