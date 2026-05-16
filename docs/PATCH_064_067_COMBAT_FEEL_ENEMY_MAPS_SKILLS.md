# Patch 064-067 — Combat Feel, Enemy Roles, Map Pacing, Skill Identity

Combined pass:

- Patch 064: Combat feel and feedback
- Patch 065: Enemy role tuning
- Patch 066: Map encounter pacing
- Patch 067: Skill behavior identity

This patch adds lightweight Godot-native feedback systems and replaces the map layout/director data with stronger pacing and pack design. It also patches EnemyActor/CombatArena/SkillSystem safely through installer-side edits.

## Test checklist

1. Run a map.
2. Check that packs feel more intentional.
3. Hit enemies and check for hit numbers / impact rings / death bursts.
4. Check that enemies have more role-specific timing and ranges.
5. Cast Fireball, Storm Lance, Frost Nova, Void Rift, Cleave, and Blade Trap.
6. Confirm skill feedback is clearer.
7. Kill boss and confirm the loop still completes.
