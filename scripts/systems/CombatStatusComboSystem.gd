class_name RVCombatStatusComboSystem
extends RefCounted

# Patch 070: status + combo hooks.
# This is intentionally simple and readable: status identity first, exact balance later.

static func augment_skill_tags(skill_name: String, tags: Array) -> Array:
	var out: Array = tags.duplicate(true)
	match skill_name:
		"Fireball":
			_add(out, "Fire"); _add(out, "Burn"); _add(out, "Explosion"); _add(out, "inflicts_burn")
		"Storm Lance":
			_add(out, "Lightning"); _add(out, "Shock"); _add(out, "shock_pressure")
		"Frost Nova":
			_add(out, "Cold"); _add(out, "Freeze"); _add(out, "strong_freeze")
		"Void Rift":
			_add(out, "Void"); _add(out, "Curse"); _add(out, "rift_pull"); _add(out, "inflicts_curse")
		"Cleave":
			_add(out, "Physical"); _add(out, "Bleed"); _add(out, "inflicts_bleed")
		"Blade Trap":
			_add(out, "Trap"); _add(out, "Bleed"); _add(out, "Physical")
	return out

static func modify_damage_for_enemy(enemy: Node, tags: Array, base_damage: float) -> float:
	var damage: float = base_damage
	if enemy == null:
		return damage
	if _has_status(enemy, "freeze") and (tags.has("Physical") or tags.has("Cleave") or tags.has("Melee")):
		damage *= 1.22
	if _has_status(enemy, "curse") and (tags.has("Trap") or tags.has("Void") or tags.has("Blade Trap")):
		damage *= 1.26
	if _has_status(enemy, "burn") and tags.has("Lightning"):
		damage *= 1.18
	if _has_status(enemy, "shock") and tags.has("Fire"):
		damage *= 1.14
	if _has_status(enemy, "bleed") and tags.has("Cleave"):
		damage *= 1.16
	return damage

static func apply_statuses_and_combos(arena: Node, state: RVGameState, enemy: Node, tags: Array, damage: float) -> void:
	if enemy == null:
		return
	# Status application with clear skill identity.
	if tags.has("Fire") or tags.has("inflicts_burn"):
		_apply_status(enemy, "burn", 3.2, max(1.0, damage * 0.030))
	if tags.has("Cold") or tags.has("Freeze") or tags.has("strong_freeze"):
		_apply_status(enemy, "freeze", 1.35, 1.0)
	if tags.has("Lightning") or tags.has("Shock") or tags.has("shock_pressure"):
		_apply_status(enemy, "shock", 2.6, 1.0)
	if tags.has("Void") or tags.has("Curse") or tags.has("inflicts_curse"):
		_apply_status(enemy, "curse", 4.2, 1.0)
	if tags.has("Bleed") or tags.has("inflicts_bleed"):
		_apply_status(enemy, "bleed", 4.0, max(1.0, damage * 0.024))

	# Combo hooks. These are deliberately readable rather than overcomplicated.
	if _has_status(enemy, "burn") and tags.has("Lightning"):
		_combo_bonus_hit(enemy, damage * 0.18, ["Lightning", "Overload"])
		_notice(state, "Overload")
	if _has_status(enemy, "freeze") and tags.has("Physical"):
		_combo_bonus_hit(enemy, damage * 0.20, ["Physical", "Shatter"])
		_notice(state, "Shatter")
	if _has_status(enemy, "curse") and tags.has("Trap"):
		_combo_bonus_hit(enemy, damage * 0.24, ["Void", "Trap", "Detonate"])
		_notice(state, "Trap Detonation")
	if _has_status(enemy, "bleed") and tags.has("Fire"):
		_combo_bonus_hit(enemy, damage * 0.12, ["Fire", "Bloodburn"])

static func on_enemy_killed(arena: Node, state: RVGameState, enemy: Node, tags: Array = []) -> void:
	if enemy == null:
		return
	var pos: Vector2 = Vector2.ZERO
	if enemy is Node2D:
		pos = (enemy as Node2D).global_position
	# Small build-readable death reactions.
	if _has_status(enemy, "burn") and arena != null and arena.has_method("_damage_enemies_in_radius"):
		arena.call("_damage_enemies_in_radius", pos, 52.0, 12.0, state, ["Fire", "Explosion", "Burn"], enemy)
		_notice(state, "Burn Burst")
	elif _has_status(enemy, "freeze") and arena != null and arena.has_method("_damage_enemies_in_radius"):
		arena.call("_damage_enemies_in_radius", pos, 46.0, 8.0, state, ["Cold", "Shatter"], enemy)
		_notice(state, "Shatter Burst")

static func _add(tags: Array, tag: String) -> void:
	if not tags.has(tag):
		tags.append(tag)

static func _has_status(enemy: Node, status_id: String) -> bool:
	if enemy != null and enemy.has_method("has_status"):
		return bool(enemy.call("has_status", status_id))
	return false

static func _apply_status(enemy: Node, status_id: String, duration: float, power: float) -> void:
	if enemy != null and enemy.has_method("apply_status"):
		enemy.call("apply_status", status_id, duration, power)

static func _combo_bonus_hit(enemy: Node, amount: float, tags: Array) -> void:
	if enemy == null or amount <= 0.0:
		return
	if enemy.has_method("take_damage"):
		enemy.call("take_damage", amount, tags, "combo")

static func _notice(state: RVGameState, text: String) -> void:
	if state != null:
		state.add_notice(text)
