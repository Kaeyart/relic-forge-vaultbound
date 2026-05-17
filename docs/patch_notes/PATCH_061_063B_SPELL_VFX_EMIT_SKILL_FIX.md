# Patch 061-063B — Spell VFX emit_skill Fix

Fixes the `Static function "emit_skill()" not found in base "RVSpellVFXSystem"` parser error.

The previous CombatArena integration calls `SpellVFXSystemScript.emit_skill(...)`, while `SpellVFXSystem.gd` only exposed `spawn_skill_cast()` and `spawn_skill_impact()`.

This patch adds a safe `emit_skill()` compatibility wrapper and keeps the existing spell VFX recipes.
