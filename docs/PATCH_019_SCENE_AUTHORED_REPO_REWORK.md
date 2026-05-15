# Patch 019 — Scene Authored Repository Rework

This patch makes the project scene-authored.

Open these scenes and drag the nodes manually:

- `res://scenes/ui/GameHUD.tscn`
- `res://scenes/hub/ForgeholdHub.tscn`
- `res://scenes/combat/CombatArena.tscn`

The main scene is set to:

- `res://scenes/main/GameRoot.tscn`

Code should update state and values. Scenes should own positions, layout, station placement, spawn points, and UI placement.
