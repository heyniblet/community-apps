# tetrisclock

## Timezone settings (September 2026)

Timezone is now a searchable IANA timezone setting. Leave it blank to follow the display timezone. Existing installations retain their previous effective timezone through the reviewed Cloud migration.

Downstream change, original authorship retained. Requires the Niblet runtime with timezone Text metadata. All changed schemas were evaluated with networking denied. Migration and rendering evidence is recorded in the timezone release audit; schema checks alone do not certify live provider behavior.

## Niblet downstream changes (2026-10-05)

- Piece shapes, paths, and rotations are now chosen by a small deterministic
  generator seeded from the displayed local time (hour and minute) and the
  24-hour, leading-zero, build-speed, and movement-rate settings, instead of the
  random module. Every render within the same minute is identical, so Niblet
  Cloud can reuse it; the animation still differs from minute to minute.
- Frames past the 15 second animation limit are no longer built (the runtime
  already dropped them, for example 60 of 210 frames at the default Medium
  speed).

No settings keys or saved values changed.

Validation (Niblet CLI v0.55.1): with the random module pinned (`--seed`), the
frame limit alone produced byte-identical output at 8, 10, 14, and 20 fps and
with the top bar. With the new generator, frame counts and durations match the
previous version at every tested speed, renders repeated within the same minute
are byte-identical, and render metadata reports `reads.random=false`. Physical
devices were not tested with this change.
