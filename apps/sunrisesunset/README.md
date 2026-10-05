# Sunrise Sunset

This community-maintained version includes downstream changes to the Starlark source. Original author and license notices remain in the source and manifest. Maintenance credit does not replace original authorship. See [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Niblet efficiency changes (October 2026)

- The sunrise and sunset icons are read once at module load instead of on every use.
- Validated by rendering the previous and new source against the same recorded HTTP responses and pinned times with the Niblet runtime: byte-identical output for 16 combinations (default and New York, 12/24-hour, each display mode, 1x and 2x, 4 dates).
