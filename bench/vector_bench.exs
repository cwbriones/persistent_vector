defmodule VectorBench do
  use Benchfella

  @size 10000
  @tuple Tuple.duplicate(0, @size)
  @list Enum.to_list(0..@size)
  @array :array.from_list(@list)

  bench "updating an element in a list" do
    List.replace_at(@list, :random.uniform(@size - 1), 1)
    :ok
  end

  bench "updating an element in a tuple" do
    put_elem(@tuple, :random.uniform(@size - 1), 1)
    :ok
  end

  bench "update an element in an array" do
    :array.set(:random.uniform(@size), 1, @array)
    :ok
  end

  bench "appending an element to a tuple" do
    Tuple.append(@tuple, 0)
    :ok
  end

  bench "appending an element to a list" do
    @list ++ [0]
    :ok
  end
end
