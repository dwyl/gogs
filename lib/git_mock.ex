defmodule Gogs.GitMock do
  @moduledoc """
  Mock functions to simulate Git commands.
  Sadly, this is necessary until we figure out how to get write-access
  on GitHub CI. See: https://github.com/dwyl/gogs/issues/15
  """
  
  def checkout(_, _) do
    {:ok, "Switched to a new branch 'draft'\n"}
  end
end
