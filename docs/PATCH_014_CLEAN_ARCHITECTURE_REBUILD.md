# Patch 014 — Clean Architecture Rebuild

## Purpose

The old project became a monolithic patch pile.

`Main.gd` had too many responsibilities:

- hub
- combat
- enemy AI
- projectiles
- skill casting
- loot
- inventory
- save data
- crafting
- UI
- rendering
- compatibility hacks

That structure caused repeated crashes because every system expected different dictionary shapes.

Patch 014 replaces the current `Main.gd` with a clean coordinator and moves game logic into modules.

## New architecture

```text
scripts/
  Main.gd                         # coordinator only

  core/
    GameState.gd                   # all runtime + persistent state
    SaveSystem.gd                  # save/load

  data/
    SkillDB.gd                     # skill definitions
    EnemyDB.gd                     # enemy definitions
    ContractDB.gd                  # dungeon contract definitions
    ItemDB.gd                      # loot + crafting definitions

  systems/
    PlayerSystem.gd                # movement
    HubSystem.gd                   # physical hub objects + interactions
    SkillSystem.gd                 # skill casting + cooldowns
    CombatSystem.gd                # enemies/projectiles/zones/rewards
    ProgressionSystem.gd           # XP/material progression

  visuals/
    RenderSystem.gd                # drawing/hud/world presentation
```

## Design direction

The hub is physical. No command menu.

The player walks to:

- contract gates
- forge anvils
- stash chest
- armory rack
- passive shrines
- skill altars

Interactions are done with:

- `E` primary
- `X` secondary
- `F5` save

## Combat controls

- WASD: move
- Mouse: aim
- Left click / Space: cast selected skill
- 1–6: select skill
- Esc: return to hub

## Hub controls

- WASD: move
- E: interact
- X: secondary interact
- F5: save

## Old code

The old `Main.gd` is backed up to:

- `backups/`
- `scripts/legacy/`

Patch 014 intentionally stops trying to preserve every old patch hook.
