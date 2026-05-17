# Patch 072 — Ground Loot + Damage Numbers + Render Layers

Adds ARPG-style ground loot drops, floating combat text, and z-order fixes so enemies/rendered combat actors stay above map dressing.

Core changes:
- enemies drop loot on death
- elites drop better bundles
- map bosses drop loot bursts
- ground loot has rarity-colored labels/markers
- E / click pickup support through the combat arena update loop
- floating damage numbers
- status/combat callout infrastructure
- combat render roots receive strict z-index ordering

This patch intentionally does not replace art assets. It adds systems and patches CombatArena behavior.
