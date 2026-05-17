# Patch 076B — Scene-authored Map Device art integration

This replaces the temporary runtime skin direction with a scene-authored Map Device panel.

## What changed

- `MapDevicePanel.tscn` now owns the major art nodes:
  - `MainFrameArt`
  - `HeaderPlateArt`
  - `MapCardFrameArt`
  - `MapSlotEmptyArt`
  - `MapCardPlaceholderArt`
  - `MapIconArt`
  - `TierBadgeArt`
  - `CompletedBadgeArt`
  - subpanel art TextureRects
  - reward icon TextureRects
  - button state StyleBoxTexture resources

- `MapDevicePanel.gd` only performs state binding:
  - swaps map icon by map id / area name
  - swaps card frame by rarity
  - shows/hides completed badge
  - fills labels
  - enables/disables buttons
  - fills modifier rows

## Production rule

Layouts, margins, frame placement, and button art states live in `.tscn`.
Script does not create decorative layout nodes.

## Install

```bash
cd /home/kaey/Desktop/Game
bash /home/kaey/Downloads/patch_076b_scene_authored_map_art/install_patch_076b.sh
tools/patch_validators/validate_patch_076b.sh
tools/validate_all.sh
git status
```
