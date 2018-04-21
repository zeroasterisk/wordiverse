defmodule Wordza.TourneyConfig do
  @moduledoc """
  This is the config for a single Tourney Game
  """
  defstruct [
    type: nil,
    player_1_module: Wordza.BotAlec,
    player_2_module: Wordza.BotAlec,
    player_1_id: :p1,
    player_2_id: :p2,
    game_pid: nil,
    done: false,
  ]
  def create(type) do
    %Wordza.TourneyConfig{
      type: type,
    }
  end
end
