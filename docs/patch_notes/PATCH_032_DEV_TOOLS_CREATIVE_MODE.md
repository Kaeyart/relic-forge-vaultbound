# Patch 032 — Dev Tools / Creative Mode

## Purpose

The project now has enough systems that manual testing is too slow.

Patch 032 adds a developer tool panel inspired by a creative-mode workflow: quickly spawn items, gems, materials, levels, enemies, and test rooms without grinding.

## Hotkey

`F10` toggles the Dev Tools panel.

## New files

- `res://scenes/ui/dev/DevToolsPanel.tscn`
- `res://scripts/ui/dev/DevToolsPanel.gd`
- `res://scripts/dev/DevToolSystem.gd`

## New GameRoot integration

`GameRoot.gd` instances the Dev Tools panel at runtime and exposes:

- `dev_start_activity(activity)`
- `dev_return_to_hub(message)`

## New CombatArena debug helpers

`CombatArena.gd` gains:

- `dev_spawn_enemy(enemy_type, count)`
- `dev_clear_enemies()`
- `dev_force_reward()`

## Dev panel features

Player/resources:

- Heal + refill
- +1 level
- +1500 XP
- Add materials
- Add gold
- Add socket prisms
- Save now

Items:

- Add Magic Weapon
- Add Rare Chest
- Add Rare Ring
- Add Unique Relic
- Add Item Bundle
- Clear Backpack

Gems:

- Add Gem Bundle
- +1 socket cap for all active/spirit gems
- Reset default gems

Combat/rooms:

- Enter Dev Test Room
- Enter Stress Room
- Spawn Grunt / Archer / Spitter / Brute
- Clear Enemies
- Force Reward Chest
- Return To Hub

## Design rule

This is a testing layer, not production gameplay. It exists so future item, combat, room, skill, and UI work can be verified quickly.
