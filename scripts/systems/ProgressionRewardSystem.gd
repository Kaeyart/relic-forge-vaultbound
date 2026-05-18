class_name RVProgressionRewardSystem
extends RefCounted

# Patch 084B repair: progression sanity layer with safe numeric conversion.
# Avoids int(value) constructor calls that can crash when patch-era fields contain
# unexpected Variant values.

const BASE_XP_NORMAL: int = 12
const BASE_XP_ELITE: int = 42
const BASE_XP_BOSS: int = 155
const GEM_XP_SHARE: float = 0.72

static func ensure_defaults(state: Object) -> void:
	if state == null:
		return
	_ensure_int_field(state, "level", 1)
	_ensure_int_field(state, "xp", 0)
	_ensure_int_field(state, "xp_to_next", _xp_to_next_level(_as_int(_state_get(state, "level", 1), 1)))
	_ensure_int_field(state, "passive_points", 0)
	_ensure_int_field(state, "passive_refund_points", 0)
	_ensure_int_field(state, "progression_reward_version", 3)

static func award_enemy_kill(state: Object, enemy: Object, activity: Dictionary = {}) -> Dictionary:
	if state == null or enemy == null:
		return {}
	ensure_defaults(state)
	var enemy_level: int = _enemy_level(state, enemy, activity)
	var boss: bool = _obj_bool(enemy, "is_map_boss", false)
	var elite: bool = _obj_bool(enemy, "is_elite", false)
	var base_xp: int = BASE_XP_NORMAL
	if boss:
		base_xp = BASE_XP_BOSS
	elif elite:
		base_xp = BASE_XP_ELITE
	var map_mult: float = 1.0
	if str(activity.get("kind", "")) == "map":
		var map_item: Dictionary = Dictionary(activity.get("map", {}))
		var tier: int = max(1, _as_int(map_item.get("tier", map_item.get("map_tier", 1)), 1))
		map_mult += float(tier - 1) * 0.045
		var rarity: String = str(map_item.get("rarity", "Normal"))
		if rarity == "Magic":
			map_mult += 0.08
		elif rarity == "Rare":
			map_mult += 0.18
		elif rarity == "Unique":
			map_mult += 0.28
	var xp_amount: int = max(1, roundi(float(base_xp + enemy_level * 3) * map_mult))
	var levelups: int = _award_character_xp(state, xp_amount)
	var gem_xp: int = max(1, roundi(float(xp_amount) * GEM_XP_SHARE))
	var gem_levelups: int = _award_equipped_gem_xp(state, gem_xp, boss or elite)
	if levelups > 0:
		_notice(state, "Level up! Level " + str(_as_int(_state_get(state, "level", 1), 1)))
	elif boss:
		_notice(state, "+" + str(xp_amount) + " XP · boss defeated")
	if gem_levelups > 0:
		_notice(state, "Skill gem level up x" + str(gem_levelups))
	return {"xp": xp_amount, "gem_xp": gem_xp, "levelups": levelups, "gem_levelups": gem_levelups, "enemy_level": enemy_level}

static func _award_character_xp(state: Object, amount: int) -> int:
	var level: int = _as_int(_state_get(state, "level", 1), 1)
	var xp: int = _as_int(_state_get(state, "xp", _state_get(state, "player_xp", 0)), 0)
	var next: int = max(1, _as_int(_state_get(state, "xp_to_next", _xp_to_next_level(level)), _xp_to_next_level(level)))
	xp += max(0, amount)
	var levelups: int = 0
	while xp >= next and level < 100:
		xp -= next
		level += 1
		levelups += 1
		next = _xp_to_next_level(level)
	_set_if_possible(state, "level", level)
	_set_if_possible(state, "character_level", level)
	_set_if_possible(state, "xp", xp)
	_set_if_possible(state, "player_xp", xp)
	_set_if_possible(state, "xp_to_next", next)
	_set_if_possible(state, "player_xp_to_next", next)
	if levelups > 0:
		var passive_points: int = _as_int(_state_get(state, "passive_points", 0), 0) + levelups
		_set_if_possible(state, "passive_points", passive_points)
		var atlas_points: int = _as_int(_state_get(state, "atlas_points", 0), 0)
		_set_if_possible(state, "atlas_points", atlas_points)
		if state.has_method("recompute_stats"):
			state.call("recompute_stats")
	return levelups

