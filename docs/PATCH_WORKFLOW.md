# Patch Workflow

## Rule

This repo is now the source of truth. Do not replace the whole project with a new generated zip unless the project is unrecoverable.

## Normal patch format

Each future patch should include:

1. What changed.
2. Which files changed.
3. Terminal commands to apply it.
4. How to test it.
5. What exact behavior confirms success.

## Preferred patch style

Prefer:
- editing `scripts/Main.gd`
- adding docs
- adding data files
- adding scenes only when needed

Avoid:
- total rewrites
- random file reorganization
- changing controls without documenting them
- deleting working systems
- huge architecture changes before the current loop is stable

## Local test loop

After every patch:

1. Open Godot.
2. Press Play.
3. Test the newest feature.
4. If an error appears, copy the first red error line.
5. Commit only after it runs or after the error state is understood.

## Commit message examples

- `patch 003 baseline`
- `fix skill draft selection crash`
- `add chain trigger debug panel`
- `expand fireball skill tree`
- `improve dungeon room pacing`
