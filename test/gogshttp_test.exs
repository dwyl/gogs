defmodule GogsHttpTest do
  use ExUnit.Case, async: true
  # Function tests that work both when mock: true and false!

  # can you think of a better way of testing/simulating this error condition? 
  test "GogsHttp.parse_body_response({:error, err})" do
    assert Gogs.Http.parse_body_response({:error, "err"}) == {:error, "err"}
  end

  # We've seen an empty body returned in practice. But how to test it ...? 
  test "GogsHttp.parse_body_response({:ok, response}) with empty/nil body" do
    res = %{body: ""}
    assert Gogs.Http.parse_body_response({:ok, res}) == {:error, :no_body}
  end

  test "GogsHttp.get/1 gets (or mocks) an HTTP GET request to Gogs Server" do
    repo_name = "public-repo"
    url = "https://gogs-server.fly.dev/api/v1/repos/myorg/#{repo_name}"
    {:ok, response} = Gogs.Http.get(url)
    # remove unpredictable fields from response when mock:false
    drop_fields = ~w(created_at default_branch description id readme size updated_at watchers_count)a
    response = Map.drop(response, drop_fields)
    mock_response = Gogs.HTTPoisonMock.make_repo_create_post_response_body(repo_name)
    assert response == mock_response
  end
end
