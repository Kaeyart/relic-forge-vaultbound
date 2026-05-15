# Patch 029C — Equipment Layout Script Fix

This patch fixes the InventoryPanel equipment area so the scene owns layout and labels.

Before this patch, `InventoryPanel.gd` wrote strings like `Weapon\nEmpty` or `Helmet\nItem` directly into equipment slot buttons. That made the in-game layout ignore the intended scene-authored label arrangement.

Now:

- equipment button text is always blank;
- equipment slot names should be separate `Label` nodes in `InventoryPanel.tscn`;
- equipped item names appear in tooltips and the detail panel, not inside the slot button;
- the script supports either `%EquipmentSlots` or the older `%EquipmentGrid` node;
- the script recursively collects equipment buttons, so manual nesting is allowed.

Recommended scene structure:

```text
CharacterPanelArt
EquipmentSlots
  SlotHelmet
  SlotChest
  SlotGloves
  SlotBoots
  SlotWeapon
  SlotAmulet
  SlotRing1
  SlotRing2
  SlotRelic
  SlotOffhand
EquipmentLabels
  LabelHelmet
  LabelChest
  LabelGloves
  LabelBoots
  LabelWeapon
  LabelAmulet
  LabelRing1
  LabelRing2
  LabelRelic
  LabelOffhand
```

Use a plain `Control` for `EquipmentSlots`, not a `GridContainer`, so each slot can be manually positioned.
