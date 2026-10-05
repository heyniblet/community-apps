# NFL Play By Play

Community app by nsluke. Shows live game state for the selected NFL team from
ESPN's public scoreboard and standings JSON (no key).

## Niblet downstream changes (2026-10-05)

- The app reads the current time only when it has to decide whether to show a
  final score (within 24 hours of kickoff) or the pregame screen (game day).
  Live-game and no-game (bye week) renders no longer read the clock, so Niblet
  Cloud can skip re-rendering them while ESPN's data is unchanged.

Output is unchanged. No settings keys or saved values changed.

## Validation

With Niblet CLI v0.55.1 and recorded ESPN responses, the original and changed
source produced byte-identical WebP output for idle (final more than 24 hours
old), bye week, pregame, final, live (edited scoreboard), and game-day-only
renders, across several `--now` instants and timezones. Render metadata shows
`reads.time=false` for live and bye-week renders. Physical devices were not
tested with this change.
