# Patch 024A — Combat Room Vertical Slice Fix

## Why this exists

Patch 024 assumed the pre-clean-reinstall path `scripts/Main.gd`. The clean reinstall moved the coordinator to:

`res://scripts/core/GameRoot.gd`

This patch fixes the combat room vertical slice for the current architecture.

## What it adds

- Scene-authored combat room markers
- Player spawn marker
- Enemy spawn markers
- Obstacle markers
- Reward chest marker
- Exit portal marker
- Combat flow: clear enemies → open reward chest → exit/next room
- Combat objective text in the HUD
- `E` interaction in combat for reward/portal

## Edited files

- `scripts/core/GameRoot.gd`
- `scripts/core/GameState.gd`
- `scripts/combat/CombatArena.gd`
- `scripts/combat/CombatObstacle.gd`
- `scenes/combat/CombatArena.tscn`
- `scripts/ui/GameHUD.gd`
- `scenes/ui/GameHUD.tscn`

## Test flow

1. Start from hub.
2. Walk to an activity gate and press `E`.
3. Kill all enemies.
4. Reward chest appears.
5. Walk to reward chest and press `E`.
6. Exit portal appears.
7. Walk to portal and press `E`.
8. Either next room starts or the activity completes and returns to hub.
