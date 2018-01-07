defmodule GameTilesTest do
  use ExUnit.Case
  doctest Wordza.GameTiles

  test "add a single tile to a list" do
    assert Wordza.GameTiles.add([], "A", 1, 1) == [
      %Wordza.GameTile{letter: "A", value: 1}
    ]
  end
  test "add multiple tiles to a list" do
    assert Wordza.GameTiles.add([], "B", 2, 3) == [
      %Wordza.GameTile{letter: "B", value: 2},
      %Wordza.GameTile{letter: "B", value: 2},
      %Wordza.GameTile{letter: "B", value: 2}
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
      {"?", 2}, {"A", 10}, {"B", 2}, {"C", 2}, {"D", 5}, {"E", 12}, {"F", 2},
      {"G", 3}, {"H", 3}, {"I", 9}, {"J", 1}, {"K", 1}, {"L", 4}, {"M", 2}, {"N", 6},
      {"O", 7}, {"P", 2}, {"Q", 1}, {"R", 6}, {"S", 5}, {"T", 7}, {"U", 4}, {"V", 2},
      {"W", 2}, {"X", 1}, {"Y", 2}, {"Z", 1}
    ]
    assert tiles
    |> Enum.map(fn(%Wordza.GameTile{value: v}) -> v end)
    |> Enum.sum() == 206
    assert Enum.count(tiles) == 104
    assert Enum.at(tiles, 0) == %Wordza.GameTile{letter: "A", value: 1}
    assert Enum.at(tiles, 9) == %Wordza.GameTile{letter: "A", value: 1}
    assert Enum.at(tiles, 10) == %Wordza.GameTile{letter: "B", value: 4}
    assert Enum.at(tiles, 11) == %Wordza.GameTile{letter: "B", value: 4}
    assert Enum.at(tiles, 12) == %Wordza.GameTile{letter: "C", value: 4}
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
      {"?", 2}, {"A", 9}, {"B", 2}, {"C", 2}, {"D", 4}, {"E", 12}, {"F", 2},
      {"G", 3}, {"H", 2}, {"I", 9}, {"J", 1}, {"K", 1}, {"L", 4}, {"M", 2}, {"N", 6},
      {"O", 8}, {"P", 2}, {"Q", 1}, {"R", 6}, {"S", 4}, {"T", 6}, {"U", 4}, {"V", 2},
      {"W", 2}, {"X", 1}, {"Y", 2}, {"Z", 1}
    ]
    assert tiles
    |> Enum.map(fn(%Wordza.GameTile{value: v}) -> v end)
    |> Enum.sum() == 187
    assert Enum.count(tiles) == 100
    assert Enum.at(tiles, 0) == %Wordza.GameTile{letter: "A", value: 1}
    assert Enum.at(tiles, 8) == %Wordza.GameTile{letter: "A", value: 1}
    assert Enum.at(tiles, 9) == %Wordza.GameTile{letter: "B", value: 3}
    assert Enum.at(tiles, 10) == %Wordza.GameTile{letter: "B", value: 3}
    assert Enum.at(tiles, 11) == %Wordza.GameTile{letter: "C", value: 3}
    assert Enum.at(tiles, 99) == %Wordza.GameTile{letter: "?", value: 0}
  end
end
