# Patch 009 — ARPG Megafoundation

## Why this patch exists

The earlier patches were too small. They added pieces, but not the full ARPG structure.

Patch 009 creates a larger foundation:

- Hub command center
- Contract selection
- Persistent character level
- Persistent XP
- Persistent mastery/passive board
- Persistent skill board
- Equipment
- Backpack
- Stash
- Forge crafting
- Contract-based dungeon launch
- Death returns to hub
- Run rewards feed permanent progression

## Key idea

The fun should be the journey from weak to insane.

The player should:

1. Prepare in the hub.
2. Choose a contract.
3. Fight for loot/materials/XP.
4. Return or die.
5. Equip/craft/spend points.
6. Enter harder contracts.
7. Create more specific builds.

## Controls

In the hub:

- `M` Contracts
- `I` Inventory / Equipment
- `V` Forge
- `P` Passive Board
- `K` Skill Board
- `L` Loadout
- `U` Stash
- `C` Character Sheet
- `F5` Save

In menus:

- `Up/Down` select
- `Enter` confirm
- `Esc` return to hub command
- Inventory: `X` salvage
- Stash: `T` deposit backpack
- Passive board: `R` refund all
- Skill board: `R` reset skill ranks

In combat:

- `Esc` returns to hub for now

## New save path

`user://relic_forge_patch009_arpg_save.json`

## What this patch supersedes

Patch 009 supersedes the small Patch 007 / Patch 008 meta systems.

Their files can remain, but the Patch 009 director disables old meta directors when it starts.

## What still needs work

Patch 009 is a foundation, not final polish.

Next large patches should be:

1. Loot/itemization overhaul:
   - affix tiers
   - item level
   - uniques
   - exalted/legendary potential
   - sockets/support gems
   - better comparison

2. Combat overhaul:
   - more enemy AI
   - elites
   - bosses
   - telegraphs
   - reward pacing

3. Skill system overhaul:
   - skill sockets
   - support modifiers
   - real visual skill boards
   - more active skills

4. Hub art/content pass:
   - station art
   - NPCs
   - contracts board
   - forge animation
