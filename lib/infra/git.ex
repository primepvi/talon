defmodule Talon.Infra.Git do
  @spec clone(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def clone(repository, target, branch \\ "main", commit \\ "HEAD") do
    base_path = Application.get_env(:talon, :repo_directory, "./talon/")
    path = Path.expand(Path.join(base_path, target))
    tar_path = "#{path}.tar"

    File.mkdir_p!(base_path)

    case System.cmd("git", ["clone", "--depth", "1", "--branch", branch, repository, path], stderr_to_stdout: true) do
      {_out, 0} ->
        checkout_commit(commit, path, tar_path)
      {out, _code} ->
        {:error, "Unexpected error during clone: #{out}"}
    end
  end

  @spec checkout_commit(String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp checkout_commit("HEAD", path, tar_path), do: generate_repo_tar(path, tar_path)
  defp checkout_commit(commit, path, tar_path) do
    case System.cmd("git", ["-C", path, "checkout", commit], stderr_to_stdout: true) do
      {_out, 0} -> generate_repo_tar(path, tar_path)
      {out, _} -> {:error, "Failed to checkout commit #{commit}: #{out}"}
    end
  end

  @spec generate_repo_tar(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp generate_repo_tar(path, tar_path) do
    abs_path = Path.expand(path) |> String.to_charlist()
    abs_tar_path = Path.expand(tar_path) |> String.to_charlist()

    case :erl_tar.create(abs_tar_path, [{~c".", abs_path}], [:compressed]) do
      :ok ->
        File.rm_rf!(path)
        {:ok, tar_path}

      {:error, reason} ->
        {:error, "Unexpected error during clone tar generation: #{inspect(reason)}"}

      _ -> {:error, "Unexpected error ocurred during git clone tar generation."}
    end
  end
end
