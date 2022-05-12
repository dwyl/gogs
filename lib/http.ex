defmodule GogsHttp do
  @moduledoc """
  Documentation for the `HTTP` "verb" functions.
  Should be self-explanatory.
  Each function documented & typespecd.  
  If anything is unclear, please open an issue: 
  [github.com/dwyl/**gogs/issues**](https://github.com/dwyl/gogs/issues)
  """
  require Logger

  @access_token Envar.get("GOGS_ACCESS_TOKEN")
  # HTTP Headers don't change so hard-coded here:
  @auth_header {"Authorization", "token #{@access_token}"}
  @headers [
    {"Accept", "application/json"},
    @auth_header,
    {"Content-Type", "application/json"}
  ]
  @mock Application.compile_env(:gogs, :mock)
  Logger.debug("GogsHttp > config :gogs, mock: #{to_string(@mock)}")
  @httpoison (@mock && Gogs.HTTPoisonMock) || HTTPoison

  @doc """
  `inject_poison/0` injects a TestDouble of HTTPoison in Test.
  see: https://github.com/dwyl/elixir-auth-google/issues/35
  """
  def inject_poison, do: @httpoison

  @doc """
  `parse_body_response/1` parses the response returned by the Gogs Server
  so your app can use the resulting JSON.
  """
  @spec parse_body_response({atom, String.t()} | {:error, any}) :: {:ok, map} | {:error, any}
  def parse_body_response({:error, err}), do: {:error, err}

  def parse_body_response({:ok, response}) do
    # Logger.debug(response) # very noisy!
    body = Map.get(response, :body)
    if body == nil || byte_size(body) == 0 do
      Logger.warning("GogsHttp.parse_body_response: response body is nil!")
      {:error, :no_body}
    else
      {:ok, str_key_map} = Jason.decode(body)
      # make keys of map atoms for easier access in templates etc.
      {:ok, Useful.atomize_map_keys(str_key_map)}
    end
  end

  @doc """
  `get/1` accepts one argument: `url` the REST API endpoint. 
  Makes an `HTTP GET` request to the specified `url`.
  Auth Headers and Content-Type are implicit.
  returns `{:ok, map}`
  """
  @spec get(String.t()) :: {:ok, map} | {:error, any}
  def get(url) do
    Logger.debug("GogsHttp.get #{url}")
    inject_poison().get(url, @headers)
    |> parse_body_response()
  end

  @doc """
  `get_raw/1` as it's name suggests gets the raw data
  (expects the reponse to be plaintext not JSON)
  accepts one argument: `url` the REST API endpoint. 
  Makes an `HTTP GET` request to the specified `url`.
  Auth Headers and Content-Type are implicit.
  returns `{:ok, map}`
  """
  @spec get_raw(String.t()) :: {:ok, map} | {:error, any}
  def get_raw(url) do
    Logger.debug("GogsHttp.get_raw #{url}")
    inject_poison().get(url, [@auth_header])
  end

  @doc """
  `post_raw_html/2` accepts two arguments: `url` and `raw_markdown`. 
  Makes an `HTTP POST` request to the specified `url`
  passing in the `params` as the request body.
  Does NOT attempt to parse the response body as JSON.
  Auth Headers and Content-Type are implicit.
  """
  @spec post_raw_html(String.t(), String.t()) :: {:ok, String.t()} | {:error, any}
  def post_raw_html(url, raw_markdown) do
    Logger.debug("GogsHttp.post_raw #{url}")
    # Logger.debug("raw_markdown: #{raw_markdown}")
    headers = [
      {"Accept", "text/html"},
      @auth_header,
    ]
    inject_poison().post(url, raw_markdown, headers)
  end

  @doc """
  `post/2` accepts two arguments: `url` and `params`. 
  Makes an `HTTP POST` request to the specified `url`
  passing in the `params` as the request body.
  Auth Headers and Content-Type are implicit.
  """
  @spec post(String.t(), map) :: {:ok, map} | {:error, any}
  def post(url, params \\ %{}) do
    Logger.debug("GogsHttp.post #{url}")
    body = Jason.encode!(params)
    inject_poison().post(url, body, @headers)
    |> parse_body_response()
  end

  @doc """
  `delete/1` accepts a single argument `url`; 
  the `url` for the repository to be deleted.
  """
  @spec delete(String.t()) :: {:ok, map} | {:error, any}
  def delete(url) do
    Logger.debug("GogsHttp.delete #{url}")
    inject_poison().delete(url <> "?token=#{@access_token}")
    |> parse_body_response()
  end
end
  