# Patch 015C — Combat Death / Update Loop Fix

## Problem

The game could crash with:

`Invalid assignment of index ... on base: Array`

This happened because a combat update loop was still iterating over enemies/projectiles/zones after `player_damage()` called `state.enter_hub()`.

`state.enter_hub()` clears combat arrays. If the old loop then tried to write back into `state.enemies[i]`, the index no longer existed.

## Fix

Combat update functions now immediately stop if combat mode ends.

Patched functions in `scripts/systems/CombatSystem.gd`:

- `update`
- `update_projectiles`
- `update_zones`
- `update_enemies`
- `enemy_touch_player`
- `player_damage`

## Behavior

If the player dies:

- combat stops safely
- runtime arrays are cleared by `state.enter_hub()`
- no stale loop writes back into cleared arrays
- player returns to the physical hub
