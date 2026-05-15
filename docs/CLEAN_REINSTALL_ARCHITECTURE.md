# Clean Reinstall Architecture

This rebuild intentionally deletes the patch pile and replaces it with a small, maintainable, Godot 4.6.x-oriented skeleton.

## Hard rule

All UI layout is scene-authored.

Scripts update state and values. They do not place HUD widgets by pixel coordinates.

## Active folders

```text
scenes/main/GameRoot.tscn
scenes/hub/ForgeholdHub.tscn
scenes/combat/CombatArena.tscn
scenes/ui/GameHUD.tscn
scenes/ui/UIPanelRoot.tscn
scenes/ui/panels/*.tscn
scenes/prefabs/player/Player.tscn
scenes/prefabs/enemies/EnemyActor.tscn
scenes/prefabs/projectiles/ProjectileActor.tscn

scripts/core
scripts/data
scripts/systems
scripts/hub
scripts/combat
scripts/player
scripts/ui
```

## Current scope

This is not the final ARPG. It is a clean playable skeleton:

Hub → activity → combat room → reward → hub panels → save.

The goal is maintainable production direction, not feature bloat.
