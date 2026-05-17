# Patch 079B — Camera, line-of-sight, and blocker collision repair

Fixes the first rough edge after continuous map layouts:

- Adds a combat camera that follows the player during large map activities.
- Replaces the old fixed screen-space player clamp with layout-aware bounds/collision clamping.
- Adds shared circular blocker collision and line-of-sight helpers.
- Constrains enemies after movement so they cannot walk through layout blockers.
- Adds arena line-of-sight helpers so enemy ranged logic and projectiles can respect map blockers.
- Adds best-effort projectile wall/boundary blocking and bounce support for projectiles that expose velocity/bounce properties.

This is still gameplay scaffolding, not final tile/collision authoring.
