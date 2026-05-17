# Patch 078A — Stash tabs, affinities, and stash economy

Adds an ARPG-style stash foundation.

## Features
- Stash tabs: Items, Maps, Currency, Materials, Gems, Uniques, Dump.
- Default unlocked tabs: Items, Maps, Currency, Materials.
- Buyable tabs with gold: Gems, Uniques, Dump.
- Affinity toggle: deposits route to owned matching tabs.
- Deposit by Affinity button.
- Basic tab economy persistence through `GameState` save/load.

## Notes
- This is functional UI, not final stash presentation art.
- Maps continue to use `map_stash` and the existing Map Tab flow.
- General gear continues to use the legacy `stash` array.
