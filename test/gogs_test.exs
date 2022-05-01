defmodule GogsTest do
  use ExUnit.Case
  doctest Gogs
  # @github_url "https://github.com/"

  # Cleanup helper functions
  defp delete_local_directory(dirname) do
    # IO.inspect(File.cwd(), label: "File.cwd()")
    File.rm_rf(dirname)
  end

  test "make_url/2 (without port) returns a valid GitHub Base URL" do
    url = "github.com"
    git_url = Gogs.make_url(url)
    assert git_url == "git@github.com:"
  end

  test "make_url/2 returns a valid Gogs (Fly.io) Base URL" do
    git_url = Gogs.make_url("gogs-server.fly.dev", "10022")
    assert git_url == "ssh://git@gogs-server.fly.dev:10022/"
  end

  test "remote_url/3 returns a valid Gogs (Fly.io) remote URL" do
    git_url = Gogs.make_url("gogs-server.fly.dev", "10022")
    remote_url = Gogs.remote_url(git_url, "nelsonic", "public-repo")
    assert remote_url == "ssh://git@gogs-server.fly.dev:10022/nelsonic/public-repo.git"
  end

  # test "Gogs.create_org creates a new organisation on the Gogs instance" do
  #   res = Gogs.clone()
  #   IO.inspect(res)

  #   assert true == true
  #   delete_local_directory("public-repo")
  # end

  test "Gogs.clone clones a remote repository" do
    url = Envar.get("GOGS_URL")
    port = Envar.get("GOGS_SSH_PORT")
    git_url = Gogs.make_url(url, port)
    org = "nelsonic"
    repo = "public-repo"
    git_repo_url = Gogs.remote_url(git_url, org, repo)

    path = Gogs.clone(git_repo_url)
    IO.inspect(path)
    assert path == Gogs.local_repo_path(repo)

    # Attempt to clone it a second time to test the :error branch:
    path2 = Gogs.clone(git_repo_url)
    assert path == path2

    # Clean up:
    delete_local_directory("public-repo")
  end

end
