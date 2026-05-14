# Asset Strategy

Patch 001 intentionally uses procedural shapes. This is not the final visual identity.

The art strategy is to choose one coherent top-down pixel asset ecosystem later and wrap the code around it. The buildcraft system should not depend on bespoke character animation.

## Required asset categories for the first real art pass

- 4-direction top-down player sprite, idle/walk only
- 4-direction enemy sprites, idle/walk only
- Dungeon floor/wall/object tiles
- Projectile sprites
- Slash/impact VFX sprites
- Status icons
- Item icons
- UI frames/cards

## Important constraint

Do not require bespoke attack animations per weapon. Attacks should be sold through weapon arcs, projectiles, hit flashes, screenshake, VFX, and sound.

## Asset-pack evaluation checklist

For any candidate asset pack, check:

1. License permits commercial game use.
2. Resolution is consistent across characters, tiles, and icons.
3. Characters and enemies share the same perspective.
4. Tilesets include enough walls/floors/props for dungeon rooms.
5. Enemy sprites are readable at gameplay scale.
6. UI/icon support exists or can be paired with another compatible pack.
7. The pack can support at least one complete biome before buying more.

## Recommended first integration path

Use placeholders until Patch 002 architecture is stable. Then integrate sprites in this order:

1. Tileset
2. Player idle/walk
3. Enemy idle/walk
4. Projectile/VFX sprites
5. Item icons
6. UI cards

Do not start with player attack animations.
