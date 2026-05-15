# Patch 017 — World, Hub, Naming, Assets, and Activity Rework

## Purpose

This patch stops the project from feeling like a disconnected test arena.

It does five things:

1. Restores the sliced UI assets and wires them back into the HUD.
2. Standardizes terminology into plain ARPG language.
3. Reworks the physical hub around clear activity stations.
4. Adds understandable activity modes with goals.
5. Improves rooms, enemies, skill effects, and run logic.

## Naming rule

No weird AI fantasy wording unless it helps readability.

Use direct ARPG language:

- Dungeon Run
- Material Hunt
- Elite Hunt
- Boss Trial
- Endless Rift
- Fire Damage
- Cold Damage
- Lightning Damage
- Void Damage
- Attack Damage
- Trap Damage
- Max Life
- Max Mana
- Critical Chance
- Support Gem
- Spirit Skill
- Forge Potential
- Affix Shard
- Rune
- Glyph

## Activity modes

### Dungeon Run

Standard multi-room clear. Balanced loot and XP.

### Material Hunt

Shorter activity focused on crafting materials and shards.

### Elite Hunt

Harder rooms with elite enemies and better item drops.

### Boss Trial

Short run ending in a boss encounter.

### Endless Rift

Scaling room chain for testing builds.

## Hub stations

- Activity Gates start game modes.
- Passive Atlas opens the passive tree.
- Skill Gem Bench opens the skill/support/spirit system.
- Forge opens crafting.
- Stash stores items.
- Armory equips or salvages backpack items.
- Skill Altars toggle active skills.

## Asset fix

Patch 017 copies the Patch 015A sliced UI PNGs back into:

`assets/ui/patch015a/slices/normalized/`

The RenderSystem now attempts to draw:

- HP bar frame
- mana bar frame
- skill slot frames
- selected skill slot frame
- prompt chip
- notice banner
- panel frames

If an asset is missing, it falls back to drawn rectangles.

## Gameplay clarity

Rooms now have clear purposes:

- clear enemies
- survive elite pressure
- defeat a boss
- complete a material hunt
- push endless scaling

Run completion now returns to the hub with a clear reward notice.
