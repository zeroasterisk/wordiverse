defmodule Wordza.GameInstance do
  @moduledoc """
  This is actions taken on our Wordza Game
  """
  defstruct [
    type: nil,
    board: nil,
    tiles_in_pile: nil,
    player_1: nil,
    player_2: nil,
    turn: 1,
    score: 0,
    plays: [],
  ]

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
    %Wordza.GameInstance{
      type: type,
      board: Wordza.GameBoard.create(type),
      tiles_in_pile: Wordza.GameTiles.create(type),
      player_1: Wordza.GamePlayer.create(player_1_id),
      player_2: Wordza.GamePlayer.create(player_2_id),
      turn: Enum.random([0, 1]),
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

  """
  def fill_player_tiles(%Wordza.GameInstance{} = game, player_key) do
    player = Map.get(game, player_key)
    tiles_in_tray = player.tiles_in_tray
    tiles_needed = 7 - Enum.count(tiles_in_tray)
    {tiles_in_hand, tiles_in_pile} = Wordza.GameTiles.take_random(game.tiles_in_pile, tiles_needed)
    tiles_in_tray = tiles_in_tray ++ tiles_in_hand
    game
    |> Map.put(:tiles_in_pile, tiles_in_pile)
    |> Map.put(player_key, Map.put(player, :tiles_in_tray, tiles_in_tray))
  end

end
