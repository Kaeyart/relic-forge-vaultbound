# Patch 024 — Combat Room Vertical Slice

## Purpose

This patch makes the combat room workflow less abstract and more scene-authored.

The goal is the first proper combat loop:

```text
Hub → Activity Gate → Authored Combat Room → Clear Enemies → Reward Chest → Exit Portal → Hub
```

## What changed

### Scene-authored room layout

`res://scenes/combat/CombatArena.tscn` now contains authored markers:

- `SpawnPoints/PlayerSpawn`
- `SpawnPoints/EnemySpawn01...EnemySpawn08`
- `Obstacles/Obstacle01...Obstacle04`
- `RewardChest`
- `ExitPortal`

You can drag these manually in Godot.

### Runtime behavior

The combat system reads the authored scene layout into `GameState.combat_room_layout`.

The room now has:

- objective text
- reward chest position
- exit portal position
- authored enemy spawn points
- authored obstacle positions

### Combat flow

- Enter activity from hub.
- Spawn into the authored room.
- Kill enemies.
- Reward chest becomes available.
- Press `E` near reward chest to claim reward.
- Exit portal becomes available.
- Press `E` near exit portal to return to hub.

## Scene-authored rule

Room placement belongs in `.tscn` scenes.

Code reads scene markers. Code should not own room layout.

## Next patch

Patch 025 should polish `InventoryPanel.tscn` using the existing sliced UI assets and make the item flow cleaner.
