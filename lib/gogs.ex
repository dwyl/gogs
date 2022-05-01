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
  """

  @httpoison (Application.compile_env(:gogs, :httpoison_mock) &&
                Gogs.HTTPoisonMock) || HTTPoison

  @doc """
  `inject_poison/0` injects a TestDouble of HTTPoison in Test
  so that we don't have duplicate mock in consuming apps.
  see: github.com/dwyl/elixir-auth-google/issues/35
  """
  def inject_poison, do: @httpoison

  @doc """
  make_url/2 constructs the URL based on the supplied git `url` and TCP `port`.
  If the `port` is set it will be a custom Gogs instance.

  ## Examples
    iex> Gogs.make_url("gogs-server.fly.dev", "10022")
    "ssh://git@gogs-server.fly.dev:10022/"
  
    iex> Gogs.make_url("github.com")
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
  returns the remote url for cloning
  """
  def remote_url(base_url, org, repo) do
    "#{base_url}#{org}/#{repo}.git"
  end



  @doc """
  clone/1 clones a remote git repository based on `git_repo_url`
  returns the path of the _local_ copy of the repository.

  """ 
  def clone(git_repo_url) do
    IO.inspect("git clone #{git_repo_url}")
    case Git.clone(git_repo_url)  do
      {:ok, %Git.Repository{path: path}} ->
        # IO.inspect(path)
        path
      {:error, %Git.Error{message: _message}} ->
        # IO.inspect("Attempted to clone #{git_repo_url}, got: #{message}")
        get_repo_name_from_url(git_repo_url) |> local_repo_path()
    end
  end

  # def commit do
    
  # end


  # Feel free to refactor/simplify this function if you want.
  def get_repo_name_from_url(url) do
    String.split(url, "/") |> List.last() |> String.split(".git") |> List.first()
  end

  def local_repo_path(repo) do
    temp_dir() <> "/" <> repo
  end

  defp temp_dir do
    File.cwd!
  end
end
