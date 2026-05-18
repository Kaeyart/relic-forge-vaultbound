class_name RVPassiveBuildApplicationSystem
extends RefCounted

# Patch 085Q: connects passive tree output to real combat/build stats.
# This file intentionally uses Object/Dictionary accessors to stay tolerant of
# old saves and patch-era field aliases.

const PassiveTreeSystemScript := preload("res://scripts/systems/PassiveTreeSystem.gd")

static func ensure_defaults(state: Object) -> void:
	if state == null:
		return
	_ensure_dict(state, "passive_stat_bonuses")
	_ensure_array(state, "passive_rules")
	_ensure_dict(state, "passive_build_breakdown")
	if _state_get(state, "passive_damage_summary", null) == null:
		state.set("passive_damage_summary", "")
	if _state_get(state, "passive_cooldown_reduction", null) == null:
		state.set("passive_cooldown_reduction", 0.0)

static func collect_passive_bundle(state: Object) -> Dictionary:
	if state == null:
		return {"stats": {}, "rules": [], "nodes": []}
	PassiveTreeSystemScript.ensure_defaults(state)
	var stats: Dictionary = PassiveTreeSystemScript.aggregate_stats(state)
	var rules: Array[String] = PassiveTreeSystemScript.aggregate_rules(state)
	var nodes: Array[String] = PassiveTreeSystemScript.unlocked_nodes(state)
	return {"stats": stats, "rules": rules, "nodes": nodes}

static func merge_passive_bundle_into_state(state: Object, bundle: Dictionary) -> void:
	if state == null:
		return
	ensure_defaults(state)
	state.set("passive_stat_bonuses", Dictionary(bundle.get("stats", {})).duplicate(true))
	state.set("passive_rules", _string_array(Array(bundle.get("rules", []))))
	state.set("passive_build_breakdown", _build_breakdown(state, bundle))

static func merge_stats(base: Dictionary, add: Dictionary) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	for key_value: Variant in add.keys():
		var key: String = str(key_value)
		out[key] = _as_float(out.get(key, 0.0), 0.0) + _as_float(add[key_value], 0.0)
	return out

static func append_rules(existing: Array, add: Array) -> Array[String]:
	var out: Array[String] = _string_array(existing)
	for value: Variant in add:
		var text: String = str(value)
		if text != "" and not out.has(text):
			out.append(text)
	return out

static func apply_derived_player_stats(state: Object) -> void:
	if state == null:
		return
	ensure_defaults(state)
	var stats: Dictionary = Dictionary(_state_get(state, "build_stats", {}))
	var rules: Array = _all_rules(state)

	var hp: float = _as_float(_state_get(state, "max_hp", 120.0), 120.0)
	var mana: float = _as_float(_state_get(state, "max_mana", 100.0), 100.0)
	var spirit: int = _as_int(_state_get(state, "spirit_max", 30), 30)
	var speed: float = _as_float(_state_get(state, "player_speed", 245.0), 245.0)

	# Percent-style resource bonuses use fractional values, e.g. 0.08 = +8%.
	hp *= 1.0 + _stat(stats, "Maximum Life %") + _stat(stats, "Life %")
	mana *= 1.0 + _stat(stats, "Maximum Mana %") + _stat(stats, "Mana %")
	spirit += int(round(_stat(stats, "Maximum Spirit")))

	if _has_rule_like(rules, ["armor_life", "armor_grants_life", "forge_bound", "forge_bound_body"]):
		# Keystones can make armor create a small life bridge without needing a new stat pipeline.
		hp += max(0.0, _stat(stats, "Armor")) * 0.10
		# The downside keeps it from becoming free generic power.
		speed *= 0.96

	speed *= 1.0 + _stat(stats, "Movement Speed") + _stat(stats, "Movement Speed %")

	var cooldown_reduction: float = clampf(_stat(stats, "Cooldown Reduction") + _stat(stats, "Cooldown Recovery") + _stat(stats, "Cooldown Reduction %"), 0.0, 0.65)

	state.set("max_hp", max(1.0, hp))
	state.set("max_mana", max(1.0, mana))
	state.set("spirit_max", max(0, spirit))
	state.set("player_speed", clampf(speed, 120.0, 520.0))
	state.set("passive_cooldown_reduction", cooldown_reduction)
	state.set("passive_damage_summary", damage_summary_for_state(state))

