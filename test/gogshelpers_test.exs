defmodule GogsHelpersTest do
  use ExUnit.Case
  doctest GogsHelpers

  test "GogsHelpers.api_base_url/0 returns the API URL for the Gogs Server" do
    assert GogsHelpers.api_base_url() == "https://gogs-server.fly.dev/api/v1/"
  end

  test "make_url/2 (without port) returns a valid GitHub Base URL" do
    url = "github.com"
    git_url = GogsHelpers.make_url(url)
    assert git_url == "git@github.com:"
  end

  test "make_url/2 returns a valid Gogs (Fly.io) Base URL" do
    git_url = GogsHelpers.make_url("gogs-server.fly.dev", "10022")
    assert git_url == "ssh://git@gogs-server.fly.dev:10022/"
  end

  test "remote_url/3 returns a valid Gogs (Fly.io) remote URL" do
    git_url = GogsHelpers.make_url("gogs-server.fly.dev", "10022")
    remote_url = GogsHelpers.remote_url(git_url, "nelsonic", "public-repo")
    assert remote_url == "ssh://git@gogs-server.fly.dev:10022/nelsonic/public-repo.git"
  end

  # can you think of a better way of testing/simulating this error condition? 
  test "parse_body_response({:error, err})" do
    assert GogsHelpers.parse_body_response({:error, "err"}) == {:error, "err"}
  end

  # We've seen an empty body returned in practice. But how to test it ...? 
  test "parse_body_response({:ok, response}) with empty/nil body" do
    res = %{body: ""}
    assert GogsHelpers.parse_body_response({:ok, res}) == {:error, :no_body}
  end
end
