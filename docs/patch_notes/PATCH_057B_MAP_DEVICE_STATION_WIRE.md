# Patch 057B — Map Device Station Wire Fix

Fixes the physical hub Map Device interaction showing `Station not wired yet`.

## Changes

- Adds `map_device` to the `RVHubStation.station_type` export enum if missing.
- Rewrites `RVHubRoot.interact_primary()` to open `state.toggle_panel("map_device")` for:
  - `station_type == "map_device"`
  - `station_id == "map_device"`
  - display name containing `Map Device`
- Makes secondary interaction on the Map Device open stash.
- Normalizes the authored hub Map Device station metadata if present.

## Test

1. Launch the game.
2. Walk to the physical Map Device in the hub.
3. Press `E`.
4. The Map Device panel should open.
5. Press `X` near it to open stash as secondary behavior.
6. `N` should still work as a dev shortcut.
