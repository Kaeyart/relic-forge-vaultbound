# Patch 079J — Map Portal, Camera Crash, Enemy Wall Collision Repair

Fixes the continuous-map repair chain:

- Removes invalid `Camera2D.clear_current()` usage when leaving combat.
- Applies segment-aware collision to enemy movement instead of final-point clamping only.
- Constrains enemy `_move()` and pull movement through the combat arena.
- Adds six-entry map portal state in `GameState`.
- Opening a map consumes the first portal entry and leaves five remaining.
- Dying in a map returns to hub and preserves remaining portal entries.
- Pressing `E` in hub can re-enter the active map portal if no station interaction is available.
- Completing the map clears the active portal.

This is still not full pathfinding. Enemies will be blocked/slid by the generated layout, but smart wall-navigation should come in a later AI/pathing pass.
