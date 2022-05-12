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
  [github.com/dwyl/**gogs/issues**](https://github.com/dwyl/gogs/issues)
  """
  import GogsHelpers
  require Logger

  @api_base_url GogsHelpers.api_base_url()
  @mock Application.compile_env(:gogs, :mock)
  Logger.debug("Gogs > config :gogs, mock: #{to_string(@mock)}")
  @git (@mock && Gogs.GitMock) || Git

  @doc """
  `inject_git/0` injects a `Git` TestDouble in Tests & CI
  so we don't have duplicate mocks in the downstream app.
  """
  def inject_git, do: @git

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

    GogsHttp.post(url, params)
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
    GogsHttp.delete(url)
  end

  @doc """
  `remote_read_file/4` reads a file from the remote repo.
  Accepts 4 arguments: `org_name`, `repo_name`, `file_name` and `branch_name`.
  The 4<sup>th</sup> argument is *optional* and defaults to `"master"` 
  (the default branch for a repo hosted on `Gogs`).
  Makes a `GET` request to the remote `Gogs` instance as defined 
  by the environment variable `GOGS_URL`.
  Returns `{:ok, %HTTPoison.Response{ body: response_body}}`
  Uses REST API Endpoint:
  ```sh
  GET /repos/:username/:reponame/raw/:branchname/:path
  ```
  Ref: https://github.com/gogs/docs-api/blob/master/Repositories/Contents.md#get-contents
  """
  @spec remote_read_raw(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, map} | {:error, any}
  def remote_read_raw(org_name, repo_name, file_name, branch_name \\ "master") do
    url = @api_base_url <> "repos/#{org_name}/#{repo_name}/raw/#{branch_name}/#{file_name}"
    Logger.debug("Gogs.remote_read_raw: #{url}")
    GogsHttp.get_raw(url)
  end

  @doc """
  `remote_render_markdown_html/4` uses `Gog` built-in Markdown processor 
  to render a Markdown Doc e.g. the `README.md` so you can easily use the HTML.
  Accepts 4 arguments: `org_name`, `repo_name`, `file_name` and `branch_name`.
  The 4<sup>th</sup> argument is *optional* and defaults to `"master"` 
  (the default branch for a repo hosted on `Gogs`).
  Makes a `GET` request to the remote `Gogs` instance as defined 
  by the environment variable `GOGS_URL`.
  Returns `{:ok, %HTTPoison.Response{ body: response_body}}`
  Uses REST API Endpoint:
  ```sh
  POST /markdown/raw
  ```
  Ref: https://github.com/dwyl/gogs/issues/23
  """
  @spec remote_render_markdown_html(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, map} | {:error, any}
  def remote_render_markdown_html(org_name, repo_name, file_name, branch_name \\ "master") do
    # First retrieve the Raw Markdown Text we want to render:
    {:ok, %HTTPoison.Response{body: response_body}} =
      Gogs.remote_read_raw(org_name, repo_name, file_name)
    IO.inspect(response_body, label: "response_body")
    url = @api_base_url <> "markdown/raw"
    Logger.info("remote_render_markdown_html/4 #{url}")
    # temp_context = "https://github.com/gogs/gogs"
    # Ask Gogs to redner the Raw Markdown to HTML:
    GogsHttp.post_raw_html(url, %{text: response_body})
    # I agree, this is clunky ... We wont use it for latency-sensitive apps.
    # But it could be useful for a quick/easy Static Site / Blog App. 💭
  end

  @doc """
  `clone/1` clones a remote git repository based on `git_repo_url`
  returns the path of the _local_ copy of the repository.
  """
  @spec clone(String.t()) :: {:ok, any} | {:error, any}
  def clone(git_repo_url) do
    org_name = get_org_name_from_url(git_repo_url)
    repo_name = get_repo_name_from_url(git_repo_url)
    local_path = local_repo_path(org_name, repo_name)
    Logger.info("git clone #{git_repo_url} #{local_path}")

    case inject_git().clone([git_repo_url, local_path]) do
      {:ok, %Git.Repository{path: path}} ->
        # Logger.info("Cloned repo: #{git_repo_url} to: #{path}")
        path

      {:error, %Git.Error{message: message}} ->
        Logger.error("Gogs.clone/1 tried to clone #{git_repo_url}, got: #{message}")
        local_path
    end
  end

  @doc """
  `local_branch_create/3` creates a branch with the specified name
  or defaults to "draft".
  """
  @spec local_branch_create(String.t(), String.t()) :: {:ok, map} | {:error, any}
  def local_branch_create(org_name, repo_name, branch_name \\ "draft") do
    case Git.checkout(local_git_repo(org_name, repo_name), ["-b", branch_name]) do
      {:ok, res} ->
        {:ok, res}

      {:error, %Git.Error{message: message}} ->
        Logger.error("Git.checkout error: #{message}, #{repo_name} (should not thow error)")
        {:error, message}
    end
  end

  @doc """
  `local_file_read/3` reads the raw text from the `file_name`,
  params: `org_name`, `repo_name` & `file_name`
  """
  @spec local_file_read(String.t(), String.t(), String.t()) :: String.t()
  def local_file_read(org_name, repo_name, file_name) do
    file_path = Path.join([local_repo_path(org_name, repo_name), file_name])
    File.read(file_path)
  end

  @doc """
  `local_file_write_text/3` writes the desired `text`,
  to the `file_name` in the `repo_name`. 
  Touches the file in case it doesn't already exist.
  """
  @spec local_file_write_text(String.t(), String.t(), String.t(), String.t()) ::
          :ok | {:error, any}
  def local_file_write_text(org_name, repo_name, file_name, text) do
    file_path = Path.join([local_repo_path(org_name, repo_name), file_name])
    Logger.info("attempting to write to #{file_path}")
    File.touch!(file_path)
    File.write(file_path, text)
  end

  @doc """
  `commit/3` commits the latest changes on the local branch.
  Accepts the `repo_name` and a `Map` of `params`:
  `params.message`: the commit message you want in the log
  `params.full_name`: the name of the person making the commit
  `params.email`: email address of the person committing. 
  """
  @spec commit(String.t(), String.t(), map) :: {:ok, any} | {:error, any}
  def commit(org_name, repo_name, params) do
    repo = local_git_repo(org_name, repo_name)
    # Add all files in the repo
    {:ok, _output} = Git.add(repo, ["."])
    # Commit with message
    {:ok, _output} =
      Git.commit(repo, [
        "-m",
        params.message,
        ~s(--author="#{params.full_name} <#{params.email}>")
      ])
  end

  @doc """
  `push/2` pushes the `org_name/repo_name` (current active branch)
  to the remote repository URL. Mocked during test/CI.
  """
  @spec push(String.t(), String.t()) :: {:ok, any} | {:error, any}
  def push(org_name, repo_name) do
    # Get the current git branch:
    git_repo = local_git_repo(org_name, repo_name)
    {:ok, branch} = Git.branch(git_repo, ~w(--show-current))
    # Remove trailing whitespace as Git chokes on it:
    branch = String.trim(branch)
    # Push the current branch:
    inject_git().push(git_repo, ["-u", "origin", branch])
  end
end
