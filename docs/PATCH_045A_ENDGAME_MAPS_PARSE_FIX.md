# Patch 045A — Endgame Maps Parse Fix

Patch 045 inserted several GDScript statements onto single lines, causing parser errors in `GameState.gd`, `UIPanelRoot.gd`, `GameRoot.gd`, `CombatArena.gd`, and `ProgressionSystem.gd`.

This repair patch rewrites the new map-device files cleanly and fixes the affected integration files without replacing the authored inventory scene.

## Test

- Press `N` in hub to open Map Device.
- `G` adds a dev map.
- `W/S` selects.
- `Enter` or `R` runs selected map.
- Clear map packs, open reward chest, return to hub.
