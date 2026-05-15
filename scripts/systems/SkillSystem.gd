class_name RVSkillSystem
extends RefCounted

static func update(state: RVGameState, delta: float) -> void:
	for skill_name: String in state.skill_cooldowns.keys():
		state.skill_cooldowns[skill_name] = max(0.0, float(state.skill_cooldowns[skill_name]) - delta)

static func can_cast(state: RVGameState, skill_name: String) -> bool:
	var skill_data: Dictionary = effective_skill_data(state, skill_name)
	if skill_data.is_empty():
		return false
	if float(state.skill_cooldowns.get(skill_name, 0.0)) > 0.0:
		return false
	if state.player_mana < float(skill_data.get("mana_cost", 0.0)):
		return false
	return true

static func pay_cost(state: RVGameState, skill_name: String) -> Dictionary:
	var skill_data: Dictionary = effective_skill_data(state, skill_name)
	var mana_cost: float = float(skill_data.get("mana_cost", 0.0))
	var cooldown: float = float(skill_data.get("cooldown", 0.5))
	state.player_mana -= mana_cost
	state.skill_cooldowns[skill_name] = cooldown
	return skill_data

static func effective_skill_data(state: RVGameState, skill_name: String) -> Dictionary:
	var base_data: Dictionary = RVSkillDB.data(skill_name)
	if base_data.is_empty():
		return {}
	var skill_data: Dictionary = RVSkillGemSystem.get_supported_skill_data(state, skill_name, base_data).duplicate(true)
	var tags: Array = skill_data.get("tags", RVSkillDB.tags(skill_name)).duplicate(true)
	var flags: Array[String] = RVItemDB.build_flags_from_equipped(state)
	if skill_name == "Fireball" and flags.has("fireball_void_conversion"):
		_add_tag(tags, "Void")
		skill_data["damage"] = float(skill_data.get("damage", 10.0)) * 1.08
	if skill_name == "Cleave" and flags.has("cleave_fire_conversion"):
		_add_tag(tags, "Fire")
	if skill_name == "Cleave" and flags.has("cleave_larger_area"):
		skill_data["radius"] = float(skill_data.get("radius", 76.0)) * 1.22
	if skill_name == "Blade Trap" and flags.has("blade_trap_void_conversion"):
		_add_tag(tags, "Void")
		skill_data["damage"] = float(skill_data.get("damage", 10.0)) * 1.06
	if skill_name == "Void Rift" and flags.has("void_rift_larger"):
		skill_data["radius"] = float(skill_data.get("radius", 92.0)) * 1.28
	if skill_name == "Void Rift" and flags.has("void_rift_cheaper"):
		skill_data["mana_cost"] = float(skill_data.get("mana_cost", 10.0)) * 0.82
	if skill_name == "Storm Lance" and flags.has("storm_lance_cold_conversion"):
		_add_tag(tags, "Cold")
	if skill_name == "Storm Lance" and flags.has("storm_lance_extra_radius"):
		skill_data["radius"] = float(skill_data.get("radius", 6.0)) + 3.0
	if flags.has("support_gem_resonance"):
		skill_data["damage"] = float(skill_data.get("damage", 10.0)) * 1.06
	skill_data["tags"] = tags
	return skill_data

static func skill_damage(state: RVGameState, skill_name: String) -> float:
	var skill_data: Dictionary = effective_skill_data(state, skill_name)
	var value: float = float(skill_data.get("damage", 10.0))
	var rank: int = int(state.skill_ranks.get(skill_name, 0))
	value *= 1.0 + float(rank) * 0.08
	for slot_name: String in state.equipped.keys():
		var item_value: Variant = state.equipped[slot_name]
		if typeof(item_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = RVItemDB.normalize_item(item_value)
		var stats: Dictionary = item.get("stats", {})
		value *= 1.0 + float(stats.get("Global Damage", 0.0))
		value *= 1.0 + float(stats.get("Spell Damage", 0.0))
		for tag: Variant in skill_data.get("tags", RVSkillDB.tags(skill_name)):
			var stat_key: String = str(tag) + " Damage"
			value *= 1.0 + float(stats.get(stat_key, 0.0))
	for spirit_gem: Dictionary in state.spirit_gem_inventory:
		if not bool(spirit_gem.get("enabled", false)):
			continue
		var spirit_data: Dictionary = RVSkillGemDB.spirit_data(str(spirit_gem.get("gem_id", "")))
		var spirit_stats: Dictionary = spirit_data.get("stats", {})
		value *= 1.0 + float(spirit_stats.get("Global Damage", 0.0))
		for tag2: Variant in skill_data.get("tags", RVSkillDB.tags(skill_name)):
			var spirit_stat_key: String = str(tag2) + " Damage"
			value *= 1.0 + float(spirit_stats.get(spirit_stat_key, 0.0))
	return value

static func toggle_skill_loadout(state: RVGameState, skill_name: String) -> void:
	for i: int in range(state.skill_gem_inventory.size()):
		var gem: Dictionary = state.skill_gem_inventory[i]
		if str(gem.get("skill_id", "")) == skill_name:
			state.skill_gem_cursor = i
			RVSkillGemSystem.toggle_selected_active_gem_equipped(state)
			return
	state.add_notice("No skill gem for " + skill_name)

static func _add_tag(tags: Array, tag: String) -> void:
	if not tags.has(tag):
		tags.append(tag)
