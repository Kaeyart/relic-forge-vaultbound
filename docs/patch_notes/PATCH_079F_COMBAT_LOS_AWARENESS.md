# Patch 079F — Combat LOS + awareness repair

Continuous maps now enforce a basic combat contract around generated blockers:

- enemies do not wake/attack from offscreen unless the player is within wake radius and line of sight
- enemy projectiles and zones are blocked when the enemy cannot see the player
- enemy melee hit callbacks check source-enemy line of sight before damaging the player
- player projectiles cannot hit enemies through hard blockers
- player area damage does not apply through blockers unless a future skill explicitly carries `ignores_los` / `wall_pierce`
- lightning chain checks line of sight between chain targets

This is not full pathfinding yet. It is the minimum rule layer needed for PoE-style continuous 2D maps to stop feeling unfair around walls.
