# Patch 072A — Ground Loot Parse/Compatibility Fix

Repairs Patch 072 by:

- adding the missing CombatArena helper functions even when only call-sites already exist
- replacing LootDropSystem with calls matching current project signatures:
  - `RVItemDB.generate_drop(state, depth)`
  - `RVMapDB.make_map(rng, depth)`
  - `RVSkillGemSystem._make_uncut_*_drop(state, level)`
- keeping enemy loot drops, ground labels, pickup flow, and floating damage numbers

This patch does not touch scenes, inventory, skill-gem UI, map device scenes, or enemy art.
