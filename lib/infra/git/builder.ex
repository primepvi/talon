defmodule Talon.Infra.Git.Builder do
  alias Talon.Models.Buildpack
  alias Talon.Infra.Docker.Dockerfile

  @spec generate_tar(String.t(), Buildpack.t()) :: {:ok, String.t()} | {:error, String.t()}
  def generate_tar(path, bp) do
    tar_path = "#{path}.tar"
    abs_path = Path.expand(path) |> String.to_charlist()
    abs_tar_path = Path.expand(tar_path) |> String.to_charlist()
    dockerfile_content = Dockerfile.generate(bp)

    case :erl_tar.create(
           abs_tar_path,
           [
             {~c"Dockerfile", dockerfile_content},
             {~c".", abs_path}
           ],
           [:compressed]
         ) do
      :ok ->
        File.rm_rf!(path)
        {:ok, tar_path}

      {:error, reason} ->
        {:error, "Unexpected error during tar generation: #{inspect(reason)}"}

      _ ->
        {:error, "Unexpected error occurred during tar generation."}
    end
  end
end
