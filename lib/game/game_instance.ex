defmodule Wordza.GameInstance do
  @moduledoc """
  This is actions taken on our Wordza Game
  """
  defstruct [
    name: nil,
    type: nil,
    dictionary_name: nil,
    board: nil,
    tiles_in_pile: nil,
    player_1: nil,
    player_2: nil,
    score: 0,
    plays: [],
    # this is game status - either players turn or :game_over
    turn: 1,
  ]
  require Logger
  alias Wordza.GameInstance
  alias Wordza.GameBoard
  alias Wordza.GameTiles
  alias Wordza.GamePlay
  alias Wordza.GamePass
  alias Wordza.GamePlayer

  @doc """
  Setup a fully ready game... requires a type and 2 player ids

  ## Examples

      iex> player_1_id = 1234
      iex> player_2_id = 827
      iex> game = Wordza.GameInstance.create(:wordfeud, player_1_id, player_2_id)
      iex> Map.get(game, :type)
      :wordfeud

  """
  def create(type, player_1_id, player_2_id) do
    name = GameInstance.build_game_name(type)
    create(type, player_1_id, player_2_id, name)
  end
  def create(:mock, player_1_id, player_2_id, name) do
    tiles_in_tray = GameTiles.create(:mock_tray)
    player_1 = player_1_id
               |> GamePlayer.create()
               |> Map.merge(%{tiles_in_tray: tiles_in_tray})
    player_2 = player_2_id
               |> GamePlayer.create()
               |> Map.merge(%{tiles_in_tray: tiles_in_tray})
    %GameInstance{
      name: name,
      type: :mock,
      dictionary_name: :mock,
      board: GameBoard.create(:mock),
      tiles_in_pile: GameTiles.create(:mock),
      player_1: player_1,
      player_2: player_2,
      turn: 1,
      score: 0,
      plays: [],
    }
  end
  def create(type, player_1_id, player_2_id, name) do
    create(type, player_1_id, player_2_id, name, type)
  end
  def create(type, player_1_id, player_2_id, name, dictionary_name) do
    # TO_DO refactor - 5 positional args?  ugly
    %GameInstance{
      name: name,
      type: type,
      dictionary_name: dictionary_name,
      board: GameBoard.create(type),
      tiles_in_pile: GameTiles.create(type),
      player_1: GamePlayer.create(player_1_id),
      player_2: GamePlayer.create(player_2_id),
      turn: Enum.random([1, 2]),
      score: 0,
      plays: [],
    }
    |> fill_player_tiles(:player_1)
    |> fill_player_tiles(:player_2)
  end

  @doc """
  Fill a single player's tray until it's full (7 tiles)

  ## Examples

      iex> tiles = ["a", "b", "c", "d", "e", "f", "g"]
      iex> p1 = Wordza.GamePlayer.create(:p1)
      iex> game = %Wordza.GameInstance{type: :wordfeud, tiles_in_pile: tiles, player_1: p1}
      iex> game = Wordza.GameInstance.fill_player_tiles(game, :player_1)
      iex> game |> Map.get(:player_1) |> Map.get(:tiles_in_tray) |> Enum.sort()
      ["a", "b", "c", "d", "e", "f", "g"]

      iex> tiles = ["a", "a", "a", "a", "a", "a", "a"]
      iex> p1 = Wordza.GamePlayer.create(:p1)
      iex> p1 = p1 |> Map.merge(%{tiles_in_tray: ["x", "x", "x", "x"]})
      iex> game = %Wordza.GameInstance{type: :wordfeud, tiles_in_pile: tiles, player_1: p1}
      iex> game = Wordza.GameInstance.fill_player_tiles(game, :player_1)
      iex> game |> Map.get(:player_1) |> Map.get(:tiles_in_tray) |> Enum.sort()
      ["a", "a", "a", "x", "x", "x", "x"]

  """
  def fill_player_tiles(%GameInstance{} = game, player_key) do
    desired_tile_count = 7
    player = Map.get(game, player_key)
    tiles_in_tray = player.tiles_in_tray
    tiles_needed = desired_tile_count - Enum.count(tiles_in_tray)
    fill_player_tiles_take(game, player_key, tiles_needed)
  end
  defp fill_player_tiles_take(%GameInstance{} = game, _player_key, 0), do: game
  defp fill_player_tiles_take(%GameInstance{} = game, player_key, tiles_needed) do
    player = Map.get(game, player_key)
    tiles_in_tray = player.tiles_in_tray
    {tiles_in_hand, tiles_in_pile} = game.tiles_in_pile |> GameTiles.take_random(tiles_needed)
    tiles_replenished = tiles_in_tray ++ tiles_in_hand
    player = player |> Map.merge(%{tiles_in_tray: tiles_replenished})
    game
    |> Map.merge(%{tiles_in_pile: tiles_in_pile})
    |> Map.put(player_key, player)
  end

  @doc """
  Build a unique name for each game
  """
  def build_game_name(type) when is_atom(type) do
    [
      "game",
      Atom.to_string(type),
      DateTime.utc_now() |> DateTime.to_unix(),
      :rand.uniform(9999),
      :rand.uniform(9999),
    ] |> Enum.join("_")
  end
  def build_game_name(type) do
    [
      "game",
      "UNKNOWN_TYPE",
      DateTime.utc_now() |> DateTime.to_unix(),
      :rand.uniform(9999),
      :rand.uniform(9999),
    ] |> Enum.join("_")
  end

  @doc """
  Apply a GamePlay to the game (if it is valid)
  """
  def apply_play(%GameInstance{}, %GamePlay{valid: false}) do
    err = "Unable to apply a GamePlay to the Game, not valid"
    Logger.warn err
    {:error, err}
  end
  def apply_play(%GameInstance{}, %GamePlay{score: 0}) do
    err = "Unable to apply a GamePlay to the Game, no score (verified play?)"
    Logger.warn err
    {:error, err}
  end
  def apply_play(
    %GameInstance{
      plays: plays,
    } = game,
    %GamePlay{
      valid: true,
      player_key: player_key,
      score: score,
      board_next: board_next,
      tiles_in_tray: tiles_in_tray,
    } = play
  ) do
    player = game |> Map.get(player_key)
    player = player |> Map.merge(%{
               # put in the new tiles_in_tray (will re-fill up to 7 again)
               tiles_in_tray: tiles_in_tray,
               # add to the score
               score: player.score + score,
             })
    play = play |> Map.merge(%{
      timestamp: DateTime.utc_now() |> DateTime.to_unix(),
      # timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
    })
    game = game |> Map.merge(%{
      # new play on the board, ready to roll
      board: board_next,
      # this play added to the log of all plays on this game
      plays: [play | plays],
      # flip to next player's turn
      turn: next_turn(game),
    })
    # put in the updated player
    |> Map.put(player_key, player)
    # re-fill player tiles
    |> fill_player_tiles(player_key)
    {:ok, game}
  end

  @doc """
  The player may not be able to play, so we log a pass
  (warning, 2 passed in a row is auto-end-game)

  ## Examples

      iex> game = Wordza.GameInstance.create(:mock, :a, :b)
      iex> {:ok, game} = Wordza.GameInstance.apply_pass(game, :player_1)
      iex> game |> Map.get(:plays) |> List.first() |> Map.merge(%{timestamp: nil})
      %Wordza.GamePass{player_key: :player_1}
  """
  def apply_pass(%GameInstance{plays: plays} = game, player_key) do
    # if last turn was a pass, end this game
    case plays |> List.first() do
      %GamePass{} -> apply_end(game)
      _ ->
        player = game |> Map.get(player_key)
        pass = player_key
               |> Wordza.GamePass.create()
               |> Map.merge(%{
                 timestamp: DateTime.utc_now() |> DateTime.to_unix(),
                 # timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
               })
        plays |> List.first()
        game = game |> Map.merge(%{
          # this pass added to the log of all plays on this game
          plays: [pass | plays],
          # flip to next player's turn
          turn: next_turn(game),
        })
        {:ok, game}
    end
  end

  @doc """
  This will end a game (regardless of anything else)

  (Not related to player)

  ## Examples

      iex> game = Wordza.GameInstance.create(:mock, :a, :b)
      iex> {:ok, game} = Wordza.GameInstance.apply_end(game)
      iex> game |> Map.get(:turn)
      :game_over
  """
  def apply_end(%GameInstance{} = game) do
    game = game |> Map.merge(%{turn: :game_over})
    {:ok, game}
  end

  @doc """
  If it's currently player 1's turn, make it player 2's and vice versa

  ## Examples

      iex> game = Wordza.GameInstance.create(:mock, :a, :b)
      iex> Wordza.GameInstance.next_turn(game)
      2
  """
  def next_turn(%GameInstance{turn: 1}), do: 2
  def next_turn(%GameInstance{turn: 2}), do: 1
  def next_turn(%GameInstance{turn: x}), do: x


end
