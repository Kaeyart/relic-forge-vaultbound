# Patch 085G — Passive Tree Visibility Repair

This is a presentation/interaction hardening patch for the character passive tree.

## Fixes

- Replaces `PassiveAtlasPanel.gd` with a defensive scene-binding script.
- Adds a guaranteed front-most scroll/content layer named `GeneratedTreeScroll` so the tree cannot be hidden behind stale dark scene panels.
- Rebuilds node buttons from `RVPassiveAtlasDB.nodes()` at data-authored positions.
- Replaces `PassiveTreeNodeButton.gd` with high-contrast visual states for locked, available, unlocked, notable, and keystone nodes.
- Replaces `PassiveTreeConnectionCanvas.gd` with a version that tolerates dictionary nodes or id-string nodes.
- Adds visible connection drawing between linked nodes.
- Left-click selects/unlocks available nodes.
- Right-click refunds refundable nodes.
- Adds fallback Allocate/Refund buttons if the scene does not already provide them.

## Intent

The previous panel could open but look like a blank brown/black board because node buttons were either not being added to the visible layer or were being hidden behind stale scene controls. This patch prioritizes visibility and stable interaction while keeping node layout data-authored.
