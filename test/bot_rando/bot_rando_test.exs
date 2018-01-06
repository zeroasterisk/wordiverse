defmodule BotRandoTest do
  use ExUnit.Case
  doctest Wordza.BotRando
  alias Wordza.BotRando
  alias Wordza.GameBoard
  alias Wordza.GameTiles

  test "pick_start_yx via center for first play" do
    start_yx = BotRando.pick_start_yx(%BotRando{
      first_play?: true,
      center_y: 5,
      center_x: 5,
      tiles_in_tray: GameTiles.add([], "a", 1, 7),
    })
    assert start_yx == [5, 5]
  end
  test "pick_start_yx via random_yx" do
    board = Wordza.GameBoard.create(:scrabble)
    |> put_in([7, 7, :letter], "a")
    |> put_in([7, 8, :letter], "a")
    |> put_in([7, 9, :letter], "a")
    {total_y, total_x, _, _} = board |> GameBoard.measure
    [y, x] = BotRando.pick_start_yx(%BotRando{
      board: board,
      total_y: total_y,
      total_x: total_x,
      tiles_in_tray: GameTiles.add([], "a", 1, 7),
    })
    assert is_number(y) == true
    assert is_number(x) == true
    assert y < 14
    assert x < 14
  end

end

