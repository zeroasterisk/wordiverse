defmodule Wordza.BotBits do
  @moduledoc """
  A set of shared "bits" for all Bots...

  These are utilities for aiding in common functionalities for all/many bots.

  - start_yx_possible?
  - build_all_words_for_letters
  """
 
  @doc """
  Is the y+x a possible start on the board?
  - must be an unplayed, valid square
  - must be within 7 of a played letter
  """
  def start_yx_possible?(board, y, x) do
    !!(
      board
      |> start_yx_playable?(y, x)
      |> start_yx_within7?(y, x)
    )
  end

  @doc """
  A start must not be on an already played spot
  """
  def start_yx_playable?(board, y, x) do
    case yx_playable?(board, y, x) do
      true -> board
      _ -> false
    end
  end


  @doc """
  A start must within 7 of an already played spot
  in either x or y
  """
  def start_yx_within7?(false, _y, _x), do: false
  def start_yx_within7?(board, y, x) do
    [
      yx_played?(board, y, x + 1),
      yx_played?(board, y, x + 2),
      yx_played?(board, y, x + 3),
      yx_played?(board, y, x + 4),
      yx_played?(board, y, x + 5),
      yx_played?(board, y, x + 6),
      yx_played?(board, y, x + 7),
      yx_played?(board, y + 1, x),
      yx_played?(board, y + 2, x),
      yx_played?(board, y + 3, x),
      yx_played?(board, y + 4, x),
      yx_played?(board, y + 5, x),
      yx_played?(board, y + 6, x),
      yx_played?(board, y + 7, x),
    ] |> Enum.any?()
  end

  @doc """
  On a board, is a y+x yx_playable?
  It must be a valid place, and have no letter already
  """
  def yx_playable?(board, y, x) do
    is_nil(board[y][x][:letter]) and !is_nil(board[y][x]) 
  end

  @doc """
  On a board, is a y+x yx_played already?
  It must be a valid place, and have a letter already
  """
  def yx_played?(board, y, x) do
    is_bitstring(board[y][x][:letter]) 
  end

end
