defmodule GogsTest do
  use ExUnit.Case, async: true
  require Logger
  doctest Gogs
  # Let's do this!! 🚀 
  @cwd File.cwd!()
  @git_dir Envar.get("GIT_TEMP_DIR_PATH", @cwd)
  @mock Application.compile_env(:gogs, :mock)

  # https://elixirforum.com/t/random-unisgned-64-bit-integers/31659
  # e.g: "43434105246416498"
  defp random_postive_int_str() do
    :crypto.strong_rand_bytes(7) |> :binary.decode_unsigned() |> Integer.to_string()
  end

  # Create a test repo with the name "test-repo123"
  defp test_repo() do
    "test-repo" <> random_postive_int_str()
  end

  defp create_test_git_repo(org_name) do
    repo_name = test_repo()
    Gogs.remote_repo_create(org_name, repo_name, false)
    git_repo_url = Gogs.Helpers.remote_url_ssh(org_name, repo_name)
    # Logger.debug("create_test_git_repo/1 git_repo_url: #{git_repo_url}")
    Gogs.clone(git_repo_url)

    repo_name
  end

  # Cleanup helper functions
  defp delete_local_directory(repo_name) do
    path = Path.join(Gogs.Helpers.temp_dir(@git_dir), repo_name)
    Logger.debug("GogsTest.delete_local_directory: #{path}")
    File.rm_rf(path)
  end

  defp teardown_local_and_remote(org_name, repo_name) do
    delete_local_directory(repo_name)
    Gogs.remote_repo_delete(org_name, repo_name)
  end

  test "remote_repo_create/3 creates a new repo on the Gogs server" do
    org_name = "myorg"
    repo_name = test_repo()
    {:ok, response} = Gogs.remote_repo_create(org_name, repo_name, false)
    response = Map.drop(response, [:id, :created_at, :updated_at])

    mock_response = Gogs.HTTPoisonMock.make_repo_create_post_response_body(repo_name)
    assert response.name == mock_response.name

    # Cleanup:
    teardown_local_and_remote(org_name, repo_name)
  end

  test "Gogs.remote_read_raw/4 retrieves the contents of the README.md file" do
    org_name = "myorg"
    repo_name = "public-repo"
    file_name = "README.md"

    {:ok, %HTTPoison.Response{body: response_body}} =
      Gogs.remote_read_raw(org_name, repo_name, file_name)

    expected = "# public-repo\n\nplease don't update this. the tests read it."
    assert expected == response_body
  end

  test "Gogs.remote_render_markdown_html/4 renders README.md file as HTML!" do
    org_name = "myorg"
    repo_name = "public-repo"
    file_name = "README.md"

    {:ok, %HTTPoison.Response{body: response_body}} =
      Gogs.remote_render_markdown_html(org_name, repo_name, file_name)

    # IO.inspect(response_body)
    assert Gogs.HTTPoisonMock.raw_html() == response_body
  end

  test "Gogs.clone clones a known remote repository Gogs on Fly.io" do
    org = "nelsonic"
    repo = "public-repo"
    git_repo_url = Gogs.Helpers.remote_url_ssh(org, repo)

    path = Gogs.clone(git_repo_url)
    # assert path == Gogs.Helpers.local_repo_path(repo)

    # Attempt to clone it a second time to test the :error branch:
    path2 = Gogs.clone(git_repo_url)
    assert path == path2

    # Clean up (but don't delete the remote repo!!)
    delete_local_directory("public-repo")
  end
  
  test "Gogs.clone error (simulate unhappy path)" do
    repo = "error"
    org = "myorg"
    git_repo_url = Gogs.Helpers.remote_url_ssh(org, repo)
    path = Gogs.clone(git_repo_url)
    assert path == Gogs.Helpers.local_repo_path(org, repo)
  end

  test "local_branch_create/1 creates a new branch on the localhost" do
    org_name = "myorg"
    repo_name = create_test_git_repo(org_name)
    # # delete draft branch if exists:
    Git.branch(Gogs.Helpers.local_git_repo(org_name, repo_name), ["-m", repo_name])
    Git.branch(Gogs.Helpers.local_git_repo(org_name, repo_name), ~w(-d draft))

    {:ok, res} = Gogs.local_branch_create(org_name, repo_name, "draft")
    assert res == "Switched to a new branch 'draft'\n"

    # Cleanup!
    teardown_local_and_remote(org_name, repo_name)
  end

  test "local_branch_create/2 returns error if repo doesn't exist" do
    repo_name = "no-repo-" <> random_postive_int_str()
    org_name = "no-org-" <> random_postive_int_str()
    {:error, error} = Gogs.local_branch_create(org_name, repo_name, "draft")
    # Unfortunately the error message depends on Git version, 
    # so we cannot assert the contents of the error message. 
    # but we know from the pattern match above that it did error.
    Logger.error("test: local_branch_create/1 > error: #{error}")
  end

  test "write_text_to_file/3 writes text to a specified file" do
    org_name = "myorg"
    repo_name = create_test_git_repo(org_name)
    file_name = "README.md"
    text = "text #{repo_name}"

    assert :ok ==
             Gogs.local_file_write_text(org_name, repo_name, file_name, text)

    # Confirm the text was written to the file:
    assert {:ok, text} == Gogs.local_file_read(org_name, repo_name, file_name)

    # Cleanup!
    teardown_local_and_remote(org_name, repo_name)
  end

  test "commit/2 creates a commit in the repo" do
    org_name = "myorg"
    repo_name = create_test_git_repo(org_name)
    file_name = "README.md"

    assert :ok ==
             Gogs.local_file_write_text(org_name, repo_name, file_name, "text #{repo_name}")

    # Confirm the text was written to the file:
    file_path = Path.join([Gogs.Helpers.local_repo_path(org_name, repo_name), file_name])
    assert {:ok, "text #{repo_name}"} == File.read(file_path)

    {:ok, msg} =
      Gogs.commit(org_name, repo_name, %{message: "test msg", full_name: "Al Ex", email: "c@t.co"})

    assert String.contains?(msg, "test msg")
    assert String.contains?(msg, "1 file changed, 1 insertion(+)")

    # Cleanup!
    teardown_local_and_remote(org_name, repo_name)
  end

  test "Gogs.push/2 pushes the commit to the remote repo" do
    org_name = "myorg"
    repo_name = create_test_git_repo(org_name)
    file_name = "README.md"
    text = "text #{repo_name}"

    assert :ok ==
             Gogs.local_file_write_text(org_name, repo_name, file_name, text)

    # Confirm the text was written to the file:
    file_path = Path.join([Gogs.Helpers.local_repo_path(org_name, repo_name), file_name])
    assert {:ok, "text #{repo_name}"} == File.read(file_path)

    # Commit the updated text:
    {:ok, msg} =
      Gogs.commit(org_name, repo_name, %{message: "test msg", full_name: "Al Ex", email: "c@t.co"})

    assert String.contains?(msg, "test msg")

    #  Push to Gogs Server!
    Gogs.push(org_name, repo_name)

    # Confirm the README.md of the newly created repo was updated:
    {:ok, %HTTPoison.Response{body: response_body}} =
      Gogs.remote_read_raw(org_name, repo_name, file_name)

    if @mock do
      assert response_body ==
        "# public-repo\n\nplease don't update this. the tests read it."
    else
      assert response_body == text
    end

    # Cleanup!
    teardown_local_and_remote(org_name, repo_name)
  end
end
