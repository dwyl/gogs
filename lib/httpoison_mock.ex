defmodule Gogs.HTTPoisonMock do
  @moduledoc """
  Mock (stub) our API requests to the Gogs API
  so that we can test all of our code (with Mocks) on GitHub CI.
  These functions pattern match on the params
  and return the expected responses.
  If you know of a better way of doing this 
  (preferably without introducing more dependencies ...)
  Please share: 
  [github.com/dwyl/**gogs/issues**](https://github.com/dwyl/gogs/issues)
  """
  require Logger
  @remote_repo_create_response_body %{
    clone_url: "https://gogs-server.fly.dev/myorg/replacethis.git",
    # created_at: "0001-01-01T00:00:00Z",
    # default_branch: "public-repo",
    # description: "replacethis",
    empty: false,
    fork: false,
    forks_count: 0,
    full_name: "myorg/replacethis",
    html_url: "https://gogs-server.fly.dev/myorg/replacethis",
    # id: 42,
    mirror: false,
    name: "replacethis",
    open_issues_count: 0,
    owner: %{
      avatar_url: "https://gogs-server.fly.dev/avatars/2",
      email: "",
      full_name: "",
      id: 2,
      login: "myorg",
      username: "myorg"
    },
    parent: nil,
    permissions: %{admin: true, pull: true, push: true},
    private: false,
    # size: 0,
    ssh_url: "ssh://git@gogs-server.fly.dev:10022/myorg/replacethis.git",
    stars_count: 0,
    # updated_at: "0001-01-01T00:00:00Z",
    # watchers_count: 0,
    website: ""
  }

  # make a valid response body for testing
  def make_repo_create_post_response_body(repo_name) do
    Map.merge(@remote_repo_create_response_body, %{
      clone_url: "https://gogs-server.fly.dev/myorg/#{repo_name}.git",
      # description: repo_name,
      full_name: "myorg/#{repo_name}",
      html_url: "https://gogs-server.fly.dev/myorg/#{repo_name}",
      ssh_url: "ssh://git@gogs-server.fly.dev:10022/myorg/#{repo_name}.git",
      # readme: repo_name,
      name: repo_name
    })
  end

  @raw_response {:ok, %HTTPoison.Response{
    body: "# public-repo\n\nplease don't update this. the tests read it.",
    status_code: 200
  }}

  @doc """
  `get/2` mocks the HTTPoison.get/2 function when parameters match test vars.
  Feel free refactor this if you can make it pretty. 
  """
  def get(url, _headers) do
    Logger.debug("Gogs.HTTPoisonMock.get/2 #{url}")
    case String.contains?(url, "/raw/") do
      true ->
        @raw_response
      false ->
        Logger.debug("Gogs.HTTPoisonMock.get/2 #{url}")
        repo_name = GogsHelpers.get_repo_name_from_url(url)
        response_body = 
          make_repo_create_post_response_body(repo_name)
          |> Jason.encode!()
        {:ok, %{body: response_body}}
    end
  end

  @doc """
  `post/3` mocks the HTTPoison.post/3 function when parameters match test vars.
  Feel free refactor this if you can make it pretty. 
  """
  def post(url, body, _headers) do
    Logger.debug("Gogs.HTTPoisonMock.post/3 #{url}")
    body_map = Jason.decode!(body) |> Useful.atomize_map_keys()
    response_body = 
      make_repo_create_post_response_body(body_map.name)
      |> Jason.encode!()
    {:ok, %{body: response_body}}
  end

  @doc """
  `delete/1` mocks the HTTPoison `delete` function.
  Feel free refactor this if you can make it pretty. 
  """
  def delete(url) do
    {:ok, %{body: Jason.encode!(%{deleted: List.first(String.split(url, "?"))})}}
  end
end
