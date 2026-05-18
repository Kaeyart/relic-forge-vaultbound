# Patch 084C — Scene-Authored Crafting UI/UX Pass

Purpose: make the existing itemization/crafting systems readable and usable without adding another gameplay layer.

Adds/replaces:

- `scenes/ui/panels/CraftingPanel.tscn`
- `scripts/ui/panels/CraftingPanel.gd`
- `tools/patch_validators/validate_patch_084c.sh`

Design rules:

- The scene owns the layout.
- The script binds state and invokes existing crafting verbs.
- No runtime-created layout controls.
- No `_get(...)` helper conflict.

Crafting panel now shows:

- selected backpack item
- rarity / slot / item level / required level
- forge potential bar
- total stats
- prefixes
- suffixes
- crafted modifier
- currency/material summary
- verb buttons and blocked-state reasons

Crafting verbs exposed:

- T — Ash Temper
- A — Vault Alchemy
- R — Regal Ember
- C — Chaos Crucible
- E — Exalted Shard
- S — Scouring Ash
- B — Essence Brand
- F — Forge Seal
