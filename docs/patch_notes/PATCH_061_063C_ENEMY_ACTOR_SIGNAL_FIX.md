# Patch 061-063C — EnemyActor Signal Compatibility Fix

Fixes a runtime error where `CombatArena.gd` connects to enemy AI request signals that were missing from `EnemyActor.gd` after the visual proxy / AI rework.

Adds these signals to `scripts/combat/EnemyActor.gd` if missing:

- `projectile_requested(payload: Dictionary)`
- `zone_requested(payload: Dictionary)`
- `spawn_requested(payload: Dictionary)`

Also defensively guards optional signal connections in `CombatArena.gd` with `has_signal()`.

This patch does not change gameplay balance, maps, UI, itemization, skill gems, or art assets.
