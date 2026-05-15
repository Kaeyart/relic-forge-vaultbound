class_name RVSkillSystem
extends RefCounted

static func update(state: RVGameState, delta: float) -> void:
	for skill_name: String in state.skill_cooldowns.keys():
		state.skill_cooldowns[skill_name] = max(0.0, float(state.skill_cooldowns[skill_name]) - delta)


static func can_cast(state: RVGameState, skill_name: String) -> bool:
	var skill_data: Dictionary = RVSkillDB.data(skill_name)
	if skill_data.is_empty():
		return false

	if float(state.skill_cooldowns.get(skill_name, 0.0)) > 0.0:
		return false

	if state.player_mana < float(skill_data.get("mana_cost", 0.0)):
		return false

	return true


static func pay_cost(state: RVGameState, skill_name: String) -> Dictionary:
	var skill_data: Dictionary = RVSkillDB.data(skill_name)
	var mana_cost: float = float(skill_data.get("mana_cost", 0.0))
	var cooldown: float = float(skill_data.get("cooldown", 0.5))

	state.player_mana -= mana_cost
	state.skill_cooldowns[skill_name] = cooldown

	return skill_data


static func skill_damage(state: RVGameState, skill_name: String) -> float:
	var skill_data: Dictionary = RVSkillDB.data(skill_name)
	var value: float = float(skill_data.get("damage", 10.0))
	var rank: int = int(state.skill_ranks.get(skill_name, 0))

	value *= 1.0 + float(rank) * 0.08

	for slot_name: String in state.equipped.keys():
		var item_value: Variant = state.equipped[slot_name]
		if typeof(item_value) != TYPE_DICTIONARY:
			continue

		var item: Dictionary = item_value
		var stats: Dictionary = item.get("stats", {})
		value *= 1.0 + float(stats.get("Global Damage", 0.0))
		value *= 1.0 + float(stats.get("Spell Damage", 0.0))

		for tag: Variant in RVSkillDB.tags(skill_name):
			var stat_key: String = str(tag) + " Damage"
			value *= 1.0 + float(stats.get(stat_key, 0.0))

	return value


static func toggle_skill_loadout(state: RVGameState, skill_name: String) -> void:
	if not state.unlocked_skills.has(skill_name):
		return

	if state.active_skills.has(skill_name):
		if state.active_skills.size() <= 1:
			state.add_notice("Keep at least one skill")
			return
		state.active_skills.erase(skill_name)
		state.add_notice(skill_name + " removed")
	else:
		if state.active_skills.size() >= 6:
			state.add_notice("Skill bar full")
			return
		state.active_skills.append(skill_name)
		state.add_notice(skill_name + " added")

	state.selected_skill_index = clamp(state.selected_skill_index, 0, state.active_skills.size() - 1)
