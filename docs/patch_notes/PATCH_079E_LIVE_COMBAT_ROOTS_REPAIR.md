# Patch 079E — Live combat roots repair

Repairs stale cached combat root references after continuous-map patches.

## Fixes
- Projectile spawning no longer uses stale `projectiles_root.add_child(...)`.
- Enemy spawning no longer uses stale `enemies_root.add_child(...)`.
- Combat roots are refreshed through live helper methods before spawn/update/cast/stop.
- `_clear_children()` accepts stale/freed roots safely.
- Recursive enemy/projectile collectors use safe iteration.
- GameRoot mouse casting guards against combat transition races.
