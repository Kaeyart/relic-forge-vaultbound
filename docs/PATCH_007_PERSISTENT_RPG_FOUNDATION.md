# Patch 007 — Persistent RPG Foundation

## Why this patch exists

Patch 006 was the wrong direction. Random combat mutation removed agency.

The intended game is closer to Diablo / Path of Exile / Last Epoch:

- persistent character
- permanent equipment
- stash
- crafting
- mastery choices
- loadout identity
- runs as loot and progression expeditions

## Added

### Persistent save

Stored at:

`user://relic_forge_vaultbound_character_save.json`

### Persistent character level

Kills and room clears grant permanent character XP.

Leveling grants permanent Mastery Points.

### Mastery branches

Press `C` to open the Character / Mastery panel.

Branches:

1. Ash — fire, burn, explosions, Fireball chains
2. Frost — freeze, Frostfire, shatter
3. Storm — chain lightning, cooldown, cascade speed
4. Void — rifts, curses, trap gravity
5. Steel — Cleave, bleed, melee execution
6. Trap — Blade Trap, poison, trap/rift loops
7. Blood — blood casting, low-resource aggression
8. Relic — global scaling, contract greed, depth scaling

### Persistent gear

Equipped gear and backpack persist through runs.

### Stash

Press `U`.

- `T` moves backpack into stash.
- `1-9` withdraws stash items.

### Forge / crafting

Press `V`.

Crafting uses materials earned from runs:

- Embers
- Shards
- Runes
- Echo Glass

Crafted gear goes into the backpack and persists.

### Loadout

Press `L`.

- `1-6` toggles skills.
- `Enter` applies the persistent loadout.

This is the character identity you bring into runs.

## Design target

The journey should be:

start weak → run dungeon → find loot/materials → craft/equip → spend mastery → return stronger → make crazier build

## Important

Patch 007 disables Patch 006's random combat mutation director.

Combat should still have drops and build interactions, but the player's long-term choices must drive the build.
