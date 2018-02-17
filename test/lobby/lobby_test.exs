defmodule LobbyTest do
  use ExUnit.Case
  doctest Wordza.Lobby

  test "init creates the lobby as a GenServer" do
    type = :wordfeud
    player_1_id = :bot_lookahead_1
    player_2_id = :bot_lookahead_2
    {:ok, lobby_pid} = Wordza.Lobby.start_link()
    assert is_pid(lobby_pid) == true
    # we don't need the pid though, because it's a named GenServer internally referenced
    # we should be able to create multiple Games
    {:ok, game_name1} = Wordza.Lobby.create_game(type, player_1_id, player_2_id)
    assert is_bitstring(game_name1)
    {:ok, game_name2} = Wordza.Lobby.create_game(type, player_1_id, player_2_id)
    assert is_bitstring(game_name2)
    assert game_name1 != game_name2
    {:ok, game_pid1} = Wordza.Lobby.get_game_pid(game_name1)
    assert is_pid(game_pid1)
    {:ok, game_pid2} = Wordza.Lobby.get_game_pid(game_name2)
    assert is_pid(game_pid2)
    assert game_pid1 != game_pid2
    # just to confirm we can get the running Game
    game_by_pid = Wordza.Game.get(game_pid1, :full)
    game_by_name = Wordza.Game.get(game_name1, :full)
    assert game_by_pid == game_by_name
    assert game_by_pid.name == game_name1
  end


end
