# Patch 068-071A — EnemyActor Empty If Parse Fix

This is a repair patch for the combined combat patch.

## Problem

Godot failed to parse:

```text
res://scripts/combat/EnemyActor.gd:278 - Parse Error: Expected indented block after "if" block.
```

That caused cascading parse failures in `CombatArena.gd` because `RVEnemyActor` could not be parsed.

## Fix

The installer scans `scripts/combat/EnemyActor.gd` and inserts a safe `pass` statement after any accidentally generated empty executable GDScript block.

It also ensures the encounter compatibility fields exist:

```gdscript
var pack_id: String = ""
var encounter_role: String = ""
var encounter_pack_type: String = ""
```

## Scope

Only touches:

```text
scripts/combat/EnemyActor.gd
docs/PATCH_068_071A_ENEMYACTOR_EMPTY_IF_PARSE_FIX.md
tools/validate_patch_068_071a.sh
```

No scene layout, inventory, skill gem scene, map panel, or item system files are replaced.
