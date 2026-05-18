# Patch 085I — Passive Tree Mouse Pan + Right-Click Allocation

## Goal
Make the passive tree usable with mouse-first interaction.

## Changes
- Left-clicking a node now selects/highlights it only.
- Right-clicking a node immediately allocates it if it is available.
- The Allocate button remains as a fallback.
- Refund still uses the Refund button to avoid accidental refunds.
- Dragging the passive tree background pans around the board.
- Passive node visuals are higher contrast and show selected state clearly.
- PassiveTreeNodeButton is rewritten as a stable scene component with left/right click signals.

## Notes
This patch is UI/UX only. It does not change passive tree data, stats, or unlock rules.

## Next Recommended Big Patch
`085J — Passive Tree Stat Application + Content Sanity`

Verify that unlocked passive stats actually affect combat/item/skill calculations, then tune early nodes/notables so the first 10–20 passive points feel meaningful.
