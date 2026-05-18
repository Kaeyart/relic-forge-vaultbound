class_name RVFlaskSystem
extends RefCounted

const HEALTH_FLASK_KEY: String = "health"
const MANA_FLASK_KEY: String = "mana"

static func ensure_defaults(state: Object) -> void:
	if state == null:
		return
	_state_set_if_missing(state, "health_flask_max_charges", 3)
	_state_set_if_missing(state, "health_flask_charges", int(_state_get(state, "health_flask_max_charges", 3)))
	_state_set_if_missing(state, "health_flask_recovery", 65.0)
	_state_set_if_missing(state, "health_flask_kill_progress", 0.0)
	_state_set_if_missing(state, "health_flask_upgrades", 0)
	_state_set_if_missing(state, "mana_flask_max_charges", 3)
	_state_set_if_missing(state, "mana_flask_charges", int(_state_get(state, "mana_flask_max_charges", 3)))
	_state_set_if_missing(state, "mana_flask_recovery", 55.0)
	_state_set_if_missing(state, "mana_flask_kill_progress", 0.0)
	_state_set_if_missing(state, "mana_flask_upgrades", 0)
	state.set("health_flask_charges", clampi(int(_state_get(state, "health_flask_charges", 0)), 0, max(1, int(_state_get(state, "health_flask_max_charges", 3)))))
	state.set("mana_flask_charges", clampi(int(_state_get(state, "mana_flask_charges", 0)), 0, max(1, int(_state_get(state, "mana_flask_max_charges", 3)))))

static func refill_all(state: Object) -> void:
	ensure_defaults(state)
	state.set("health_flask_charges", int(_state_get(state, "health_flask_max_charges", 3)))
	state.set("mana_flask_charges", int(_state_get(state, "mana_flask_max_charges", 3)))
	state.set("health_flask_kill_progress", 0.0)
	state.set("mana_flask_kill_progress", 0.0)

static func use_health(state: Object) -> bool:
	ensure_defaults(state)
	var charges: int = int(_state_get(state, "health_flask_charges", 0))
	if charges <= 0:
		_notice(state, "Health flask is empty")
		return false
	var hp: float = float(_state_get(state, "player_hp", 0.0))
	var max_hp: float = float(_state_get(state, "max_hp", 1.0))
	if hp >= max_hp:
		_notice(state, "Life is already full")
		return false
	state.set("health_flask_charges", charges - 1)
	state.set("player_hp", min(max_hp, hp + float(_state_get(state, "health_flask_recovery", 65.0))))
	_notice(state, "Health flask used")
	return true

static func use_mana(state: Object) -> bool:
	ensure_defaults(state)
	var charges: int = int(_state_get(state, "mana_flask_charges", 0))
	if charges <= 0:
		_notice(state, "Mana flask is empty")
		return false
	var mana: float = float(_state_get(state, "player_mana", 0.0))
	var max_mana: float = float(_state_get(state, "max_mana", 1.0))
	if mana >= max_mana:
		_notice(state, "Mana is already full")
		return false
	state.set("mana_flask_charges", charges - 1)
	state.set("player_mana", min(max_mana, mana + float(_state_get(state, "mana_flask_recovery", 55.0))))
	_notice(state, "Mana flask used")
	return true

static func award_kill_charge_progress(state: Object, enemy_level: int, is_elite: bool = false, is_boss: bool = false) -> void:
	ensure_defaults(state)
	var gain: float = 0.18 + float(enemy_level) * 0.004
	if is_elite:
		gain += 0.42
	if is_boss:
		gain += 1.25
	_add_flask_progress(state, "health", gain)
	_add_flask_progress(state, "mana", gain * 0.88)

static func apply_upgrade_drop(state: Object, flask_kind: String, upgrade_id: String = "") -> bool:
	ensure_defaults(state)
	var kind: String = flask_kind.to_lower()
	if kind != "health" and kind != "mana":
		kind = "health"
	var roll_id: String = upgrade_id
	if roll_id == "":
		roll_id = _random_upgrade_id(state, kind)
	match roll_id:
		"extra_charge":
			var key: String = kind + "_flask_max_charges"
			state.set(key, int(_state_get(state, key, 3)) + 1)
			state.set(kind + "_flask_charges", int(_state_get(state, key, 3)))
			_notice(state, _display_kind(kind) + " Flask upgraded: +1 max charge")
		"recovery":
			var recovery_key: String = kind + "_flask_recovery"
			var amount: float = 14.0 if kind == "health" else 11.0
			state.set(recovery_key, float(_state_get(state, recovery_key, 50.0)) + amount)
			_notice(state, _display_kind(kind) + " Flask upgraded: stronger recovery")
		_:
			var charges_key: String = kind + "_flask_charges"
			var max_key: String = kind + "_flask_max_charges"
			state.set(charges_key, min(int(_state_get(state, max_key, 3)), int(_state_get(state, charges_key, 0)) + 1))
			_notice(state, _display_kind(kind) + " Flask charge restored")
	state.set(kind + "_flask_upgrades", int(_state_get(state, kind + "_flask_upgrades", 0)) + 1)
	return true

