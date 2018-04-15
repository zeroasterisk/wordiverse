defmodule WordfeudMapTest do
  use ExUnit.Case
  doctest Wordza.WordfeudMap
  alias Wordza.WordfeudMap
  alias Wordza.GameInstance


  test "convert wf_game details into GameInstance (new game)" do
    wf_game = %{
      "bag_count" => 90,
      "board" => 0,
      "chat_count" => 0,
      "created" => 1521774562,
      "current_player" => 0,
      "end_game" => 0,
      "id" => 2226982257,
      "is_running" => true,
      "last_move" => %{},
      "move_count" => 0,
      "pass_count" => 0,
      "players" => [
        %{
          "id" => 29591280,
          "is_local" => true,
          "position" => 0,
          "rack" => ["A", "E", "R", "I", "E", "N", "S"],
          "score" => 0,
          "username" => "botlife1",
        },
        %{
          "avatar_updated" => 1493736704,
          "fb_first_name" => "Laura",
          "fb_last_name" => "Felix",
          "fb_middle_name" => "",
          "fb_user_id" => 10156082637656978,
          "id" => 28445748,
          "is_local" => false,
          "position" => 1,
          "score" => 0,
          "username" => "_fb_10156082637656978",
        },
      ],
      "read_chat_count" => 0, "ruleset" => 5, "seen_finished" => false,
      "tiles" => [],
      "updated" => 1521776416
    }
    {:ok, game} = WordfeudMap.wf_game_into_game_instance(wf_game)


    p1 = game |> Map.get(:player_1)
    p2 = game |> Map.get(:player_2)
    assert p1.id == 29591280
    assert p2.id == 28445748

    game = game |> Map.merge(%{
      player_1: nil,
      player_2: nil,
    })
    # TODO fix this map, to continue work on the API client
    # assert game == %GameInstance{
    #   name: "wf2226982257",
    #   type: :wordfeud,
    #   board: %{
    #   },
    #   # tiles_in_pile: tiles_in_pile,
    #   # player_1: player_1,
    #   # player_2: player_2,
    #   score: 0,
    #   plays: [
    #   ],
    #   turn: 1,
    # }
  end
end
