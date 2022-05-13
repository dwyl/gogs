defmodule Gogs.HelpersTest do
  use ExUnit.Case, async: true
  doctest Gogs.Helpers

  test "Gogs.Helpers.api_base_url/0 returns the API URL for the Gogs Server" do
    assert Gogs.Helpers.api_base_url() == "https://gogs-server.fly.dev/api/v1/"
  end

  test "temp_dir/1 returns cwd if no dir supplied" do
    dir = Envar.get("GITHUB_WORKSPACE", "tmp")
    assert Gogs.Helpers.temp_dir(dir) == dir
  end

  test "make_url/2 (without port) returns a valid GitHub Base URL" do
    url = "github.com"
    git_url = Gogs.Helpers.make_url(url)
    assert git_url == "git@github.com:"
  end

  test "make_url/2 returns a valid Gogs (Fly.io) Base URL" do
    git_url = Gogs.Helpers.make_url("gogs-server.fly.dev", "10022")
    assert git_url == "ssh://git@gogs-server.fly.dev:10022/"
  end

  test "remote_url/3 returns a valid Gogs (Fly.io) remote URL" do
    git_url = Gogs.Helpers.make_url("gogs-server.fly.dev", "10022")
    remote_url = Gogs.Helpers.remote_url(git_url, "nelsonic", "public-repo")
    assert remote_url == "ssh://git@gogs-server.fly.dev:10022/nelsonic/public-repo.git"
  end
end
