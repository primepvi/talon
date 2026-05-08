defmodule Talon.Infra.Git do
  @spec clone(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def clone(repository, target, branch \\ "main", commit \\ "HEAD") do
    base_path = Application.get_env(:talon, :repo_directory, "./talon/")
    path = Path.expand(Path.join(base_path, target))

    File.mkdir_p!(base_path)

    case System.cmd("git", ["clone", "--depth", "1", "--branch", branch, repository, path],
           stderr_to_stdout: true
         ) do
      {_out, 0} ->
        checkout_commit(commit, path)

      {out, _code} ->
        {:error, "Unexpected error during clone: #{out}"}
    end
  end

  @spec checkout_commit(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp checkout_commit("HEAD", path), do: {:ok, path}

  defp checkout_commit(commit, path) do
    case System.cmd("git", ["-C", path, "checkout", commit], stderr_to_stdout: true) do
      {_out, 0} -> {:ok, path}
      {out, _} -> {:error, "Failed to checkout commit #{commit}: #{out}"}
    end
  end
end
