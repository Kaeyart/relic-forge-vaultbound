# Patch 002 Plan

Patch 002 should not inflate content. It should convert Patch 001 from prototype code into expandable Godot architecture.

## Target

Keep the same playable content, but move data and logic into production-shaped components.

## Step order

1. Split skill definitions into Resource files.
2. Split item definitions into Resource files.
3. Split passive nodes into Resource files.
4. Create a `BuildStats` calculator that merges equipment, passives, buffs, and temporary effects.
5. Create a central combat event bus for `on_hit`, `on_kill`, `on_cast`, `on_dash`, and `on_status_applied`.
6. Create `LootDirector` for drop tables and item generation.
7. Create `RunDirector` for room state, reward choices, and boss routing.
8. Add a basic inventory/equipment screen.
9. Add a proper training dummy room for build testing.
10. Add first sprite-pack integration pass only after the systems split is stable.

## Patch 002 minimum acceptance test

The same interactions from Patch 001 must still work after the refactor:

- Frost Nova + Fireball + Frostfire flag causes steam explosion.
- Cleave + slash_bleed applies bleed.
- Burn death explosion chains through groups.
- Skill echo repeats every third cast.
- Dash thunder triggers on dash.
- Bone wisps spawn on kills.

Do not accept Patch 002 if any of those interactions regress.
