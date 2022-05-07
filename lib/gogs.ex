defmodule Gogs do
  @moduledoc """
  Documentation for the main `Gogs` functions.  
  This package is an `Elixir` interface to our `Gogs` Server.
  It contains all functions we need to create repositories,
  clone, add data to files, commit, push and diff.
  Some of these functions use `Git` and others use the `REST API`.
  We would _obviously_ prefer if everything was one or the other,
  but sadly, some things cannot be done via `Git` or `REST`
  so we have adopted a "hybrid" approach.

  If anything is unclear, please open an issue: 
  https://github.com/dwyl/gogs/issues
  """
  import GogsHelpers
  require Logger

  @access_token Envar.get("GOGS_ACCESS_TOKEN")
  @api_base_url GogsHelpers.api_base_url()
  @mock Application.compile_env(:gogs, :mock)
  @git (@mock && Gogs.GitMock) || Git
  @httpoison (@mock && Gogs.HTTPoisonMock) || HTTPoison

  @doc """
  `inject_git/0` injects a `Git` TestDouble in Tests & CI
  so we don't have duplicate mocks in the downstream app.
  """
  def inject_git, do: @git

  @doc """
  `inject_poison/0` injects a TestDouble of HTTPoison in Test.
  see: github.com/dwyl/elixir-auth-google/issues/35
  """
  def inject_poison, do: @httpoison

  @doc """
  `post/2` accepts two arguments: `url` and `params`. 
  Makes an `HTTP POST` request to the specified `url`
  passing in the `params` as the request body.
  Auth Headers and Content-Type are implicit.
  """
  @spec post(String.t(), map) :: {:ok, map} | {:error, any}
  def post(url, params \\ %{}) do
    # IO.inspect(url, label: url)
    body = Jason.encode!(params)
    headers = [
      {"Accept", "application/json"},
      {"Authorization", "token #{@access_token}"},
      {"Content-Type", "application/json"}
    ]
    inject_poison().post(url, body, headers)
    |> parse_body_response()
  end

  @doc """
  `remote_repo_create/3` accepts 3 arguments: `org_name`, `repo_name` & `private`.
  It creates a repo on the remote `Gogs` instance as defined 
  by the environment variable `GOGS_URL`.
  For convenience it assumes that you only have _one_ `Gogs` instance.
  If you have more or different requirements, please share!
  """
  @spec remote_repo_create(String.t(), String.t(), boolean) :: {:ok, map} | {:error, any}
  def remote_repo_create(org_name, repo_name, private \\ false) do
    url = @api_base_url <> "org/#{org_name}/repos"
    Logger.info("remote_repo_create api endpoint: #{url}")
    
    params = %{
      name: repo_name,
      private: private,
      description: repo_name,
      readme: repo_name
    }
    post(url, params)
  end

  @doc """
  `delete/1` accepts a single argument `url`; 
  the `url` for the repository to be deleted.
  """
  @spec delete(String.t()) :: {:ok, map} | {:error, any}
  def delete(url) do
    inject_poison().delete(url <> "?token=#{@access_token}")
    |> parse_body_response()
  end

  @doc """
  `remote_repo_delete/2` accepts two arguments: `org_name` and `repo_name`.
  It deletes the repo on the remote `Gogs` instance as defined 
  by the environment variable `GOGS_URL`.
  """
  @spec remote_repo_delete(String.t(), String.t()) :: {:ok, map} | {:error, any}
  def remote_repo_delete(org_name, repo_name) do
    url = @api_base_url <> "repos/#{org_name}/#{repo_name}"
    Logger.info("remote_repo_delete: #{url}")
    delete(url)
  end

  @doc """
  `clone/1` clones a remote git repository based on `git_repo_url`
  returns the path of the _local_ copy of the repository.
  """
  @spec clone(String.t()) :: {:ok, any} | {:error, any}
  def clone(git_repo_url) do
    repo_name = get_repo_name_from_url(git_repo_url)
    local_path = local_repo_path(repo_name)
    Logger.info("git clone #{git_repo_url} #{local_path}")
    case inject_git().clone([git_repo_url, local_path])  do
      {:ok, %Git.Repository{path: path}} ->
        # Logger.info("Cloned repo: #{git_repo_url} to: #{path}")
        path
      {:error, %Git.Error{message: message}} ->
        Logger.error("ERROR: Tried to clone #{git_repo_url}, got: #{message}")
        local_path
    end
  end

  @doc """
  `local_branch_create/2` creates a branch with the specified name
  or defaults to "draft".
  """ 
  @spec local_branch_create(String.t(), String.t()) :: {:ok, map} | {:error, any}
  def local_branch_create(repo_name, branch_name \\ "draft") do
    case Git.checkout(local_git_repo(repo_name), ["-b", branch_name]) do
      {:ok, res} ->
        {:ok, res}
      {:error, %Git.Error{message: message}} -> 
        Logger.error("Git.checkout error: #{message}")
        {:ok, message}
    end
  end

  @doc """
  `local_file_write_text/3` writes the desired `text`,
  to the `file_name` in the `repo_name`. 
  Touches the file in case it doesn't already exist.
  """ 
  @spec local_file_write_text(String.t(), String.t(), String.t()) :: :ok | {:error, any}
  def local_file_write_text(repo_name, file_name, text) do
    file_path = Path.join([local_repo_path(repo_name), file_name])
    Logger.info("attempting to write to #{file_path}")
    File.touch!(file_path)
    File.write(file_path, text)
  end
  
  @doc """
  `commit/2` commits the latest changes on the local branch.
  Accepts the `repo_name` and a `Map` of `params`:
  `params.message`: the commit message you want in the log
  `params.full_name`: the name of the person making the commit
  `params.email`: email address of the person committing. 
  """ 
  @spec commit(String.t(), map) :: {:ok, any} | {:error, any}
  def commit(repo_name, params) do
    repo = %Git.Repository{path: local_repo_path(repo_name)}
    # Add all files in the repo
    {:ok, _output} = Git.add(repo, ["."])
    # Commit with message
    {:ok, _output} = Git.commit(repo, [
        "-m",
        params.message,
        ~s(--author="#{params.full_name} <#{params.email}>")
      ])
  end

  @doc """
  `push/1` pushes the `repo_name` (current active branch)
  to the remote repository URL. Mocked during test/CI.
  """ 
  @spec push(String.t()) :: {:ok, any} | {:error, any}
  def push(repo_name) do
    # Get the current git branch:
    git_repo = %Git.Repository{path: local_repo_path(repo_name)}
    {:ok, branch} = Git.branch(git_repo,  ~w(--show-current))
    # Remove trailing whitespace as Git chokes on it:
    branch = String.trim(branch)
    # Push the current branch:
    inject_git().push(git_repo, ["-u", "origin", branch])
  end

end
  