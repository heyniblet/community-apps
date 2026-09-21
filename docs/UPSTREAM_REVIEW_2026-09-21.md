> Updated for this community fork. Original upstream authorship and applicable notices are preserved.

# Upstream and CI review, September 21, 2026

Reviewed against the community source and pinned CI runtime. A fresh fetch of Tronbyt main returned `523d8eacaef0744abb2823ea8171c369d416ec3b`, unchanged from the earlier audit. There are 151 upstream-only commits by ancestry. This is not a count of missing fixes: some have equivalent downstream implementations, and others are metadata updates.

This review changes documentation only. No upstream app or CI implementation has been imported or changed. Recommendations below are based on source inspection, not new end-to-end app validation.

## Suggested import order

| Priority | Upstream change | Assessment for this fork |
| --- | --- | --- |
| First | [EPL/MLS missing-data fixes, #686](https://github.com/tronbyt/apps/pull/686), `edf5e1f5` | Worth adapting now. EPL still indexes odds at element 1 and hard-indexes moneyLine; MLS uses element 0 but does not handle a null element or missing moneyLine. Both still hard-index series.summary. Preserve our playback changes and add fixtures for missing fields. |
| Review selectively | [ESPN dates, #714](https://github.com/tronbyt/apps/pull/714), `e444b21a` | Upstream uses individual date requests and filters after accumulating results. Our NCAAF implementation already uses daily requests, and our sports apps include complete playback and frame_keys work. Compare each affected app before porting missing behavior; do not replace the whole sports implementation. |
| New app candidate | [Uptime Kuma introduction, #696](https://github.com/tronbyt/apps/pull/696), `f58c940f`, plus [heartbeat fixes, #716](https://github.com/tronbyt/apps/pull/716), `3f6a88a4`, and [layout fixes, #717](https://github.com/tronbyt/apps/pull/717), `523d8eac` | The app is absent locally. Import the app with its subsequent fixes, including integer monitor IDs, null ping handling, and alert layout. Validate endpoint policy and 1x/2x rendering before catalog consideration. |
| New app candidate | [Frog Desk, #711](https://github.com/tronbyt/apps/pull/711), `670233d1` | No HTTP calls in the inspected source. A useful first visual app candidate, subject to artwork provenance and animation/runtime checks. |
| New app candidate | [Champs introduction, #691](https://github.com/tronbyt/apps/pull/691), `fc7d71d0`, plus [NHL/WNBA expansion, #706](https://github.com/tronbyt/apps/pull/706), `6c6c4861` | App is absent locally. Includes historical results and external logo/data requests. Review assets, source-data terms, and runtime behavior. |
| Demand-dependent | [Zabbix Problems, #713](https://github.com/tronbyt/apps/pull/713), `1f9cc546`; [ROVA, #709](https://github.com/tronbyt/apps/pull/709), `c9bfb2a5`; [PigBank, #715](https://github.com/tronbyt/apps/pull/715), `f7f4fbcc` | Respectively require a reachable monitoring endpoint and token, a supported address, or a PigBank service key. Keep configuration and service requirements intact; do not replace integrations with demo behavior to pass hosted checks. |
| Lower priority | [WPBL postseason update, #710](https://github.com/tronbyt/apps/pull/710), `0668e08e` | Depends on importing WPBL Standings itself. Evaluate as a complete app, not a standalone fix to an existing directory. |
| Already covered in principle | [Formula 1 missing track image, #699](https://github.com/tronbyt/apps/pull/699), `e988e220` | Local source already uses tracks.get(), guarded decoding, and an empty image area fallback. Upstream centers the text instead. No urgent correctness import identified. |
| Do not copy wholesale | [Skip broken apps in CI](https://github.com/tronbyt/apps/commit/940bf84bb7cdd54e258995e91ec1a36354f80a01), `940bf84b`, and upstream workflow/metadata automation | A broken flag should not exempt changed source from all checks. Separate static validation from live integration eligibility. Keep Niblet's pinned runtime and explicit catalog rollout process. |

When importing, retain upstream human authorship and source provenance. Credit each contributor for their own work. Preserve original notices, and identify any adapted patch and source commit in the contribution record. New commit messages follow repository rules on attribution trailers.

## CI failure evidence

[Build and Test run 35635219168](https://github.com/heyniblet/community-apps/actions/runs/35635219168) failed in `Check modified apps`:

- `apps/acnhvillager` took `1.513595741s` against the default `1s` render-time limit.
- Seven earlier app checks passed. The shell script exits at the first failing app, so the rest of the collection was not validated by that run.
- The `publish` job was skipped. The Git push succeeded, but this run did not publish a validated source snapshot.
- `acnhvillager` has no per-app runtime exception. Its source performs public HTTP requests for villager data and an icon. The log alone does not establish whether network latency, decoding, rendering, or another factor caused the elapsed time.
- Its executable source is unchanged by the documentation/attribution commit. The previous successful run checked a different change set; it is not evidence that this app passed on the same runner conditions.

The maintenance update added app README and source notices across 744 directories. Both the workflow comparison and a direct before/after tree comparison select those directories. Changing the comparison base alone would not resolve the render-time failure.

## Recommended CI follow-up

1. Reproduce and profile AC:NH Villager using pinned Niblet CLI v0.54.12, distinguishing cold-cache and warm-cache behavior. Optimize the measured bottleneck or add a narrowly justified runtime exception if it meets the intended platform budget. Do not raise every app's limit from one timing sample.
2. Make push comparisons use the before/after trees and keep merge-base comparison for pull requests. Cover divergent branch histories in the existing target-selection tests.
3. Exclude documentation-only changes from render target selection. Source comments still appear as source changes; do not introduce a regex-based Starlark change detector to bypass checks.
4. Keep static/source validation separate from live API timing checks. A fixture-based render suite would make behavior regression checks reproducible, while a separate integration pass can report external service failures.
5. Aggregate app failures so a broad pass reports all failures instead of stopping at the first, with an overall nonzero exit if any required check fails. Keep the validated-source publication gate intact.

These are proposed changes for discussion, not implemented repairs. A green documentation-only follow-up run would not prove that the original 744-app batch passes.
