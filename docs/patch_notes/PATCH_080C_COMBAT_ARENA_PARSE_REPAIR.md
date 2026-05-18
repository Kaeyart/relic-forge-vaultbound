# Patch 080C CombatArena parse repair

Repairs `scripts/combat/CombatArena.gd` after a patch-chain header corruption.

The installer rebuilds the script header so Godot can register `RVCombatArena` again:

```gdscript
class_name RVCombatArena
extends Node2D
```

It also removes duplicate top-level `class_name RVCombatArena` / `extends ...` lines left in the class body.
