defmodule GogsHttpTest do
  use ExUnit.Case, async: true

  # can you think of a better way of testing/simulating this error condition? 
  test "GogsHttp.parse_body_response({:error, err})" do
    assert GogsHttp.parse_body_response({:error, "err"}) == {:error, "err"}
  end

  # We've seen an empty body returned in practice. But how to test it ...? 
  test "GogsHttp.parse_body_response({:ok, response}) with empty/nil body" do
    res = %{body: ""}
    assert GogsHttp.parse_body_response({:ok, res}) == {:error, :no_body}
  end
  
  test "GogsHttp.get/1 gets (or mocks) an HTTP GET request to Gogs Server" do
    url = "https://gogs-server.fly.dev/api/v1/repos/nelsonic/public-repo"
    {:ok, res} = GogsHttp.get(url)

    assert true == true
  end
end
