# Patch 030A — GameState Parse Fix

Patch 030 accidentally produced a malformed `GameState.gd` statement while adding item stat support for `Maximum Spirit`.

Bad shape:

```gdscript
max_mana += float(stats.get("Maximum Mana", 0.0)) spirit_max += int(round(float(stats.get("Maximum Spirit", 0.0))))
```

Fixed shape:

```gdscript
max_mana += float(stats.get("Maximum Mana", 0.0))
spirit_max += int(round(float(stats.get("Maximum Spirit", 0.0))))
```

This should restore `RVGameState` parsing and stop the cascade of missing-class errors.
