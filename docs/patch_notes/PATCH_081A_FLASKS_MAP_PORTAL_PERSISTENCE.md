# Patch 081A — Flasks + Persistent Map Portal

Adds a minimal ARPG survival/return loop:

- one health flask
- one mana flask
- flask charges refill in hub and slowly from kills
- `Z` uses health flask in combat
- `X` uses mana flask in combat
- `T` inside a map opens a town portal and returns to hub
- `T` in hub re-enters the active map portal
- active maps keep their layout/enemies/ground loot when you portal out or die
- map portals use six total entries; opening a map consumes the first entry

This is intentionally not a full flask crafting system. It is the foundation only.
