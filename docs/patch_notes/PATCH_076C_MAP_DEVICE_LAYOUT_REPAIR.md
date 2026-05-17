# Patch 076C — Map Device Scene Layout Repair

Fixes the first scene-authored art pass where TextureRect art was using keep-aspect mode and spilled across the panel.

## Changes
- Converts MapDevicePanel art TextureRects from keep-aspect-centered to authored-rect scale mode.
- Hides the large outer `MainFrameArt` because the current asset is not a proper full-panel 9-slice frame.
- Keeps the scene-authored art nodes in place for manual editor adjustment.
- Reduces visual dominance of subpanel art using scene-owned opacity.
- Prevents empty-state double-framing by hiding `MapCardFrameArt` until a real map is selected.

## Production rule
The panel remains scene-driven. Scripts only toggle state-specific visuals and textures.
