# Wordza

This is an experiment to play with Elixir, OTP, and _(eventually)_ neural networks implemented in Elixir.

### Roadmap

- [x] Build out a WordFued/Scabble like game in Elixir, via OTP
- [x] Build a dictionary and rule set to secure the game
- [x] Build a basic "look ahead" player bot _(see [BotAlec](./lib/bot_alec/))_
- [ ] Build a system to generate a ton of games and moves
- [ ] Build a neural network player bot and train
- [ ] Build a basic lobby (game management) interface
- [ ] Build a basic API client to connect to WordFued

### Usage

Run a set of 1000 games, BotAlec vs BotAlec

```
$ uh... not built yet :(
```

Fire it up in iex to play with it by hand:

```
$ iex -S mix
```

```ex
iex> Wordza.Dictionary.start_link(:wordfeud)
iex> {:ok, pid} = Wordza.Game.start_link(:wordfeud, :bot_alec_a, :bot_alec_b)
iex> Wordza.Game.get(pid)
iex> Wordza.Game.board(pid)
iex> Wordza.Game.player_1(pid)
iex> Wordza.Game.player_2(pid)
iex> Wordza.Game.tiles(pid)
```

And of course, a reasonable test suite:

```
$ mix test
```

### Resources

#### Basics of OTP
- https://www.dailydrip.com/topics/elixir/drips/genserver-and-supervisor
- https://github.com/cse5345-fall-2016/assignment4-otp-hangman
- https://github.com/benjamintanweihao/the-little-elixir-otp-guidebook-code/
- http://codeloveandboards.com/blog/2016/04/29/building-phoenix-battleship-pt-1/

#### Neural Networks in Elixir
- http://www.automatingthefuture.com/blog/2016/9/7/artificial-neural-networks-elixir-and-you
- https://github.com/TheQuengineer/deepnet
- https://www.dailydrip.com/topics/elixir/drips/implementing-a-simple-neural-network-in-elixir
