# Patch 079G — Enemy wall collision repair and six-entry map portals

## Fixes
- Enemy movement is constrained segment-by-segment against generated map geometry instead of only by final position.
- Player movement uses the same segment-aware constraint when the arena exposes it.
- Enemy projectiles are blocked when the enemy lacks line of sight to the player.
- Player projectile and area hits use line-of-sight with a close-range grace radius so nearby hits still feel reliable.
- Enemy and projectile roots are refreshed through live-root helpers before spawn.

## Adds
- A simple hub map-return portal scene.
- Map activities now create six entries/portals.
- Every map entry consumes one portal, including the first.
- Dying in a map returns to the hub and leaves the portal active while entries remain.
- Completing the map clears the active map portal.
