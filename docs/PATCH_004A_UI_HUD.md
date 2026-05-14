# Patch 004A — Low-Intrusion HUD

## Purpose

Patch 004A starts the UI cleanup without rewriting the game.

The goal is to replace the feeling of debug overlays with a restrained ARPG HUD:

- status bottom-left
- skill bar bottom-center
- room state top-center
- side drawer panels
- no permanent giant center overlay during combat

## Controls preserved

- `I` inventory
- `K` skill tree
- `P` build panel
- `M` dungeon panel
- `G` guide
- `O` respec
- `R` restart

## UI philosophy

The center of the screen belongs to combat.

The HUD should explain the build without covering the game.

## What changed

Added:

- `scripts/ui/LowIntrusionHUD.gd`
- Patch 004 HUD setup/update helpers inside `scripts/Main.gd`
- cleaner combat HUD
- compact side drawers
- low-intrusion room banner
- notice banner for important state changes

## What this patch does not do yet

This is not the final UI.

Patch 004B should replace the old text-heavy panels with proper inventory cards, route cards, reward cards, and a visual skill tree/passive tree.

## Test checklist

1. Launch Godot.
2. Press Play.
3. Confirm the new HUD appears.
4. Draft skills.
5. Cast skills.
6. Press `I`, `K`, `P`, `M`.
7. Confirm the center of the screen stays playable.
