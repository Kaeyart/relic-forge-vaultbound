# Patch 085N — Input Lock + Scene-Owned UI Repair

Fixes a soft-lock where the player character remains visible but movement / world input no longer works after moving HUD and panel UI into scene-owned layouts.

## Root Cause

`GameRoot._update_player()` intentionally blocks movement while `state.panel_mode != ""`. After panel/HUD scene ownership cleanup, stale saved `panel_mode` values or full-screen UI roots could leave gameplay input locked even when the user was effectively back in the game.

## Changes

- Clears transient `panel_mode` after save-load and hub entry.
- Adds F8 emergency gameplay input unlock.
- Makes `UIPanelRoot` ignore mouse input when no panel is open.
- Makes `GameHUD` ignore mouse input at the root level.
- Keeps scene-authored HUD/panel ownership intact.

## Controls

- `F8` clears stuck panel/input state if it ever happens again.
