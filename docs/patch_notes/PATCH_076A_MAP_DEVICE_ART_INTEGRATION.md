# Patch 076A — Map Device Art Integration

This patch installs the first cleaned/sliced map-system art kit and wires it into the current UI without changing backend map logic.

## Added assets
- Map device frames, header plate, and subpanel frame.
- Map card rarity frames.
- Empty map slot and map card placeholder art.
- Reward frames and reward icons.
- Button state assets for activate, secondary, close, tab, and tier arrows.
- 10 map icons: ash cistern, iron catacomb, forgeworks, bastion, sanctum, depths, aqueducts, vault, stronghold, ossuary.
- Hub map-device active glow overlay asset.
- Source sheets and slice manifest.

## Runtime integration
- `RVMapDeviceArtSkin` dynamically skins the existing scene-authored MapDevicePanel nodes.
- Map card frame switches by rarity.
- Map art switches by map id / area name.
- Completed maps show the completed badge overlay.
- Reward preview icons use the new reward art.
- Map device buttons use the new button state art.
- Stash map tab buttons and tier arrows use the new button art.

## Scope boundaries
- No map backend redesign.
- No atlas progression change.
- No full drag/drop rewrite.
- No final UI layout rewrite.
