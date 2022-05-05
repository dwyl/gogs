defmodule Gogs.GitMock do
  @moduledoc """
  Mock functions to simulate Git commands.
  Sadly, this is necessary until we figure out how to get write-access
  on GitHub CI. See: https://github.com/dwyl/gogs/issues/15
  """
  require Logger

  def rename_repo(real_repo, destination) do
    source = GogsHelpers.local_repo_path(real_repo)
    Logger.info("rename: #{source} to: #{destination}")
    File.rename!(source, destination)
  end
  
  @doc """
  `clone/1` clones a _real_ Gogs Repo but renames it to `repo_name`
  so that it can be used in other tests. This is ugly, we agree!
  But we want something we can use in our end-to-end tests
  without having to re-invent all of Git.
  If you can think of a cleaner way of doing this, please share!
  """
  def clone(url) do
    # Logger.info("MOCK clone: #{url}")
    # save this for later:
    repo_name = GogsHelpers.get_repo_name_from_url(url)
    destination = GogsHelpers.local_repo_path(repo_name)

    # Clone the *real* repo:
    real_repo = "public-repo"
    git_repo_url = GogsHelpers.remote_url_ssh("nelsonic", real_repo)
    
    # Run the *real* clone:
    case Git.clone(git_repo_url)  do
      {:ok, %Git.Repository{path: path}} ->
        Logger.info("MOCK actually cloned: #{git_repo_url} to: #{path}")

        # rename the local repo to repo_name
        rename_repo(real_repo, destination)

        # return the path to the renamed repo:
        {:ok, %Git.Repository{path: destination}}

      {:error, %Git.Error{message: message}} ->
        # Logger.info("MOCK Tried to clone #{git_repo_url}, got: #{message} (but it's ok!)")
        rename_repo(real_repo, destination)
        # pass the actual error back to the Gogs.clone function:
        {:error, %Git.Error{message: message}}
    end
  end

  def checkout(_, _) do
    {:ok, "Switched to a new branch 'draft'\n"}
  end
end
