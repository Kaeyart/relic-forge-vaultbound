# Patch 083A — Systems Stabilization Audit

This patch adds a static maintenance/audit pass for the current Relic Forge: Vaultbound prototype state.

It does **not** add gameplay. It adds checks for the failure patterns that repeatedly broke the project during the map, loot, itemization, crafting, flask, and portal patch series.

## Adds

```text
tools/maintenance/audit_systems_083a.py
tools/patch_validators/validate_patch_083a.sh
docs/SYSTEMS_STATUS.md
docs/patch_notes/PATCH_083A_SYSTEMS_STABILIZATION_AUDIT.md
```

## Checks

The audit checks for:

```text
- duplicate functions in GDScript files
- duplicate class variables in GDScript files
- duplicate class_name / extends headers
- missing critical RV global classes
- unresolved RV-prefixed references as warnings
- stale RVMapDeviceArtSkin references
- invalid custom _get(...) helpers that conflict with Godot Object._get
- invalid Camera2D.clear_current() calls
- missing scene-owned FlaskHUD inside GameHUD.tscn
- script-created UI layout controls in FlaskHUD/LootFilterPanel
- unsafe add_child() calls on cached combat roots
- unsafe _rf_safe_children(root: Node) signatures
```

## Why this patch exists

The project now has real ARPG systems: maps, portals, loot pickup, loot filter, stash affinity, itemization, crafting, flasks, XP, and map persistence. The cost is that `GameState.gd` and `CombatArena.gd` became fragile. This patch gives us a tripwire before adding atlas/classes/passives.

## Run

```bash
cd /home/kaey/Desktop/Game
tools/patch_validators/validate_patch_083a.sh
tools/validate_all.sh
git status
```

If the audit fails, fix the listed errors before adding new gameplay systems.
