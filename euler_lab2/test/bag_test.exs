defmodule BagTest do
  use ExUnit.Case, async: true

  describe "construction and basic operations" do
    test "empty/0 and mempty/0 produce an empty bag" do
      assert Bag.size(Bag.empty()) == 0
      assert Bag.size(Bag.mempty()) == 0
      refute Bag.member?(Bag.empty(), :anything)
    end

    test "new/1 and from_list/1 build bag with correct counts" do
      bag1 = Bag.new([:a, :a, :b])
      bag2 = Bag.from_list([:a, :a, :b])

      assert Bag.count(bag1, :a) == 2
      assert Bag.count(bag1, :b) == 1
      assert Bag.equal?(bag1, bag2)
    end

    test "add/2 increases count and size" do
      bag =
        Bag.empty()
        |> Bag.add(:x)
        |> Bag.add(:x)
        |> Bag.add(:y)

      assert Bag.count(bag, :x) == 2
      assert Bag.count(bag, :y) == 1
      assert Bag.size(bag) == 3
      assert Bag.member?(bag, :x)
      refute Bag.member?(bag, :z)
    end

    test "remove/2 decreases count and size, and removes key on last occurrence" do
      bag =
        Bag.empty()
        |> Bag.add(:x)
        |> Bag.add(:x)
        |> Bag.add(:y)

      bag1 = Bag.remove(bag, :x)
      assert Bag.count(bag1, :x) == 1
      assert Bag.size(bag1) == 2

      bag2 = Bag.remove(bag1, :x)
      assert Bag.count(bag2, :x) == 0
      refute Bag.member?(bag2, :x)
      assert Bag.size(bag2) == 1

      # remove non-existing element should not change bag
      bag3 = Bag.remove(bag2, :not_there)
      assert Bag.equal?(bag2, bag3)
    end

    test "to_list/1 returns all elements with multiplicities" do
      bag = Bag.from_list([:a, :b, :a, :c])

      list = bag |> Bag.to_list() |> Enum.sort()
      # В порядке сортировки: [:a, :a, :b, :c]
      assert list == [:a, :a, :b, :c]
    end
  end

  describe "higher-order functions" do
    test "map/2 applies function to each occurrence" do
      bag =
        [1, 1, 2]
        |> Bag.from_list()
        |> Bag.map(&(&1 * 2))

      assert Bag.to_list(bag) |> Enum.sort() == [2, 2, 4]
    end

    test "filter/2 keeps only elements satisfying predicate" do
      bag =
        [1, 2, 3, 4]
        |> Bag.from_list()
        |> Bag.filter(&(rem(&1, 2) == 0))

      assert Bag.to_list(bag) |> Enum.sort() == [2, 4]
    end

    test "foldl/3 sums elements" do
      bag = Bag.from_list([1, 2, 3])
      sum = Bag.foldl(fn x, acc -> x + acc end, 0, bag)
      assert sum == 6
    end

    test "foldr/3 can be used to reverse element order" do
      bag = Bag.from_list([1, 2, 3])
      res = Bag.foldr(fn x, acc -> [x | acc] end, [], bag)
      assert length(res) == 3
      assert Enum.sum(res) == 6
    end
  end

  describe "monoid behavior (with small examples)" do
    test "empty/0 is left and right identity for append/2" do
      a = Bag.from_list([1, 2, 2])
      assert Bag.equal?(Bag.append(Bag.empty(), a), a)
      assert Bag.equal?(Bag.append(a, Bag.empty()), a)
    end

    test "append/2 is associative on small bags" do
      a = Bag.from_list([1, 2])
      b = Bag.from_list([2, 3])
      c = Bag.from_list([3, 4])

      left = Bag.append(Bag.append(a, b), c)
      right = Bag.append(a, Bag.append(b, c))

      assert Bag.equal?(left, right)
    end
  end

  describe "equal?/2 semantics" do
    test "bags with same multiplicities are equal, independent of insertion order" do
      a =
        Bag.empty()
        |> Bag.add(:x)
        |> Bag.add(:x)
        |> Bag.add(:y)

      b =
        Bag.empty()
        |> Bag.add(:y)
        |> Bag.add(:x)
        |> Bag.add(:x)

      c =
        Bag.empty()
        |> Bag.add(:x)
        |> Bag.add(:y)

      assert Bag.equal?(a, b)
      refute Bag.equal?(a, c)
    end
  end
end
