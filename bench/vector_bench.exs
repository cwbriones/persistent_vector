defmodule VectorBench do
  use Benchfella

  @size 1000
  @tuple Tuple.duplicate(0, @size)
  @list Enum.to_list(0..@size)
  @array :array.from_list(@list)
  @vector PersistentVector.from_list(@list)

  bench "Access: List" do
    Enum.at(@list, :random.uniform(@size - 1))
    :ok
  end

  bench "Access: Tuple" do
    elem(@tuple, :random.uniform(@size - 1))
    :ok
  end

  bench "Access: :array" do
    :array.get(:random.uniform(@size), @array)
    :ok
  end

  bench "Access: PersistentVector" do
    PersistentVector.get(@vector, :random.uniform(@size))
    :ok
  end

  bench "Updates: List" do
    List.replace_at(@list, :random.uniform(@size - 1), 1)
    :ok
  end

  bench "Updates: Tuple" do
    put_elem(@tuple, :random.uniform(@size - 1), 1)
    :ok
  end

  bench "Updates: Array" do
    :array.set(:random.uniform(@size), 1, @array)
    :ok
  end

  bench "Updates: PersistentVector" do
    PersistentVector.set(@vector, :random.uniform(@size), 1)
    :ok
  end

  bench "Append: Tuple" do
    Tuple.append(@tuple, 0)
    :ok
  end

  bench "Append: List" do
    @list ++ [0]
    :ok
  end

  bench "Append: PersistentVector" do
    PersistentVector.append(@vector, 0)
    :ok
  end

  bench "Append: Array" do
    :array.set(:array.size(@array), 1, @array)
    :ok
  end

  bench "Last: PersistentVector" do
    PersistentVector.get(@vector, @vector.size)
    :ok
  end

  bench "Last: List" do
    List.last @list
    :ok
  end

  bench "Last: Tuple" do
    elem(@tuple, tuple_size(@tuple) - 1)
  end

  bench "Last: Array" do
    :array.get(:array.size(@array), @array)
    :ok
  end
end
