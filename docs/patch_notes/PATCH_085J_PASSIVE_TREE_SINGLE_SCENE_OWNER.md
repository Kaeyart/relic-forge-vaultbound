# Patch 085J — Passive Tree Single Scene Owner

Purpose: remove the duplicate passive tree conflict caused by mixing an authored panel scene with script-generated fallback layout controls.

Changes:
- Replaces `PassiveAtlasPanel.tscn` with one canonical scene-owned panel.
- Rewrites `PassiveAtlasPanel.gd` so it no longer creates fallback layout containers such as `GeneratedTreeScroll`, `GeneratedSummaryLabel`, or generated action panels.
- Keeps runtime generation only for passive node buttons, because the node set is data-driven.
- Left-click selects/highlights a passive node only.
- Right-click immediately allocates an available node.
- Drag empty tree space to pan.
- Keeps Allocate/Refund buttons as explicit fallback controls.
