# Day Night Map

This community-maintained version includes downstream changes to the Starlark source. Original author and license notices remain in the source and manifest. Maintenance credit does not replace original authorship. See [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Niblet efficiency changes (October 2026)

- The 366-entry solar declination table is a constant with the exact same float values instead of being recomputed with trigonometry when the app loads (about 24 ms less per render locally).
- Validated by rendering the previous and new source against the same recorded HTTP responses and pinned times with the Niblet runtime: byte-identical output for 15 combinations (default, centered 12-hour with date, centered 24-hour in Sydney; 5 dates including a leap-year 31 December).
