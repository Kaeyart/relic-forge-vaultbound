class_name RVProgressionRewardSystem
extends RefCounted

# Patch 082A: makes progression/drops visible and trustworthy.
# This deliberately complements existing RVProgressionSystem/RVLootDropSystem instead of replacing them.

static func award_enemy_kill(state: Object, enemy: Node, activity: Dictionary = {}) -> void:
	if state == null or enemy == null:
		return
	var level: int = enemy_level(state, enemy, activity)
	var elite: bool = _bool_prop(enemy, "is_elite", false)
	var boss: bool = _bool_prop(enemy, "is_map_boss", false) or str(enemy.get("role")).to_lower() == "boss"
	var xp_amount: float = xp_for_enemy(level, elite, boss)
	if state.has_method("add_xp"):
		state.call("add_xp", xp_amount)
	award_skill_gem_xp(state, xp_amount * 0.72)
	RVFlaskSystem.award_kill_charge_progress(state, level, elite, boss)
	maybe_award_sanity_drops(state, enemy, activity, level, elite, boss)

static func enemy_level(state: Object, enemy: Node, activity: Dictionary = {}) -> int:
	var base_level: int = max(1, int(_state_get(state, "level", 1)))
	var map_item: Dictionary = Dictionary(activity.get("map", {}))
	if not map_item.is_empty():
		base_level = max(base_level, int(map_item.get("map_level", map_item.get("item_level", base_level))))
	var explicit_level: Variant = enemy.get("level")
	if typeof(explicit_level) == TYPE_INT or typeof(explicit_level) == TYPE_FLOAT:
		base_level = max(base_level, int(explicit_level))
	return max(1, base_level)

static func xp_for_enemy(level: int, elite: bool, boss: bool) -> float:
	var amount: float = 8.0 + float(level) * 2.2
	if elite:
		amount *= 2.35
	if boss:
		amount *= 7.5
	return amount

static func award_skill_gem_xp(state: Object, amount: float) -> void:
	if amount <= 0.0:
		return
	var multiplier: float = float(_state_get(state, "gem_xp_gain_multiplier", 1.0))
	var final_amount: float = amount * multiplier
	var any_level: bool = false
	var skill_gems: Array = Array(_state_get(state, "skill_gem_inventory", []))
	for i: int in range(skill_gems.size()):
		if typeof(skill_gems[i]) != TYPE_DICTIONARY:
			continue
		var gem: Dictionary = Dictionary(skill_gems[i])
		if bool(gem.get("equipped", false)):
			if _add_xp_to_gem(gem, final_amount):
				any_level = true
			skill_gems[i] = gem
	state.set("skill_gem_inventory", skill_gems)

	var spirit_gems: Array = Array(_state_get(state, "spirit_gem_inventory", []))
	for j: int in range(spirit_gems.size()):
		if typeof(spirit_gems[j]) != TYPE_DICTIONARY:
			continue
		var spirit: Dictionary = Dictionary(spirit_gems[j])
		if bool(spirit.get("enabled", false)):
			if _add_xp_to_gem(spirit, final_amount * 0.65):
				any_level = true
			spirit_gems[j] = spirit
	state.set("spirit_gem_inventory", spirit_gems)

	if any_level and state.has_method("recompute_stats"):
		state.call("recompute_stats")
	if any_level and state.has_method("add_notice"):
		state.call("add_notice", "Skill gem leveled up")

