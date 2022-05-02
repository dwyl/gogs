defmodule GogsHelpersTest do
  use ExUnit.Case
  doctest GogsHelpers

  test "GogsHelpers.api_base_url/0 returns the API URL for the Gogs Server" do
    assert GogsHelpers.api_base_url() == "https://gogs-server.fly.dev/api/v1/"
  end
end