static func augment_skill_tags(state: Object, skill_name: String, tags: Array) -> Array:
	var out: Array = tags.duplicate(true)
	var rules: Array = _all_rules(state)
	var flags: Array = _all_flags(state)
	var lower_skill: String = skill_name.to_lower()

	if lower_skill.contains("fire") or lower_skill == "fireball":
		_add_tag(out, "Fire")
		if _has_rule_like(rules, ["burn", "ignite", "cinder"]):
			_add_tag(out, "inflicts_burn")

	if lower_skill.contains("storm") or lower_skill.contains("lance"):
		_add_tag(out, "Lightning")
		if _has_rule_like(rules, ["storm", "chain", "conduit"]) or _has_flag_like(flags, ["storm", "chain"]):
			_add_tag(out, "chain_plus")
			_add_tag(out, "shock_pressure")

	if lower_skill.contains("void") or lower_skill.contains("rift"):
		_add_tag(out, "Void")
		if _has_rule_like(rules, ["void", "rift", "debt", "echo"]) or _has_flag_like(flags, ["void", "rift"]):
			_add_tag(out, "void_echo")
			_add_tag(out, "inflicts_curse")

	if lower_skill.contains("trap"):
		_add_tag(out, "Trap")
		if _has_rule_like(rules, ["trap", "echo", "repeat"]):
			_add_tag(out, "secondary_trap_tick")

	if lower_skill.contains("cleave"):
		_add_tag(out, "Melee")
		_add_tag(out, "Attack")
		if _has_rule_like(rules, ["bleed", "blood"]):
			_add_tag(out, "Bleed")
			_add_tag(out, "inflicts_bleed")
		if _has_rule_like(rules, ["blood_ignition", "fire_bleed", "ignite"]):
			_add_tag(out, "Fire")
			_add_tag(out, "inflicts_burn")

	return out

static func modify_skill_damage(state: Object, skill_name: String, base_damage: float, tags: Array = []) -> float:
	if state == null:
		return base_damage
	var stats: Dictionary = Dictionary(_state_get(state, "build_stats", {}))
	var rules: Array = _all_rules(state)
	var flags: Array = _all_flags(state)
	var lower_skill: String = skill_name.to_lower()
	var multiplier: float = 1.0

	multiplier += _stat(stats, "Damage")
	multiplier += _stat(stats, "Global Damage")
	multiplier += _stat(stats, "All Damage")

	if _is_spell_skill(lower_skill, tags):
		multiplier += _stat(stats, "Spell Damage") + _stat(stats, "Spell Damage %")
	if _is_attack_skill(lower_skill, tags):
		multiplier += _stat(stats, "Attack Damage") + _stat(stats, "Attack Damage %")
	if _has_tag(tags, "Melee") or lower_skill.contains("cleave"):
		multiplier += _stat(stats, "Melee Damage")
	if _has_tag(tags, "Trap") or lower_skill.contains("trap"):
		multiplier += _stat(stats, "Trap Damage")

	if _has_tag(tags, "Fire") or lower_skill.contains("fire"):
		multiplier += _stat(stats, "Fire Damage") + _stat(stats, "Elemental Damage")
	if _has_tag(tags, "Lightning") or lower_skill.contains("storm") or lower_skill.contains("lance"):
		multiplier += _stat(stats, "Lightning Damage") + _stat(stats, "Elemental Damage")
	if _has_tag(tags, "Cold") or lower_skill.contains("frost"):
		multiplier += _stat(stats, "Cold Damage") + _stat(stats, "Elemental Damage")
	if _has_tag(tags, "Void") or lower_skill.contains("void") or lower_skill.contains("rift"):
		multiplier += _stat(stats, "Void Damage")
	if _has_tag(tags, "Bleed"):
		multiplier += _stat(stats, "Bleed Damage") + _stat(stats, "Physical Damage")

	if lower_skill.contains("storm") and _has_rule_like(rules, ["storm", "conduit"]):
		multiplier += 0.08
	if lower_skill.contains("void") and _has_rule_like(rules, ["void", "debt", "rift"]):
		multiplier += 0.10
	if lower_skill.contains("trap") and _has_rule_like(rules, ["trap", "echo"]):
		multiplier += 0.08
	if _has_rule_like(rules, ["blood_ignition", "fire_bleed"]) and (_has_tag(tags, "Fire") or _has_tag(tags, "Bleed")):
		multiplier += 0.07
	if _has_flag_like(flags, ["cleave_fire_conversion"]) and lower_skill.contains("cleave"):
		multiplier += _stat(stats, "Fire Damage") * 0.55
	if _has_flag_like(flags, ["fireball_void_conversion"]) and lower_skill.contains("fireball"):
		multiplier += _stat(stats, "Void Damage") * 0.55

	return max(0.0, base_damage * max(0.05, multiplier))

static func damage_summary_for_state(state: Object) -> String:
	var stats: Dictionary = Dictionary(_state_get(state, "build_stats", {}))
	var parts: Array[String] = []
	for key: String in ["Fire Damage", "Lightning Damage", "Void Damage", "Melee Damage", "Trap Damage", "Spell Damage", "Attack Damage", "Movement Speed", "Cooldown Reduction"]:
		var amount: float = _stat(stats, key)
		if abs(amount) > 0.0001:
			parts.append(key + " " + _format_percent(amount))
	if parts.is_empty():
		return "No passive build bonuses yet."
	return " · ".join(PackedStringArray(parts))

