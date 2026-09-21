<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Downstream maintenance contact: [edwin-page](https://github.com/edwin-page). Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Simple National Pokédex
Display a random Pokémon with its name and dex number from Generations I - VII (Kanto through Alola). 

<p align="center">
  <img src="natdex.gif" alt="animated" />
</p>

## Features
- Dropdown menu in app settings allows you to choose random Pokémon based on region (Kanto, Johto, etc.)
- Default set to National Dex (all Gen I - VIII, range from 1 to 809)

### Feature Ideas

- Add functionality for Gen VIII (Galar) 
  - Issue: sprites pulled from API are of a different size in Gen VIII

## Shout Outs
Thanks to Kay Savetz ([@savetz](https://github.com/savetz)) for the idea of pulling from [random.org](random.org) for random number generation in the absence of a `random()` function in Starlark.

Credit to Max Timkovich ([@mtimkovich](https://github.com/mtimkovich)) for originally developing the code to pull from the [Pokemon API](https://pokeapi.co/).




