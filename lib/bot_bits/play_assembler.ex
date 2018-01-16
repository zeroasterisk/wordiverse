defmodule Wordza.PlayAssembler do
  @moduledoc """
  A useful module/struct for assembling possible plays
  """
  alias Wordza.GamePlay
  alias Wordza.GameInstance

  @doc """
  Create a PlayAssembler for a given start_yx and word_start
  This gets things start, from top or left, until the first played letter
  NOTE this will often not be a complete word, look for other functions to extend/complete
  """
  def create_y(
    %GameInstance{} = game,
    player_key,
    start_yx,
    word_start
  ) do
    letters_yx = play_word_start_y([], start_yx, word_start)
    player_key |> GamePlay.create(letters_yx) |> GamePlay.verify_start(game)
  end

  @doc """
  Lay down tiles for a word_start

  ## Examples

      iex> Wordza.PlayAssembler.play_word_start_y([], [0, 0], ["a", "l", "l"])
      [
        ["a", 0, 0],
        ["l", 1, 0],
        ["l", 2, 0],
      ]
  """
  def play_word_start_y(letters_yx, _start_yx, [] = _word_start), do: letters_yx |> Enum.reverse()
  def play_word_start_y(letters_yx, [y, x] = _start_yx, [letter | word_start]) do
    [[letter, y, x] | letters_yx] |> play_word_start_y([y + 1, x], word_start)
  end

  @doc """
  Lay right tiles for a word_start

  ## Examples

      iex> Wordza.PlayAssembler.play_word_start_x([], [0, 0], ["a", "l", "l"])
      [
        ["a", 0, 0],
        ["l", 0, 1],
        ["l", 0, 2],
      ]

  """
  def play_word_start_x(letters_yx, _start_yx, [] = _word_start), do: letters_yx |> Enum.reverse()
  def play_word_start_x(letters_yx, [y, x] = _start_yx, [letter | word_start]) do
    [[letter, y, x] | letters_yx] |> play_word_start_x([y, x + 1], word_start)
  end

end

