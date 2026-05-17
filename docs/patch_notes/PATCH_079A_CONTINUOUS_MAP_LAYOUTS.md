# Patch 079A — Continuous PoE-style map layout archetypes

This patch makes maps continuous 2D combat fields with authored/generated layout identity. It does **not** add a room-choice graph and does **not** generate giant blank rectangles.

## Added
- `RVMapLayoutSystem` with 10 continuous layout archetypes:
  1. Strand / Road
  2. Loop / Cistern
  3. Branching Catacomb
  4. Sewer / Aqueduct
  5. Fortress / Bastion
  6. Forgeworks
  7. Sanctum / Temple
  8. Vault
  9. Ossuary / Crypt Maze
  10. Open Ruins / Ash Field

## Runtime model
Each layout provides:
- walkable sections
- corridor edges
- blocker obstacles
- pack anchors
- side pockets
- elite pockets
- boss anchor
- reward and exit anchors
- continuous-field metadata

CombatArena and MapEncounterDirector can consume the same data shape already used by the map-combat pipeline.
