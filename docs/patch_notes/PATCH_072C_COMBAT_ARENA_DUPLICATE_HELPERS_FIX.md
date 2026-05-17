# Patch 072C — CombatArena Duplicate Helper Fix

Fixes a parser failure caused by duplicate top-level helper functions in `scripts/combat/CombatArena.gd`, especially duplicate `_rf_feedback_root()` definitions created during the ground-loot/damage-number patch repair sequence.

This patch:

- backs up `CombatArena.gd` under `.patch_backups/patch_072c/`
- scans top-level `func` declarations in `CombatArena.gd`
- keeps the first occurrence of each function
- removes later duplicate function blocks
- installs `tools/validate_patch_072c.sh`

It does not change scenes, UI, items, maps, skill gems, or inventory.
