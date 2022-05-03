defmodule GogsTest do
  use ExUnit.Case
  doctest Gogs
  # @github_url "https://github.com/"

  # Cleanup helper functions
  defp delete_local_directory(dirname) do
    # IO.inspect(File.cwd(), label: "File.cwd()")
    File.rm_rf(dirname)
  end

  test "remote_repo_create/3 creates a new repo on the Gogs server" do
    org_name = "myorg"
    repo_name = "test-repo" <> Integer.to_string(System.unique_integer([:positive]))
    response = Gogs.remote_repo_create(org_name, repo_name, false)
    mock_response = Gogs.HTTPoisonMock.make_repo_create_post_response_body(repo_name)
    assert response == {:ok, mock_response}

    Gogs.remote_repo_delete(org_name, repo_name)    
  end

  # can you think of a better way of testing/simulating this error condition? 
  test "parse_body_response({:error, err})" do
    assert Gogs.parse_body_response({:error, "err"}) == {:error, "err"}
  end

  # We've seen an empty body returned in practice. But how to test it ...? 
  test "parse_body_response({:ok, response}) with empty/nil body" do
    response = %{body: ""}
    assert Gogs.parse_body_response({:ok, response}) == {:error, :no_body}
  end

  
  test "local_branch_create/1 creates a new branch on the localhost" do
    org_name = "myorg"
    repo_name = "test-repo" <> Integer.to_string(System.unique_integer([:positive]))
    Gogs.remote_repo_create(org_name, repo_name, false)
    IO.puts "waiting for repo to be crated" ; :timer.sleep(1000); IO.puts "done."
    git_repo_url = Gogs.remote_url_ssh(org_name, repo_name)
    _path = Gogs.clone(git_repo_url)
    # IO.inspect(path, label: "path:41")

    {:ok, res} = Gogs.local_branch_create(repo_name, "draft")
    # IO.inspect(res, label: "local_branch_create(repo_name) res")
    # IO.inspect(response, label: "org_create response")

    assert res == "Switched to a new branch 'draft'\n"

    # Cleanup!
    Gogs.remote_repo_delete(org_name, repo_name)
    delete_local_directory(repo_name)
  end

  

  # test "Gogs.create_org creates a new organisation on the Gogs instance" do
  #   res = Gogs.clone()
  #   IO.inspect(res)

  #   assert true == true
  #   delete_local_directory("public-repo")
  # end

  # test "remote_url/3 returns a valid Gogs (Fly.io) remote URL" do
  #   git_url = GogsHelpers.make_url("gogs-server.fly.dev", "10022")
  #   remote_url = Gogs.remote_url(git_url, "nelsonic", "public-repo")
  #   assert remote_url == "ssh://git@gogs-server.fly.dev:10022/nelsonic/public-repo.git"
  # end

  test "Gogs.clone clones a remote repository Gogs on Fly.io" do
    org = "nelsonic"
    repo = "public-repo"
    git_repo_url = Gogs.remote_url_ssh(org, repo)

    path = Gogs.clone(git_repo_url)
    IO.inspect(path)
    assert path == Gogs.local_repo_path(repo)

    # Attempt to clone it a second time to test the :error branch:
    path2 = Gogs.clone(git_repo_url)
    assert path == path2

    # Clean up:
    delete_local_directory("public-repo")
  end

  test "Gogs.clone clones a GitHub Repo just for completeness" do
    repo = "studio" # just cause it's empty but still a valid repo.
    git_repo_url = "git@github.com:dwyl/#{repo}.git"
    path = Gogs.clone(git_repo_url)
    IO.inspect(path)
    assert path == Gogs.local_repo_path(repo)

    # Clean up:
    delete_local_directory(repo)
  end
end
