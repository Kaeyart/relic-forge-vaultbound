# Relic Forge: Vaultbound — Clean Reinstall Baseline

This is the cleaned scene-authored baseline.

The project is intentionally small and modular. It preserves the usable art/assets already in the project during installation, but removes the old patch-script pile and replaces the runtime with a clean skeleton.

## Current playable loop

Hub → activity gate → combat room → reward → inventory/crafting/passives/skills → hub.

## Controls

Hub:
- WASD: move
- E: interact with focused hub station
- I: Inventory
- C: Crafting
- P: Passive Atlas
- K: Skill Gems
- B: Stash
- M: Activities
- Tab: Character
- F5: save

Combat:
- WASD: move
- Left click / Space: cast selected skill
- 1–6: select skill
- Q/E: cycle skills
- Esc: return to hub

## Scene-authored rule

All screen UI layout belongs in `.tscn` scenes.

Scripts may update labels, progress bars, icons, and visibility. Scripts should not hardcode screen layout positions.
