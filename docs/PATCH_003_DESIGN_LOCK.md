# Patch 003 Design Lock

Patch 003 changes the project direction from “small ARPG prototype with items” to “buildcraft dungeon crawler with run-born skill identity.”

## Locked goals

1. The player should start a run mostly empty.
2. The player should draft one or two skills early.
3. The run should gradually turn those skills into a build engine.
4. Gear, passive nodes, and skill-tree nodes should create interactions, not just stat scaling.
5. Late-run builds should chain skills together.
6. Respec must be easy while systems are being tested.
7. The dungeon structure should support 20–30 minute runs once tuned.

## Do not drift into these yet

- Do not build a huge open world.
- Do not add story-heavy NPC systems yet.
- Do not chase custom sprites yet.
- Do not split into dozens of files until the main loop is stable.
- Do not balance the fun out of the crazy interactions too early.

## Next patch target

Patch 004 should focus on reliability after local testing:

- Fix any Godot syntax/runtime errors.
- Make the skill draft UI cleaner.
- Add build summary cards.
- Add clearer chain-trigger VFX labels.
- Add save/load only after the run loop feels stable.
- Begin separating data tables from `Main.gd` only if Patch 003 proves too hard to maintain.
