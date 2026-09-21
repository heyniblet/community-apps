<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Marex

Tidbyt/Pixlet applet that renders today's tide table for Brazilian beachs.

The first version defaults to the Cabedelo station (`pb01`) and calls:

```text
https://tabuamare.api.br/api/v2/tabua-mare/pb01/{month}/{day}
```

`{month}` is the current month in `MM` format and `{day}` is the current local day for the configured timezone.

## Development

Install Pixlet from the official repository:

```sh
brew install tidbyt/tidbyt/pixlet
```

Render the app locally:

```sh
pixlet render marex.star
```

Serve and auto-refresh while editing:

```sh
pixlet serve --watch marex.star
```

Run the community app checks before submitting:

```sh
pixlet check marex.star
```

## Configuration

The app exposes two optional configuration values:

- `harbor_id`: defaults to `pb01`.
- `timezone`: defaults to `America/Fortaleza`.

For local testing:

```sh
pixlet render marex.star harbor_id=pb01 timezone=America/Fortaleza
```
