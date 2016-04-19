defmodule PersistentVectorTest do
  use ExUnit.Case
  doctest PersistentVector

  test "new makes an empty vector" do
    v = PersistentVector.new
    assert v.size == 0
  end

  test "set changes the value at the given index" do
  end

  test "append adds an item to the end" do
  end
end
