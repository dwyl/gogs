defmodule GogsTest do
  use ExUnit.Case
  doctest Gogs

  test "greets the world" do
    assert Gogs.hello() == :world
  end
end
