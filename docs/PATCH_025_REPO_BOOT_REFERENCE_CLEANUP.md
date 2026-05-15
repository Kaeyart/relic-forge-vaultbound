# Patch 025 — Repo Boot + Reference Cleanup

## Goal

Patch 025 turns the current clean reinstall into a cleaner repository baseline.

It does not add gameplay.

## Changes

- Forces `project.godot` to boot from `res://scenes/main/GameRoot.tscn`.
- Renames the project display name to `Relic Forge Vaultbound`.
- Keeps Godot feature target at `4.6`.
- Archives the old Patch 003 boot files:
  - `scenes/Main.tscn` → `scenes/legacy/patch003/Main.tscn`
  - `scripts/Main.gd` → `scripts/legacy/patch003/Main.gd`
- Rewrites `README.md` around the clean scene-authored baseline.
- Adds `docs/ACTIVE_SCENE_SPINE.md`.
- Adds `tools/validate_patch_025.sh`.

## Why

The repo had two mental entry points:

1. the old Patch 003 one-scene/one-script prototype;
2. the new clean scene-authored architecture.

That ambiguity is dangerous. Future work should use the new scene-authored baseline only.

## Rule going forward

`Main.gd` at `scripts/Main.gd` should not return.

The active coordinator is:

`res://scripts/core/GameRoot.gd`

The active boot scene is:

`res://scenes/main/GameRoot.tscn`
