defmodule Wordiverse.GameActions do
  @moduledoc """
  This is actions taken on our Wordiverse Game
  """

  @doc """
  Setup a fully ready game... requires a type and 2 player ids

  ## Examples

      iex> player_1_id = 1234
      iex> player_2_id = 827
      iex> game = Wordiverse.GameActions.create(:wordfeud, player_1_id, player_2_id)
      iex> Map.get(game, :type)
      :wordfeud

  """
  def create(type, player_1_id, player_2_id) do
    %Wordiverse.Game{
      type: type,
      board: Wordiverse.GameBoard.create(type),
      tiles_in_pile: Wordiverse.GameTiles.create(type),
      player_1: Wordiverse.GamePlayer.create(player_1_id),
      player_2: Wordiverse.GamePlayer.create(player_2_id),
      turn: Enum.random([0, 1]),
      score: 0,
      plays: [],
    }
    |> fill_player_tiles(:player_1)
    |> fill_player_tiles(:player_2)
  end

  @doc """
  Fill a single player's tray until it's full (7 tiles)
  """
  def fill_player_tiles(%Wordiverse.Game{} = game, player_key) do
    player = Map.get(game, player_key)
    tiles_in_tray = player.tiles_in_tray
    tiles_needed = 7 - Enum.count(tiles_in_tray)
    {tiles_in_hand, tiles_in_pile} = Wordiverse.GameTiles.take_random(game.tiles_in_pile, tiles_needed)
    tiles_in_tray = tiles_in_tray ++ tiles_in_hand
    game
    |> Map.put(:tiles_in_pile, tiles_in_pile)
    |> Map.put(player_key, Map.put(player, :tiles_in_tray, tiles_in_tray))
  end

end
