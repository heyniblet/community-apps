<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# FFXIV Character

This app reads Final Fantasy XIV character data from the
[North American Lodestone](https://na.finalfantasyxiv.com/lodestone).

![render](./ffxiv_character.gif)

## Lodestone ID

You can find your Lodestone ID by [searching](https://na.finalfantasyxiv.com/lodestone/character/) for your
character and copying the ID number from the end of the page address.

```
https://na.finalfantasyxiv.com/lodestone/character/<LODESTONE ID>/
```
