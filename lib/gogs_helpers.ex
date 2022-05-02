defmodule GogsHelpers do
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
end