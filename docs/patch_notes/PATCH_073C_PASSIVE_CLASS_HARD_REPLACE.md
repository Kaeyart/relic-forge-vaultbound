# Patch 073C — Passive/Class Hard Replace

This is a stronger recovery patch for the class / ascendancy / passive atlas parser failures.

It hard-replaces the corrupted parser roots:
- scripts/core/GameState.gd
- scripts/data/ClassDB.gd
- scripts/data/AscendancyDB.gd
- scripts/data/PassiveAtlasDB.gd
- scripts/systems/ClassAscendancySystem.gd
- scripts/systems/BuildcraftSystem.gd
- scripts/ui/panels/PassiveAtlasPanel.gd

It keeps the implementation text-first and data-driven so Godot can parse again before we do art/scene work on the passive atlas.
