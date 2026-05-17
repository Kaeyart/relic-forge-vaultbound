# Patch 073A — Classes / Ascendancy / Passive Atlas Parse Fix

Repairs the initial classes/ascendancy/passive atlas patch after parser errors.

Fixes:
- Replaces malformed ClassDB.gd; no function uses reserved names.
- Replaces AscendancyDB.gd with safe original Relic Forge ascendancy data.
- Replaces PassiveAtlasDB.gd with parse-safe passive node data.
- Replaces ClassAscendancySystem.gd with a dynamic, parser-safe implementation.
- Replaces PassiveAtlasPanel.gd with a simple functional text UI.
- Repairs GameState.gd same-line insertions and ensures class/passive fields exist.
- Repairs BuildcraftSystem.gd accidental `return static func` one-line corruption.

Controls:
- P opens Passive Atlas.
- A/D select passive node.
- Enter allocates selected passive.
- Backspace/Delete refunds last passive.
- C cycles class.
- V chooses/cycles ascendancy.
- G allocates first available ascendancy node.
