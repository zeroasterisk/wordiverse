defmodule WordfeudClientTest do
  use ExUnit.Case
  doctest Wordza.WordfeudClient
  alias Wordza.WordfeudClient
  alias Wordza.GameInstance

  test "encode a password" do
  end
  test "hash a password" do
    assert WordfeudClient.getHashedPassword("xxxxxx") == "a20678fa097887db966a0220601edf7550028daa"
  end
  test "process_url prefixes with api domain" do
    assert WordfeudClient.process_url("/xxxxxx") == "https://game02.wordfeud.com/wf/xxxxxx"
  end
  test "extract_session_id from headers response from login" do
    headers = [
      {"Cache-Control", "private,no-cache,no-store,no-transform"},
      {"Content-Language", "en"}, {"Content-Type", "text/plain"},
      {"Date", "Fri, 23 Mar 2018 02:16:04 GMT"},
      {"Server", "nginx/1.4.6 (Ubuntu)"},
      {"Set-Cookie",
        "sessionid=f3s4j0oyqa4b501mzh8sm3vhlr5fp1qw; Domain=.wordfeud.com; expires=Fri, 06-Apr-2018 02:16:04 GMT; httponly; Max-Age=1209600; Path=/"},
      {"Vary", "Accept-Language, Cookie"}, {"Content-Length", "1020"},
      {"Connection", "keep-alive"},
    ]
    assert WordfeudClient.extract_session_id(headers) == "f3s4j0oyqa4b501mzh8sm3vhlr5fp1qw"
  end
  # test "convert wf_game details into GameInstance (game in progress)" do
  #   wf_game = %{
  #     "bag_count" => 71,
  #     "board" => 0,
  #     "chat_count" => 0,
  #     "created" => 1521774562,
  #     "current_player" => 0,
  #     "end_game" => 0,
  #     "id" => 2226982257,
  #     "is_running" => true,
  #     "last_move" => %{
  #       "main_word" => "BEY",
  #       "move" => [[8, 10, "B", false], [9, 10, "E", false]],
  #       "move_type" => "move",
  #       "points" => 27,
  #       "user_id" => 28445748,
  #     },
  #     "move_count" => 6,
  #     "pass_count" => 0,
  #     "players" => [
  #       %{"id" => 29591280, "is_local" => true, "position" => 0, "rack" => ["A", "E", "R", "I", "E", "N", "S"], "score" => 74, "username" => "botlife1"},
  #       %{"avatar_updated" => 1493736704, "fb_first_name" => "Laura", "fb_last_name" => "Felix", "fb_middle_name" => "", "fb_user_id" => 10156082637656978, "id" => 28445748, "is_local" => false, "position" => 1, "score" => 41, "username" => "_fb_10156082637656978"},
  #     ],
  #     "read_chat_count" => 0, "ruleset" => 5, "seen_finished" => false,
  #     "tiles" => [
  #       [10, 5, "M", false], [6, 6, "T", false], [7, 6, "E", false],
  #       [8, 6, "D", false], [10, 6, "I", false], [11, 6, "D", false],
  #       [7, 7, "L", false], [8, 7, "O", false], [9, 7, "G", false],
  #       [10, 7, "G", false], [11, 7, "E", true], [12, 7, "R", false],
  #       [10, 8, "H", false], [8, 9, "O", false], [9, 9, "F", false],
  #       [10, 9, "T", false], [8, 10, "B", false], [9, 10, "E", false],
  #       [10, 10, "Y", false],
  #     ],
  #     "updated" => 1521776416
  #   }
  #   {:ok, game} = WordfeudClient.wf_game_into_game_instance(wf_game)
  #   assert game == %GameInstance{
  #     name: "wf2226982257",
  #     type: :wordfeud,
  #     board: %{
  #     },
  #     tiles_in_pile: tiles_in_pile,
  #     player_1: player_1,
  #     player_2: player_2,
  #     score: 0,
  #     plays: [
  #     ],
  #     turn: 1,
  #   }
  # end

  # ======================================================== #
  describe "integration - real API requests" do
    # mock data, as if just logged in
    setup do
      session_id = "bvih3q3vuzjane0alcak162jdadm3zm9"
      details = %{
        "avatar_root" => "https://avatars-wordfeud-com.s3.amazonaws.com",
        "cookies" => false,
        "created" => 1521769982.0,
        "email" => "botalec_1@0-a.org",
        "id" => 29591280,
        "mopub_android_banner_id" => "dbb59436f53a48efaed8dbbb12d03781",
        "mopub_android_interstitial_id" => "3635a3cd638346aeaa0f801cf866f2b8",
        "mopub_android_leaderboard_id" => "17dfefd4afaa41b69556df6b4fd73cea",
        "mopub_android_tablet_landscape_interstitial_id" => "b0e759ea430340468a37b0293a0cb2da",
        "mopub_android_tablet_portrait_interstitial_id" => "4e41fcf545694a2f8bdb0a0692dddb00",
        "mopub_ipad_interstitial_landscape_id" => "11cdfea52dbd4a9b9d385f8dcc26c8fe",
        "mopub_ipad_interstitial_portrait_id" => "e512f2b5724f4a60b246ed549438c876",
        "mopub_ipad_leaderboard_id" => "fa402f7a89d140c98eb7ae2c9a5d042f",
        "mopub_ipad_rectangle_id" => "cde9e7f8729d4a03a44247b5c61c3592",
        "mopub_iphone_banner_id" => "99e994ba354a4bd7b76af4dec7d7e7af",
        "mopub_iphone_interstitial_id" => "f3e72b55aa9e498e980a689e0b801fb8",
        "tournaments_enabled" => true, "username" => "botlife1"
      }
      game = %{
        "board" => 0, "chat_count" => 0, "created" => 1521774562,
        "current_player" => 0, "end_game" => 0, "id" => 2226982257,
        "is_running" => true,
        "last_move" => %{
          "main_word" => "BEY",
          "move" => [[8, 10, "B", false], [9, 10, "E", false]],
          "move_type" => "move", "points" => 27, "user_id" => 28445748,
        },
        "move_count" => 6,
        "players" => [
          %{"id" => 29591280, "is_local" => true, "position" => 0,
            "rack" => ["A", "E", "R", "I", "E", "N", "S"], "score" => 74,
            "username" => "botlife1"},
          %{"avatar_updated" => 1493736704, "fb_first_name" => "Laura",
            "fb_last_name" => "Felix", "fb_middle_name" => "",
            "fb_user_id" => 10156082637656978, "id" => 28445748, "is_local" => false,
            "position" => 1, "score" => 41, "username" => "_fb_10156082637656978"}
        ],
        "read_chat_count" => 0, "ruleset" => 5, "seen_finished" => false,
        "updated" => 1521776416
      }
      games = [game]
      {:ok, session_id: session_id, details: details, game: game, games: games}
    end
    # test "login" do
    #   {status, session_id, details} = WordfeudClient.login(%{
    #     email: "botalec_1@0-a.org",
    #     password: "robo$ecure",
    #   })
    #   assert status == :ok
    #   IO.puts "logged in with session_id = #{session_id}"
    #   assert session_id |> is_bitstring() == true
    #   assert details |> Map.get("username") == "botlife1"
    # end
    # test "inviteRandom US Standard", state do
    #   {status, details} = WordfeudClient.inviteRandom(state[:session_id], :english, :normal)
    #   assert status == :ok
    #   assert details |> Map.get("status") == "request_scheduled"
    #   assert details |> Map.get("id") |> is_integer() == true
    # end
    # test "list games", state do
    #   {status, games} = WordfeudClient.list_games(state[:session_id])
    #   assert status == :ok
    #   # IO.inspect games
    #   game = games |> List.first()
    #   assert game |> Map.get("id") |> is_bitstring() == true
    # end
    # test "get game details", state do
    #   wf_game_id = state[:game] |> Map.get("id")
    #   {status, game} = WordfeudClient.get_game(state[:session_id], wf_game_id)
    #   assert status == :ok
    #   assert game |> Map.get("id") |> is_bitstring() == true
    #   assert game |> Map.get("bag_count") |> is_integer() == true
    #   assert game |> Map.get("players") |> is_list() == true
    #   assert game |> Map.get("tiles") |> is_list() == true
    # end
  end

end
