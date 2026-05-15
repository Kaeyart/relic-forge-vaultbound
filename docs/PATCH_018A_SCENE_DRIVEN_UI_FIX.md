# Patch 018A — Scene-Driven UI Fix

The previous Scene-Driven UI patch was missing the actual scene file on some installs.

This patch creates:

- `res://scenes/ui/GameHUD.tscn`
- `res://scripts/ui/GameHUD.gd`

It also wires `Main.gd` to instantiate the HUD scene and update it from `RVGameState`.

## Editable UI nodes

Open:

`res://scenes/ui/GameHUD.tscn`

Move these in the Godot editor:

- `Root/TopStatus`
- `Root/BottomHUD`
- `Root/SkillBar`
- `Root/PromptBanner`
- `Root/NoticeBanner`
- `Root/PanelRoot`

The code only updates values. Layout is now scene-owned.

## Note

This disables the old hardcoded HUD drawing in `RenderSystem.gd` when possible.
