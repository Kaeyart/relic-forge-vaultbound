# Patch 080B repair — ItemAffixDB crafting compatibility

Adds compatibility methods required by older deterministic forgecraft and newer crafting verbs:

- `max_tier_for_affix(def, item_level)`
- `next_tier_affix(affix, rng, item_level)`
- `roll_affix(rng, affix_type, base, item_level, blocked_families, wanted_tags)`

The helper includes a fallback affix pool so forge actions can add, reroll, and upgrade prefixes/suffixes even if the lean affix DB schema does not expose those methods directly.
