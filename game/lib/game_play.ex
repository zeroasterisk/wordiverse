defmodule Wordiverse.GamePlay do
  @moduledoc """
  This is a single play on our Wordiverse Game
  1. setup: player_id, letter on coords
  2. verify: player_id, has letters in tray
  3. verify: letters are in row or col
  4. verify: letters touch existing letters on board
  5. verify: letters do not overlap any letters on board
  6. verify: letters + board form full words
  """

  defstruct [
    player_key: nil,
    letters_yx: [],
    letters_in_tray_after_play: [],
    score: 0,
    valid: nil,
    errors: [],
  ]

  @doc """
  Create a new play
  """
  def create(player_key, letters_yx) do
    %Wordiverse.GamePlay{
      player_key: player_key,
      letters_yx: letters_yx,
    }
  end


  @doc """
  Verify a play is playable on a game
  """
  def verify(
    %Wordiverse.GamePlay{} = play,
    %Wordiverse.Game{} = game
  ) do
    play
    # verifications which only consider the play itself
    |> verify_letters_are_valid()
    |> verify_letters_are_single_direction()
    # verifications with game
    |> verify_letters_in_tray(game)
    |> verify_letters_do_not_overlap(game)
    |> verify_letters_touch(game)
    |> verify_letters_cover_start(game)
    # final verification
    |> verify_no_errors()
  end

  @doc """
  Verify a play is playable on a game

  ## Examples

      iex> play = %Wordiverse.GamePlay{}
      iex> play = Wordiverse.GamePlay.verify_no_errors(play)
      iex> Map.get(play, :valid)
      true

      iex> play = %Wordiverse.GamePlay{errors: ["bad stuff"]}
      iex> play = Wordiverse.GamePlay.verify_no_errors(play)
      iex> Map.get(play, :valid)
      false

  """
  def verify_no_errors(%Wordiverse.GamePlay{errors: []} = play), do: play |> Map.merge(%{valid: true})
  def verify_no_errors(%Wordiverse.GamePlay{} = play), do: play |> Map.merge(%{valid: false})

  @doc """
  Verify a play letters are all valid letters

  ## Examples

      iex> play = %Wordiverse.GamePlay{letters_yx: []}
      iex> play = Wordiverse.GamePlay.verify_letters_are_valid(play)
      iex> Map.get(play, :errors)
      ["You have not played any letters"]

      iex> letters_yx = [[:a, 0, 2], ["l", 1, 2], ["l", 2, 2]]
      iex> play = %Wordiverse.GamePlay{letters_yx: letters_yx}
      iex> play = Wordiverse.GamePlay.verify_letters_are_valid(play)
      iex> Map.get(play, :errors)
      ["You have played invalid letters"]

      iex> letters_yx = [["a", 0, 2], ["l", 1, 2], ["l", 2, 2]]
      iex> play = %Wordiverse.GamePlay{letters_yx: letters_yx}
      iex> play = Wordiverse.GamePlay.verify_letters_are_valid(play)
      iex> Map.get(play, :errors)
      []

  """
  def verify_letters_are_valid(%Wordiverse.GamePlay{letters_yx: [], errors: errors} = play) do
    play |> Map.merge(%{errors: ["You have not played any letters" | errors]})
  end
  def verify_letters_are_valid(%Wordiverse.GamePlay{letters_yx: letters_yx, errors: errors} = play) do
    case Enum.all?(letters_yx, &is_valid_letter_xy/1) do
      true -> play
      false ->
        play |> Map.merge(%{errors: ["You have played invalid letters" | errors]})
    end
  end
  defp is_valid_letter_xy([letter, y, x]) when is_bitstring(letter) and is_integer(y) and is_integer(x) do
    true
  end
  defp is_valid_letter_xy(_), do: false


  @doc """
  Verify a play letters are all valid letters

  ## Examples

      iex> letters_yx = [["a", 0, 0], ["l", 1, 1]]
      iex> play = %Wordiverse.GamePlay{letters_yx: letters_yx}
      iex> play = Wordiverse.GamePlay.verify_letters_are_single_direction(play)
      iex> Map.get(play, :errors)
      ["You must play all tiles in a single row or column"]

      iex> letters_yx = [["a", 0, 2], ["l", 1, 2], ["l", 2, 2]]
      iex> play = %Wordiverse.GamePlay{letters_yx: letters_yx}
      iex> play = Wordiverse.GamePlay.verify_letters_are_single_direction(play)
      iex> Map.get(play, :errors)
      []

  """
  def verify_letters_are_single_direction(%Wordiverse.GamePlay{letters_yx: letters_yx, errors: []} = play) do
    count_y = letters_yx |> Enum.map(fn([_, y, _]) -> y end) |> Enum.uniq() |> Enum.count()
    count_x = letters_yx |> Enum.map(fn([_, _, x]) -> x end) |> Enum.uniq() |> Enum.count()
    case count_x == 1 or count_y == 1 do
      true -> play
      false ->
        play |> Map.merge(%{errors: ["You must play all tiles in a single row or column"]})
    end
  end
  def verify_letters_are_single_direction(%Wordiverse.GamePlay{} = play), do: play


  @doc """
  Verify a play only contains letter which are in a player's tray right now

  NOTE this will modify letters_in_tray_after_play on successful run (could move to different function)
  """
  def verify_letters_in_tray(
    %Wordiverse.GamePlay{player_key: player_key, letters_yx: letters_yx, errors: []} = play,
    %Wordiverse.Game{} = game
  ) do
    player = Map.get(game, player_key)
    letters_in_tray = Map.get(player, :tiles_in_tray) |> Enum.map(fn(t) -> t.letter end)
    letters_in_play = letters_yx |> Enum.map(fn([letter, _, _]) -> letter end)
    # TODO account for "?"
    {tiles_playable, tray} = Wordiverse.GameTiles.take_from_tray(
      letters_in_tray,
      letters_in_play
    )
    case Enum.count(tiles_playable) == Enum.count(letters_in_play) do
      true ->
        Map.merge(play, %{letters_in_tray_after_play: tray})
      false ->
        Map.merge(play, %{errors: ["Tiles not in your tray"]})
    end
  end
  def verify_letters_in_tray(%Wordiverse.GamePlay{} = play, %Wordiverse.Game{}), do: play

  @doc """
  Verify a play does no overlap any played squares on the board game
  """
  def verify_letters_do_not_overlap(
    %Wordiverse.GamePlay{letters_yx: letters_yx, errors: []} = play,
    %Wordiverse.Game{board: board}
  ) do
    new_squares = letters_yx
                  |> Enum.map(fn([_, y, x]) -> board[y][x][:letter] end)
                  |> Enum.all?(&is_nil/1)
    case new_squares do
      true -> play
      false ->
        Map.merge(play, %{errors: ["Tiles may not overlap"]})
    end
  end
  def verify_letters_do_not_overlap(%Wordiverse.GamePlay{} = play, %Wordiverse.Game{}), do: play

  @doc """
  Verify a play does abut at least 1 already played tile
  NOTE expemt for empty board
  """
  def verify_letters_touch(
    %Wordiverse.GamePlay{letters_yx: letters_yx, errors: []} = play,
    %Wordiverse.Game{board: board}
  ) do
    case Wordiverse.GameBoard.empty?(board) do
      true -> play
      false ->
        # find first instance where any played position, has a non-nil in an adjacent tile
        case letters_yx
        |> Enum.any?(fn([_, y, x]) ->
          Wordiverse.GameBoard.touching(board, y, x) |> Enum.any?(fn(%{letter: letter}) -> is_bitstring(letter) end)
        end) do
          true -> play
          false ->
            Map.merge(play, %{errors: ["Tiles must touch an existing tile"]})
        end
    end
  end
  def verify_letters_touch(%Wordiverse.GamePlay{} = play, %Wordiverse.Game{}), do: play

  @doc """
  Verify a play does cover the center square
  NOTE only for empty board
  """
  def verify_letters_cover_start(
    %Wordiverse.GamePlay{letters_yx: letters_yx, errors: []} = play,
    %Wordiverse.Game{board: board}
  ) do
    case Wordiverse.GameBoard.empty?(board) do
      false -> play
      true ->
        # ensure the center cell is in the play
        {_total_y, _total_x, center_y, center_x} = Wordiverse.GameBoard.measure(board)
        case letters_yx |> Enum.any?(fn([_, y, x]) -> y == center_y and x == center_x end) do
          true -> play
          false ->
            Map.merge(play, %{errors: ["Tiles must cover the center square to start"]})
        end
    end
  end
  def verify_letters_cover_start(%Wordiverse.GamePlay{} = play, %Wordiverse.Game{}), do: play



end

