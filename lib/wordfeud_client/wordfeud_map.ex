defmodule Wordza.WordfeudMap do
  @moduledoc """
  This is a module which will transform Wordfeud data into Wordza data
  and vice versa

  See: https://github.com/hillerstorm/wordfeud-api.js/blob/master/api.js
  """
  require Logger
  alias Wordza.GameInstance
  alias Wordza.GameTiles

  @doc """
  Convert a WordFeud Game (wf_game) into a Wordza.GameInstance

  Handles board, tiles_in_pile, players & tray/rack
  """
  def wf_game_into_game_instance(%{"id" => id, "players" => players} = wf_game) do
    name = "wf#{id}"
    p1 = players |> List.first()
    p1_id = p1 |> Map.get("id")
    p2 = players |> List.last()
    p2_id = p2 |> Map.get("id")
    game = GameInstance.create(:wordfeud, p1_id, p2_id, name)
           |> assign_board(wf_game)
           |> assign_player_rack(:player_1, p1)
           |> assign_player_rack(:player_2, p2)

    {:ok, game}
  end

  @doc """
  Assign the tiles on the board, to the game
  """
  def assign_board(
    %{tiles_in_pile: tiles_in_pile} = game,
    %{"tiles" => wf_tiles_on_board} = wf_game
  ) do
    # TODO determine tiles-on-board
    #   take those from the tiles_in_pile and put onto the board
    game
  end

  @doc """
  Assign the rack for a player, from the wf_game, into the Wordza.GameInstance
  """
  def assign_player_rack(
    %{tiles_in_pile: tiles_in_pile} = game,
    player_key,
    %{"rack" => rack} = wf_player
  ) do
    # "rack" => ["A", "E", "R", "I", "E", "N", "S"],
    letters_yx = rack |> Enum.map(fn(l) -> [l, 0, 0] end)
    {letters_taken, pile_left} = GameTiles.take_from_tray(tiles_in_pile, letters_yx)
    player = game
             |> Map.get(player_key)
             |> Map.put(:tiles_in_pile, letters_taken)

    game
    |> Map.put(player_key, player)
    |> Map.put(:tiles_in_pile, pile_left)
  end
  def assign_player_rack(game, _player_key, _player), do: game

end
