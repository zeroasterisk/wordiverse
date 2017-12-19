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
    |> verify_letters_form_full_words(game)
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
    letters_in_tray = player |> Map.get(:tiles_in_tray) |> Enum.map(fn(t) -> t.letter end)
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
        case any_letters_xy_touching?(board, letters_yx) do
          true -> play
          false ->
            Map.merge(play, %{errors: ["Tiles must touch an existing tile"]})
        end
    end
  end
  def verify_letters_touch(%Wordiverse.GamePlay{} = play, %Wordiverse.Game{}), do: play

  defp any_letters_xy_touching?(board, letters_yx) do
    letters_yx
    |> Enum.any?(
      fn([_, y, x]) ->
        board
        |> Wordiverse.GameBoardGet.touching(y, x)
        |> Enum.any?(fn(%{letter: letter}) -> is_bitstring(letter) end)
      end
    )
  end

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
        case any_letters_xy_on_center?(board, letters_yx) do
          true -> play
          false ->
            Map.merge(play, %{errors: ["Tiles must cover the center square to start"]})
        end
    end
  end
  def verify_letters_cover_start(%Wordiverse.GamePlay{} = play, %Wordiverse.Game{}), do: play

  defp any_letters_xy_on_center?(board, letters_yx) do
    {_total_y, _total_x, center_y, center_x} = Wordiverse.GameBoard.measure(board)
    letters_yx
    |> Enum.any?(
      fn([_, y, x]) -> y == center_y and x == center_x end
    )
  end


  @doc """
  This verifies all "words" formed with the new letters
  are full words (uses the Dictionary for the type of game = GenServer)
  """
  def verify_letters_form_full_words(
    %Wordiverse.GamePlay{letters_yx: letters_yx, errors: []} = play,
    %Wordiverse.Game{board: board} = game
  ) do
    # get all words for all letters
    # ensure all words are full words
    board_next = board |> Wordiverse.GameBoard.add_letters_xy(letters_yx)
    words = Wordiverse.GameBoardGet.touching_words(board_next, letters_yx)
    words_invalid = Enum.filter(words, fn(word) -> !verify_word_full(game, word) end)
    case Enum.count(words_invalid) do
      0 -> play
      1 ->
        Map.merge(play, %{errors: ["Not In Dictionary, unknown word: #{simplify_words(words_invalid)}"]})
      _ ->
        Map.merge(play, %{errors: ["Not In Dictionary, unknown words: #{simplify_words(words_invalid)}"]})
    end
  end
  def verify_letters_form_full_words(%Wordiverse.GamePlay{} = play, %Wordiverse.Game{}), do: play

  @doc """
  Sometimes we want simple lists of actual words, not squares/plays

  ## Examples

      iex> Wordiverse.GamePlay.simplify_words([[%{letter: "A"}, %{letter: "B"}]])
      "AB"

      iex> Wordiverse.GamePlay.simplify_words([[%{letter: "A"}, %{letter: "B"}], [%{letter: "B"}, %{letter: "A"}]])
      "AB, BA"
  """
  def simplify_words(words) do
    words
    |> Enum.map(
      fn(word) ->
        word |> Enum.map(fn(%{letter: l}) -> l end) |> Enum.join("")
      end
    )
    |> Enum.join(", ")
  end

  @doc """
  Lookup a word in the dictionary serivce for this type
  NOTE the Dictionary must already be started and running

  ## Examples

      iex> Wordiverse.Dictionary.start_link(:mock)
      iex> game = %Wordiverse.Game{type: :mock}
      iex> word = [%{letter: "A"}, %{letter: "L"}, %{letter: "L"}]
      iex> Wordiverse.GamePlay.verify_word_full(game, word)
      true

      iex> Wordiverse.Dictionary.start_link(:mock)
      iex> game = %Wordiverse.Game{type: :mock}
      iex> word = [%{letter: "A"}, %{letter: "L"}]
      iex> Wordiverse.GamePlay.verify_word_full(game, word)
      false
  """
  def verify_word_full(%Wordiverse.Game{type: type}, word) do
    word = Enum.map(word, fn(%{letter: l}) -> l end)
    Wordiverse.Dictionary.is_word_full?(type, word) == :ok
  end

end
