defmodule BagPropertyTest do
  use ExUnit.Case
  use ExUnitProperties

  defp int_list_generator do
    list_of(integer())
  end

  property "from_list(to_list(bag)) is semantically equal to bag" do
    check all(list <- int_list_generator()) do
      bag = Bag.from_list(list)

      bag_roundtrip =
        bag
        |> Bag.to_list()
        |> Bag.from_list()

      assert Bag.equal?(bag, bag_roundtrip)
    end
  end

  property "size(bag) equals length(to_list(bag))" do
    check all(list <- int_list_generator()) do
      bag = Bag.from_list(list)

      assert Bag.size(bag) == bag |> Bag.to_list() |> length()
    end
  end

  property "count(bag, x) equals number of occurrences of x in the source list" do
    check all(list <- int_list_generator()) do
      bag = Bag.from_list(list)

      Enum.each(list, fn x ->
        expected =
          list
          |> Enum.filter(&(&1 == x))
          |> length()

        assert Bag.count(bag, x) == expected
      end)

      missing_candidate = 10_000_000

      if missing_candidate not in list do
        assert Bag.count(bag, missing_candidate) == 0
      end
    end
  end

  property "Bag with append/2 and empty/0 forms a monoid" do
    check all(
            l1 <- int_list_generator(),
            l2 <- int_list_generator(),
            l3 <- int_list_generator()
          ) do
      a = Bag.from_list(l1)
      b = Bag.from_list(l2)
      c = Bag.from_list(l3)
      e = Bag.empty()

      assert Bag.equal?(Bag.append(e, a), a)
      assert Bag.equal?(Bag.append(a, e), a)

      left = Bag.append(Bag.append(a, b), c)
      right = Bag.append(a, Bag.append(b, c))

      assert Bag.equal?(left, right)
    end
  end
end
