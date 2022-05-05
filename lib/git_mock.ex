defmodule Gogs.GitMock do
  @moduledoc """
  Mock functions to simulate Git commands.
  Sadly, this is necessary until we figure out how to get write-access
  on GitHub CI. See: https://github.com/dwyl/gogs/issues/15
  """
  # require Logger

  @doc """
  `clone/1` clones a _real_ Gogs Repo but renames it to `repo_name`
  so that it can be used in other tests. This is ugly, we agree!
  But we want something we can use in our end-to-end tests
  without having to re-invent all of Git.
  If you can think of a cleaner way of doing this, please share!
  """
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
