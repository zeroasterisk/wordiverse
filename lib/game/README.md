# Wordza > Game

The "Game" is actually several things.

A **GameInstance** is the current "state" of any "game"

It is composed from:

1. A **GameBoard** which is all of the squares you can play on (with bonuses)
2. Two **GamePlayer(s)** who are referred to by the term `player_key` as either `:player_1` or `:player_2`
3. A bunch of **GameTile(s)** which are found in `tiles_in_pile` or in the player's `tiles_in_tray`
4. A log of play history


