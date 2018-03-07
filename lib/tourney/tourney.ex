defmodule Wordza.Tourney do
  @moduledoc """
  Setup a Tournement for several games

  * create a number of games in the lobby
  * create an Autoplayer for each game, which will run until complete
  * collect the results of each game, and centralize those results
  * report on the results
  """
  require Logger
  use GenServer

  ### Client API

  @doc """
  Easy access to start up the server

  On new:
    returns {:ok, pid}
  On repeat:
    returns {:error, {:already_started, #PID<0.248.0>}}
  """
  def start_link(type, player_1_id, player_2_id, number_of_games) do
    out = GenServer.start_link(__MODULE__, %{
      type: type,
      player_1_id: player_1_id,
      player_2_id: player_2_id,
      number_of_games: number_of_games
    }, [])
    out |> start_link_nice()
  end
  def start_link_nice({:ok, pid}), do: {:ok, pid}
  def start_link_nice({:error, {:already_started, pid}}), do: {:ok, pid}
  def start_link_nice({:error, err}), do: {:error, err}

  ### Server API
  def init(%{
      type: type,
      player_1_id: player_1_id,
      player_2_id: player_2_id,
      number_of_games: number_of_games
  }) do
    {:ok, %{
      type: type,
      player_1_id: player_1_id,
      player_2_id: player_2_id,
      number_of_games: number_of_games,
      running_game_ids: [],
      completed_game_ids: [],
    }}
  end

end
