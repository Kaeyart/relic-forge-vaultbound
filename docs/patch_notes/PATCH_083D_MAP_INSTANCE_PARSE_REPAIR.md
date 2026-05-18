# Patch 083D — Map Instance Parse Repair

Repairs the 083C decomposition-prep parser errors.

## Fixes

- Rewrites `MapInstancePersistenceSystem.gd` with `_state_get(...)` instead of `_get(...)`.
- Uses a `CombatRootSystemScript` preload alias instead of direct `RVCombatRootSystem` references.
- Rewrites `CombatRootSystem.gd` as a parse-safe global helper class.
- Adds a validator for these exact regressions.
