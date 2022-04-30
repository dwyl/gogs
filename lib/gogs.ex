defmodule Gogs do
  @moduledoc """
  Documentation for `Gogs`.
  """
  Envar.load(".env")

  @doc """
  make_url/0 constructs the URL based on the environment variables
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
  def remote_url(org, repo) do
    "ssh://git@gogs-server.fly.dev:10022/#{org}/#{repo}.git"
  end




  def clone do
    org = "nelsonic"
    repo = "public-repo"
    case Git.clone remote_url(org, repo) do
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
