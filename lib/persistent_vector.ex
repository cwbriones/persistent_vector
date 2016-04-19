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
    get_priv(vector.root, key, vector.shift)
  end

  defp get_priv(node, key, level) when level > 0 do
    idx = band(key >>> level, @mask)
    get_priv(elem(node, idx), key, level - @bits)
  end
  defp get_priv(node, key, level), do: elem(node, band(key, @mask))

  def append(vector = %__MODULE__{capacity: 0, root: nil}, value) do
    %__MODULE__{vector | capacity: @width, root: new_node(value), size: 1}
  end
  def append(vector = %__MODULE__{capacity: cap, root: root, shift: shift, size: cap}, value) do
    %__MODULE__{vector | capacity: cap <<< @bits, root: new_node(root), shift: shift + @bits} |> append(value)
  end
  def append(vector = %__MODULE__{root: root, shift: shift, size: size}, value) do
    %__MODULE__{vector | root: set_priv(root, size, value, shift), size: size + 1}
  end

  def set(vector = %__MODULE__{root: root, shift: shift}, key, value) do
    %__MODULE__{vector | root: set_priv(root, key, value, shift)}
  end

  def set_priv(nil, key, value, level) do
    Enum.reduce(0..div(level, @bits), value, fn val, acc ->
      new_node(acc)
    end)
  end
  def set_priv(node, key, value, level) when level > 0 do
    idx = band(key >>> level, @mask)
    child = elem(node, idx)
    put_elem(node, idx, set_priv(child, key, value, level - @bits))
  end
  def set_priv(node, key, value, level) do
    idx = band(key, @mask)
    put_elem(node, idx, value)
  end

  def new_node(value) do
    Tuple.duplicate(nil, @width) |> put_elem(0, value)
  end

  def from_list(list), do: Enum.reduce(list, new, &(append(&2, &1)))
end
