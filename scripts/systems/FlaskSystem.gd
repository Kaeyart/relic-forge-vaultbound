class_name RVFlaskSystem
extends RefCounted

const HEALTH_FLASK_KEY: String = "health"
const MANA_FLASK_KEY: String = "mana"

static func ensure_defaults(state: Object) -> void:
	if state == null:
		return
	_set_if_missing(state, "health_flask_max_charges", 3)
	_set_if_missing(state, "health_flask_charges", int(state.get("health_flask_max_charges")))
	_set_if_missing(state, "health_flask_heal_ratio", 0.45)
	_set_if_missing(state, "mana_flask_max_charges", 3)
	_set_if_missing(state, "mana_flask_charges", int(state.get("mana_flask_max_charges")))
	_set_if_missing(state, "mana_flask_restore_ratio", 0.55)
	_set_if_missing(state, "flask_kill_refill_counter", 0)
	state.set("health_flask_max_charges", max(1, int(state.get("health_flask_max_charges"))))
	state.set("mana_flask_max_charges", max(1, int(state.get("mana_flask_max_charges"))))
	state.set("health_flask_charges", clampi(int(state.get("health_flask_charges")), 0, int(state.get("health_flask_max_charges"))))
	state.set("mana_flask_charges", clampi(int(state.get("mana_flask_charges")), 0, int(state.get("mana_flask_max_charges"))))

static func refill_all(state: Object) -> void:
	ensure_defaults(state)
	state.set("health_flask_charges", int(state.get("health_flask_max_charges")))
	state.set("mana_flask_charges", int(state.get("mana_flask_max_charges")))

static func use_health(state: Object) -> bool:
	ensure_defaults(state)
	var hp: float = float(state.get("player_hp"))
	var max_hp: float = max(1.0, float(state.get("max_hp")))
	if hp >= max_hp - 0.5:
		_notice(state, "Health flask not needed")
		return false
	var charges: int = int(state.get("health_flask_charges"))
	if charges <= 0:
		_notice(state, "Health flask empty")
		return false
	state.set("health_flask_charges", charges - 1)
	var amount: float = max_hp * float(state.get("health_flask_heal_ratio"))
	state.set("player_hp", min(max_hp, hp + amount))
	_notice(state, "Health flask used (" + str(int(state.get("health_flask_charges"))) + "/" + str(int(state.get("health_flask_max_charges"))) + ")")
	return true

static func use_mana(state: Object) -> bool:
	ensure_defaults(state)
	var mana: float = float(state.get("player_mana"))
	var max_mana: float = max(1.0, float(state.get("max_mana")))
	if mana >= max_mana - 0.5:
		_notice(state, "Mana flask not needed")
		return false
	var charges: int = int(state.get("mana_flask_charges"))
	if charges <= 0:
		_notice(state, "Mana flask empty")
		return false
	state.set("mana_flask_charges", charges - 1)
	var amount: float = max_mana * float(state.get("mana_flask_restore_ratio"))
	state.set("player_mana", min(max_mana, mana + amount))
	_notice(state, "Mana flask used (" + str(int(state.get("mana_flask_charges"))) + "/" + str(int(state.get("mana_flask_max_charges"))) + ")")
	return true

static func on_enemy_killed(state: Object, enemy: Object = null) -> void:
	ensure_defaults(state)
	var refill_score: int = 1
	if enemy != null:
		var elite_value: Variant = enemy.get("is_elite")
		var boss_value: Variant = enemy.get("is_map_boss")
		if bool(elite_value):
			refill_score += 1
		if bool(boss_value):
			refill_score += 3
	var counter: int = int(state.get("flask_kill_refill_counter")) + refill_score
	var gained: int = 0
	while counter >= 4:
		counter -= 4
		gained += 1
	state.set("flask_kill_refill_counter", counter)
	if gained <= 0:
		return
	var health: int = min(int(state.get("health_flask_max_charges")), int(state.get("health_flask_charges")) + gained)
	var mana: int = min(int(state.get("mana_flask_max_charges")), int(state.get("mana_flask_charges")) + gained)
	state.set("health_flask_charges", health)
	state.set("mana_flask_charges", mana)

static func hud_text(state: Object) -> String:
	ensure_defaults(state)
	return "Flasks: Z HP " + str(int(state.get("health_flask_charges"))) + "/" + str(int(state.get("health_flask_max_charges"))) + " | X Mana " + str(int(state.get("mana_flask_charges"))) + "/" + str(int(state.get("mana_flask_max_charges"))) + " | T Portal"

static func _set_if_missing(state: Object, key: String, value: Variant) -> void:
	if state.get(key) == null:
		state.set(key, value)

static func _notice(state: Object, text: String) -> void:
	if state != null and state.has_method("add_notice"):
		state.call("add_notice", text)
