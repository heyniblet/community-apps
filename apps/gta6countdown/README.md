# GTA 6 Countdown

Community app by nsluke. Counts down to Grand Theft Auto VI at local midnight on
19 November 2026, or to a target date you set.

## Niblet downstream changes (2026-10-05)

- The countdown animation is built with 20 one-second frames instead of 60.
  Niblet encodes at most 15 seconds of animation, so only the first 15 frames
  were ever shown. On hosts that play longer animations, the countdown now
  loops after 20 seconds instead of 60.

No settings keys or saved values changed.

## Validation

With Niblet CLI v0.55.1 and the 15 second limit Niblet Cloud uses, the original
and changed source produced byte-identical WebP output at 1x and 2x for the
default target, a custom target, the last hours, minutes, and seconds before
launch, and after launch. Starlark CPU time per render dropped by about a third.
Physical devices were not tested with this change.
