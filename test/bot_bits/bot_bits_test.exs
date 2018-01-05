defmodule BotBitsTest do
  use ExUnit.Case
  doctest Wordza.BotBits
  alias Wordza.BotBits
  alias Wordza.GameBoard

  test "start_yx_playable is false, if already played square" do
    board = GameBoard.create(:scrabble)
    |> put_in([9, 7, :letter], "a") 
    |> put_in([9, 8, :letter], "a") 
    |> put_in([9, 9, :letter], "a") 
    assert BotBits.start_yx_possible?(board, 9, 9) == false
  end


  test "start_yx_playable is false, if no overlap within 7 tiles of played word" do
    board = GameBoard.create(:scrabble)
    |> put_in([9, 7, :letter], "a") 
    |> put_in([9, 8, :letter], "a") 
    |> put_in([9, 9, :letter], "a") 
    # totally alone
    assert BotBits.start_yx_possible?(board, 0, 0) == false
    # too far above
    assert BotBits.start_yx_possible?(board, 0, 8) == false
    # below a valid tile (not a valid start)
    assert BotBits.start_yx_possible?(board, 10, 8) == false
  end

  test "start_yx_playable is true, if valid" do
    board = GameBoard.create(:scrabble)
    |> put_in([9, 7, :letter], "a") 
    |> put_in([9, 8, :letter], "a") 
    |> put_in([9, 9, :letter], "a") 
    assert BotBits.start_yx_possible?(board, 7, 7) == true
  end

end
