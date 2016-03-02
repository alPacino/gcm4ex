defmodule GCMTest do
  use ExUnit.Case

  test "GCM starts all the pools from config" do
    for {pool, _conf} <- Application.get_env(:gcm, :pools) do
      assert {:ready, _, _, _} = :poolboy.status(GCM.pool_name(pool))
    end
  end
end
