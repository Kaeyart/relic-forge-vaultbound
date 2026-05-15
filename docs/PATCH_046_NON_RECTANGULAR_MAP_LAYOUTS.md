# Patch 046 — Non-Rectangular Endgame Map Layouts

This patch makes map runs stop feeling like a rectangular debug arena.

It adds a runtime map layout generator that creates authored-feeling map shapes:

- winding Ash Cistern paths
- branching Iron Catacombs
- loop-like Bone Archive layouts
- side chambers
- boss arenas
- corridor visuals
- map-specific spawn clusters
- runtime path clamping so the player follows the map shape instead of the full rectangular arena

The patch does not replace inventory UI or art assets. It only touches map/combat layout behavior.

## Testing

1. Launch the game.
2. Press `N` in the hub to open the Map Device.
3. Press `G` to add a dev map if needed.
4. Select a map with `W/S`.
5. Press `Enter` or `R` to run it.
6. Confirm the map is a path/chambers/boss arena layout instead of one rectangle.
7. Kill the boss, open the reward chest, and return to hub.

## Notes

The current visuals are still primitive procedural shapes. The important step is the structure: map runs now have different spatial layouts and can later be replaced with authored tiles/props.
