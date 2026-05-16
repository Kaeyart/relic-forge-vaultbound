# Patch 060 — Visual Proxy Plus

A stronger Godot-native art proxy pass for enemies, spell VFX, and runtime maps.

This is still Tier-1 proxy art, not final production sprites. The goal is to make combat readable and visually intentional without requiring Blender, final spritesheets, or hand animation yet.

## Changes

- Replaces `EnemyVisualProfileDB.gd` with stronger role silhouettes.
- Replaces `EnemyVisualRig.gd` with better part layering, role badges, hit sparks, state telegraphs, and windup visuals.
- Replaces `SpellVFXSystem.gd` with more readable Fireball, Storm Lance, Frost Nova, Void Rift, Cleave, and Blade Trap effects.
- Replaces `MapPropVisualSystem.gd` with stronger map dressing: floor language, corridor trims, boss seals, start seals, elite marks, props, gates, and exit glow.
- Patches `EnemyActor.gd` if the visual rig exists so AI state is pushed into the proxy rig more consistently.

## Test

1. Run a map.
2. Look for distinct enemy silhouettes.
3. Watch enemy windups.
4. Cast all active skills.
5. Check map floors/corridors/boss spaces for visual dressing.
