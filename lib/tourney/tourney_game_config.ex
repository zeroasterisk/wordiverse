defmodule Wordza.TourneyGameConfig do
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
    tourney_worker_pid: nil,
    tourney_scheduler_pid: nil,
    enable_loop: true,
  ]
  def create(type) do
    %Wordza.TourneyGameConfig{
      type: type,
    }
  end
end
