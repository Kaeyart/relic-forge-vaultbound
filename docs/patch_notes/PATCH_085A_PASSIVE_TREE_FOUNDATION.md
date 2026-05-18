# Patch 085A — Passive Tree Foundation V1

Adds the first real character passive tree foundation.

## Adds

- `scripts/data/PassiveAtlasDB.gd`
- `scripts/systems/PassiveTreeSystem.gd`
- `scripts/ui/panels/PassiveAtlasPanel.gd`
- `scripts/ui/components/PassiveTreeNodeButton.gd`
- `scripts/ui/components/PassiveTreeConnectionCanvas.gd`
- `scenes/ui/panels/PassiveAtlasPanel.tscn`
- `scenes/ui/components/PassiveTreeNodeButton.tscn`

## Features

- 100+ character passive nodes.
- Start, small, notable, and keystone node types.
- Fire, Lightning, Void, Melee, Bleed, Trap, Life, Armor, Mana, and Spirit clusters.
- Cross-cluster bridge notables.
- Persistent unlocked passive node list.
- Passive point spending.
- Refund point support with connectivity validation.
- Passive stat/rule aggregation into state fields.
- Scene-authored panel with scrollable tree, details panel, unlock/refund buttons.

## Notes

This is the character passive tree, not the future Atlas/map economy tree.
The node layout is data-authored. The panel renders node buttons from a reusable scene component.
