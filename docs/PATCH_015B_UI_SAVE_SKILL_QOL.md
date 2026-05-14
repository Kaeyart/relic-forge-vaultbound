# Patch 015B — Save, HUD, Skill Selection QOL

## Purpose

Patch 015A installed the sliced UI assets. Patch 015B makes the clean architecture slice more comfortable to actually play.

## Changes

- Adds autosave every 10 seconds.
- Saves when returning to hub, using hub interactions, pressing F5, or closing the game.
- Adds direct hub skill loadout selection with keys 1–6.
- Adds combat skill cycling with Q / E.
- Keeps combat 1–6 selection for active loadout slots.
- Reworks HUD placement so health and mana fills sit under the UI frames instead of spilling around them.
- Makes the top HUD a compact low-intrusion strip instead of a confusing big banner.
- Keeps notice banner smaller and temporary.

## Controls

### Hub

- WASD: move
- E: interact
- X: secondary interact
- 1–6: toggle skill in loadout
- F5: save

### Combat

- WASD: move
- Mouse: aim
- Left click / Space: cast selected skill
- 1–6: select active skill slot
- Q / E: cycle selected skill
- Esc: return to hub and save

## Notes

This patch targets the clean Patch 014 architecture. It does not patch the old monolithic `Main.gd` system.
