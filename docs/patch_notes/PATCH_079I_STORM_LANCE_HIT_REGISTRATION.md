# Patch 079I — Storm Lance hit registration in continuous maps

Storm Lance was unreliable inside generated maps because it behaved like a very small projectile while the new coarse map-layout collision and LOS checks were tuned for blockers. This patch makes Storm Lance a map-safe lightning lance / hitscan-style skill while keeping wall rules at longer distances.

## Changes
- Adds a dedicated `Storm Lance` branch in `CombatArena.cast_selected_skill()`.
- Adds `_damage_enemies_along_lance()` for wide line-segment hit detection.
- Keeps blocker/LOS checks, but adds generous close-range grace so generated layout seams do not eat hits.
- Removes the duplicate strict projectile LOS gate that could reject valid overlaps.
- Repairs/normalizes forgiving combat LOS helpers.

## Design note
Storm Lance should feel like a crisp ARPG lightning skill, not like a tiny bullet that misses because a procedural blocker edge is one pixel off.
