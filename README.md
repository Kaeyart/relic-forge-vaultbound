# RELIC FORGE: VAULTBOUND — Patch 003

Patch 003 is a cleanup-and-expansion patch for the Godot 4 buildcraft dungeon crawler slice.

The main design change is that the player no longer starts with a full hotbar. A new run starts with a Skill Draft. Pick two starting skills, then grow them through gear, passive nodes, and per-skill trees. This pushes the game toward the intended fantasy: start weak, discover a build, then turn one or two skills into a ridiculous end-run machine.

## How to run

1. Open this folder in Godot 4.x.
2. Open `scenes/Main.tscn` if Godot does not select it automatically.
3. Press Play.
4. At run start, choose two starting skills with number keys.

The project is still intentionally one main scene and one main script for reliability while the game loop is being proven.

## Controls

WASD: move  
Mouse: aim  
Left click: cast selected skill  
1–6: select active skill / choose menu option  
1–9: unlock skill-tree nodes while the skill tree panel is open  
Q: dash  
E: interact / open chest / pick up nearby loot  
I: inventory panel  
K: skill tree panel  
P: build panel  
M: dungeon panel  
G: guide panel  
O: free respec/refund passive and skill-tree nodes  
F: spawn a test item  
R: restart run

## Patch 003 features

- New start-empty run flow with a two-skill draft.
- Longer dungeon pacing: 16-depth route before boss, intended to tune toward 20–30 minute runs.
- Larger reward system with item caches, skill study, passive shrines, skill drafts, forge rewards, and respec fonts.
- Larger route pool: Combat, Elite, Treasure, Shrine, Forge, Skill Trial, Reliquary, Gauntlet, Library, Boss.
- Free respec key: `O` refunds passive nodes and all skill-tree nodes.
- New guide panel: `G` explains the patch and suggested builds.
- Per-skill trees expanded from 3 nodes to 9 nodes per skill.
- More passives focused on skill chains, mana loops, depth scaling, and build identity.
- More equipment focused on cascade chains and absurd end-run builds.

## The important build change

Patch 002 mostly had direct interactions like:

- Fireball + frozen target = Frostfire steam explosion.
- Cleave + bleed gear = bleed duelist.
- Blade Trap + poison = trap hunter.

Patch 003 adds chain engines:

- Fireball can queue Storm Lance.
- Storm Lance can queue Frost Nova.
- Frost Nova can queue Fireball.
- Void Rift can queue Blade Trap.
- Blade Trap can queue Void Rift or Fireball.
- Cleave can queue Blade Trap or Storm Lance.
- Cascade engines can trigger random extra skills.
- Fivefold cascade can queue five different skills every fifth manual cast.

The goal is that late-run builds can look like:

`Fireball -> Storm Lance -> Frost Nova -> Fireball -> Void Rift -> Blade Trap`

without requiring the player to manually press six buttons every time.

## Suggested test builds

### Frostfire Engine

Start with Frost Nova and Fireball. Look for Frostfire Core, Winter Ignition Lens, Pressure Vessel, Steam Engine Theology, and Frostfire/Steam nodes. Freeze enemies, then ignite them to make steam explosions.

### Cascade Mage

Start with Fireball and Storm Lance. Look for Cascade Primer, Ashen Conductor Coil, Choir of Five Motions, Combustion Cascade, Ash Conductor, Runaway Current, and Fivefold Doctrine. The build becomes about triggering skill chains rather than raw projectiles.

### Trap Abyss

Start with Blade Trap and Void Rift. Look for Rifted Tripwire, Debt-Engine Heart, Trapdoor Abyss, Gravity Tripwire, Venom Mechanism, and curse/passive mana refund. The build should become a room-control machine.

### Bleed Duelist

Start with Cleave. Pair it with Blade Trap or Storm Lance. Look for Rustblade, Butcher Moon Axe, Red Edge, Open Vein Payoff, Blood Wave, corpse sparks, and execution passives.

### Contract Eater

Take dangerous routes. Combine Contract Eater, Runaway Thesis, Ash Contract Plate, and high-threat rooms. This build scales from dungeon risk instead of only item luck.

## Known limitations

This patch was generated without running Godot inside the container, so there may be one syntax/runtime pass needed locally. Patch 001 and 002 used the same one-scene architecture and worked for local testing, so this should be close, but paste the first exact Godot error if it appears.

The art is still primitive debug art. That is intentional. The purpose of this phase is to prove that the build system is fun before locking asset packs or sprite style.
