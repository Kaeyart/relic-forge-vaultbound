# Patch 080C — Loot Filter V1

Adds a first in-game loot filter with ARPG-style presets and rule toggles.

## Features
- Filters by rarity: Normal, Magic, Rare, Unique.
- Filters by item type: equipment, maps, gems, currency, materials.
- Highlights maps, gems, uniques, high-tier affixes, and high-forge-potential crafting bases.
- Supports affix-tier and forge-potential thresholds.
- Supports a simple build-tag filter.
- Adds presets: Show All, Starter, Strict, Crafting, Maps, Build Filter.
- Adds a scene-authored `LootFilterPanel.tscn` opened with `L`.
- Adds ground-loot visual filtering pass through `RVLootFilterSystem.update_ground_loot`.

## Controls
- `L` opens the loot filter panel.
- `P/O` cycle presets.
- `1-4` toggle rarity display.
- `5/6/7` toggle maps/gems/crafting bases.
- `8/9/0` toggle auto-pickup currency/materials/maps.
- `Q/E` adjust max visible affix tier.
- `Z/X` adjust minimum forge potential.
- `C` cycles build filter tag.
- `V` toggles require build tag.