static func make_upgrade_item(state: Object, kind: String = "") -> Dictionary:
	var flask_kind: String = kind.to_lower()
	if flask_kind != "health" and flask_kind != "mana":
		flask_kind = "health" if _rngf(state) < 0.5 else "mana"
	var upgrade_id: String = _random_upgrade_id(state, flask_kind)
	var name: String = _display_kind(flask_kind) + " Flask Upgrade"
	if upgrade_id == "extra_charge":
		name = _display_kind(flask_kind) + " Flask Charge Vessel"
	elif upgrade_id == "recovery":
		name = _display_kind(flask_kind) + " Flask Recovery Core"
	return {
		"uid": "flask_upgrade_" + str(Time.get_ticks_msec()) + "_" + str(randi()),
		"item_type": "flask_upgrade",
		"category": "flask",
		"slot": "flask",
		"rarity": "Magic",
		"name": name,
		"base_type": "Flask Upgrade",
		"flask_kind": flask_kind,
		"upgrade_id": upgrade_id,
		"description": "Use later to improve your single " + flask_kind + " flask.",
		"tags": ["flask", flask_kind, "progression"],
		"inv_w": 1,
		"inv_h": 1,
		"quantity": 1,
		"stack_size": 1,
	}

static func status_text(state: Object) -> String:
	ensure_defaults(state)
	return "HP Flask " + str(int(_state_get(state, "health_flask_charges", 0))) + "/" + str(int(_state_get(state, "health_flask_max_charges", 3))) + "  ·  Mana Flask " + str(int(_state_get(state, "mana_flask_charges", 0))) + "/" + str(int(_state_get(state, "mana_flask_max_charges", 3)))

static func _add_flask_progress(state: Object, kind: String, amount: float) -> void:
	var progress_key: String = kind + "_flask_kill_progress"
	var charges_key: String = kind + "_flask_charges"
	var max_key: String = kind + "_flask_max_charges"
	var progress: float = float(_state_get(state, progress_key, 0.0)) + amount
	var charges: int = int(_state_get(state, charges_key, 0))
	var max_charges: int = int(_state_get(state, max_key, 3))
	while progress >= 1.0 and charges < max_charges:
		progress -= 1.0
		charges += 1
	state.set(progress_key, clampf(progress, 0.0, 0.999))
	state.set(charges_key, clampi(charges, 0, max_charges))

static func _random_upgrade_id(state: Object, _kind: String) -> String:
	return "extra_charge" if _rngf(state) < 0.38 else "recovery"

static func _display_kind(kind: String) -> String:
	return "Health" if kind == "health" else "Mana"

static func _rngf(state: Object) -> float:
	if state != null:
		var rng_value: Variant = state.get("rng")
		if rng_value is RandomNumberGenerator:
			return (rng_value as RandomNumberGenerator).randf()
	return randf()

static func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	return fallback if value == null else value

static func _state_set_if_missing(state: Object, key: String, value: Variant) -> void:
	if state.get(key) == null:
		state.set(key, value)

static func _notice(state: Object, text: String) -> void:
	if state != null and state.has_method("add_notice"):
		state.call("add_notice", text)


# Patch 082C: called by CombatArena when an enemy dies.
# Kept Object-typed on purpose so class registration cannot break on load order.
static func on_enemy_killed(state: Object, enemy: Object = null) -> void:
	if state == null:
		return
	ensure_defaults(state)
	var charge_gain: int = 1
	if enemy != null and is_instance_valid(enemy):
		var elite_value: Variant = enemy.get("is_elite")
		var boss_value: Variant = enemy.get("is_map_boss")
		if bool(elite_value):
			charge_gain += 1
		if bool(boss_value):
			charge_gain += 3
	_rf082c_add_charge_pair(state, charge_gain)

static func _rf082c_add_charge_pair(state: Object, amount: int) -> void:
	_rf082c_add_charge_flexible(state, "health", amount)
	_rf082c_add_charge_flexible(state, "mana", amount)

static func _rf082c_add_charge_flexible(state: Object, flask_id: String, amount: int) -> void:
	if state == null or amount <= 0:
		return
	var prefixes: Array[String] = []
	if flask_id == "health":
		prefixes = ["health_flask", "flask_health"]
	else:
		prefixes = ["mana_flask", "flask_mana"]
	for prefix: String in prefixes:
		var charges_key: String = prefix + "_charges"
		var max_key: String = prefix + "_max_charges"
		var charges_value: Variant = _rf082c_state_get(state, charges_key, null)
		var max_value: Variant = _rf082c_state_get(state, max_key, null)
		if charges_value != null or max_value != null:
			var max_charges: int = max(1, int(max_value if max_value != null else 3))
			var charges: int = clampi(int(charges_value if charges_value != null else max_charges), 0, max_charges)
			state.set(charges_key, clampi(charges + amount, 0, max_charges))
			return
	# Canonical fallback used by the current visible FlaskHUD pass.
	var fallback_prefix: String = "health_flask" if flask_id == "health" else "mana_flask"
	var fallback_charges_key: String = fallback_prefix + "_charges"
	var fallback_max_key: String = fallback_prefix + "_max_charges"
	var fallback_max: int = max(1, int(_rf082c_state_get(state, fallback_max_key, 3)))
	state.set(fallback_max_key, fallback_max)
	state.set(fallback_charges_key, clampi(int(_rf082c_state_get(state, fallback_charges_key, fallback_max)) + amount, 0, fallback_max))

static func _rf082c_set_if_missing(state: Object, key: String, value: Variant) -> void:
	if state == null:
		return
	if _rf082c_state_get(state, key, null) == null:
		state.set(key, value)

static func _rf082c_state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	return fallback if value == null else value
