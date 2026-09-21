<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Zen Quotes

A daily dose of wisdom from [ZenQuotes.io](https://zenquotes.io), featuring a customizable display and a built-in breath pacer to help you center yourself.

## Configuration

### Cache Duration (Important!)

Since the quote only updates once per day, please set the **Cache-Control** / **TTL** to **86400 seconds (24 hours)**.

- This prevents unnecessary API calls to ZenQuotes.io.
- It ensures you always see the Quote of the Day without hitting rate limits.

### App Rotation (Dwell Time)

If you use the **Zen Breath Pacer** feature, you need to ensure the app stays on screen long enough to complete a full breathing cycle.

The total cycle time is calculated as:
`Cycle Time = (3 * Breath Duration) + 2 seconds`

| Breath Duration  | Total Cycle Time | Recommended Dwell Time |
| :--------------- | :--------------- | :--------------------- |
| 2s               | 8 seconds        | **10 seconds**         |
| 3s               | 11 seconds       | **13 seconds**         |
| **4s (Default)** | 14 seconds       | **16 seconds**         |
| 5s               | 17 seconds       | **19 seconds**         |
| 6s               | 20 seconds       | **22 seconds**         |
| 7s               | 23 seconds       | **25 seconds**         |
| 8s               | 26 seconds       | **28 seconds**         |

**Note**: If your Tidbyt is set to rotate apps every 10 or 15 seconds, a longer breathing cycle (like 6s) will be cut off before it finishes. Please adjust your installation's rotation duration accordingly.
