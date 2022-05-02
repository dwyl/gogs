defmodule Gogs.HTTPoisonMock do
  @moduledoc """
    This is a set up to mock (stub) our API requests to the GitHub API
    so that we can test all of our code in ElixirAuthGithub.
    These are just functions that pattern match on the entries
    and return things in the way we expect,
    so that we can check the pipeline in ElixirAuthGithub.github_auth
  """
  @remote_repo_create_response_body %{
    clone_url: "https://gogs-server.fly.dev/myorg/replacethis.git",
    created_at: "0001-01-01T00:00:00Z",
    default_branch: "",
    description: "replacethis",
    empty: false,
    fork: false,
    forks_count: 0,
    full_name: "myorg/replacethis",
    html_url: "https://gogs-server.fly.dev/myorg/replacethis",
    id: 17,
    mirror: false,
    name: "test-repo450",
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
    size: 0,
    ssh_url: "ssh://git@gogs-server.fly.dev:10022/myorg/replacethis.git",
    stars_count: 0,
    updated_at: "0001-01-01T00:00:00Z",
    watchers_count: 0,
    website: ""
  }

  # make a valid response body for testing
  def make_repo_create_post_response_body(repo_name) do
    Map.merge(@remote_repo_create_response_body, %{
      clone_url: "https://gogs-server.fly.dev/myorg/#{repo_name}.git",
      description: repo_name,
      full_name: "myorg/#{repo_name}",
      html_url: "https://gogs-server.fly.dev/myorg/#{repo_name}",
      ssh_url: "ssh://git@gogs-server.fly.dev:10022/myorg/#{repo_name}.git",
    })
  end

  @doc """
  `post/3` stubs the HTTPoison post function when parameters match test vars.
  feel free refactor this if you can make it pretty. 
  """
  def post("https://gogs-server.fly.dev/api/v1/org/myorg/repos", body, _headers) do
    # IO.inspect("Gogs.HTTPoisonMock.post/3 called!")
    body_map = Jason.decode!(body) |> Useful.atomize_map_keys()
    response_body = 
      make_repo_create_post_response_body(body_map.name)
      |> Jason.encode!()
    {:ok, %{body: response_body}}
  end

  

  # @body_email_nil %{
  #   access_token: "12345",
  #   login: "test_user",
  #   name: "Testy McTestface",
  #   email: nil,
  #   avatar_url: "https://avatars3.githubusercontent.com/u/10835816",
  #   id: "28"
  # }

  # @emails [
  #   %{
  #     "email" => "octocat@github.com",
  #     "verified" => true,
  #     "primary" => false,
  #     "visibility" => "private"
  #   },
  #   %{
  #     "email" => "private_email@gmail.com",
  #     "verified" => true,
  #     "primary" => true,
  #     "visibility" => "private"
  #   }
  # ]

  # def get!(url, headers \\ [], options \\ [])

  # def get!(
  #       "https://api.github.com/user",
  #       [
  #         {"User-Agent", "ElixirAuthGithub"},
  #         {"Authorization", "token 123"}
  #       ],
  #       _options
  #     ) do
  #   %{body: "{\"error\": \"test error\"}"}
  # end

  # def get!(
  #       "https://api.github.com/user",
  #       [
  #         {"User-Agent", "ElixirAuthGithub"},
  #         {"Authorization", "token 42"}
  #       ],
  #       _options
  #     ) do
  #   %{body: Jason.encode!(@body_email_nil)}
  # end

  # # user emails
  # def get!(
  #       "https://api.github.com/user/emails",
  #       [
  #         {"User-Agent", "ElixirAuthGithub"},
  #         {"Authorization", "token 42"}
  #       ],
  #       _options
  #     ) do
  #   %{body: Jason.encode!(@emails)}
  # end

  # def get!(_url, _headers, _options) do
  #   %{body: Jason.encode!(@valid_body)}
  # end

  # @doc """
  # `post/3` stubs the HTTPoison post! function when parameters match test vars.
  # """
  # def post!(url, body, headers \\ [], options \\ [])

  # def post!(
  #       "https://github.com/login/oauth/access_token?client_id=TEST_ID&client_secret=TEST_SECRET&code=1234",
  #       _body,
  #       _headers,
  #       _options
  #     ) do
  #   %{body: "error=error"}
  # end

  # def post!(
  #       "https://github.com/login/oauth/access_token?client_id=TEST_ID&client_secret=TEST_SECRET&code=123",
  #       _body,
  #       _headers,
  #       _options
  #     ) do
  #   %{body: "access_token=123"}
  # end



  # # for some reason GitHub's Post returns a URI encoded string
  # def post!(_url, _body, _headers, _options) do
  #   %{body: URI.encode_query(@valid_body)}
  # end
end
