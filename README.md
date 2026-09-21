> Updated for this community fork. Original upstream authorship and applicable notices are preserved.

# Niblet Community Apps

A downstream collection of Pixlet apps from [Tronbyt Apps](https://github.com/tronbyt/apps), which originated in Tidbyt's community repository. Original developers retain their authorship and applicable rights.

## Update or contribute an app

Original app authors are welcome to update their apps here. Find your directory in `apps/`, read its README and current source, and submit a focused pull request against `main`. Link your original contribution if your account has changed. See [CONTRIBUTING.md](CONTRIBUTING.md) and [Updating your app](docs/UPDATING_YOUR_APP.md).

For new apps, use `pixlet create apps/<appname>`. Develop with `pixlet serve apps/<appname>/<appname>.star`, using the generated filename. Preserve app IDs, configuration meanings, original credits, and license notices when updating existing apps.

## Maintenance and compatibility

Our downstream changes include API repairs, rendering and animation improvements, preview and manifest updates, and configuration changes for Niblet Cloud. Some configuration changes require migration or restoration of compatibility. This fork is not yet verified as interchangeable with upstream for every app.

Read the [change summary](docs/MAINTENANCE.md), [known compatibility differences](docs/COMPATIBILITY.md), and the maintenance section in each changed app's README before replacing an installed version. A sample image or successful schema check does not establish working live integration.

This repository contains app source. Niblet catalog policy, source pins, credentials review, and rollout belong to the separate `catalog-apps` repository. CI checks changed apps on pull requests and main using the pinned Niblet CLI runtime. Main publishes a checksummed `source-<commit>` snapshot after validation; the catalog must explicitly pin and review it before activation. Merging source here does not automatically deploy it. Portable improvements can also be submitted to Tronbyt through its own contribution process.

## Credits, licenses, and help

The root [Apache License 2.0](LICENSE) applies subject to app-specific licenses and notices. Check individual app directories and asset provenance before reuse. Retain original copyright, license, and attribution notices; mark modified files. Inactivity does not transfer an author's rights or grant control of their repository.

See [support](docs/SUPPORT.md), [private security reporting](docs/SECURITY.md), and the [code of conduct](docs/CODE_OF_CONDUCT.md). The historical Tidbyt CLA is retained for context, not presented as the agreement for new submissions to this fork.

The retained `docs/assets/banner.jpg` depicts Fuzzy Clock by [Max Timkovich](https://github.com/mtimkovich), photographed by [Tidbyt](https://tidbyt.com).