static func _award_equipped_gem_xp(state: Object, amount: int, include_bonus: bool = false) -> int:
	var active_skills: Array = Array(_state_get(state, "active_skills", []))
	var leveled: int = 0
	leveled += _award_gem_array_xp(state, "skill_gem_inventory", active_skills, amount, include_bonus)
	leveled += _award_gem_array_xp(state, "support_gem_inventory", active_skills, max(1, roundi(float(amount) * 0.55)), include_bonus)
	leveled += _award_gem_array_xp(state, "spirit_gem_inventory", active_skills, max(1, roundi(float(amount) * 0.55)), include_bonus)
	return leveled

static func _award_gem_array_xp(state: Object, key: String, active_skills: Array, amount: int, include_bonus: bool) -> int:
	var arr_value: Variant = _state_get(state, key, [])
	if typeof(arr_value) != TYPE_ARRAY:
		return 0
	var arr: Array = Array(arr_value)
	if arr.is_empty():
		return 0
	var leveled: int = 0
	for i: int in range(arr.size()):
		if typeof(arr[i]) != TYPE_DICTIONARY:
			continue
		var gem: Dictionary = Dictionary(arr[i])
		if not _gem_is_equipped_or_active(gem, active_skills, key):
			continue
		var xp_gain: int = amount
		if include_bonus:
			xp_gain = roundi(float(xp_gain) * 1.20)
		var level: int = _as_int(gem.get("level", gem.get("gem_level", 1)), 1)
		var xp: int = _as_int(gem.get("xp", gem.get("gem_xp", 0)), 0) + max(1, xp_gain)
		var required: int = max(1, _as_int(gem.get("required_xp", gem.get("xp_to_next", _gem_xp_to_next(level))), _gem_xp_to_next(level)))
		while xp >= required and level < 20:
			xp -= required
			level += 1
			leveled += 1
			required = _gem_xp_to_next(level)
		gem["level"] = level
		gem["gem_level"] = level
		gem["xp"] = xp
		gem["gem_xp"] = xp
		gem["required_xp"] = required
		gem["xp_to_next"] = required
		arr[i] = gem
	_set_if_possible(state, key, arr)
	return leveled

static func _gem_is_equipped_or_active(gem: Dictionary, active_skills: Array, source_key: String) -> bool:
	if bool(gem.get("equipped", false)) or bool(gem.get("enabled", false)):
		return true
	if source_key == "spirit_gem_inventory" and bool(gem.get("active", false)):
		return true
	var name: String = str(gem.get("name", gem.get("skill", gem.get("skill_name", ""))))
	if name != "" and active_skills.has(name):
		return true
	return false

static func _enemy_level(state: Object, enemy: Object, activity: Dictionary) -> int:
	var enemy_level: int = _as_int(_obj_get(enemy, "level", 0), 0)
	if enemy_level > 0:
		return enemy_level
	var map_item: Dictionary = Dictionary(activity.get("map", {}))
	if not map_item.is_empty():
		return max(1, _as_int(map_item.get("map_level", map_item.get("area_level", map_item.get("item_level", _state_get(state, "level", 1)))), 1))
	return max(1, _as_int(_state_get(state, "level", 1), 1))

static func _xp_to_next_level(level: int) -> int:
	var safe_level: int = max(1, level)
	return roundi(110.0 + pow(float(safe_level), 1.72) * 42.0)

static func _gem_xp_to_next(level: int) -> int:
	var safe_level: int = max(1, level)
	return roundi(85.0 + pow(float(safe_level), 1.55) * 35.0)

static func _ensure_int_field(state: Object, key: String, fallback: int) -> void:
	var value: Variant = _state_get(state, key, null)
	if value == null:
		_set_if_possible(state, key, fallback)

static func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	return fallback if value == null else value

static func _set_if_possible(state: Object, key: String, value: Variant) -> void:
	if state == null:
		return
	state.set(key, value)

static func _obj_get(obj: Object, key: String, fallback: Variant = null) -> Variant:
	if obj == null:
		return fallback
	var value: Variant = obj.get(key)
	return fallback if value == null else value

static func _obj_bool(obj: Object, key: String, fallback: bool = false) -> bool:
	return bool(_obj_get(obj, key, fallback))

static func _notice(state: Object, text: String) -> void:
	if state != null and state.has_method("add_notice"):
		state.call("add_notice", text)

static func _as_int(value: Variant, fallback: int = 0) -> int:
	match typeof(value):
		TYPE_INT:
			return value
		TYPE_FLOAT:
			return floori(value)
		TYPE_STRING:
			return str(value).to_int()
		TYPE_BOOL:
			return 1 if value else 0
		_:
			return fallback
