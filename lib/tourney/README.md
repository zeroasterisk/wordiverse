# Wordza > Tourney

Organize and manage a lot of games (between bots, maybe eventually humans?)

Tourney in it's current implementation is focused on "autoplay-between-bots"

## Overview

* Application
 * TourneySchedulerSupervisor
  * TourneySchedulerWorker
   * (listens for triggers, configures needed tourney)
   * For each needed game: (Swarm.register to distribute)
    * TourneySupervisor
      * TourneyWorker
       * TourneyAutoplayer
        * Game

## What the what?

That looks way overly complex... especially if you're coming from a different language.

In many other scripting languages it might look like this:

* Application
 * TourneyScheduler
   * (listens for triggers, configures needed tourney)
   * For each needed game:
    * TourneyAutoplayer
     * Game

Why all the extra cruft?

Well - we are using Elixir, not just because it's fun to write,
but also because of all the extra functionality we get for free.

That extra functionality is often organized into
[Supervisor](https://hexdocs.pm/elixir/Supervisor.html#content) and
[Workers as GenServer](https://hexdocs.pm/elixir/Supervisor.html#content).

This is a core concept of OTP and part of what we are excite about.

The extra layers of Supervisors and Workers ensure that processes either do not fail,
or are restarted when they fail un-expectedly.

