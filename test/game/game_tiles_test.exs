defmodule GameTilesTest do
  use ExUnit.Case
  doctest Wordza.GameTiles

  test "add a single tile to a list" do
    assert Wordza.GameTiles.add([], "a", 1, 1) == [
      %Wordza.GameTile{letter: "a", value: 1}
    ]
  end
  test "add multiple tiles to a list" do
    assert Wordza.GameTiles.add([], "b", 2, 3) == [
      %Wordza.GameTile{letter: "b", value: 2},
      %Wordza.GameTile{letter: "b", value: 2},
      %Wordza.GameTile{letter: "b", value: 2}
    ]
  end
  test "create a list of tiles for :wordfeud" do
    tiles = Wordza.GameTiles.create(:wordfeud)
    distro = tiles
    |> Enum.group_by(
      fn(%Wordza.GameTile{letter: l}) -> l end,
      fn(%Wordza.GameTile{value: p}) -> p end
    )
    |> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
    assert distro == [
      {"?", 2}, {"a", 10}, {"b", 2}, {"c", 2}, {"d", 5}, {"e", 12}, {"f", 2},
      {"g", 3}, {"h", 3}, {"i", 9}, {"j", 1}, {"k", 1}, {"l", 4}, {"m", 2}, {"n", 6},
      {"o", 7}, {"p", 2}, {"q", 1}, {"r", 6}, {"s", 5}, {"t", 7}, {"u", 4}, {"v", 2},
      {"w", 2}, {"x", 1}, {"y", 2}, {"z", 1}
    ]
    assert tiles
    |> Enum.map(fn(%Wordza.GameTile{value: v}) -> v end)
    |> Enum.sum() == 206
    assert Enum.count(tiles) == 104
    assert Enum.at(tiles, 0) == %Wordza.GameTile{letter: "a", value: 1}
    assert Enum.at(tiles, 9) == %Wordza.GameTile{letter: "a", value: 1}
    assert Enum.at(tiles, 10) == %Wordza.GameTile{letter: "b", value: 4}
    assert Enum.at(tiles, 11) == %Wordza.GameTile{letter: "b", value: 4}
    assert Enum.at(tiles, 12) == %Wordza.GameTile{letter: "c", value: 4}
    assert Enum.at(tiles, 103) == %Wordza.GameTile{letter: "?", value: 0}
  end
  test "create a list of tiles for :scrabble" do
    tiles = Wordza.GameTiles.create(:scrabble)

    distro = tiles
    |> Enum.group_by(
      fn(%Wordza.GameTile{letter: l}) -> l end,
      fn(%Wordza.GameTile{value: p}) -> p end
    )
    |> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
    assert distro == [
      {"?", 2}, {"a", 9}, {"b", 2}, {"c", 2}, {"d", 4}, {"e", 12}, {"f", 2},
      {"g", 3}, {"h", 2}, {"i", 9}, {"j", 1}, {"k", 1}, {"l", 4}, {"m", 2}, {"n", 6},
      {"o", 8}, {"p", 2}, {"q", 1}, {"r", 6}, {"s", 4}, {"t", 6}, {"u", 4}, {"v", 2},
      {"w", 2}, {"x", 1}, {"y", 2}, {"z", 1}
    ]
    assert tiles
    |> Enum.map(fn(%Wordza.GameTile{value: v}) -> v end)
    |> Enum.sum() == 187
    assert Enum.count(tiles) == 100
    assert Enum.at(tiles, 0) == %Wordza.GameTile{letter: "a", value: 1}
    assert Enum.at(tiles, 8) == %Wordza.GameTile{letter: "a", value: 1}
    assert Enum.at(tiles, 9) == %Wordza.GameTile{letter: "b", value: 3}
    assert Enum.at(tiles, 10) == %Wordza.GameTile{letter: "b", value: 3}
    assert Enum.at(tiles, 11) == %Wordza.GameTile{letter: "c", value: 3}
    assert Enum.at(tiles, 99) == %Wordza.GameTile{letter: "?", value: 0}
  end
end
