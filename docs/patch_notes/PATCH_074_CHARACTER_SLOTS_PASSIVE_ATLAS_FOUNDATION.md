# Patch 074 — Character Slots + Passive Atlas Foundation

This patch converts the class/passive work into a proper per-character save foundation.

## Main changes

- Adds a 10-character roster under `user://relic_forge_vaultbound_characters/`.
- Keeps a roster file at `user://relic_forge_vaultbound_roster.json`.
- Saves each character to its own file.
- Adds per-character class identity.
- Class can be chosen before locking the character.
- Adds Sorceress, Huntress, and Warrior.
- Adds 3 ascendancies per class.
- Ascendancy points unlock at levels 20, 30, 40, and 50.
- Adds a text-first passive atlas with class starts, shared nodes, notables, keystones, and ascendancy nodes.

## Passive Atlas controls

Open Passive Atlas with `P`.

- `1-9` / `0`: switch character slot 1-10. The current character saves before switching.
- `C`: cycle class before class lock.
- `Enter`: lock class if unlocked, otherwise allocate selected passive.
- `A/D`: move selected passive.
- `Backspace/Delete`: refund last passive.
- `V`: choose/cycle ascendancy at level 20+ before allocating ascendancy nodes.
- `G`: allocate next ascendancy node.

## Notes

This patch is intentionally text-first. The next pass should make the Passive Atlas scene-authored and visual, similar to the Skill Gems screen workflow.
