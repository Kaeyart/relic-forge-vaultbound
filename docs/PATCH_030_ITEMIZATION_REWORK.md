# Patch 030 — Itemization Rework

This patch replaces flat generated stat-stick items with a proper ARPG item model.

Items now have base identity, item level, slot, base type, armor class where relevant, rarity, implicit stats, prefixes, suffixes, total stats, forge potential, and optional unique flags/effects.

Rarity rules:

- Normal: base + implicit only
- Magic: usually 1 prefix and/or 1 suffix
- Rare: 4–6 affixes, capped at 3 prefixes and 3 suffixes
- Unique: fixed base + fixed build-changing effects, no forge potential for now

New file:

- `scripts/data/ItemAffixDB.gd`

Reworked files:

- `scripts/data/ItemDB.gd`
- `scripts/systems/InventorySystem.gd`
- `scripts/systems/SkillSystem.gd`

The first unique pass includes effects that alter Fireball, Cleave, Blade Trap, Void Rift, Storm Lance, and global active skill scaling. This is the foundation for future buildcraft, not final balance.
