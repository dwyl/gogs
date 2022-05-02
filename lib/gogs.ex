defmodule Gogs do
  @moduledoc """
  Documentation for `Gogs`.
  This package is an `Elixir` interface to our `Gogs` Server.
  It contains all functions we need to create repositories,
  clone, add data to files, commit, push and diff.
  Some of these functions use `Git` and others use the `REST API`.
  We would _obviously_ prefer if everything was one or the other,
  but sadly, some things cannot be done via `Git` or `REST`
  so we have adopted a "hybrid" approach.

  The functions in this file are defined in the order that we
  are _using_ them. So they tell a story. 
  If you are reading this and prefer to order them alphabetically
  or some other way, please share by opening an issue: 
  github.com/dwyl/gogs/issues
  """
  @access_token Envar.get("GOGS_ACCESS_TOKEN")
  @api_base_url GogsHelpers.api_base_url()
  @httpoison (Application.compile_env(:gogs, :httpoison_mock) &&
                Gogs.HTTPoisonMock) || HTTPoison

  @doc """
  `inject_poison/0` injects a TestDouble of HTTPoison in Test
  so that we don't have duplicate mock in consuming apps.
  see: github.com/dwyl/elixir-auth-google/issues/35
  """
  def inject_poison, do: @httpoison

  @doc """
  returns the remote url for cloning
  """
  def remote_url(base_url, org, repo) do
    "#{base_url}#{org}/#{repo}.git"
  end

  @doc """
  `parse_body_response/1` parses the response returned by the Gogs Server
  so your app can use the resulting JSON.
  """
  @spec parse_body_response({atom, String.t()} | {:error, any}) :: {:ok, map} | {:error, any}
  def parse_body_response({:error, err}), do: {:error, err}

  def parse_body_response({:ok, response}) do
    # IO.inspect(response)
    body = Map.get(response, :body)
    # make keys of map atoms for easier access in templates
    if body == nil || byte_size(body) == 0 do
      # IO.inspect("response body is nil")
      {:error, :no_body}
    else
      {:ok, str_key_map} = Jason.decode(body)
      {:ok, Useful.atomize_map_keys(str_key_map)}
    end
  end

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
  def remote_repo_create(org_name, repo_name, private \\ false) do
    url = @api_base_url <> "org/#{org_name}/repos"
    # IO.inspect(url, label: "remote_repo_create url")
    params = %{
      name: repo_name,
      private: private,
      description: repo_name
    }
    post(url, params)
  end

  @doc """
  `delete/1` accepts a single argument `url`; 
  the `url` for the repository to be deleted.
  """
  @spec delete(String.t()) :: {:ok, map} | {:error, any}
  def delete(url) do
    inject_poison().delete(url)
    |> parse_body_response()
  end

  @doc """
  `remote_repo_delete/2` accepts two arguments: `org_name` and `repo_name`.
  It deletes the repo on the remote `Gogs` instance as defined 
  by the environment variable `GOGS_URL`.
  """
  def remote_repo_delete(org_name, repo_name) do
    url = @api_base_url <> "repos/#{org_name}/#{repo_name}?token=#{@access_token}"
    IO.inspect(url, label: "remote_repo_delete url")
    delete(url)
  end


  @doc """
  `clone/1` clones a remote git repository based on `git_repo_url`
  returns the path of the _local_ copy of the repository.
  """ 
  def clone(git_repo_url) do
    # IO.inspect("git clone #{git_repo_url}")
    case Git.clone(git_repo_url)  do
      {:ok, %Git.Repository{path: path}} ->
        # IO.inspect(path)
        path
      {:error, %Git.Error{message: _message}} ->
        # IO.inspect("Attempted to clone #{git_repo_url}, got: #{message}")
        get_repo_name_from_url(git_repo_url) |> local_repo_path()
    end
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
  def local_repo_path(repo) do
    temp_dir() <> "/" <> repo
  end

  # Made this a function in case we want to 
  defp temp_dir do
    File.cwd!
  end


  # def commit do
    
  # end
end
