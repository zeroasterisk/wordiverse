defmodule GameTilesTest do
  use ExUnit.Case
  doctest Wordza.GameTiles
  alias Wordza.GameTile
  alias Wordza.GameTiles

  test "add a single tile to a list" do
    assert GameTiles.add([], "A", 1, 1) == [
      %GameTile{letter: "A", value: 1}
    ]
  end
  test "add multiple tiles to a list" do
    assert GameTiles.add([], "B", 2, 3) == [
      %GameTile{letter: "B", value: 2},
      %GameTile{letter: "B", value: 2},
      %GameTile{letter: "B", value: 2}
    ]
  end
  test "create a list of tiles for :wordfeud" do
    tiles = GameTiles.create(:wordfeud)
    distro = tiles
    |> Enum.group_by(
      fn(%GameTile{letter: l}) -> l end,
      fn(%GameTile{value: p}) -> p end
    )
    |> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
    assert distro == [
      {"?", 2}, {"A", 10}, {"B", 2}, {"C", 2}, {"D", 5}, {"E", 12}, {"F", 2},
      {"G", 3}, {"H", 3}, {"I", 9}, {"J", 1}, {"K", 1}, {"L", 4}, {"M", 2}, {"N", 6},
      {"O", 7}, {"P", 2}, {"Q", 1}, {"R", 6}, {"S", 5}, {"T", 7}, {"U", 4}, {"V", 2},
      {"W", 2}, {"X", 1}, {"Y", 2}, {"Z", 1}
    ]
    assert tiles
    |> Enum.map(fn(%GameTile{value: v}) -> v end)
    |> Enum.sum() == 206
    assert Enum.count(tiles) == 104
    assert Enum.at(tiles, 0) == %GameTile{letter: "A", value: 1}
    assert Enum.at(tiles, 9) == %GameTile{letter: "A", value: 1}
    assert Enum.at(tiles, 10) == %GameTile{letter: "B", value: 4}
    assert Enum.at(tiles, 11) == %GameTile{letter: "B", value: 4}
    assert Enum.at(tiles, 12) == %GameTile{letter: "C", value: 4}
    assert Enum.at(tiles, 103) == %GameTile{letter: "?", value: 0}
  end
  test "create a list of tiles for :scrabble" do
    tiles = GameTiles.create(:scrabble)

    distro = tiles
    |> Enum.group_by(
      fn(%GameTile{letter: l}) -> l end,
      fn(%GameTile{value: p}) -> p end
    )
    |> Enum.map(fn({k, v}) -> {k, Enum.count(v)} end)
    assert distro == [
      {"?", 2}, {"A", 9}, {"B", 2}, {"C", 2}, {"D", 4}, {"E", 12}, {"F", 2},
      {"G", 3}, {"H", 2}, {"I", 9}, {"J", 1}, {"K", 1}, {"L", 4}, {"M", 2}, {"N", 6},
      {"O", 8}, {"P", 2}, {"Q", 1}, {"R", 6}, {"S", 4}, {"T", 6}, {"U", 4}, {"V", 2},
      {"W", 2}, {"X", 1}, {"Y", 2}, {"Z", 1}
    ]
    assert tiles
    |> Enum.map(fn(%GameTile{value: v}) -> v end)
    |> Enum.sum() == 187
    assert Enum.count(tiles) == 100
    assert Enum.at(tiles, 0) == %GameTile{letter: "A", value: 1}
    assert Enum.at(tiles, 8) == %GameTile{letter: "A", value: 1}
    assert Enum.at(tiles, 9) == %GameTile{letter: "B", value: 3}
    assert Enum.at(tiles, 10) == %GameTile{letter: "B", value: 3}
    assert Enum.at(tiles, 11) == %GameTile{letter: "C", value: 3}
    assert Enum.at(tiles, 99) == %GameTile{letter: "?", value: 0}
  end

  test "take_from_tray should pull out no tiles for this play, because J is not in tray" do
    letters_yx = [["A", 0, 2], ["L", 1, 2], ["A", 2, 2], ["N", 3, 2], ["J", 4, 2]]
    tiles_in_tray = [
      %GameTile{letter: "D", value: 1, x: nil, y: nil},
      %GameTile{letter: "N", value: 1, x: nil, y: nil},
      %GameTile{letter: "N", value: 1, x: nil, y: nil},
      %GameTile{letter: "L", value: 1, x: nil, y: nil},
      %GameTile{letter: "L", value: 1, x: nil, y: nil},
      %GameTile{letter: "A", value: 1, x: nil, y: nil},
      %GameTile{letter: "A", value: 1, x: nil, y: nil},
    ]
    assert GameTiles.take_from_tray(tiles_in_tray, letters_yx) == {
      [],
      [
        %GameTile{letter: "D", value: 1, x: nil, y: nil},
        %GameTile{letter: "N", value: 1, x: nil, y: nil},
        %GameTile{letter: "N", value: 1, x: nil, y: nil},
        %GameTile{letter: "L", value: 1, x: nil, y: nil},
        %GameTile{letter: "L", value: 1, x: nil, y: nil},
        %GameTile{letter: "A", value: 1, x: nil, y: nil},
        %GameTile{letter: "A", value: 1, x: nil, y: nil},
      ]
    }
  end
  test "take_from_tray should pull out the tiles for this play" do
    letters_yx = [["A", 0, 2], ["L", 1, 2], ["A", 2, 2], ["N", 3, 2]]
    tiles_in_tray = [
      %GameTile{letter: "D", value: 1, x: nil, y: nil},
      %GameTile{letter: "N", value: 1, x: nil, y: nil},
      %GameTile{letter: "N", value: 1, x: nil, y: nil},
      %GameTile{letter: "L", value: 1, x: nil, y: nil},
      %GameTile{letter: "L", value: 1, x: nil, y: nil},
      %GameTile{letter: "A", value: 1, x: nil, y: nil},
      %GameTile{letter: "A", value: 1, x: nil, y: nil},
    ]
    assert GameTiles.take_from_tray(tiles_in_tray, letters_yx) == {
      [
        %GameTile{letter: "A", value: 1, x: 2, y: 0},
        %GameTile{letter: "L", value: 1, x: 2, y: 1},
        %GameTile{letter: "A", value: 1, x: 2, y: 2},
        %GameTile{letter: "N", value: 1, x: 2, y: 3},
      ],
      [
        %GameTile{letter: "D", value: 1, x: nil, y: nil},
        %GameTile{letter: "N", value: 1, x: nil, y: nil},
        %GameTile{letter: "L", value: 1, x: nil, y: nil},
      ]
    }
  end
end
