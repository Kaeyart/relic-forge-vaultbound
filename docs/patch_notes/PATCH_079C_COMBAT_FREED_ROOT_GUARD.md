# Patch 079C — Combat freed-root guard repair

Fixes a runtime crash where `CombatArena._rf_safe_children()` accepted a typed `Node` parameter. When an arena root reference had already been freed, Godot rejected the call before the helper could check `is_instance_valid()`.

## Fix
- Rewrites `_rf_safe_children(root: Variant)` so freed instances can be checked safely.
- Rewrites `_rf_child_count(root: Variant)` for the same reason.
- Keeps enemy/projectile iteration routed through safe helpers.
- Adds a safer loot-pickup-pet validity check in `GameRoot.gd`.
- Normalizes the `CombatArena.gd` class header to exactly `class_name RVCombatArena` / `extends Node2D`.

## Design note
This is a stability patch only. It does not change map layout, loot filter rules, itemization, or enemy behavior.
