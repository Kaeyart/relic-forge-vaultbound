# Patch 001 Design Lock

## Game shape

Top-down 2D buildcraft dungeon-crawler ARPG.

The player clears dungeon rooms, chooses reward/route cards, equips loot, gains passive nodes, and tests skill interactions. The game is not an open-world RPG and not an isometric roguelite.

## Core design question

Can a small set of skills, gear, and passives create meaningfully different builds?

Patch 001 answers this by implementing a compact interaction matrix:

- Fire + Freeze = steam explosion
- Fire + death = burn death chain
- Slash + bleed = melee damage-over-time archetype
- Dash + lightning = mobility/offense archetype
- Repeated casting + echo = cooldown/cast engine archetype
- Kills + wisps = proto-summoner archetype
- Lightning + chain = projectile chain archetype
- HP payment + spell damage = blood mage archetype

## What not to do yet

Do not add:

- Dialogue systems
- World map
- Huge NPC hub
- Isometric rendering
- Custom sprite generation
- 50 weapons
- 100 enemies
- Complex crafting UI

The build loop must be proven first.

## Vertical slice success criteria

Patch 001 is successful if the player can make at least five recognizable builds:

1. Frostfire detonator
2. Bleed cleaver
3. Storm dash caster
4. Projectile splitter
5. Burn chain clearer
6. Summon/wisp engine
7. Blood-cast spell build

If those feel meaningfully different, the project direction is valid.
