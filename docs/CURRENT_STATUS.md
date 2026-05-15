# Current Status — Relic Forge: Vaultbound

Version target: `0.4.7-repo-hygiene-baseline`

## Current playable identity

Relic Forge: Vaultbound is now a scene-authored Godot ARPG prototype focused on:

- physical hub interaction
- endgame-style map loops
- loot drops
- inventory/equipment/stash management
- affix-based itemization
- forge potential / crafting direction
- uncut skill/support/spirit gems
- buildcraft experimentation
- developer tools and simulation/observatory reports

The current production goal is not full content scale. The goal is a reliable vertical slice that can be expanded without returning to one-file prototype chaos.

## Active loop

```text
Hub
→ Map Device / activity station
→ generated map or combat room
→ monster packs
→ boss / reward chest
→ loot drops
→ inventory / stash / craft / skill gems
→ run again
```

## Active boot scene

```text
res://scenes/main/GameRoot.tscn
```

## Active scene spine

```text
scenes/main/GameRoot.tscn
scenes/hub/ForgeholdHub.tscn
scenes/combat/CombatArena.tscn
scenes/ui/GameHUD.tscn
scenes/ui/UIPanelRoot.tscn
scenes/ui/panels/*.tscn
scenes/prefabs/player/Player.tscn
scenes/prefabs/enemies/EnemyActor.tscn
scenes/prefabs/projectiles/ProjectileActor.tscn
```

## Active script spine

```text
scripts/core/GameRoot.gd        coordinator
scripts/core/GameState.gd       runtime/persistent state
scripts/core/SaveSystem.gd      save/load
scripts/data/                   databases and definitions
scripts/systems/                gameplay logic
scripts/combat/                 combat room and actor logic
scripts/hub/                    hub station behavior
scripts/player/                 player actor/controller
scripts/ui/                     scene-authored UI controllers
scripts/dev/                    dev tools, lab, observatory
```

## What is working enough

- Clean boot spine
- Physical hub direction
- Inventory and equipment flow
- Skill/support/spirit gem first pass
- Affix item roller first pass
- Crafting/forge direction first pass
- Endgame map device first pass
- Non-rectangular generated map layout first pass
- Dev tools and Buildcraft Observatory foundation

## Current weak points

- Combat feel and enemy identity are still early.
- Map layouts are structural placeholders, not final authored/visual maps.
- Inventory is functional but still needs polish, item icons, and better layout tuning.
- Observatory classification is useful but still needs accuracy improvement.
- Art coverage is low: character, enemies, items, map tiles, VFX, and UI icons need production passes.
- Some scripts may need formatting/refactoring for reviewability after rapid patching.

## Current near-term priority

1. Keep repo clean.
2. Improve map layout quality and combat readability.
3. Improve enemy identity.
4. Improve Observatory accuracy.
5. Start focused art batches only when the relevant system is stable.
