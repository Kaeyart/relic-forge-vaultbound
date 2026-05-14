# Patch 012A — Asset Foundation

This patch creates a first static asset pack for:

- UI
- HUD
- iconography
- static VFX

## Why

Trying to brute-force feel entirely through code is slowing development down.

The better path is:

1. lock visual language
2. generate static assets
3. integrate those assets into HUD / menus / hub props
4. later do rooms / tiles / enemy art / animation

## Formats

This patch uses SVG for clean scaling and easy iteration.

## Main directories

- `assets/ui/`
- `assets/icons/`
- `assets/vfx/`
- `assets/hub/`
- `docs/`

## Next patch

Patch 012B should integrate these assets into:
- current HUD
- prompt chips
- hub interaction markers
- inventory / stash / crafting
- skill loadout / skill display
