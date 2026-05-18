# Patch 085Q — Passive Tree Stat Application + Build Feel Sanity

Goal: make passive tree allocations affect real gameplay instead of only existing as a visual/passive-data layer.

## Adds

- `scripts/systems/PassiveBuildApplicationSystem.gd`

## Changes

- `GameState.gd`
  - tracks passive build bonuses/rules/breakdown
  - merges passive tree stats into `build_stats`
  - merges equipped item stats into `build_stats` for combat scaling
  - resets base movement speed during stat recompute so speed bonuses do not stack forever
  - applies derived passive effects such as movement speed, cooldown reduction storage, and armor-to-life style rules

- `CombatArena.gd`
  - augments skill tags from passive rules
  - modifies skill damage from `build_stats` and passive rules

## Build-feel checks

Early passives should now be testable:

- Maximum Life increases max HP.
- Maximum Mana increases max mana.
- Maximum Spirit increases spirit capacity.
- Movement Speed increases movement speed.
- Fire / Lightning / Void / Melee / Trap / Spell / Attack damage increase matching skills.
- Storm-style rules can add chain behavior to Storm Lance.
- Void-style rules can add void echo behavior to Void Rift.
- Trap echo-style rules can add secondary trap ticks.
- Bleed/fire bridge rules can make Cleave interact with burn/bleed tags.

This is still V1. The important result is that the passive tree is now wired to the build pipeline.
