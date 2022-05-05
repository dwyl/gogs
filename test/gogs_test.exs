defmodule GogsTest do
  use ExUnit.Case
  doctest Gogs
  # @github_url "https://github.com/"

  # Cleanup helper functions
  defp delete_local_directory(dirname) do
    # IO.inspect(File.cwd(), label: "File.cwd()")
    File.rm_rf(dirname)
  end

  # Create a test repo with the name "test-repo123"
  defp test_repo() do
    "test-repo" <> Integer.to_string(System.unique_integer([:positive]))
  end

  def create_test_git_repo(org_name) do
    repo_name = test_repo()
    Gogs.remote_repo_create(org_name, repo_name, false)
    git_repo_url = GogsHelpers.remote_url_ssh(org_name, repo_name)
    Gogs.clone(git_repo_url)

    repo_name
  end

  test "remote_repo_create/3 creates a new repo on the Gogs server" do
    org_name = "myorg"
    repo_name = test_repo()
    response = Gogs.remote_repo_create(org_name, repo_name, false)
    mock_response = Gogs.HTTPoisonMock.make_repo_create_post_response_body(repo_name)
    assert response == {:ok, mock_response}

    # Cleanup:
    Gogs.remote_repo_delete(org_name, repo_name)    
  end

  test "Gogs.clone clones a known remote repository Gogs on Fly.io" do
    org = "nelsonic"
    repo = "public-repo"
    git_repo_url = GogsHelpers.remote_url_ssh(org, repo)

    path = Gogs.clone(git_repo_url)
    # IO.inspect(path)
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
    # IO.inspect(path)
    assert path == GogsHelpers.local_repo_path(repo)

    # Clean up:
    delete_local_directory(repo)
  end

  test "Gogs.clone error (simulate unhappy path)" do
    repo = "error"
    org = "nelsonic"
    git_repo_url = GogsHelpers.remote_url_ssh(org, repo)
    path = Gogs.clone(git_repo_url)
    IO.inspect(path)
    assert path == GogsHelpers.local_repo_path(repo)
  end

  test "local_branch_create/1 creates a new branch on the localhost" do
    repo_name = create_test_git_repo("myorg")
    # delete before if exists:
    Git.branch(GogsHelpers.local_git_repo(repo_name), ~w(-D draft))

    {:ok, res} = Gogs.local_branch_create(repo_name, "draft")
    assert res == "Switched to a new branch 'draft'\n"

    # Cleanup!
    Gogs.remote_repo_delete("myorg", repo_name)
    delete_local_directory(repo_name)
    Git.branch(GogsHelpers.local_git_repo(repo_name), ~w(-D draft))
  end


  test "write_text_to_file/3 writes text to a specified file" do
    repo_name = create_test_git_repo("myorg")
    file_name = "README.md"
    assert :ok ==
      Gogs.local_file_write_text(repo_name, file_name, "text #{repo_name}")

    # Confirm the text was written to the file:
    file_path = Path.join([GogsHelpers.local_repo_path(repo_name), file_name])
    assert {:ok,"text #{repo_name}" } == File.read(file_path)

    # Cleanup!
    Gogs.remote_repo_delete("myorg", repo_name)
    delete_local_directory(repo_name)
  end

end
