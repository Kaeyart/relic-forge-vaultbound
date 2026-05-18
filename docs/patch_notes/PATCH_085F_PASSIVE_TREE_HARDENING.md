# Patch 085F — Passive Tree Hardening

This patch repairs passive tree API and UI mismatches discovered after 085A–085E.

## Scope

- Replaces `PassiveAtlasDB.gd` with a compatibility-safe passive node database.
- Replaces `PassiveTreeSystem.gd` with parse-safe unlock/refund/stat aggregation logic.
- Replaces `PassiveTreeConnectionCanvas.gd` so it tolerates both dictionary nodes and node id strings.
- Replaces `PassiveTreeNodeButton.gd` with a small robust component script.
- Replaces `PassiveAtlasPanel.gd` with a defensive scene-binding panel script.
- Adds/keeps `PassiveTreeNodeButton.tscn`.
- Ensures `GameState.gd` declares passive-tree state fields and calls `RVPassiveTreeSystem.ensure_defaults(self)`.

## Design intent

This is not a content-expansion patch. It stabilizes the passive tree foundation so future node/class/atlas work does not keep breaking on API mismatches.
