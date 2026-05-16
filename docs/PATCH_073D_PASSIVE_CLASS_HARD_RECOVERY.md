# Patch 073D — Passive/Class Hard Recovery

This is a parser recovery patch for the classes, ascendancies, and passive atlas system.

It hard-replaces the corrupted parser roots instead of trying to repair one-line insertions:

- `scripts/core/GameState.gd`
- `scripts/systems/BuildcraftSystem.gd`
- `scripts/data/ClassDB.gd`
- `scripts/data/AscendancyDB.gd`
- `scripts/data/PassiveAtlasDB.gd`
- `scripts/systems/ClassAscendancySystem.gd`
- `scripts/ui/panels/PassiveAtlasPanel.gd`

Controls in Passive Atlas:

- `A/D` select passive node
- `Enter` allocate selected passive
- `Backspace/Delete` refund last passive
- `C` cycle class
- `V` choose/cycle ascendancy, level 10+
- `G` allocate first available ascendancy node

This patch is intentionally text-first. The passive atlas art scene should be handled later, after the class/passive logic parses and runs.
