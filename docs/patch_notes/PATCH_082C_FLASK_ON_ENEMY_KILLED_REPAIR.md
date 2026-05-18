# Patch 082C — Flask `on_enemy_killed` Repair

Fixes a parser error where `CombatArena.gd` calls `FlaskSystemScript.on_enemy_killed(state_ref, enemy)` but `RVFlaskSystem` does not define the static method.

Adds a parse-safe static `on_enemy_killed(state: Object, enemy: Object = null)` compatibility method to `scripts/systems/FlaskSystem.gd`.

Behavior:
- Normal enemy kill restores 1 charge to health and mana flasks, capped at max charges.
- Elite enemy kill restores +1 additional charge.
- Map boss kill restores +3 additional charges.
- Uses flexible field names so it works with both `health_flask_charges`/`mana_flask_charges` and `flask_health_charges`/`flask_mana_charges`.

This is a repair patch only. It does not change flask keybinds, HUD layout, or item drops.
