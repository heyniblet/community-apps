<!-- community-maintenance:start -->
## Community maintenance

Imported from [Tronbyt apps](https://github.com/tronbyt/apps/tree/32af8b9a/apps/rainy) on October 6, 2026. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime.
<!-- community-maintenance:end -->

# Rainy?

Tronbyt Pixlet applet (64x32). Two 24-hour rain-intensity bars, today and tomorrow, midnight to midnight.

Work in `D:\MortonWebWorks\rainy` (own folder). AntiGravity is the IDE. Author: SamuLab. Tronbyt only.

- Open-Meteo hourly precipitation and precipitation probability
- Dry hours (< 0.05 mm) get a faint teal tint by chance of rain: 15-24%, 25-39%, 40-59%, 60%+ (blank below 15%). Real rainfall uses the brighter intensity colours.
- Default: Houston, TX
- Catalog slug: `rainy`
- Bars: 2px/hour, 48px, x=8–55. TODAY / TOM labels (tom-thumb). Now-tick on TODAY only.
- Colors: gray → cyan → blue → purple → red. No words inside the bar.

```bat
cd D:\MortonWebWorks\rainy
pixlet check rainy.star
pixlet render rainy.star
pixlet serve rainy.star
```
