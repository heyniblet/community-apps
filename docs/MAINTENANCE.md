> Updated for this community fork. Original upstream authorship and applicable notices are preserved.

# Downstream history and maintenance

## What changed

The September 21, 2026 audit compared the original downstream head `ed9e2285e195299fcc1e82432296a38bc06fa613` with shared Tronbyt ancestor `83fb7d2bd25749fb25d9c8c872b247d6d7c3a06f`. It found 1,117 changed app files across 744 app directories: 705 modified and five added Starlark files, 232 YAML files, 143 WebP files, 29 Markdown files, two Python files, and one text file. These are historical snapshot counts, before this documentation update.

The changes include:

- Configuration simplification for Niblet Cloud, including generated options, typeahead, location selection, and OAuth flows replaced with static inputs or relays in some apps.
- API and provider repairs, credential handling changes, and alternative data sources.
- Rendering, animations, full animation playback, and 2x display improvements.
- Manifest health flags and recommended intervals, previews, and app documentation.
- New app sources and changes in catalog behavior or app identity.

Static analysis found schema differences in 286 apps, including removed fields in 113 and changed field types in 81. These categories overlap and include cosmetic changes. They are indicators for review, not counts of broken apps. Some materially different behavior is confirmed; see [COMPATIBILITY.md](COMPATIBILITY.md).

The earlier `niblet-apps` import began August 12, 2026 with parentless history, so its exact imported upstream commit is not established. The public `community-apps` fork was created September 4. Its initial Niblet port touched 247 files across 187 apps, followed by further downstream work. This fork retains upstream ancestry.

## Maintenance process

Keep original licenses and author notices, record substantive downstream changes in source and app READMEs, and distinguish upstream authors from downstream maintenance. The app notes added with this audit summarize changed file categories, not full functional verification.

Future upstream imports should preserve upstream-authored commits, identify downstream conflicts, verify rights and assets, and test configurations before a separate catalog rollout. An automated importer and full compatibility matrix remain future work. Current source changes do not automatically update production catalog pins.
