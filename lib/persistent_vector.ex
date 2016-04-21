defmodule PersistentVector do
  use Bitwise

  defmodule Node do
    @bits 5
    @width 1 <<< @bits
    @mask @width - 1

    def bits, do: @bits

    @inline true
    def new(value \\ nil) do
      Tuple.duplicate(nil, @width) |> put_elem(0, value)
    end

    def insert(nil, key, node, level) when level > 0 do
      idx = band(key >>> level, @mask)
      tree = Node.new
      child = insert(elem(tree, idx), key, node, level - @bits)
      put_elem(tree, idx, child)
    end
    def insert(nil, _, node, _), do: node
    def insert(tree, key, node, level) when level > 0 do
      idx = band(key >>> level, @mask)
      child = insert(elem(tree, idx), key, node, level - @bits)
      put_elem(tree, idx, child)
    end
    def insert(tree, key, node, _) do
      idx = band(key >>> @bits, @mask)
      put_elem(tree, idx, node)
    end

    def get(node, key, level) when level > 0 do
      idx = band(key >>> level, @mask)
      get(elem(node, idx), key, level - @bits)
    end
    def get(node, key, _), do: elem(node, band(key, @mask))

    def set(nil, _, value, level) do
      Enum.reduce(0..div(level, @bits), value, fn _, acc ->
        Node.new(acc)
      end)
    end
    def set(node, key, value, level) when level > 0 do
      idx = band(key >>> level, @mask)
      child = elem(node, idx)
      put_elem(node, idx, set(child, key, value, level - @bits))
    end
    def set(node, key, value, _) do
      idx = band(key, @mask)
      put_elem(node, idx, value)
    end

    def to_list(nil, _), do: []
    def to_list(node, 0), do: Tuple.to_list(node)
    def to_list(node, level) do
      Tuple.to_list(node)
      |> Enum.flat_map(&Node.to_list(&1, level - @bits))
    end
  end

  @bits Node.bits
  @width 1 <<< @bits

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
    tail = Node.new

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
    Node.get(vector.root, key, vector.shift)
  end

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
        {Node.new(root), shift + @bits}
      _ -> {root, shift}
    end

    new_root = Node.insert(new_root, size - @width, tail, new_shift)
    tail = Node.new(value)

    %__MODULE__{vector |
      root: new_root,
      tail: tail,
      tail_offset: size,
      shift: new_shift,
      size: size + 1}
  end

  def set(vector = %__MODULE__{tail: tail, tail_offset: offset}, key, value) when key >= offset do
    %__MODULE__{vector | tail: put_elem(tail, key - offset, value)}
  end
  def set(vector = %__MODULE__{root: root, shift: shift}, key, value) do
    %__MODULE__{vector | root: Node.set(root, key, value, shift)}
  end

  def from_list(list), do: Enum.reduce(list, new, &(append(&2, &1)))

  def to_list(%__MODULE__{root: root, size: size, shift: shift, tail: tail, tail_offset: offset}) do
    head = Node.to_list(root, shift) |> Enum.take(offset)
    tail = Tuple.to_list(tail) |> Enum.take(size - offset)
    head ++ tail
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
