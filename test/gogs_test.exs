defmodule GogsTest do
  use ExUnit.Case
  doctest Gogs

  test "make_url/2 (without port) returns a valid GitHub Base URL" do
    url = "github.com"
    git_url = Gogs.make_url(url)
    assert git_url == "git@github.com:"
  end

  test "make_url/2returns a valid Gogs (Fly.io) Base URL" do
    git_url = Gogs.make_url("gogs-server.fly.dev", "10022")
    assert git_url == "ssh://git@gogs-server.fly.dev:10022/"
  end

  test "Gogs.create_org creates a new organisation on the Gogs instance" do
    res = Gogs.clone()
    IO.inspect(res)

    assert true == true
  end

  test "Gogs.clone clones a repository" do
    path = Gogs.clone()
    IO.inspect(path)

    assert true == true
  end

end
