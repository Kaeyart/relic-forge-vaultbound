# Patch 085C — Passive START_NODE_ID Compatibility Repair

Fixes a parser/compile error where `PassiveAtlasPanel.gd` expects `RVPassiveAtlasDB.START_NODE_ID`, while the rebuilt passive database did not expose that constant.

## Changes

- Adds `const START_NODE_ID: String = "center"` to `scripts/data/PassiveAtlasDB.gd`.
- Adds `const CENTER_NODE_ID: String = START_NODE_ID` as a stable alias.
- Adds small helper aliases `start_node_id()` and `get_start_node_id()` if missing.
- Normalizes duplicate `class_name RVPassiveAtlasDB` / `extends` header damage if present.

## Gameplay Impact

None. This is a compatibility/parser repair only.
