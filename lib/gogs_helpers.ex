defmodule GogsHelpers do
  @doc """
  `api_base_url/0` returns the `Gogs` Server REST API url for API requests.

  ## Examples
    iex> Gogs.api_base_url()
    "https://gogs-server.fly.dev/api/v1/"
  """
  def api_base_url do
    "https://" <> Envar.get("GOGS_URL") <> "/api/v1/"
  end
end