defmodule GameTilesTest do
  use ExUnit.Case
  doctest Wordiverse.Game.Tiles

  test "add a single tile to a list" do
    assert Wordiverse.Game.Tiles.add([], "a", 1, 1) == [
      %Wordiverse.Game.Tile{letter: "a", value: 1}
    ]
  end
  test "add multiple tiles to a list" do
    assert Wordiverse.Game.Tiles.add([], "b", 2, 3) == [
      %Wordiverse.Game.Tile{letter: "b", value: 2},
      %Wordiverse.Game.Tile{letter: "b", value: 2},
      %Wordiverse.Game.Tile{letter: "b", value: 2}
    ]
  end
  test "create a list of tiles for :wordfeud" do
    tiles = Wordiverse.Game.Tiles.create_list(:wordfeud)
    distro = tiles
    |> Enum.group_by(
      fn(%Wordiverse.Game.Tile{letter: l}) -> l end,
      fn(%Wordiverse.Game.Tile{value: p}) -> p end
    )
    |> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
    assert distro == [
      {"?", 2}, {"a", 10}, {"b", 2}, {"c", 2}, {"d", 5}, {"e", 12}, {"f", 2},
      {"g", 3}, {"h", 3}, {"i", 9}, {"j", 1}, {"k", 1}, {"l", 4}, {"m", 2}, {"n", 6},
      {"o", 7}, {"p", 2}, {"q", 1}, {"r", 6}, {"s", 5}, {"t", 7}, {"u", 4}, {"v", 2},
      {"w", 2}, {"x", 1}, {"y", 2}, {"z", 1}
    ]
    assert tiles
    |> Enum.map(fn(%Wordiverse.Game.Tile{value: v}) -> v end)
    |> Enum.sum() == 206
    assert Enum.count(tiles) == 104
    assert Enum.at(tiles, 0) == %Wordiverse.Game.Tile{letter: "a", value: 1}
    assert Enum.at(tiles, 9) == %Wordiverse.Game.Tile{letter: "a", value: 1}
    assert Enum.at(tiles, 10) == %Wordiverse.Game.Tile{letter: "b", value: 4}
    assert Enum.at(tiles, 11) == %Wordiverse.Game.Tile{letter: "b", value: 4}
    assert Enum.at(tiles, 12) == %Wordiverse.Game.Tile{letter: "c", value: 4}
    assert Enum.at(tiles, 103) == %Wordiverse.Game.Tile{letter: "?", value: 0}
  end
  test "create a list of tiles for :scrabble" do
    tiles = Wordiverse.Game.Tiles.create_list(:scrabble)

    distro = tiles
    |> Enum.group_by(
      fn(%Wordiverse.Game.Tile{letter: l}) -> l end,
      fn(%Wordiverse.Game.Tile{value: p}) -> p end
    )
    |> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
    assert distro == [
      {"?", 2}, {"a", 9}, {"b", 2}, {"c", 2}, {"d", 4}, {"e", 12}, {"f", 2},
      {"g", 3}, {"h", 2}, {"i", 9}, {"j", 1}, {"k", 1}, {"l", 4}, {"m", 2}, {"n", 6},
      {"o", 8}, {"p", 2}, {"q", 1}, {"r", 6}, {"s", 4}, {"t", 6}, {"u", 4}, {"v", 2},
      {"w", 2}, {"x", 1}, {"y", 2}, {"z", 1}
    ]
    assert tiles
    |> Enum.map(fn(%Wordiverse.Game.Tile{value: v}) -> v end)
    |> Enum.sum() == 187
    assert Enum.count(tiles) == 100
    assert Enum.at(tiles, 0) == %Wordiverse.Game.Tile{letter: "a", value: 1}
    assert Enum.at(tiles, 8) == %Wordiverse.Game.Tile{letter: "a", value: 1}
    assert Enum.at(tiles, 9) == %Wordiverse.Game.Tile{letter: "b", value: 3}
    assert Enum.at(tiles, 10) == %Wordiverse.Game.Tile{letter: "b", value: 3}
    assert Enum.at(tiles, 11) == %Wordiverse.Game.Tile{letter: "c", value: 3}
    assert Enum.at(tiles, 99) == %Wordiverse.Game.Tile{letter: "?", value: 0}
  end
end
