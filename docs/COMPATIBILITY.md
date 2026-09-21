> Niblet documentation changes maintained by [edwin-page](https://github.com/edwin-page). Original upstream authorship and applicable notices are preserved.

# Compatibility and known differences

The aim is portable Pixlet app source with platform-specific deployment policy kept separately. The current fork has known behavior and configuration differences. Do not replace an installed upstream app assuming its saved configuration will work unchanged.

## Observed differences at the September 21, 2026 audit

| App | Downstream change | Consequence |
| --- | --- | --- |
| Roomba | `serverIP` and `serverPort` replaced by HTTPS `serverURL` | Old settings can render demo data instead of robot state. |
| Fitbit | Direct credential configuration replaced by `endpoint_url` and `relay_token` | Old settings can produce no output. |
| Office Status | Account/calendar integration changed to manual status | The same app no longer provides the previous automatic behavior. |
| Outlook Calendar | OAuth configuration replaced by a calendar URL | Users need an ICS configuration; a default public calendar does not represent their previous account. |
| Time and Weather | Schema fixes the provider to Open-Meteo | Older provider settings are no longer exposed, although some legacy code remains. |
| New Apps | Catalog endpoint changed to Niblet Cloud | The same app ID now shows a different catalog. |
| Dolar Blue | Manifest ID changed to `dolar-blue` | Existing installations may need an identity mapping. |

These are examples, not a complete list. Anime Next Episode retains an adapter for an older JSON selection value; preserve adapters like this when simplifying configuration. See each app's README and history.

## Requirements for future changes

Preserve stable IDs and settings meanings. Accept legacy values where practical, and explicitly migrate incompatible settings. Separate platform-specific OAuth, relays, and catalog policy from portable rendering where feasible. Do not weaken hosted execution isolation or restore unsafe credentials to imitate upstream behavior.

Test old saved settings, new settings, missing credentials, provider failures, and advertised display sizes. Distinguish live behavior from synthetic fixtures and preview images. A successful schema load does not prove working authentication or rendering.

## What is verified

The original audit snapshot pinned upstream Pixlet v0.53.1. Two newer commits preserved during publication preparation pin Niblet CLI v0.54.12 for sports apps using `frame_keys`, which upstream Pixlet cannot evaluate. Those apps therefore have an additional runtime compatibility limitation. CI does not run a complete Niblet/Tronbyt matrix. Focused audit probes loaded seven selected apps' schemas from both snapshots on upstream Pixlet v0.53.1 and v0.54.0. Network-denied probes reproduced the Roomba and Fitbit issues above. These checks do not certify the whole collection.

A broader compatibility suite and automated upstream import pipeline are planned, not implemented by this documentation update. Before importing new Tronbyt commits, compare IDs, schemas, saved settings, behavior, licenses, and notices, then review conflicts and test affected apps. Keep upstream commits and downstream patches distinguishable.

Tronbyt distribution should be tested in a separate installation using its supported repository mechanism. Check app discovery, manifest interpretation, entry files, assets, and saved configuration there; a repository URL alone is not evidence of compatibility. Back up existing settings before switching app sources.
