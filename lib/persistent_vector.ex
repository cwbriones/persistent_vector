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
    default: 0
  ]

  def new(opts \\ []) do
    default = Keyword.get(opts, :default, 0)
    root = Tuple.duplicate(nil, @width)

    %__MODULE__{
      size: 0,
      capacity: 0,
      shift: 0,
      root: nil,
      default: default
    }
  end

  def get(vector, key) do
    node_get(vector.root, key, vector.shift)
  end

  defp node_get(node, key, level) when level > 0 do
    idx = band(key >>> level, @mask)
    node_get(elem(node, idx), key, level - @bits)
  end
  defp node_get(node, key, level), do: elem(node, band(key, @mask))

  def append(vector = %__MODULE__{capacity: 0, root: nil}, value) do
    %__MODULE__{vector | capacity: @width, root: node_new(value), size: 1}
  end
  def append(vector = %__MODULE__{capacity: cap, root: root, shift: shift, size: cap}, value) do
    %__MODULE__{vector | capacity: cap <<< @bits, root: node_new(root), shift: shift + @bits} |> append(value)
  end
  def append(vector = %__MODULE__{root: root, shift: shift, size: size}, value) do
    %__MODULE__{vector | root: node_set(root, size, value, shift), size: size + 1}
  end

  def set(vector = %__MODULE__{root: root, shift: shift}, key, value) do
    %__MODULE__{vector | root: node_set(root, key, value, shift)}
  end

  def node_set(nil, key, value, level) do
    Enum.reduce(0..div(level, @bits), value, fn val, acc ->
      node_new(acc)
    end)
  end
  def node_set(node, key, value, level) when level > 0 do
    idx = band(key >>> level, @mask)
    child = elem(node, idx)
    put_elem(node, idx, node_set(child, key, value, level - @bits))
  end
  def node_set(node, key, value, level) do
    idx = band(key, @mask)
    put_elem(node, idx, value)
  end

  def from_list(list), do: Enum.reduce(list, new, &(append(&2, &1)))

  def to_list(vector = %__MODULE__{root: root, shift: shift}) do
    node_to_list(root, shift) |> Enum.take(vector.size)
  end

  def node_to_list(nil, level), do: []
  def node_to_list(node, 0), do: Tuple.to_list(node)
  def node_to_list(node, level) do
    Tuple.to_list(node)
    |> Enum.flat_map(&node_to_list(&1, level - @bits))
  end

  def node_new(value) do
    Tuple.duplicate(nil, @width) |> put_elem(0, value)
  end
end
