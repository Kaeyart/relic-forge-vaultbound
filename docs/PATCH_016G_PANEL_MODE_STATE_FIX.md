# Patch 016G — Panel Mode State Fix

## Problem

`RenderSystem.gd` reads `state.panel_mode`, but `RVGameState` did not define `panel_mode` after the hard GameState replacement.

That caused:

`Invalid access to property or key 'panel_mode' on RVGameState`

## Fix

This patch adds `panel_mode` and a defensive set of buildcraft runtime fields to `GameState.gd` if they are missing.

It also makes `apply_save_dict()` tolerate `panel_mode` and ensures `refund_points` is saved/loaded when available.

## Notes

`panel_mode` is runtime UI state. It should normally start closed (`""`).
