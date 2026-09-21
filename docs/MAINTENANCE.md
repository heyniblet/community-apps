> Niblet documentation changes maintained by [edwin-page](https://github.com/edwin-page). Original upstream authorship and applicable notices are preserved.

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

## Edwin attribution, local history migration

Edwin is the contributor's other GitHub account. On the local branch `local/edwin-community-maintenance`, 104 downstream commits were reconstructed with author `edwin-page <332077620+edwin-page@users.noreply.github.com>`. The same person's committer identity changed on 103 commits; another committer identity was retained. Original upstream commits and app author credits were preserved.

Every rewritten commit retains its original tree, message, timestamps, and parent ordering, with downstream parent hashes remapped. One signature header was removed because a signature cannot authenticate a rewritten commit. Rewritten commits are not represented as retaining that verification.

The original head is retained locally as `local/pre-edwin-attribution-20260921`; local `main` and the remote tracking branch were not rewritten. The rewritten history ended at `7ef6cf68fee1710694d9a45e1297b562ec15fb46` before the documentation changes. [edwin-history-map.csv](edwin-history-map.csv) maps the initial 104 commits and the two additional commits described below. New documentation commits follow the rewritten app history.

Nothing was pushed as part of this migration. Publishing rewritten history later requires a coordinated replacement and reconciliation of collaborators' branches, commit pins, and release references. Commit attribution does not transfer ownership of upstream code.

## Maintenance process

Keep original licenses and author notices, record substantive downstream changes in source and app READMEs, and distinguish upstream authors from downstream maintenance. The app notes added with this audit summarize changed file categories, not full functional verification.

Future upstream imports should preserve upstream-authored commits, identify downstream conflicts, verify rights and assets, and test configurations before a separate catalog rollout. An automated importer and full compatibility matrix remain future work. Current source changes do not automatically update production catalog pins. `CODEOWNERS` names Edwin as the downstream review contact, but GitHub review assignment requires repository write access, which the account did not have at this audit. The file does not grant that permission.

## Publication preparation

After the initial local migration, remote main advanced to `9570da452f26098351f18243b4b499991e91c69a`. Its two new commits, covering sports playback and the Niblet CLI v0.54.12 CI pin, were preserved and reattributed to Edwin with identical trees and messages. The documentation was reapplied on top. The mapping now records 106 rewritten downstream commits. The pre-publication remote head is backed up locally as `local/pre-publish-main-20260921`.

The user authorized publishing this history replacement to main. Publication uses an explicit lease against the inspected remote head so that a concurrent update cannot be overwritten. The earlier local-only statement above describes the initial migration stage. Existing commit pins and collaborators' branches still need to be reconciled with the published history when used.

Publication completed at `e6ec4571dda843a441cf1aebf0c3114fd4c42f9b`. The guarded replacement succeeded and the remote head was verified. GitHub CI subsequently failed on the existing AC:NH Villager render-time check; see the [follow-up review](UPSTREAM_REVIEW_2026-09-21.md).
