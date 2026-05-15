# Patch 029E — Stash Select Compatibility Fix

## Purpose

Patch 029D improved inventory comparison and equipped visibility, but some local installs ended up with `StashPanel.gd` calling:

```gdscript
RVInventorySystem.select_stash_index(current_state, index)
```

while the local `InventorySystem.gd` did not contain that helper.

This patch restores the missing click-selection helper:

```gdscript
static func select_stash_index(state: RVGameState, index: int) -> void:
    state.stash_cursor = clamp(index, 0, max(0, state.stash.size() - 1))
```

It also adds a small compatibility helper:

```gdscript
static func withdraw_stash_index(state: RVGameState, index: int) -> void:
    select_stash_index(state, index)
    withdraw_selected_stash_item(state)
```

## Scope

No scene layout changes. No item balance changes. No UI art changes.
