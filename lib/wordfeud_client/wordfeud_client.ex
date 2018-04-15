defmodule Wordza.WordfeudClient do
  @moduledoc """
  This is an API client to Wordfeud

  See: https://github.com/hillerstorm/wordfeud-api.js/blob/master/api.js
  """
  use HTTPoison.Base
  require Logger

  # @expected_fields ~w(
  #   status content type
  # )

  @rule_sets %{
    american: 0,
    norwegian: 1,
    dutch: 2,
    danish: 3,
    swedish: 4,
    english: 5,
    spanish: 6,
    french: 7,
  }
  @board_types %{
    normal: "normal",
    random: "random",
  }

  # @type response :: {:ok, :jsx.json_term, HTTPoison.Response.t } | {integer, any, HTTPoison.Response.t}
  #
  # @spec process_response_body(binary) :: term
  # def process_response_body(""), do: nil
  # def process_response_body(body), do: JSX.decode!(body)
  #
  # @spec process_response(HTTPoison.Response.t) :: response
  # def process_response(%HTTPoison.Response{status_code: status_code, body: body} = resp), do: { status_code, body,resp}


  def getHashedPassword(password) when is_bitstring(password) do
    :crypto.hash(:sha, password <> "JarJarBinks9") |> Base.encode16 |> String.downcase
  end

  def process_request_headers(headers) do
    [
      # "Authorization": "Bearer #{token}",
      "Accept": "application/json",
      "User-Agent": "WebFeudClient/2.0.3 (Linux; Android 8.0.0; Pixel 2 XL Build/OPD1.170816.004)",
      "Content-Type": "application/json",
      # "Content-Length": contentLength.toString()
    ] ++ headers
# options.headers.Cookie = "sessionid=" + sessionid;
# hackney: [cookie: ["session=a933ec1dd923b874e691; logged_in=true"]]
  end

  def process_request_body(%{} = body) do
    body |> Poison.encode!
  end
  def process_request_body(body) when is_bitstring(body), do: body

  def process_url(url) do
    "https://game02.wordfeud.com/wf" <> url
  end

  def process_response_body("{" <> body) do
    body = "{" <> body
    body |> Poison.decode!
    # |> Map.take(@expected_fields)
  end
  def process_response_body(body) do
    IO.inspect body
    %{"status" => "error", "content" => body}
  end

  def extract_session_id(headers) do
    cookies = headers |> Enum.filter(fn
      {"Set-Cookie", _} -> true
      _ -> false
    end) |> Enum.map(fn({_, str}) -> str |> extract_session_val() end)
    |> List.first()
  end
  # sadly we can not do this :(
  # https://thepugautomatic.com/2016/01/pattern-matching-complex-strings/
  # def extract_session_val("sessionid=" <> str <> ";" <> _), do: str
  def extract_session_val(str) do
    str
    |> String.split(";")
    |> List.first()
    |> String.split("=")
    |> List.last()
  end

  @doc """
  Post a login request to Wordfeud API

  Returns {:ok, session_id, data}
  """
  def login(%{email: email, password: password}) do
    url = "/user/login/email/"
    body = %{
      password: getHashedPassword(password),
      email: email,
    }
    case url |> post(body) do
      {:ok, %HTTPoison.Response{body: %{"status" => "success", "content" => out}, headers: headers}} ->
        session_id = headers |> extract_session_id()
        {:ok, session_id, out}
      {:ok, %HTTPoison.Response{body: %{"status" => "error", "content" => %{"type" => "wrong_email"}}}} -> {:error, "unknown_email"}
      {:ok, %HTTPoison.Response{body: %{"status" => "error", "content" => %{"type" => "wrong_password"}}}} -> {:error, "invalid_pass"}
      {:ok, %HTTPoison.Response{body: %{"status" => "error", "content" => out}}} -> {:error, out}
      {:ok, %HTTPoison.Response{body: out}} -> {:error, out}
      {:error, %{error: out}} -> {:error, out}
      {:error, %{reason: out}} -> {:error, out}
    end
  end

  @doc """
  List all current games

  returns {:ok, [game, game, ...]}
  """
  def list_games(session_id) do
    url = "/user/games/"
    case url |> get([], hackney: [cookie: ["sessionid=#{session_id}; logged_in=true"]]) do
      {:ok, %HTTPoison.Response{body: %{"status" => "success", "content" => %{"games" => games}}}} ->
        {:ok, games}
      _ = out ->
        Logger.error "Nope, unable to list_games #{inspect(out)}"
        {:error, "total fail"}
    end
  end

  @doc """
  Get details about a single game

  returns {:ok, game}
  """
  def get_game(session_id, wf_game_id) do
    url = "/game/#{wf_game_id}/"
    case url |> get([], hackney: [cookie: ["sessionid=#{session_id}; logged_in=true"]]) do
      {:ok, %HTTPoison.Response{body: %{"status" => "success", "content" => %{"game" => game}}}} ->
        {:ok, game}
      _ = out ->
        Logger.error "Nope, unable to get_game #{inspect(out)}"
        {:error, "total fail"}
    end
  end


  @doc """
  Send a random invite

  returns {:ok, %{status: "request_scheduled", id: id, created: created, board_type_int: board_type_int, ruleset: ruleset_int}}
  """
  def inviteRandom(session_id, ruleset_id \\ :american, board_type \\ :normal) do
    url = "/random_request/create/"
    body = %{
      "ruleset": @rule_sets |> Map.get(ruleset_id),
      "board_type": @board_types |> Map.get(board_type),
    }
    case url |> post(body, [], hackney: [cookie: ["sessionid=#{session_id}; logged_in=true"]]) do
      {:ok, %HTTPoison.Response{body: %{"status" => "success", "content" => %{
        "request_status" => "request_scheduled",
        "request" => %{
          "id" => id,
          "created" => created,
          "board_type" => board_type_int,
          "ruleset" => ruleset_int,
        },
      }}}} ->
        Logger.info "Invited Random! WFRequest##{id}"
        {:ok, %{status: "request_scheduled", id: id, created: created, board_type_int: board_type_int, ruleset: ruleset_int}}
      {:ok, %HTTPoison.Response{body: %{"status" => "error", "content" => %{"type" => type, "message" => msg}}}} ->
        Logger.error "Unable to inviteRandom: #{type <> msg}"
        {:error, type <> msg}
      _ = out ->
        Logger.error "Nope, unable to inviteRandom #{inspect(out)}"
        {:error, "nope"}
    end
  end
end
