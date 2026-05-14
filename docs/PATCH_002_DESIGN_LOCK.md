# Patch 002 Design Lock

Patch 002 moves RELIC FORGE from a combat arena prototype toward a dungeon buildcraft game.

The core design rule is unchanged: the game is a build-testing machine. Content is judged by how many interactions it creates, not by how many names or icons it adds.

## Locked production constraints

- Top-down 2D.
- Godot 4.
- Procedural shape art until the build loop is strong.
- No custom sprite dependency yet.
- Build depth comes from tags, flags, room modifiers, skill-tree nodes, passives, and equipment.
- Avoid pure +5% stat filler unless it supports a real interaction.

## Patch 002 pillars

1. Reliability first. Keep the runnable one-scene structure.
2. Dungeon crawler structure second. Rooms must have type, biome, threat, modifiers, obstacles, traps, chests, and enemy pools.
3. Buildcraft third. Every new mechanic should attach to tags or flags.
4. Skill agency always. Builds should ask for aim, dodge timing, positioning, setup/payoff, trap placement, or cooldown sequencing.

## New systems

- Dungeon route choices.
- Room modifiers.
- Procedural obstacles and traps.
- Chests/interactions.
- Inventory before equip.
- Skill-tree points and unlocks.
- Additional active skills.
- More enemy roles.
- More status tags.

## Build archetypes actively supported

- Frostfire Detonator.
- Storm Shatter.
- Trap Poison Hunter.
- Void Debt Caster.
- Meteor Pyromancer.
- Bleed Duelist.
- Dodge Storm.
- Blood Orb Caster.

## What not to do next

Do not start a giant story system. Do not hunt for final art. Do not split the architecture before the current loop is tested. Do not add twenty new skills until these six skills have interesting trees and reliable interactions.
