# AI Project Context — RELIC FORGE: VAULTBOUND

## Current project path

`/home/kaey/Desktop/Game`

## Engine

Godot 4.

## Current design direction

This is now a top-down 2D buildcraft dungeon-crawler ARPG, not a one-off prototype and not an isometric sprite project.

The player should start weak, enter a dungeon, find or draft a small number of skills, then mutate those skills into absurd late-run build engines through gear, passives, skill-tree nodes, relics, and dungeon modifiers.

The main fantasy is buildcraft:
- skill chaining
- equipment synergies
- passive-tree identity
- per-skill trees
- respec/testing convenience
- long-form dungeon runs around 20–30 minutes
- runs that start simple and end with ridiculous chained effects

## Current patch state

Patch 003 is installed.

Patch 003 introduced:
- Skill Draft start
- longer dungeon route pacing
- per-skill trees
- respec
- chain triggers
- cascade_engine
- fivefold_cascade
- Void Rift
- Blade Trap
- guide panel
- inventory/passive/build panels

## Workflow rule

Do not rewrite the whole game unless explicitly requested.

Future work should be delivered as targeted patches:
- new files
- replacement scripts
- small terminal commands
- clear patch notes
- migration instructions

Always preserve working systems unless replacing them deliberately.

## Current important files

- `project.godot`
- `scenes/Main.tscn`
- `scripts/Main.gd`
- `docs/PATCH_003_DESIGN_LOCK.md`
- `docs/PATCH_003_SYSTEM_EXPLANATION.md`
- `README.md`

## Design priorities

1. Reliability first.
2. Build variety second.
3. Dungeon crawler structure third.
4. UI readability and QOL always matter.
5. Existing working systems should not be casually destroyed.

## Build direction

The game should support builds like:
- Fireball causing Storm Lance, Frost Nova, Void Rift, and Blade Trap chains
- Frostfire detonator
- trap/void curse loops
- bleed duelist
- lightning cascade caster
- blood/self-damage caster
- summon/corpse engine later
- contract-scaling greed builds

The player should be able to respec easily and test builds without punishment.
