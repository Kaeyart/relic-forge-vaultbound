# Patch 036 — Affix Pool + Item Roller Rework

This patch replaces the loose item generator with an original Relic Forge itemization engine inspired by the broad ARPG structure: base items, implicits, prefixes, suffixes, item-level-gated tiers, slot-specific affix pools, weighted rolls, family blocking, forge potential, and build-changing uniques.

It does not copy external affix tables, names, values, tiers, or item pools.

## New files

- `res://scripts/data/ItemBaseDB.gd`
- `res://scripts/data/ItemAffixDB.gd`
- `res://scripts/systems/ItemRollSystem.gd`

## Replaced file

- `res://scripts/data/ItemDB.gd`

## Design rules

- Normal items are clean bases with implicit stats and high forge potential.
- Magic items roll one or two explicit affixes.
- Rare items roll three to six explicit affixes with a maximum of three prefixes and three suffixes.
- Unique items use fixed stats and build flags instead of normal affix rolling.
- Affixes have legal slots, legal base types, tiers, weights, tags, and families.
- Family blocking prevents nonsense items from rolling too many unrelated duplicate damage/resistance families.
- Higher item levels unlock better tiers.
- Items now include inventory dimensions: `inv_w`, `inv_h`, and `dimensions`.

## Test targets

1. Start an activity.
2. Clear a room.
3. Open reward chest.
4. Inspect dropped items.
5. Confirm items show prefixes/suffixes, tiers, forge potential, item level, and total stats.
6. Confirm Uniques still produce build flags.
7. Run the Observatory again after the inventory is stable.

## Notes

This patch is a foundation. The next pass should improve inventory display of affix tiers and then update the Buildcraft Observatory so it validates legal affix pools, noisy rares, tier distribution, and crafting-base quality.
