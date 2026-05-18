# Patch 085B — PassiveAtlasDB Compatibility Repair

Fixes the 085A passive tree parser break where `RVClassAscendancySystem` calls:

- `RVPassiveAtlasDB.ordered_ids_for_class()`
- `RVPassiveAtlasDB.can_allocate()`
- `RVPassiveAtlasDB.node()`

The repair replaces `scripts/data/PassiveAtlasDB.gd` with a parse-safe compatibility database that exposes old and new passive APIs. It includes 100+ nodes across Fire, Lightning, Void, Melee, Bleed, Trap, Life, Armor, Mana, and Spirit clusters, plus notables, keystones, starts, and bridge nodes.

This patch is meant to stabilize the tree foundation. It does not add class ascendancies or atlas passives.
