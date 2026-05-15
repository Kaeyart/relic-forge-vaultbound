# Patch 016D — Hard Replace GameState

## Problem

Patch 016B/016C left `scripts/core/GameState.gd` malformed around `to_save_dict()`. Godot could not parse the global class `RVGameState`, causing every dependent system to fail.

## Fix

This patch replaces `GameState.gd` with a clean, parseable version that includes:

- Patch 014 clean architecture runtime state
- Patch 015 save/HUD/QOL state
- Patch 016 passive atlas state
- Patch 016 skill/support/spirit gem state
- Patch 016 forgecraft state
- valid `to_save_dict()`
- valid `apply_save_dict()`
- canonical `spirit_max` / `spirit_reserved` declarations

## Required after install

Close Godot completely and reopen the project so the global class cache refreshes.
