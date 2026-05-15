# Patch 016 — Hub Buildcraft Rework

This patch adds a large original buildcraft layer inspired by modern ARPG structure without copying proprietary layouts or exact systems.

## Adds

- Physical hub rework with specialized stations.
- Large passive atlas with node allocation, adjacency, refunds, and branch identity.
- Skill gem loadout system with active gems, support gems, support sockets, and spirit reservation.
- Forgecraft system with item affixes, forge integrity, shards, sigils, runes, sealing, rerolling, upgrading, shattering, and base crafting.
- HUD/panel rendering for passive tree, skill gem board, and crafting station.
- Skill selection and loadout rebuild from equipped skill gems.

## Controls

### General
- WASD: move
- F5: save
- Esc: close panel or return from combat to hub

### Hub
- E: primary station action
- X: secondary station action
- 1-6: toggle a skill gem in the active loadout
- P: passive atlas
- K: skill gem board
- C: forgecraft panel

### Passive Atlas panel
- Q / E: cycle visible/selectable nodes
- Enter: allocate selected node
- Backspace: refund last allocated node

### Skill Gem board panel
- Q / E: select active skill gem
- W / S: select support gem
- Enter: socket support into selected skill
- X: remove last support from selected skill
- 1-6: toggle skill gem in loadout

### Forgecraft panel
- F: craft a new base item
- E: add/rank up an affix on the focused item
- X: chaos-reroll an affix
- Q: seal an affix
- R: shatter the focused item into shards
- W / S: change focused backpack item

## Notes

The system uses original names and implementation. It is intended to capture the design goals of deep buildcraft: passive planning, socketed skill modification, resource reservation, and deterministic-risk crafting.
