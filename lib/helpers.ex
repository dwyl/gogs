defmodule GogsHelpers do
  @moduledoc """
  Helper functions that can be unit tested independently of the main functions.
  If you spot any way to make these better, please share:
  https://github.com/dwyl/gogs/issues
  """
  require Logger
  @cwd File.cwd!
  @git_dir Envar.get("GIT_TEMP_DIR_PATH", @cwd)
  @mock Application.compile_env(:gogs, :mock)

  @doc """
  `api_base_url/0` returns the `Gogs` Server REST API url for API requests.

  ## Examples
    iex> GogsHelpers.api_base_url()
    "https://gogs-server.fly.dev/api/v1/"
  """
  def api_base_url do
    "https://" <> Envar.get("GOGS_URL") <> "/api/v1/"
  end

  @doc """
  `make_url/2` constructs the URL based on the supplied git `url` and TCP `port`.
  If the `port` is set it will be a custom Gogs instance.

  ## Examples
    iex> GogsHelpers.make_url("gogs-server.fly.dev", "10022")
    "ssh://git@gogs-server.fly.dev:10022/"
  
    iex> GogsHelpers.make_url("github.com")
    "git@github.com:"

  """
  def make_url(git_url, port \\ 0) do
    if port > 0 do
      "ssh://git@#{git_url}:#{port}/"
    else
      "git@#{git_url}:"
    end
  end

    @doc """
  `remote_url/3` returns the git remote url.
  """
  def remote_url(base_url, org, repo) do
    "#{base_url}#{org}/#{repo}.git"
  end

  @doc """
  `remote_url_ssh/2` returns the remote ssh url for cloning.
  """
  def remote_url_ssh(org, repo) do
    url = Envar.get("GOGS_URL")
    port = Envar.get("GOGS_SSH_PORT")
    git_url = GogsHelpers.make_url(url, port)
    remote_url(git_url, org, repo)
  end

  @doc """
  `get_repo_name_from_url/1` extracts the repository name from a .git url.
  Feel free to refactor/simplify this function if you want.
  """ 
  def get_repo_name_from_url(url) do
    String.split(url, "/") |> List.last() |> String.split(".git") |> List.first()
  end

  @doc """
  `local_repo_path/1` returns the full system path for the cloned repo
  on the `localhost` i.e. the Elixir/Phoenix server that cloned it.
  """ 
  def local_repo_path(repo_name) do
    # coveralls-ignore-start
    if @mock do
      Path.join([temp_dir(@git_dir), "test-repo"])
    else
      Path.join([temp_dir(@git_dir), repo_name])
    end
    # coveralls-ignore-stop
  end

  @doc """
  `local_git_repo/1` returns the `%Git.Repository{}` (struct) for a `repo_name`
  on the `localhost`. This is used by the `Git` module to perform operations.
  """ 
  def local_git_repo(repo_name) do
    %Git.Repository{path: local_repo_path(repo_name)}
  end

  @doc """
  `temp_dir/1` returns the Current Working Directory (CWD).
  Made this a function in case we want to change the location of the
  directory later e.g. to a temporary directory. 
  """ 
  def temp_dir(dir \\ nil) do
    # Logger.info("temp_dir: #{dir} ")
    if dir && File.exists?(dir) do
      dir
    # coveralls-ignore-start
    else
      File.cwd!
    # coveralls-ignore-stop
    end
  end
end