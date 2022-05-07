defmodule GogsTest do
  use ExUnit.Case, async: false
  doctest Gogs
  # @github_url "https://github.com/"
  @cwd File.cwd!
  @git_dir Envar.get("GIT_TEMP_DIR_PATH", @cwd)

  # Cleanup helper functions
  defp delete_local_directory(dirname) do
    # IO.inspect(File.cwd(), label: "File.cwd()")
    path = Path.join(GogsHelpers.temp_dir(@git_dir), dirname)
    IO.inspect(path)
    File.rm_rf(path)
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
    IO.inspect(repo_name, label: "repo_name")
    {:ok, response} = Gogs.remote_repo_create(org_name, repo_name, false)
    response = Map.drop(response, [:id, :created_at, :updated_at])
    IO.inspect(response.name)

    mock_response = Gogs.HTTPoisonMock.make_repo_create_post_response_body(repo_name)
    IO.inspect(mock_response.name)
    assert response.name == mock_response.name

    # Cleanup:
    Gogs.remote_repo_delete(org_name, repo_name)    
  end

  test "Gogs.clone clones a known remote repository Gogs on Fly.io" do
    org = "nelsonic"
    repo = "public-repo"
    git_repo_url = GogsHelpers.remote_url_ssh(org, repo)

    path = Gogs.clone(git_repo_url)
    IO.inspect(path)
    # assert path == GogsHelpers.local_repo_path(repo)

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
    org = "myorg"
    git_repo_url = GogsHelpers.remote_url_ssh(org, repo)
    path = Gogs.clone(git_repo_url)
    IO.inspect(path)
    assert path == GogsHelpers.local_repo_path(repo)
  end

  test "local_branch_create/1 creates a new branch on the localhost" do
    repo_name = create_test_git_repo("myorg")
    # delete draft branch if exists:
    Git.branch(GogsHelpers.local_git_repo(repo_name), ["-m", repo_name])
    Git.branch(GogsHelpers.local_git_repo(repo_name), ~w(-D draft))


    {:ok, res} = Gogs.local_branch_create(repo_name, "draft")
    assert String.contains?(res, "'draft'")

    # Try create the "draft" branch again. Should error but not "throw":
    {:ok, err} = Gogs.local_branch_create(repo_name, "draft")
    assert String.contains?(err, "'draft'")

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

  test "commit/2 creates a commit in the repo" do
    repo_name = create_test_git_repo("myorg")
    file_name = "README.md"
    assert :ok ==
      Gogs.local_file_write_text(repo_name, file_name, "text #{repo_name}")

    # Confirm the text was written to the file:
    file_path = Path.join([GogsHelpers.local_repo_path(repo_name), file_name])
    assert {:ok,"text #{repo_name}" } == File.read(file_path)

    {:ok, msg} = Gogs.commit(repo_name, 
      %{message: "test msg", full_name: "Al Ex", email: "c@t.co"})
    assert String.contains?(msg, "test msg")
    assert String.contains?(msg, "1 file changed, 1 insertion(+)")

    # Cleanup!
    Gogs.remote_repo_delete("myorg", repo_name)
    delete_local_directory(repo_name)
  end

  test "push/2 pushes the commit to the remote repo" do
    repo_name = create_test_git_repo("myorg")
    
    file_name = "README.md"
    assert :ok ==
      Gogs.local_file_write_text(repo_name, file_name, "text #{repo_name}")

    # Confirm the text was written to the file:
    file_path = Path.join([GogsHelpers.local_repo_path(repo_name), file_name])
    assert {:ok,"text #{repo_name}" } == File.read(file_path)

    # Commit the updated text:
    {:ok, msg} = Gogs.commit(repo_name, %{message: "test msg", full_name: "Al Ex", email: "c@t.co"})
    assert String.contains?(msg, "test msg")

    # Push to Gogs Server!
    Gogs.push(repo_name)

    # Cleanup!
    Gogs.remote_repo_delete("myorg", repo_name)
    # delete_local_directory(repo_name)
  end
end
