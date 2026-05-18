# Patch 080D — Scene-authored Loot Filter Panel

Replaces the previous code-heavy Loot Filter UI with a scene-authored panel.

## Rule
The scene owns layout and controls. The script only binds state and handles button/key input.

## Scene
`scenes/ui/panels/LootFilterPanel.tscn` now contains the full panel layout:
- header / preset row
- visibility toggles
- auto-pickup toggles
- quality thresholds
- build tag controls
- summary / footer

## Script
`scripts/ui/panels/LootFilterPanel.gd` no longer creates UI controls at runtime. It only:
- reads/writes `state.loot_filter_preset`
- reads/writes `state.loot_filter_settings`
- updates labels/buttons
- exposes `handle_panel_key()` for future routing

## Access
Press `L` in game to open the panel.
