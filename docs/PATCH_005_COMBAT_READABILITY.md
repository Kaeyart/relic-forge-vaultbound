# Patch 005 — Combat Readability + Skill Feel

## Purpose

The game had systems, but the screen was not readable enough. It felt like dots moving around.

Patch 005 adds a combat readability layer:

- stronger player silhouette
- role-based enemy silhouettes
- enemy labels and threat rings
- projectile trails
- skill aim previews
- visible traps
- visible zones
- loot beams
- chest markers
- impact pulses
- light screen-shake logic

## Design rule

This is not final pixel art.

This is a readability pass so the game becomes easier to parse and more satisfying to test before final sprite packs.

## What should feel better

- Fireball should read as a fire projectile.
- Storm Lance should read as a fast lightning shot.
- Frost Nova should show its radius.
- Void Rift should look like a dangerous zone.
- Blade Trap should read as a placed hazard.
- Enemy roles should be understandable without reading debug text.

## Next patch candidates

- enemy attack telegraphs
- better enemy AI behavior separation
- procedural SFX
- proper hit-stop
- damage number cleanup
- room theme art pass
- sprite-pack integration
