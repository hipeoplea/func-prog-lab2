defmodule Bag do

  @moduledoc """
  Create a module `Bag` that implements a multiset (bag) data structure
  based on Separate Chaining HashMap in Elixir.
  """

  @opaque t :: %__MODULE__{
            size: non_neg_integer(),
            buckets: tuple()
          }

  @enforce_keys [:size, :buckets]
  defstruct size: 0, buckets: {}

  @default_bucket_count 16

  defp empty_buckets do
    :erlang.make_tuple(@default_bucket_count, [])
  end

  defp bucket_index(elem) do
    :erlang.phash2(elem, @default_bucket_count)
  end

  defp get_bucket(%__MODULE__{buckets: buckets}, idx) do
    elem(buckets, idx)
  end

  defp bucket_add([], elem), do: [{elem, 1}]

  defp bucket_add([{e, c} | rest], elem) when e == elem do
    [{e, c + 1} | rest]
  end

  defp bucket_add([pair | rest], elem) do
    [pair | bucket_add(rest, elem)]
  end

  defp bucket_remove([], _elem), do: {[], false}

  defp bucket_remove([{e, c} | rest], elem) when e == elem do
    cond do
      c > 1 -> {[{e, c - 1} | rest], true}
      c == 1 -> {rest, true}
    end
  end

  defp bucket_remove([pair | rest], elem) do
    {tail, removed?} = bucket_remove(rest, elem)
    {[pair | tail], removed?}
  end

  defp bucket_count([], _elem), do: 0
  defp bucket_count([{e, c} | _], elem) when e == elem, do: c
  defp bucket_count([_ | rest], elem), do: bucket_count(rest, elem)

  defp repeat_apply_left(_fun, acc, _elem, 0), do: acc

  defp repeat_apply_left(fun, acc, elem, n) do
    acc1 = fun.(elem, acc)
    repeat_apply_left(fun, acc1, elem, n - 1)
  end

  defp fold_bucket_left(_fun, acc, []), do: acc

  defp fold_bucket_left(fun, acc, [{elem, cnt} | rest]) do
    acc1 = repeat_apply_left(fun, acc, elem, cnt)
    fold_bucket_left(fun, acc1, rest)
  end

  defp fold_bucket_right(_fun, acc, []), do: acc

  defp fold_bucket_right(fun, acc, [{elem, cnt} | rest]) do
    acc1 = fold_bucket_right(fun, acc, rest)
    repeat_apply_left(fun, acc1, elem, cnt)
  end

  defp fold_buckets_left(fun, acc, buckets) do
    buckets
    |> Tuple.to_list()
    |> Enum.reduce(acc, fn bucket, a -> fold_bucket_left(fun, a, bucket) end)
  end

  defp fold_buckets_right(fun, acc, buckets) do
    buckets
    |> Tuple.to_list()
    |> Enum.reverse()
    |> Enum.reduce(acc, fn bucket, a -> fold_bucket_right(fun, a, bucket) end)
  end

  @spec empty() :: t()
  def empty do
    %__MODULE__{size: 0, buckets: empty_buckets()}
  end

  @spec mempty() :: t()
  def mempty, do: empty()

  @spec new(Enumerable.t()) :: t()
  def new(enum) do
    Enum.reduce(enum, empty(), fn x, acc -> add(acc, x) end)
  end

  @spec from_list(list()) :: t()
  def from_list(list), do: new(list)

  @spec add(t(), any()) :: t()
  def add(%__MODULE__{} = bag, elem) do
    idx = bucket_index(elem)
    bucket = get_bucket(bag, idx)
    new_bucket = bucket_add(bucket, elem)

    %__MODULE__{
      size: bag.size + 1,
      buckets: put_elem(bag.buckets, idx, new_bucket)
    }
  end

  @spec remove(t(), any()) :: t()
  def remove(%__MODULE__{} = bag, elem) do
    idx = bucket_index(elem)
    bucket = get_bucket(bag, idx)
    {new_bucket, removed?} = bucket_remove(bucket, elem)

    if removed? do
      %__MODULE__{
        size: bag.size - 1,
        buckets: put_elem(bag.buckets, idx, new_bucket)
      }
    else
      bag
    end
  end

  @spec count(t(), any()) :: non_neg_integer()
  def count(%__MODULE__{} = bag, elem) do
    idx = bucket_index(elem)
    bucket = get_bucket(bag, idx)
    bucket_count(bucket, elem)
  end

  @spec member?(t(), any()) :: boolean()
  def member?(bag, elem), do: count(bag, elem) > 0

  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{size: s}), do: s

  @spec to_list(t()) :: list()
  def to_list(%__MODULE__{buckets: buckets}) do
    fold_buckets_left(fn e, a -> [e | a] end, [], buckets)
    |> Enum.reverse()
  end

  @spec map(t(), (any() -> any())) :: t()
  def map(bag, fun) do
    bag
    |> to_list()
    |> Enum.map(fun)
    |> from_list()
  end

  @spec filter(t(), (any() -> as_boolean(term))) :: t()
  def filter(bag, pred) do
    bag
    |> to_list()
    |> Enum.filter(pred)
    |> from_list()
  end

  @spec foldl((any(), any() -> any()), any(), t()) :: any()
  def foldl(fun, acc, %__MODULE__{buckets: buckets}) do
    fold_buckets_left(fun, acc, buckets)
  end

  @spec foldr((any(), any() -> any()), any(), t()) :: any()
  def foldr(fun, acc, %__MODULE__{buckets: buckets}) do
    fold_buckets_right(fun, acc, buckets)
  end

  @spec append(t(), t()) :: t()
  def append(bag1, bag2) do
    foldl(fn elem, acc -> add(acc, elem) end, bag1, bag2)
  end

  @spec equal?(t(), t()) :: boolean()
  def equal?(a, b) do
    if size(a) != size(b) do
      false
    else
      {_seen, ok?} =
        foldl(
          fn elem, acc -> equal_step(elem, a, b, acc) end,
          {MapSet.new(), true},
          a
        )

      ok?
    end
  end

  defp equal_step(_elem, _a, _b, {seen, false}), do: {seen, false}

  defp equal_step(elem, a, b, {seen, true}) do
    if MapSet.member?(seen, elem) do
      {seen, true}
    else
      ok = count(a, elem) == count(b, elem)
      {MapSet.put(seen, elem), ok}
    end
  end
end
