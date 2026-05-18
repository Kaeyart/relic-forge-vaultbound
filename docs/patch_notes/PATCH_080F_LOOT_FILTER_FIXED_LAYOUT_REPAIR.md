# Patch 080F — Loot Filter fixed-layout repair

The previous scene-authored Loot Filter used containers. Even with stable button labels, toggles and focus/pressed state could still trigger container recalculation or theme offset jitter in some local themes.

This patch replaces the panel with a scene-authored **absolute-positioned** layout:

- No VBox/HBox/Grid containers inside the panel.
- No runtime-created UI controls.
- Buttons keep fixed rectangles.
- The script does not move, resize, or recreate controls.
- Toggle state uses tint and tooltip, not dynamic label prefixes.

You can still edit everything manually in `LootFilterPanel.tscn`.
