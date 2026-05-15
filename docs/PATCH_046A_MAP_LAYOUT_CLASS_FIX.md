# Patch 046A — Map Layout Class Fix

Fixes the parser error where `RVMapLayoutSystem` was not declared in scope after Patch 046.

The fix does two things:

1. Ensures `scripts/systems/MapLayoutSystem.gd` declares `class_name RVMapLayoutSystem`.
2. Adds a local preload alias in `CombatArena.gd` and rewrites references to use it, so parsing does not depend on Godot's global class cache being refreshed.

This patch does not touch inventory, items, skills, or authored UI scenes.
