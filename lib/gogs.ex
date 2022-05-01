defmodule Gogs do
  @moduledoc """
  Documentation for `Gogs`.
  This package is the `Elixir` interface with our `Gogs` Server.
  It contains all functions we need to create repositories,
  clone them, add data to repos, commit, push and diff.
  Some of these functions use `Git` and others use the `REST API`.
  We would _obviously_ prefer if everything was one or the other,
  but sadly, some things cannot be done via `Git` or `REST`
  so we have adopted a "hybrid" approach.
  """
  Envar.load(".env")

  @httpoison (Application.compile_env(:gogs, :httpoison_mock) &&
                Gogs.HTTPoisonMock) || HTTPoison

  @doc """
  `inject_poison/0` injects a TestDouble of HTTPoison in Test
  so that we don't have duplicate mock in consuming apps.
  see: https://github.com/dwyl/elixir-auth-google/issues/35
  """
  def inject_poison, do: @httpoison

  @doc """
  make_url/0 constructs the URL based on the supplied git `url` and TCP `port`
  returns the remote url for cloning.
  If the `port` is set it will be a custom Gogs instance.

  ## Examples
    iex> Gogs.make_url("gogs-server.fly.dev", "10022")
    "ssh://git@gogs-server.fly.dev:10022/"
  
    iex> Gogs.make_url("github.com")
    "git@github.com:"

  """
  def make_url(url, port \\ 0) do
    if port > 0 do
      "ssh://git@#{url}:#{port}/"
    else
      "git@#{url}:"
    end
  end


  @doc """
  returns the remote url for cloning
  """
  def remote_url(url, org, repo) do
    "#{url}#{org}/#{repo}.git"
  end




  def clone do
    url = Envar.get("GOGS_URL")
    port = Envar.get("GOGS_SSH_PORT")
    git_url = make_url(url, port)
    org = "nelsonic"
    repo = "public-repo"
    case Git.clone remote_url(git_url, org, repo) do
      {:ok, %Git.Repository{path: path}} ->
        # IO.inspect(path)
        path
      {:error, %Git.Error{message: message}} ->
        IO.inspect("Attempted to clone #{org}/#{repo}, got: #{message}")
        local_repo_path(repo)
    end
  end

  # def commit do
    
  # end

  defp local_repo_path(repo) do
    temp_dir() <> "/" <> repo
  end

  def temp_dir do
    File.cwd!
  end
end
