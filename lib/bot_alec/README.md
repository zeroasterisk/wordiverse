# Wordza > BotAlec

Bot Alec _(sounds like smart alec)_ is a "basic" bot, but a formidable player.

It is written with the game code, so it has the ability to use the Dictionary server and evaluate plays, based on game code _(kinda cheating, but hey - why not?)_

Because it has the ability to evaluate possible moves, it's real job is to (quickly) evaluate a board and consider all possible plays it could make, based on the tiles in the bot's tray.

Once it has a list of all possible plays, it just picks the highest scoring play.

NOTE: this does not have any strategy, no memory, no soul.

## Usage / Example

```ex
iex> {:ok, pid} = Wordza.Game.start_link(:wordfeud, :bot_alec_a, :bot_alec_b)
iex> game_instance = Wordza.Game.get(pid, :full)
iex> play = BotAlec.play(:player_1, game_instance)
iex> IO.inspect play
```
