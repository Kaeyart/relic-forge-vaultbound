# Patch 016B — Full Buildcraft Hub Rework

This patch pushes the project toward a serious ARPG buildcraft loop.

It adds three major hub systems:

1. Passive Atlas
2. Skill / Support / Spirit Gem Board
3. Forgecraft

## Passive Atlas

The passive atlas is a large linked graph rather than a flat list.

Features:
- many branch families
- connected node allocation
- mastery-point spending
- refund-last support
- notables
- keystones
- stat aggregation

Branches:
- Ash
- Frost
- Storm
- Void
- Steel
- Trap
- Blood
- Relic

## Skill Gem Board

The skill system is now gem-board driven.

Features:
- active skill gems
- socket counts per skill
- support gems
- support compatibility by tag
- support inventory counts
- spirit reservation
- persistent spirit gems
- active loadout toggling

## Forgecraft

The forgecraft system uses deterministic item modification with limited crafting potential.

Features:
- base item creation
- forging potential
- prefix/suffix affix slots
- affix tiers
- upgrade/add affix
- chaos reroll
- refinement reroll
- sealing
- shattering into affix shards
- rune/glyph inventories
- focused backpack item

## Hub controls

- P: Passive Atlas
- K: Skill Gem Board
- C: Forgecraft
- E: interact / confirm
- X: secondary / remove / reroll depending panel
- Q/E: cycle nodes or options inside panels
- W/S: cycle forge item
- Backspace: refund passive / remove support depending panel
- Esc: close panel or return to hub

## Intent

This is not a small feature patch. It is the foundation for permanent character buildcraft.
