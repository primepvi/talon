defmodule Talon.Infra.Docker.Client do
  @finch Talon.Infra.Docker.Finch
  @version "v1.51"
  @base_url "http://127.0.0.1:2375/#{@version}/"
  
  def request(method, path, body \\ nil, headers \\ []) do
    url = @base_url <> path

    Finch.build(method, url, headers, body)
    |> Finch.request(@finch)
    |> parse()
  end

  def parse({:ok, %Finch.Response{status: status, body: body}}) do
    Jason.decode(body)
  end
end
