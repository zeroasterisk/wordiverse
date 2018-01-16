defmodule Wordza.GamePlay do
  @moduledoc """
  This is a single play on our Wordza Game
  1. setup: player_id, letter on coords
  2. verify: player_id, has letters in tray
  3. verify: letters are in row or col
  4. verify: letters touch existing letters on board
  5. verify: letters do not overlap any letters on board
  6. verify: letters + board form full words
  """
  require Logger
  alias Wordza.GamePlay
  alias Wordza.GameBoard
  alias Wordza.GameBoardGet
  alias Wordza.GameInstance
  alias Wordza.GameTiles
  alias Wordza.GameTile
  alias Wordza.Dictionary

  defstruct [
    player_key: nil,
    direction: nil,
    letters_yx: [], # intended played letters/tiles
    board_next: nil, # intended board after play
    tiles_in_play: [], # tiles pulled from tray for play
    tiles_in_tray: [],  # tiles in tray, after the play
    score: 0,
    valid: nil,
    words: [],
    errors: [],
  ]

  @doc """
  Create a new GamePlay (does not verify)

  ## Examples

      iex> letters_yx = [["a", 0, 2], ["l", 1, 2], ["l", 2, 2]]
      iex> Wordza.GamePlay.create(:player_1, letters_yx)
      %Wordza.GamePlay{
        player_key: :player_1,
        letters_yx: [["a", 0, 2], ["l", 1, 2], ["l", 2, 2]],
        direction: :y,
        score: 0,
        valid: nil,
        errors: [],
      }
  """
  def create(player_key, letters_yx) do
    %GamePlay{
      player_key: player_key,
      letters_yx: letters_yx,
      direction: guess_direction(letters_yx),
    }
  end
  def create(player_key, letters_yx, direction) do
    %GamePlay{
      player_key: player_key,
      letters_yx: letters_yx,
      direction: direction,
    }
  end

  @doc """
  Guess the direction of a play of letters_yx

  ## Examples

      iex> letters_yx = [["a", 0, 2], ["l", 1, 2], ["l", 2, 2]]
      iex> Wordza.GamePlay.guess_direction(letters_yx)
      :y

      iex> letters_yx = [["a", 2, 0], ["l", 2, 1], ["l", 2, 2]]
      iex> Wordza.GamePlay.guess_direction(letters_yx)
      :x
  """
  def guess_direction(letters_yx) do
    xs = letters_yx |> Enum.map(fn([_letter, _y, x]) -> x end) |> Enum.uniq() |> Enum.count()
    ys = letters_yx |> Enum.map(fn([_letter, y, _x]) -> y end) |> Enum.uniq() |> Enum.count()
    cond do
      xs > ys -> :x
      ys > xs -> :y
      true -> :y
    end
  end

  @doc """
  Assign extra details, like the "next" board after this play, and the words found, and the score
  NOTE this is automatically done in verify()
  """
  def assign(
    %GamePlay{errors: []} = play,
    %GameInstance{board: board} = game
  ) do
    play
    |> assign_letters(game)
    |> assign_words(game)
    |> assign_score(game)
  end

  @doc """
  Assign extra details, the board_next is the board after this play
  NOTE this is automatically done in verify()
  NOTE that any "?" should already be converted to a 0 value letter before this
  """
  def assign_letters(
    %GamePlay{player_key: player_key, letters_yx: letters_yx, errors: []} = play,
    %GameInstance{board: board} = game
  ) do
    player = Map.get(game, player_key)
    tray = player |> Map.get(:tiles_in_tray)
    # NOTE take_from_tray must keep the x & y from letters_yx
    {tiles_in_play, tiles_in_tray} = GameTiles.take_from_tray(tray, letters_yx)
    play |> Map.merge(%{
      board_next: board |> GameBoard.add_letters(tiles_in_play),
      tiles_in_play: tiles_in_play,
      tiles_in_tray: tiles_in_tray,
    })
  end
  def assign_letters(%GamePlay{} = play, %GameInstance{} = _game), do: play

  @doc """
  Assign extra details, the words found with this play (tiles_in_play + played on board)
  NOTE this is automatically done in verify()
  """
  def assign_words(
    %GamePlay{tiles_in_play: tiles_in_play, board_next: board_next, errors: []} = play,
    %GameInstance{} = _game
  ) do
    words = GameBoardGet.touching_words(board_next, tiles_in_play)
    play |> Map.merge(%{words: words})
  end
  def assign_words(%GamePlay{} = play, %GameInstance{} = _game), do: play

  @doc """
  Assign extra details, the score for the words in this play (tiles_in_play + played on board + bonuses)
  NOTE this is automatically done in verify()
  """
  def assign_score(
    %GamePlay{tiles_in_play: tiles_in_play, words: words, errors: []} = play,
    %GameInstance{} = _game
  ) do
    words = words_bonuses_only_on_played(words, tiles_in_play)
    score = words |> Enum.map(&score_word/1) |> Enum.sum()
    play |> Map.merge(%{score: score})
  end
  def assign_score(%GamePlay{} = play, %GameInstance{} = _game), do: play

  @doc """
  Add up a score for a single word

      iex> word = [%{bonus: nil, value: 1, letter: "A", y: 0, x: 2}, %{bonus: nil, value: 1, letter: "L", y: 1, x: 2}, %{bonus: nil, value: 1, letter: "L", y: 2, x: 2}]
      iex> Wordza.GamePlay.score_word(word)
      3

      iex> word = [%{bonus: :tl, value: 1, letter: "A", y: 0, x: 2}, %{bonus: nil, value: 1, letter: "L", y: 1, x: 2}, %{bonus: :st, value: 1, letter: "L", y: 2, x: 2}]
      iex> Wordza.GamePlay.score_word(word)
      10
  """
  def score_word(word) do
    word
    |> Enum.map(&apply_bonus_letter/1)
    |> Enum.map(&ensure_value/1)
    |> Enum.map(fn(%{value: value}) -> value end)
    |> Enum.sum()
    |> apply_bonus_word(word)
  end
  defp ensure_value(%{value: value} = l), do: l
  defp ensure_value(%{} = l) do
    raise "ensure_value no value"
    Logger.error fn() -> "GamePlay.ensure_value missing value #{inspect(l)}" end
    l |> Map.merge(%{value: 0})
  end
  defp apply_bonus_letter(%{bonus: :tl, value: value} = l), do: l |> Map.merge(%{bonus: nil, value: value * 3})
  defp apply_bonus_letter(%{bonus: :dl, value: value} = l), do: l |> Map.merge(%{bonus: nil, value: value * 2})
  defp apply_bonus_letter(%{} = l), do: l
  defp apply_bonus_word(score, []), do: score
  defp apply_bonus_word(score, [%{bonus: :tw} = played | word]), do: (score * 3) |> apply_bonus_word(word)
  defp apply_bonus_word(score, [%{bonus: :dw} = played | word]), do: (score * 2) |> apply_bonus_word(word)
  defp apply_bonus_word(score, [%{bonus: :st} = played | word]), do: (score * 2) |> apply_bonus_word(word)
  defp apply_bonus_word(score, [%{} = played | word]), do: score |> apply_bonus_word(word)

  @doc """
  We only allow bonuses on letters/squares which were just played

  ## Examples

      iex> words = [[%{bonus: :tl, letter: "A", y: 0, x: 2}, %{bonus: nil, letter: "L", y: 1, x: 2}, %{bonus: :st, letter: "L", y: 2, x: 2}]]
      iex> Wordza.GamePlay.words_bonuses_only_on_played(words, [["A", 0, 2]])
      [[
        %{bonus: :tl, letter: "A", y: 0, x: 2},
        %{bonus: nil, letter: "L", y: 1, x: 2},
        %{bonus: nil, letter: "L", y: 2, x: 2}
      ]]
  """
  def words_bonuses_only_on_played(words, tiles_in_play) do
    words |> Enum.map(fn(word) -> word_bonuses_only_on_played(word, tiles_in_play) end)
  end

  @doc """
  We only allow bonuses on letters/squares which were just played

  ## Examples

      iex> word = [%{bonus: :tl, letter: "A", y: 0, x: 2}, %{bonus: nil, letter: "L", y: 1, x: 2}, %{bonus: :st, letter: "L", y: 2, x: 2}]
      iex> tiles_in_play = [%{letter: "A", y: 0, x: 2}]
      iex> Wordza.GamePlay.word_bonuses_only_on_played(word, tiles_in_play)
      [
        %{bonus: :tl, letter: "A", y: 0, x: 2},
        %{bonus: nil, letter: "L", y: 1, x: 2},
        %{bonus: nil, letter: "L", y: 2, x: 2}
      ]
  """
  def word_bonuses_only_on_played(word, tiles_in_play) do
    word |> Enum.map(fn(played) -> tile_bonuses_only_on_played(played, tiles_in_play) end)
  end

  @doc """
  We only allow bonuses on letters/squares which were just played

  ## Examples

      iex> played = %{bonus: :tl, letter: "A", y: 0, x: 2}
      iex> tiles_in_play = [%{letter: "A", y: 0, x: 2}]
      iex> Wordza.GamePlay.tile_bonuses_only_on_played(played, tiles_in_play)
      %{bonus: :tl, letter: "A", y: 0, x: 2}

      iex> played = %{bonus: :tl, letter: "A", y: 0, x: 2}
      iex> tiles_in_play = [%{letter: "A", y: 0, x: 3}]
      iex> Wordza.GamePlay.tile_bonuses_only_on_played(played, tiles_in_play)
      %{bonus: nil, letter: "A", y: 0, x: 2}
  """
  def tile_bonuses_only_on_played(%{letter: letter, y: y, x: x} = played, tiles_in_play) do
    letters_yx = tiles_to_letters_yx([], tiles_in_play)
    case Enum.member?(letters_yx, [letter, y, x]) do
      true -> played
      false -> Map.merge(played, %{bonus: nil})
    end
  end
  defp tiles_to_letters_yx(acc, [%{letter: letter, y: y, x: x} | tiles_in_play]) do
    [[letter, y, x] | acc]
  end
  defp tiles_to_letters_yx(acc, [[letter, y, x] | tiles_in_play]) do
    [[letter, y, x] | acc]
  end

  @doc """
  Verify a play is playable on a game (FINAL - ALL FULL WORDS)
  """
  def verify(
    %GamePlay{} = play,
    %GameInstance{} = game
  ) do
    play
    # verifications which only consider the play itself
    |> verify_letters_are_valid()
    |> verify_letters_are_single_direction()
    # assign stuff
    |> assign_letters(game)
    |> assign_words(game)
    # verifications with game
    |> verify_letters_in_tray(game)
    |> verify_letters_do_not_overlap(game)
    |> verify_letters_touch(game)
    |> verify_letters_cover_start(game)
    |> verify_words_exist(game)
    |> verify_words_are_full_words(game)
    # final verification
    |> verify_no_errors()
    |> assign_score(game)
  end

  @doc """
  Verify a play is possibly playable on a game (PARTIAL - ALL WORDS AT LEAST START)
  """
  def verify_start(
    %GamePlay{} = play,
    %GameInstance{} = game
  ) do
    play
    # verifications which only consider the play itself
    |> verify_letters_are_valid()
    |> verify_letters_are_single_direction()
    # assign stuff
    |> assign_letters(game)
    |> assign_words(game)
    # verifications with game
    |> verify_letters_in_tray(game)
    |> verify_letters_do_not_overlap(game)
    |> verify_letters_touch(game)
    |> verify_letters_cover_start(game)
    |> verify_letters_form_partial_words(game)
    # final verification
    |> verify_no_errors()
    |> assign_score(game)
  end

  @doc """
  Verify a play is playable on a game

  ## Examples

      iex> play = %Wordza.GamePlay{}
      iex> play = Wordza.GamePlay.verify_no_errors(play)
      iex> Map.get(play, :valid)
      true

      iex> play = %Wordza.GamePlay{errors: ["bad stuff"]}
      iex> play = Wordza.GamePlay.verify_no_errors(play)
      iex> Map.get(play, :valid)
      false

  """
  def verify_no_errors(%GamePlay{errors: []} = play), do: play |> Map.merge(%{valid: true})
  def verify_no_errors(%GamePlay{} = play), do: play |> Map.merge(%{valid: false})

  @doc """
  Verify a play letters are all valid letters

  ## Examples

      iex> play = %Wordza.GamePlay{letters_yx: []}
      iex> play = Wordza.GamePlay.verify_letters_are_valid(play)
      iex> Map.get(play, :errors)
      ["You have not played any letters"]

      iex> letters_yx = [[:a, 0, 2], ["l", 1, 2], ["l", 2, 2]]
      iex> play = %Wordza.GamePlay{letters_yx: letters_yx}
      iex> play = Wordza.GamePlay.verify_letters_are_valid(play)
      iex> Map.get(play, :errors)
      ["You have played invalid letters"]

      iex> letters_yx = [["a", 0, 2], ["l", 1, 2], ["l", 2, 2]]
      iex> play = %Wordza.GamePlay{letters_yx: letters_yx}
      iex> play = Wordza.GamePlay.verify_letters_are_valid(play)
      iex> Map.get(play, :errors)
      []

  """
  def verify_letters_are_valid(%GamePlay{letters_yx: [], errors: errors} = play) do
    play |> Map.merge(%{errors: ["You have not played any letters" | errors]})
  end
  def verify_letters_are_valid(%GamePlay{letters_yx: letters_yx, errors: errors} = play) do
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
      iex> play = %Wordza.GamePlay{letters_yx: letters_yx}
      iex> play = Wordza.GamePlay.verify_letters_are_single_direction(play)
      iex> Map.get(play, :errors)
      ["You must play all tiles in a single row or column"]

      iex> letters_yx = [["a", 0, 2], ["l", 1, 2], ["l", 2, 2]]
      iex> play = %Wordza.GamePlay{letters_yx: letters_yx}
      iex> play = Wordza.GamePlay.verify_letters_are_single_direction(play)
      iex> Map.get(play, :errors)
      []

  """
  def verify_letters_are_single_direction(%GamePlay{letters_yx: letters_yx, errors: []} = play) do
    count_y = letters_yx |> Enum.map(fn([_, y, _]) -> y end) |> Enum.uniq() |> Enum.count()
    count_x = letters_yx |> Enum.map(fn([_, _, x]) -> x end) |> Enum.uniq() |> Enum.count()
    case count_x == 1 or count_y == 1 do
      true -> play
      false ->
        play |> Map.merge(%{errors: ["You must play all tiles in a single row or column"]})
    end
  end
  def verify_letters_are_single_direction(%GamePlay{} = play), do: play


  @doc """
  Verify a play only contains letter which are in a player's tray right now

  NOTE this will modify tiles_in_tray on successful run (could move to different function)
  """
  def verify_letters_in_tray(
    %GamePlay{player_key: player_key, letters_yx: letters_yx, errors: []} = play,
    %GameInstance{} = game
  ) do
    # TODO vv replace this with an assign_letters <--
    player = Map.get(game, player_key)
    letters_in_tray = player |> Map.get(:tiles_in_tray)
    letters_in_play = letters_yx |> Enum.map(fn([letter, _, _]) -> letter end)
    {tiles_in_play, tray} = GameTiles.take_from_tray(letters_in_tray, letters_in_play)
    # TODO ^^ replace with assign_letters <--
    case Enum.count(tiles_in_play) == Enum.count(letters_in_play) do
      true ->
        Map.merge(play, %{tiles_in_tray: tray})
      false ->
        Map.merge(play, %{errors: ["Tiles not in your tray"]})
    end
  end
  def verify_letters_in_tray(%GamePlay{} = play, %GameInstance{}), do: play

  @doc """
  Verify a play does no overlap any played squares on the board game
  """
  def verify_letters_do_not_overlap(
    %GamePlay{letters_yx: letters_yx, errors: []} = play,
    %GameInstance{board: board}
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
  def verify_letters_do_not_overlap(%GamePlay{} = play, %GameInstance{}), do: play

  @doc """
  Verify a play does abut at least 1 already played tile
  NOTE expemt for empty board
  """
  def verify_letters_touch(
    %GamePlay{letters_yx: letters_yx, errors: []} = play,
    %GameInstance{board: board}
  ) do
    case GameBoard.empty?(board) do
      true -> play
      false ->
        case any_letters_xy_touching?(board, letters_yx) do
          true -> play
          false ->
            Map.merge(play, %{errors: ["Tiles must touch an existing tile"]})
        end
    end
  end
  def verify_letters_touch(%GamePlay{} = play, %GameInstance{}), do: play

  defp any_letters_xy_touching?(board, letters_yx) do
    letters_yx
    |> Enum.any?(
      fn([_, y, x]) ->
        board
        |> GameBoardGet.touching(y, x)
        |> Enum.any?(fn(%{letter: letter}) -> is_bitstring(letter) end)
      end
    )
  end

  @doc """
  Verify a play does cover the center square
  NOTE only for empty board
  """
  def verify_letters_cover_start(
    %GamePlay{letters_yx: letters_yx, errors: []} = play,
    %GameInstance{board: board}
  ) do
    case GameBoard.empty?(board) do
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
  def verify_letters_cover_start(%GamePlay{} = play, %GameInstance{}), do: play

  defp any_letters_xy_on_center?(board, letters_yx) do
    {_total_y, _total_x, center_y, center_x} = GameBoard.measure(board)
    letters_yx
    |> Enum.any?(
      fn([_, y, x]) -> y == center_y and x == center_x end
    )
  end

  @doc """
  This verifies there are at least some "words" formed with the new letters
  """
  def verify_words_exist(
    %GamePlay{words: words, errors: []} = play,
    %GameInstance{} = game
  ) do
    case Enum.count(words) do
      0 ->
        Map.merge(play, %{errors: ["No words formed, invalid play"]})
      _ -> play
    end
  end
  def verify_words_exist(%GamePlay{} = play, %GameInstance{}), do: play


  @doc """
  This verifies all "words" formed with the new letters
  are full words (uses the Dictionary for the type of game = GenServer)
  """
  def verify_words_are_full_words(
    %GamePlay{words: words, errors: []} = play,
    %GameInstance{} = game
  ) do
    words_invalid = Enum.filter(words, fn(word) -> !verify_word_full(game, word) end)
    case Enum.count(words_invalid) do
      0 -> play
      1 ->
        Map.merge(play, %{errors: ["Not In Dictionary, unknown word: #{simplify_words(words_invalid)}"]})
      _ ->
        Map.merge(play, %{errors: ["Not In Dictionary, unknown words: #{simplify_words(words_invalid)}"]})
    end
  end
  def verify_words_are_full_words(%GamePlay{} = play, %GameInstance{}), do: play

  @doc """
  This verifies all "words" formed with the new letters
  are at least partial words (uses the Dictionary for the type of game = GenServer)
  NOTE this is used by bots for assembling plays
  """
  def verify_letters_form_partial_words(
    %GamePlay{words: words, board_next: board_next, errors: []} = play,
    %GameInstance{board: board} = game
  ) do
    words_invalid = Enum.filter(words, fn(word) -> !verify_word_start(game, word) end)
    case Enum.count(words_invalid) do
      0 -> play
      1 ->
        Map.merge(play, %{errors: ["Not In Dictionary, unknown word: #{simplify_words(words_invalid)}"]})
      _ ->
        Map.merge(play, %{errors: ["Not In Dictionary, unknown words: #{simplify_words(words_invalid)}"]})
    end
  end
  def verify_letters_form_partial_words(%GamePlay{} = play, %GameInstance{}), do: play

  @doc """
  Sometimes we want simple lists of actual words, not squares/plays

  ## Examples

      iex> Wordza.GamePlay.simplify_words([[%{letter: "A"}, %{letter: "B"}]])
      "AB"

      iex> Wordza.GamePlay.simplify_words([[%{letter: "A"}, %{letter: "B"}], [%{letter: "B"}, %{letter: "A"}]])
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

      iex> Wordza.Dictionary.start_link(:mock)
      iex> game = %Wordza.GameInstance{type: :mock}
      iex> word = [%{letter: "A"}, %{letter: "L"}, %{letter: "L"}]
      iex> Wordza.GamePlay.verify_word_full(game, word)
      true

      iex> Wordza.Dictionary.start_link(:mock)
      iex> game = %Wordza.GameInstance{type: :mock}
      iex> word = [%{letter: "A"}, %{letter: "L"}]
      iex> Wordza.GamePlay.verify_word_full(game, word)
      false
  """
  def verify_word_full(%GameInstance{type: type}, word) do
    word = Enum.map(word, fn(%{letter: l}) -> l end)
    Dictionary.is_word_full?(type, word) == :ok
  end

  @doc """
  Lookup a word in the dictionary serivce for this type
  NOTE the Dictionary must already be started and running

  ## Examples

      iex> Wordza.Dictionary.start_link(:mock)
      iex> game = %Wordza.GameInstance{type: :mock}
      iex> word = [%{letter: "A"}, %{letter: "L"}, %{letter: "L"}]
      iex> Wordza.GamePlay.verify_word_start(game, word)
      true

      iex> Wordza.Dictionary.start_link(:mock)
      iex> game = %Wordza.GameInstance{type: :mock}
      iex> word = [%{letter: "A"}, %{letter: "L"}]
      iex> Wordza.GamePlay.verify_word_start(game, word)
      true

      iex> Wordza.Dictionary.start_link(:mock)
      iex> game = %Wordza.GameInstance{type: :mock}
      iex> word = [%{letter: "J"}, %{letter: "J"}]
      iex> Wordza.GamePlay.verify_word_start(game, word)
      false
  """
  def verify_word_start(%GameInstance{type: type}, word) do
    word = Enum.map(word, fn(%{letter: l}) -> l end)
    Dictionary.is_word_start?(type, word) == :ok
  end

end
