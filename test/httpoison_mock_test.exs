defmodule HttPoisonMockTest do
  use ExUnit.Case, async: true
  # Mock function tests that work both when mock: true and false!

  test "Gogs.HTTPoisonMock.get /raw/ returns 200" do
    {:ok, %HTTPoison.Response{status_code: status}} =
      Gogs.HTTPoisonMock.get("/raw/", "any-header")

    assert status == 200
  end

  test "Gogs.HTTPoisonMock.get any url should return status 200" do
    {:ok, %HTTPoison.Response{status_code: status}} =
      Gogs.HTTPoisonMock.get("org/any", "any-header")

    assert status == 200
  end

  test "Gogs.HTTPoisonMock.post any url should return status 200" do
    {:ok, %HTTPoison.Response{status_code: status, body: resp_body}} =
      Gogs.HTTPoisonMock.post("hi", Jason.encode!(%{name: "simon"}), "any-header")

    assert status == 200
    body_map = Jason.decode!(resp_body) |> Useful.atomize_map_keys()
    assert body_map.full_name == "myorg/simon"
  end

  test "Gogs.HTTPoisonMock.delete any url should return status 200" do
    {:ok, %HTTPoison.Response{status_code: status}} = Gogs.HTTPoisonMock.delete("any?url")
    assert status == 200
  end
end
