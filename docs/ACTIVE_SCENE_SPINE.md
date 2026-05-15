# Active Scene Spine

This document defines the active runtime structure for Relic Forge: Vaultbound.

## Boot

`project.godot` must point to:

```text
res://scenes/main/GameRoot.tscn
```

## GameRoot

`scenes/main/GameRoot.tscn` should instance:

- `ForgeholdHub.tscn`
- `CombatArena.tscn`
- `Player.tscn`
- `GameHUD.tscn`
- `UIPanelRoot.tscn`

The script is:

```text
res://scripts/core/GameRoot.gd
```

## Hub

`scenes/hub/ForgeholdHub.tscn` owns hub layout.

Hub station placement is scene-authored. Move stations in the Godot editor, not in scripts.

## Combat

`scenes/combat/CombatArena.tscn` owns room layout.

Spawn points, obstacles, reward chest, and exit portal should be scene-authored.

## UI

`scenes/ui/GameHUD.tscn` owns combat/hub HUD layout.

`scenes/ui/UIPanelRoot.tscn` owns system panels.

Scripts may update:

- text
- visibility
- progress/fill values
- selected states
- icons

Scripts should not own final screen placement.

## Legacy files

Old prototype files live under:

```text
scenes/legacy/patch003/
scripts/legacy/patch003/
```

They are reference only.
