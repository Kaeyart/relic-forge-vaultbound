# Patch 073B — Passive/Class Hard Repair

Repairs the class/ascendancy/passive atlas parser break from Patch 073/073A.

This patch:
- Replaces `ClassDB.gd`, `AscendancyDB.gd`, `PassiveAtlasDB.gd`, `ClassAscendancySystem.gd`, `PassiveAtlasPanel.gd`, and `BuildcraftSystem.gd` with parse-safe versions.
- Repairs malformed class/passive field insertions in `GameState.gd`.
- Adds three classes: Sorceress, Huntress, Warrior.
- Adds nine ascendancies.
- Adds a functional data-driven passive atlas foundation.
- Keeps the passive panel text-driven for now. Art/layout pass comes later.

Controls:
- `P` opens Passive Atlas.
- `A/D` select passive node.
- `Enter` allocates selected passive.
- `Backspace/Delete` refunds last passive.
- `C` cycles class.
- `V` cycles ascendancy.
- `G` allocates the first available ascendancy node.
