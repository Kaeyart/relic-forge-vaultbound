# Patch 015A — Sliced UI Asset Pack

This patch installs the user-cleaned UI frame sheets as sliced transparent PNGs and wires the clean architecture HUD to use them.

## Assets

The patch provides tight cropped slices and normalized predictable-canvas slices.

## Sliced assets

- `ui_skill_slot_empty`
- `ui_skill_slot_selected`
- `ui_inventory_slot`
- `ui_equipped_item_slot`
- `ui_material_chip`
- `ui_passive_node_circle`
- `ui_health_bar_frame`
- `ui_mana_bar_frame`
- `ui_tooltip_panel_large`
- `ui_notice_banner`
- `ui_vertical_card_panel`
- `ui_main_window_panel`

## Integration behavior

The installer patches:

- `scripts/Main.gd`
- `scripts/visuals/RenderSystem.gd`

It loads textures into the existing `textures` dictionary and uses them in the HUD.
