# Patch 016C — GameState Spirit Parse Fix

## Problem

Patch 016B introduced duplicate declarations in `scripts/core/GameState.gd`:

- `spirit_max`
- `spirit_reserved`

Godot stops parsing `RVGameState` when a script has duplicate variable names. Once `RVGameState` fails, every script that references it also reports unresolved classes/functions.

## Fix

This patch:

- backs up `GameState.gd`
- removes duplicate `spirit_max` / `spirit_reserved` declarations
- ensures canonical typed declarations exist
- ensures spirit values are saved/loaded
- clamps `spirit_reserved` to `spirit_max` during stat recompute

## After installing

Close Godot completely and reopen the project so the global class cache refreshes.
