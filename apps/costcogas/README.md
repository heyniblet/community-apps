<!-- niblet-maintenance:start -->
## Niblet downstream maintenance

This directory contains Niblet changes to Starlark source, manifest, documentation, compared with the shared Tronbyt ancestor in the September 21, 2026 audit. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

The configuration schema differs from the audited upstream baseline. Check the current schema and test existing saved settings before switching versions; differences may include labels as well as behavior.

Original authors and other contributors can follow [Updating your app](../../docs/UPDATING_YOUR_APP.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md). Preserve app IDs, settings compatibility, original credits, and applicable licenses. Describe changes and actual test results in your pull request.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime. Earlier setup instructions below may describe the upstream version.
<!-- niblet-maintenance:end -->

# Costco Gas Applet for Tidbyt

Displays current gas prices for a selected [Costco](https://www.costco.com) warehouse in the US.

## Features

* Enter the number from Costco's warehouse locator for the gas station to display
* The applet will display the price for Regular (R), Premium (P), and if available, Diesel (D)
* Choose the colour scheme for gas prices: all white, red for gas/petrol and green for diesel, or green for gas/petrol and red for diesel
* Choose to display an icon (Costco logo or Gas Pump logo)

**Default display:**

![Default display](default.gif)

**Display with price colour and opening hours:**

![Hours display](hours.gif)

## Data Source

Data is sourced from the gas-price service used by Costco's warehouse pages and is provided AS-IS only. Website updates made by Costco may cause this app to fail and may require updates.

Even though gas (petrol) stations are available in other countries like Canada and the UK, only US warehouses reliably return prices at the present time.