static func _build_breakdown(state: Object, bundle: Dictionary) -> Dictionary:
	var stats: Dictionary = Dictionary(bundle.get("stats", {}))
	var rules: Array = Array(bundle.get("rules", []))
	var out: Dictionary = {
		"node_count": Array(bundle.get("nodes", [])).size(),
		"stats": stats.duplicate(true),
		"rules": _string_array(rules),
		"summary": ""
	}
	var summary_parts: Array[String] = []
	for key_value: Variant in stats.keys():
		var key: String = str(key_value)
		var value: float = _as_float(stats[key_value], 0.0)
		if abs(value) > 0.0001:
			summary_parts.append(key + " " + _format_amount(value))
	out["summary"] = " · ".join(PackedStringArray(summary_parts)) if not summary_parts.is_empty() else "No passive stats allocated."
	return out

static func _all_rules(state: Object) -> Array:
	var result: Array = []
	for value: Variant in Array(_state_get(state, "passive_rules", [])):
		_add_unique(result, str(value))
	for value: Variant in Array(_state_get(state, "build_flags", [])):
		_add_unique(result, str(value))
	return result

static func _all_flags(state: Object) -> Array:
	var result: Array = []
	for value: Variant in Array(_state_get(state, "build_flags", [])):
		_add_unique(result, str(value))
	return result

static func _is_spell_skill(lower_skill: String, tags: Array) -> bool:
	return _has_tag(tags, "Spell") or lower_skill.contains("fire") or lower_skill.contains("frost") or lower_skill.contains("storm") or lower_skill.contains("void") or lower_skill.contains("rift")

static func _is_attack_skill(lower_skill: String, tags: Array) -> bool:
	return _has_tag(tags, "Attack") or _has_tag(tags, "Melee") or lower_skill.contains("cleave")

static func _has_tag(tags: Array, tag: String) -> bool:
	var want: String = tag.to_lower()
	for value: Variant in tags:
		if str(value).to_lower() == want:
			return true
	return false

static func _add_tag(tags: Array, tag: String) -> void:
	if tag == "":
		return
	if not _has_tag(tags, tag):
		tags.append(tag)

static func _has_rule_like(rules: Array, needles: Array) -> bool:
	for value: Variant in rules:
		var text: String = str(value).to_lower()
		for needle_value: Variant in needles:
			if text.find(str(needle_value).to_lower()) >= 0:
				return true
	return false

static func _has_flag_like(flags: Array, needles: Array) -> bool:
	return _has_rule_like(flags, needles)

static func _stat(stats: Dictionary, key: String) -> float:
	if stats.has(key):
		return _as_float(stats[key], 0.0)
	# Common aliases from older item/passive code.
	var aliases: Dictionary = {
		"Spell Damage": ["Spell Damage %"],
		"Attack Damage": ["Attack Damage %"],
		"Movement Speed": ["Movement Speed %"],
		"Maximum Life %": ["Life %"],
		"Maximum Mana %": ["Mana %"]
	}
	for alias_value: Variant in Array(aliases.get(key, [])):
		var alias: String = str(alias_value)
		if stats.has(alias):
			return _as_float(stats[alias], 0.0)
	return 0.0

static func _ensure_dict(state: Object, key: String) -> void:
	if typeof(_state_get(state, key, null)) != TYPE_DICTIONARY:
		state.set(key, {})

static func _ensure_array(state: Object, key: String) -> void:
	if typeof(_state_get(state, key, null)) != TYPE_ARRAY:
		state.set(key, [])

static func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	return fallback if value == null else value

static func _as_float(value: Variant, fallback: float = 0.0) -> float:
	match typeof(value):
		TYPE_FLOAT:
			return value
		TYPE_INT:
			return float(value)
		TYPE_STRING:
			var text: String = str(value)
			return float(text) if text.is_valid_float() else fallback
		_:
			return fallback

static func _as_int(value: Variant, fallback: int = 0) -> int:
	match typeof(value):
		TYPE_INT:
			return value
		TYPE_FLOAT:
			return int(value)
		TYPE_STRING:
			var text: String = str(value)
			return int(text) if text.is_valid_int() else fallback
		_:
			return fallback

static func _string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value: Variant in values:
		var text: String = str(value)
		if text != "" and not out.has(text):
			out.append(text)
	return out

static func _add_unique(values: Array, text: String) -> void:
	if text != "" and not values.has(text):
		values.append(text)

static func _format_percent(amount: float) -> String:
	return "+" + str(snappedf(amount * 100.0, 0.1)) + "%"

static func _format_amount(amount: float) -> String:
	if abs(amount) < 1.0:
		return _format_percent(amount)
	return "+" + str(int(round(amount)))
