# Patch 037-041 — Itemization Mega Pass

This patch intentionally merges the requested item-system passes into one production patch:

- Patch 037: Item detail readability + affix validation
- Patch 038: Affix pool expansion by build archetype
- Patch 039: Forgecraft MVP
- Patch 040: Shards / salvage / crafting materials
- Patch 041: Observatory itemization accuracy pass

## What changed

### Itemization

Items now use a stronger original Relic Forge item model:

- slot-specific base items
- item-level-gated prefix/suffix tiers
- family blocking so rares are less nonsensical
- build-tag-biased affix clustering
- more archetype support for Fire/Burn, Cold/Freeze, Lightning/Chain, Void/Curse, Physical/Bleed, Trap, Mana/Spirit, and Defense
- clearer unique build engines

### Crafting

The crafting MVP now supports keyboard-driven operations from the Crafting panel:

- `F` craft basic item
- `A` add prefix
- `S` add suffix
- `U` upgrade first upgradeable affix
- `R` reroll first unsealed affix
- `Backspace/Delete` remove first unsealed affix
- `L` seal first unsealed affix
- `X` shatter selected backpack item

All forge edits consume forge potential. Uniques are not craftable yet.

### Salvage / shards

Salvage and shatter now return general materials plus tag-specific shards:

- fire_shards
- cold_shards
- lightning_shards
- void_shards
- melee_shards
- trap_shards
- defense_shards
- utility_shards

### Validation

`RVItemValidationSystem` can validate generated items for obvious illegal states:

- wrong affix type
- duplicate family
- illegal slot affix
- tier above item level
- stat total mismatch
- bad rarity/affix shape

### Observatory accuracy

The Observatory evaluator no longer treats every high-potential item as a unique/proc/archetype item. Archetype hits now require actual uniques, build flags, unique effects, or true synergy density.

## Notes

This is a big system patch. It does not replace scene-authored UI. It does replace item data and several item/crafting systems.
