# Patch 073 — Classes, Ascendancies, and Passive Atlas Rework

Adds the first real class/passive/ascendancy foundation for Relic Forge.

## New systems

- `RVClassDB`
- `RVAscendancyDB`
- `RVPassiveAtlasDB`
- `RVClassAscendancySystem`

## Classes

- Sorceress
- Huntress
- Warrior

## Ascendancies

Sorceress:
- Ember Savant
- Storm Oracle
- Void Arcanist

Huntress:
- Trapwright
- Bloodstalker
- Rift Poacher

Warrior:
- Ironbreaker
- Bloodbound
- Forgeguard

## Passive Atlas

The atlas now has:

- class start nodes
- class-biased node clusters
- shared center nodes
- small passives
- notables
- keystones
- ascendancy nodes

## Panel controls

Open Passive Atlas with `P`.

Keyboard:

- `A / D` — select passive node
- `Enter` — allocate selected passive
- `Backspace / Delete` — refund last allocated passive
- `C` — cycle class
- `V` — choose/cycle ascendancy
- `G` — allocate first available ascendancy node

Mouse:

- class buttons select class
- ascendancy buttons choose ascendancy
- passive node buttons select nodes
- bottom buttons allocate/refund/ascend/close

## Notes

This patch is system-first, not art-first. The passive screen is still plain, but it now carries the real design model that a later art pass can build around.
