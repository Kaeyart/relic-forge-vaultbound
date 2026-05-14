# Patch 003 System Explanation

## Build architecture

The game uses a tag-and-flag structure.

Skills have tags such as Fire, Cold, Lightning, Spell, Projectile, Trap, Slash, Area, Curse, and Freeze.

Items, passives, and skill-tree nodes add stats and flags. Stats are numeric. Flags are boolean build rules.

Examples:

- `fire_calls_lance` means Fireball queues Storm Lance.
- `nova_calls_fire` means Frost Nova queues Fireball.
- `cascade_engine` means manual casts can queue random extra skills.
- `fivefold_cascade` means every fifth manual cast queues multiple different skills.
- `frostfire_steam` means Fire hitting a frozen enemy creates a steam explosion.

## Why this matters

A boring ARPG build says: “+10% fire damage.”

This game should say: “When Fireball hits, Storm Lance triggers; when Storm Lance triggers, Frost Nova triggers; then the frozen enemies get detonated by Fireball again.”

That is the intended direction.

## Run pacing

Patch 003 sets the route depth to 16 before the boss. This is not final balance. It is a structural target so runs can eventually sit around 20–30 minutes.

Room time should eventually average around 60–90 seconds including reward decisions. Boss + late rooms can be longer.

## Respec

Press `O` to refund passive nodes and skill-tree nodes. This is intentionally free in prototype because build testing is the whole point of the game.

## Content scale in Patch 003

- 6 active skills.
- 9 skill-tree nodes per skill.
- More than 35 equipment pieces including cascade gear.
- More than 35 passive nodes including chain engines and depth scaling.
- 9 route/room types.
- 6 biome families.

This is not final content. It is enough content to test whether the buildcraft premise works.
