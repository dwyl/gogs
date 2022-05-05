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

  test "Gogs.clone clones a remote repository Gogs on Fly.io" do
    org = "nelsonic"
    repo = "public-repo"
    git_repo_url = GogsHelpers.remote_url_ssh(org, repo)

    path = Gogs.clone(git_repo_url)
    IO.inspect(path)
    assert path == GogsHelpers.local_repo_path(repo)

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
    assert path == GogsHelpers.local_repo_path(repo)

    # Clean up:
    delete_local_directory(repo)
  end

  test "local_branch_create/1 creates a new branch on the localhost" do
    org_name = "myorg"
    repo_name = "test-repo" <> Integer.to_string(System.unique_integer([:positive]))
    Gogs.remote_repo_create(org_name, repo_name, false)
    IO.puts "waiting for repo to be created"
    :timer.sleep(1000)
    IO.puts "done."
    git_repo_url = GogsHelpers.remote_url_ssh(org_name, repo_name)
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


end
