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

  test "you can access elements" do
    vector = 0..99
    |> Enum.to_list
    |> PersistentVector.from_list

    for i <- 0..99 do
      assert i == PersistentVector.get(vector, i)
    end
  end

  test "you can set elements" do
    vector = 0..99
    |> Enum.to_list
    |> PersistentVector.from_list

    updated = Enum.reduce(0..99, vector, fn i, acc ->
      PersistentVector.set(acc, i, i * 2)
    end) |> PersistentVector.to_list

    expected = Enum.map(0..99, &(&1 * 2))

    assert updated == expected
  end
end
