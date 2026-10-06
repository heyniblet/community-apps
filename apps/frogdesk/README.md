<!-- community-maintenance:start -->
## Community maintenance

Imported from [Tronbyt apps](https://github.com/tronbyt/apps/tree/32af8b9a/apps/frogdesk) on October 6, 2026. Original author and license notices remain in the source, manifest, and any original documentation below. Maintenance credit does not replace original authorship.

See [known compatibility differences](../../docs/COMPATIBILITY.md) and [maintenance history](../../docs/MAINTENANCE.md). These notes do not certify live integration or compatibility with every runtime.
<!-- community-maintenance:end -->

# Frog Desk

Frog Desk is a hand-drawn 64×32 pixel-art desk scene. Every frame is preserved from the original artwork.

## App settings

- **Artwork display** — choose the original all-scene rotation, a themed set, or one exact scene.
- **Finish each animation** — keep the selected scene playing through its original animation.

## How often it updates

Frog Desk uses Tronbyt’s built-in **Render interval** setting. The catalog recommends **5 minutes**; set any interval you prefer in the Tronbyt Manager when adding or editing the app. Each refresh makes a new randomized selection when an artwork group is selected.

## Original rotation

With **All scenes** selected, the original distribution is preserved: Vacant office is 33%; Default, Side-eye, Fly, Glitch, and Sleep are each 13.4%. The random choice is reseeded at every render.

## Local validation

```sh
pixlet check frog_desk.star
pixlet render -z 9 frog_desk.star
```