static func maybe_award_sanity_drops(state: Object, enemy: Node, activity: Dictionary, level: int, elite: bool, boss: bool) -> void:
	var rng: RandomNumberGenerator = _rng(state)
	var kind: String = str(activity.get("kind", ""))
	var map_bonus: float = 0.018 if kind == "map" else 0.0
	# Gear sanity: elites/bosses should regularly prove itemization is alive.
	var gear_chance: float = 0.035 + map_bonus
	if elite:
		gear_chance = 0.35
	if boss:
		gear_chance = 1.0
	if rng.randf() < gear_chance:
		_add_scaled_item_drop(state, level + (2 if elite else 0) + (4 if boss else 0), boss)
	# Gem sanity: early maps should visibly produce gems sometimes.
	var gem_chance: float = 0.010 + map_bonus
	if elite:
		gem_chance = 0.11
	if boss:
		gem_chance = 0.55
	if rng.randf() < gem_chance:
		RVSkillGemSystem.award_random_gem_drop(state, level)
	# Flask upgrade sanity: rare but visible.
	var flask_chance: float = 0.006 + map_bonus * 0.5
	if elite:
		flask_chance = 0.035
	if boss:
		flask_chance = 0.18
	if rng.randf() < flask_chance:
		var upgrade: Dictionary = RVFlaskSystem.make_upgrade_item(state)
		var backpack: Array = Array(_state_get(state, "backpack", []))
		backpack.append(upgrade)
		state.set("backpack", backpack)
		_notice(state, "Flask upgrade dropped: " + str(upgrade.get("name", "Flask Upgrade")))

static func _add_scaled_item_drop(state: Object, item_level: int, boss: bool) -> void:
	var item: Dictionary = RVItemDB.generate_drop(state, max(1, item_level))
	if boss:
		item["drop_source"] = "map_boss"
		item["forge_potential"] = int(item.get("forge_potential", 12)) + 4
	var backpack: Array = Array(_state_get(state, "backpack", []))
	backpack.append(item)
	state.set("backpack", backpack)
	_notice(state, "Item dropped: " + str(item.get("name", "Item")))

static func _add_fallback_gem_drop(state: Object, rng: RandomNumberGenerator) -> void:
	var gem_ids: Array[String] = ["fireball", "cleave", "frost_nova", "storm_lance", "void_rift", "blade_trap"]
	var gem_id: String = gem_ids[rng.randi_range(0, gem_ids.size() - 1)]
	var data: Dictionary = RVSkillGemDB.active_data(gem_id)
	var inv: Array = Array(_state_get(state, "skill_gem_inventory", []))
	inv.append({
		"uid": "active_drop_" + str(Time.get_ticks_msec()) + "_" + str(randi()),
		"type": "active",
		"gem_id": gem_id,
		"name": str(data.get("name", gem_id.capitalize())),
		"skill_id": str(data.get("skill_id", data.get("name", gem_id))),
		"level": 1,
		"xp": 0.0,
		"max_support_sockets": int(data.get("base_sockets", 2)),
		"supports": [],
		"equipped": false,
	})
	state.set("skill_gem_inventory", inv)
	_notice(state, "Skill gem dropped: " + str(data.get("name", gem_id.capitalize())))

static func _add_xp_to_gem(gem: Dictionary, amount: float) -> bool:
	var leveled: bool = false
	var level: int = max(1, int(gem.get("level", 1)))
	var xp: float = float(gem.get("xp", 0.0)) + amount
	while level < 20 and xp >= gem_xp_to_next(level):
		xp -= gem_xp_to_next(level)
		level += 1
		leveled = true
	gem["level"] = level
	gem["xp"] = xp
	return leveled

static func gem_xp_to_next(level: int) -> float:
	return 85.0 + pow(float(max(1, level)), 1.42) * 70.0

static func _bool_prop(node: Object, key: String, fallback: bool) -> bool:
	if node == null:
		return fallback
	var value: Variant = node.get(key)
	return fallback if value == null else bool(value)

static func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	return fallback if value == null else value

static func _rng(state: Object) -> RandomNumberGenerator:
	var value: Variant = _state_get(state, "rng", null)
	if value is RandomNumberGenerator:
		return value as RandomNumberGenerator
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng

static func _notice(state: Object, text: String) -> void:
	if state != null and state.has_method("add_notice"):
		state.call("add_notice", text)
