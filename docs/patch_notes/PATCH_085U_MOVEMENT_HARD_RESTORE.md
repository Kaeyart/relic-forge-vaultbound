# Patch 085U — Movement Hard Restore

Purpose: restore WASD movement after UI scene-ownership/input-lock cleanup.

Fixes:
- Replaces GameRoot._update_player with a robust movement path.
- Clears stale/invisible panel modes instead of permanently blocking movement.
- Preserves movement blocking when a real panel is open.
- Repairs invalid/zero player_speed.
- Adds F8 emergency input unlock.
- Uses segment-aware combat movement when available.
