# Patch 035A — Inventory Compare Parse Fix

Fixes a parser error introduced by Patch 035.

## Fixes

- Replaces the invalid static call `RVInventorySystem.has_method("equipped_item_for_item")`.
- Adds/restores `RVInventorySystem.equipped_item_for_item()`.
- Adds compatibility helpers for slot normalization and slot labels if missing.
- Keeps inventory layout scene-authored.

## Why

Godot does not allow calling `has_method()` directly on the `RVInventorySystem` class. The inventory panel needs a static helper to find the currently equipped comparison item for a selected backpack item.
