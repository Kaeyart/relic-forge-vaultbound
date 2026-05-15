# Patch 016F — Refund Points HUD Fix

## Problem

`RenderSystem.gd` displayed `state.refund_points`, but `RVGameState` did not define that field after the hard GameState replacement.

Godot crashed with:

`Invalid access to property or key 'refund_points' on RVGameState`

## Fix

- Adds `refund_points` to `GameState.gd`.
- Saves and loads `refund_points`.
- Clamps it to nonnegative after loading.
- Moves the buildcraft overlay draw call out of the prompt-only block if needed.

## Notes

This is an old-save-compatible state-field repair.
