defmodule Gogs.GitMock do
  @moduledoc """
  Mock functions to simulate Git commands.
  Sadly, this is necessary until we figure out how to get write-access
  on GitHub CI.
  """
  # require Logger

  @doc """
  `clone/1` (mock) returns the path of the existing `test-repo`
  so that no remote cloning occurs. This is needed for CI and
  is used in downstream tests to speed up suite execution.

    ## Examples
    iex> GitMock.clone("ssh://gogs-server.fly.dev:10022/myorg/public-repo.git")
    {:ok, %Git.Repository{path: "/path/to/public-repo"}}

    iex> GitMock.clone("any-url-containing-the-word-error-to-trigger-failure")
    {:error, %Git.Error{message: "git clone error (mock)"}}
  """
  @spec clone(String.t()) :: {:ok, %Git.Repository{}} | {:error, %Git.Error{}}
  def clone(url) do
    if String.contains?(url, "error") do
      {:error, %Git.Error{message: "git clone error (mock)"}}
    else
      {:ok, %Git.Repository{path: GogsHelpers.local_repo_path("test-repo")}}
    end
  end

  # def checkout(_, _) do
  #   {:ok, "Switched to a new branch 'draft'\n"}
  # end
end
