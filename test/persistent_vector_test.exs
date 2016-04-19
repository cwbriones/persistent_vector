defmodule PersistentVectorTest do
  use ExUnit.Case
  doctest PersistentVector

  test "new makes an empty vector" do
    v = PersistentVector.new
    assert v.size == 0
  end

  test "it can be created from a list" do
    vector = 0..99 |> Enum.to_list |> PersistentVector.from_list
    assert vector.size == 100
    for i <- 0..99 do
      assert PersistentVector.get(vector, i) == i
    end
  end

  test "it can be turned into a list" do
    list = 0..99
    |> Enum.to_list
    |> PersistentVector.from_list
    |> PersistentVector.to_list

    assert list == Enum.to_list(0..99)
  end
end
