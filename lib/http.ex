defmodule GogsHttp do
  @moduledoc """
  Documentation for the `HTTP` "verb" functions.  

  If anything is unclear, please open an issue: 
  https://github.com/dwyl/gogs/issues
  """
  import GogsHelpers
  require Logger

  @access_token Envar.get("GOGS_ACCESS_TOKEN")
  @mock Application.compile_env(:gogs, :mock)
  Logger.info("GogsHttp > config :gogs, mock: #{to_string(@mock)}")
  @httpoison (@mock && Gogs.HTTPoisonMock) || HTTPoison

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
  `delete/1` accepts a single argument `url`; 
  the `url` for the repository to be deleted.
  """
  @spec delete(String.t()) :: {:ok, map} | {:error, any}
  def delete(url) do
    inject_poison().delete(url <> "?token=#{@access_token}")
    |> parse_body_response()
  end
end
  