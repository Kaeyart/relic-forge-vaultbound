# Patch 080B — Crafting Currency Verbs

Adds first-pass ARPG crafting verbs on top of the 080A itemization model.

## Added
- `RVCraftingCurrencyDB`
- `RVCraftingCurrencySystem`
- Currency-like crafting materials:
  - Ash Temper: Normal → Magic
  - Vault Alchemy: Normal → Rare
  - Regal Ember: Magic → Rare + one affix
  - Chaos Crucible: reroll Rare affixes
  - Exalted Shard: add one affix to a Rare with room
  - Scouring Ash: remove explicit affixes, return to Normal
  - Essence Brand: reroll as Rare with a guaranteed themed affix
  - Forge Seal: add one crafted modifier

## Crafting Panel Keys
- `T` Ash Temper / Transmute
- `A` Vault Alchemy
- `R` Regal Ember
- `C` Chaos Crucible
- `E` Exalted Shard
- `S` Scouring Ash
- `B` Essence Brand
- `F` Forge Seal / bench craft

## Rules
- Consumes a currency-like material.
- Consumes Forge Potential.
- Uses prefix/suffix limits.
- Does not craft maps, gems, currency, or uniques.
- Selected backpack item is the crafting target.
