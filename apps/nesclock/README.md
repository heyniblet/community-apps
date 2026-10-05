<!-- community-maintenance:start -->
## Community maintenance

This community-maintained version includes updates to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- community-maintenance:end -->

## Timezone settings (September 2026)

Timezone is now a searchable IANA timezone setting. Leave it blank to follow the display timezone. Existing installations retain their previous effective timezone through the reviewed Cloud migration.

Downstream change, original authorship retained. Requires the Niblet runtime with timezone Text metadata. All changed schemas were evaluated with networking denied. Migration and rendering evidence is recorded in the timezone release audit; schema checks alone do not certify live provider behavior.

## Niblet downstream changes (2026-10-05)

- The game (when **Game** is Random), level, sprite set, and speed (when
  **Speed** is Random) are now picked by a small deterministic generator seeded
  from the displayed local time (hour and minute) and the settings, instead of
  the random module. Every render within the same minute is identical, so Niblet
  Cloud can reuse it; the choice still changes from minute to minute (all 16
  games appear about equally often across a day).
- Frames past the 15 second animation limit are no longer built (the runtime
  already dropped them).

No settings keys or saved values changed.

Validation (Niblet CLI v0.55.1): fixed game and speed settings (for example
Super Mario Bros. 3 at Medium, Zelda at Snail in 24 hour format) produce the same
frame count and duration as before; renders repeated within the same minute are
byte-identical and render metadata reports `reads.random=false`. Physical
devices were not tested with this change.
