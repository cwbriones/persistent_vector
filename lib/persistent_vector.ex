defmodule PersistentVector do
  use Bitwise

  @bits 5
  @width 1 <<< @bits
  @mask @width - 1

  defstruct [
    size: 0,
    capacity: 0,
    root: nil,
    shift: 0,
    default: 0,
    tail: nil,
    tail_offset: 0,
  ]

  def new(opts \\ []) do
    default = Keyword.get(opts, :default, 0)
    tail = Tuple.duplicate(nil, @width)

    %__MODULE__{
      size: 0,
      shift: 0,
      root: nil,
      default: default,
      tail: tail,
      tail_offset: 0,
    }
  end

  def get(%__MODULE__{tail: tail, tail_offset: offset}, key) when key >= offset do
    elem(tail, key - offset)
  end
  def get(vector, key) do
    node_get(vector.root, key, vector.shift)
  end

  defp node_get(node, key, level) when level > 0 do
    idx = band(key >>> level, @mask)
    node_get(elem(node, idx), key, level - @bits)
  end
  defp node_get(node, key, _), do: elem(node, band(key, @mask))

  def append(vector = %__MODULE__{tail_offset: offset, size: size}, value) when size - offset < @width do
    tail = put_elem(vector.tail, size - offset, value)
    %__MODULE__{vector | tail: tail, tail_offset: offset, size: size + 1}
  end
  def append(vector = %__MODULE__{
    root: root,
    tail: tail,
    shift: shift,
    size: size}, value) do

    capacity = @width <<< shift

    {new_root, new_shift} = case size - @width do
      ^capacity ->
        {node_new(root), shift + @bits}
      _ -> {root, shift}
    end

    new_root = node_insert(new_root, size - @width, tail, new_shift)
    tail = node_new(value)

    %__MODULE__{vector |
      root: new_root,
      tail: tail,
      tail_offset: size,
      shift: new_shift,
      size: size + 1}
  end

  def node_insert(nil, key, node, level) when level > 0 do
    idx = band(key >>> level, @mask)
    tree = node_new(nil)
    child = node_insert(elem(tree, idx), key, node, level - @bits)
    put_elem(tree, idx, child)
  end
  def node_insert(nil, _, node, _), do: node
  def node_insert(tree, key, node, level) when level > 0 do
    idx = band(key >>> level, @mask)
    child = node_insert(elem(tree, idx), key, node, level - @bits)
    put_elem(tree, idx, child)
  end
  def node_insert(tree, key, node, _) do
    idx = band(key >>> @bits, @mask)
    put_elem(tree, idx, node)
  end

  def set(vector = %__MODULE__{tail: tail, tail_offset: offset}, key, value) when key >= offset do
    %__MODULE__{vector | tail: put_elem(tail, key - offset, value)}
  end
  def set(vector = %__MODULE__{root: root, shift: shift}, key, value) do
    %__MODULE__{vector | root: node_set(root, key, value, shift)}
  end

  def node_set(nil, _, value, level) do
    Enum.reduce(0..div(level, @bits), value, fn _, acc ->
      node_new(acc)
    end)
  end
  def node_set(node, key, value, level) when level > 0 do
    idx = band(key >>> level, @mask)
    child = elem(node, idx)
    put_elem(node, idx, node_set(child, key, value, level - @bits))
  end
  def node_set(node, key, value, _) do
    idx = band(key, @mask)
    put_elem(node, idx, value)
  end

  def from_list(list), do: Enum.reduce(list, new, &(append(&2, &1)))

  def to_list(%__MODULE__{root: root, size: size, shift: shift, tail: tail, tail_offset: offset}) do
    head = node_to_list(root, shift) |> Enum.take(offset)
    tail = Tuple.to_list(tail) |> Enum.take(size - offset)
    head ++ tail
  end

  def node_to_list(nil, _), do: []
  def node_to_list(node, 0), do: Tuple.to_list(node)
  def node_to_list(node, level) do
    Tuple.to_list(node)
    |> Enum.flat_map(&node_to_list(&1, level - @bits))
  end

  def node_new(value) do
    Tuple.duplicate(nil, @width) |> put_elem(0, value)
  end
end

defimpl Collectable, for: PersistentVector do
  def into(original) do
    {original, fn
      acc, {:cont, v} -> PersistentVector.append(acc, v)
      acc, :done -> acc
      _, :halt -> :ok
    end}
  end
end
