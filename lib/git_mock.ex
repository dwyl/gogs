defmodule Gogs.GitMock do
  @moduledoc """
  Mock functions to simulate Git commands.
  Sadly, this is necessary until we figure out how to get write-access
  on GitHub CI. This module is exported for testing convenience/speed 
  in downstream/dependent apps.
  """
  require Logger

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
  @spec clone(String.t() | list(String.t())) :: {:ok, Git.Repository.t()} | {:error, Git.Error}
  def clone(url) do
    case Useful.typeof(url) do
      # e.g: ["ssh://git@gogs.dev/myorg/error-test.git", "tmp/test-repo"]
      # recurse using just the url (String) portion of the list:
      "list" ->
        url |> List.first() |> clone()

      "binary" ->
        Logger.info("Gogs.GitMock.clone #{url}")

        if String.contains?(url, "error") do
          {:error, %Git.Error{message: "git clone error (mock)"}}
        else
          {:ok, %Git.Repository{path: Gogs.Helpers.local_repo_path("test-org", "test-repo")}}
        end
    end
  end

  @doc """
  `push/1` (mock) pushes the latest commits on the current branch 
  to the Gogs remote repository.

    ## Examples
    iex> GitMock.push("my-repo")
    {:ok, "To ssh://gogs-server.fly.dev:10022/myorg/my-repo.git\n"}
  """
  @spec push(Git.Repository.t(), [any]) :: {:ok, any}
  def push(%Git.Repository{path: repo_path}, _args) do
    Logger.info("Gogs.GitMock.push #{repo_path}")
    repo_name = Gogs.Helpers.get_repo_name_from_url(repo_path <> ".git")
    {:ok, "To ssh://gogs-server.fly.dev:10022/myorg/#{repo_name}.git\n"}
  end
end
