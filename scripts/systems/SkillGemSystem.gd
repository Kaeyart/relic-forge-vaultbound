class_name RVSkillGemSystem
extends RefCounted

static func rebuild(state: RVGameState) -> void:
	for skill in RVSkillGemDB.active_skill_names():
		if not state.skill_gems.has(skill):
			state.skill_gems[skill] = {"id": skill, "level": 1, "sockets": 2, "supports": []}
		var gem: Dictionary = state.skill_gems[skill]
		if not gem.has("supports") or typeof(gem["supports"]) != TYPE_ARRAY:
			gem["supports"] = []
		if not gem.has("sockets"):
			gem["sockets"] = 2
		state.skill_gems[skill] = gem

	var valid_active: Array = []
	for skill2 in state.active_skills:
		if state.skill_gems.has(skill2) and not valid_active.has(skill2):
			valid_active.append(skill2)
	if valid_active.size() == 0:
		valid_active = ["Fireball", "Cleave"]
	state.active_skills = valid_active
	state.selected_skill = clamp(state.selected_skill, 0, state.active_skills.size() - 1)

	state.spirit_reserved = 0
	state.spirit_bonuses = {}
	for spirit in state.spirit_gems.keys():
		var entry: Dictionary = state.spirit_gems[spirit]
		if bool(entry.get("enabled", false)):
			var data: Dictionary = RVSkillGemDB.spirit_data(spirit)
			var reservation: int = int(data.get("reservation", 0))
			if state.spirit_reserved + reservation <= state.spirit_max:
				state.spirit_reserved += reservation
				var stats: Dictionary = data.get("stats", {})
				for k in stats.keys():
					state.spirit_bonuses[k] = float(state.spirit_bonuses.get(k, 0.0)) + float(stats[k])
			else:
				entry["enabled"] = false
				state.spirit_gems[spirit] = entry

	state.skill_supports = {}
	for skill3 in state.skill_gems.keys():
		state.skill_supports[skill3] = state.skill_gems[skill3].get("supports", [])

static func toggle_skill_loadout(state: RVGameState, skill: String) -> void:
	if state.active_skills.has(skill):
		if state.active_skills.size() <= 1:
			state.add_notice("At least one skill required")
			return
		state.active_skills.erase(skill)
		state.add_notice(skill + " removed")
	else:
		if state.active_skills.size() >= 6:
			state.add_notice("Loadout full")
			return
		state.active_skills.append(skill)
		state.add_notice(skill + " added")
	rebuild(state)

static func selected_skill_name(state: RVGameState) -> String:
	var names: Array = RVSkillGemDB.active_skill_names()
	if names.size() == 0:
		return ""
	state.skill_board_cursor = posmod(state.skill_board_cursor, names.size())
	return str(names[state.skill_board_cursor])

static func selected_support_name(state: RVGameState) -> String:
	var names: Array = state.support_gems_owned
	if names.size() == 0:
		return ""
	state.support_board_cursor = posmod(state.support_board_cursor, names.size())
	return str(names[state.support_board_cursor])

static func cycle_skill_cursor(state: RVGameState, dir: int) -> void:
	var names: Array = RVSkillGemDB.active_skill_names()
	if names.size() == 0:
		return
	state.skill_board_cursor = posmod(state.skill_board_cursor + dir, names.size())

static func cycle_support_cursor(state: RVGameState, dir: int) -> void:
	if state.support_gems_owned.size() == 0:
		return
	state.support_board_cursor = posmod(state.support_board_cursor + dir, state.support_gems_owned.size())

static func socket_selected_support(state: RVGameState) -> void:
	var skill: String = selected_skill_name(state)
	var support: String = selected_support_name(state)
	if skill == "" or support == "":
		return
	if not RVSkillGemDB.support_can_attach(support, skill):
		state.add_notice("Support does not fit " + skill)
		return
	var gem: Dictionary = state.skill_gems[skill]
	var supports: Array = gem.get("supports", [])
	if supports.has(support):
		state.add_notice("Already socketed")
		return
	if supports.size() >= int(gem.get("sockets", 2)):
		state.add_notice("No support socket")
		return
	supports.append(support)
	gem["supports"] = supports
	state.skill_gems[skill] = gem
	rebuild(state)
	state.add_notice("Socketed " + support + " into " + skill)

static func remove_last_support(state: RVGameState) -> void:
	var skill: String = selected_skill_name(state)
	if skill == "":
		return
	var gem: Dictionary = state.skill_gems[skill]
	var supports: Array = gem.get("supports", [])
	if supports.size() == 0:
		state.add_notice("No supports to remove")
		return
	var removed: String = str(supports.pop_back())
	gem["supports"] = supports
	state.skill_gems[skill] = gem
	rebuild(state)
	state.add_notice("Removed " + removed)

static func toggle_spirit(state: RVGameState, spirit: String) -> void:
	if not state.spirit_gems.has(spirit):
		return
	var entry: Dictionary = state.spirit_gems[spirit]
	entry["enabled"] = not bool(entry.get("enabled", false))
	state.spirit_gems[spirit] = entry
	rebuild(state)
	state.recompute_stats()
	state.add_notice(spirit + (" enabled" if bool(entry["enabled"]) else " disabled"))

static func support_mods(state: RVGameState, skill: String) -> Dictionary:
	var mods: Dictionary = {"damage_mult": 1.0, "cost_mult": 1.0, "cooldown_mult": 1.0, "extra_projectiles": 0, "echo": 0, "chain_bonus": 0, "trigger_rift": 0, "trigger_trap": 0}
	var gem: Dictionary = state.skill_gems.get(skill, {})
	var supports: Array = gem.get("supports", [])
	for support in supports:
		var data: Dictionary = RVSkillGemDB.support_data(str(support))
		mods["damage_mult"] = float(mods["damage_mult"]) * (1.0 + float(data.get("damage_more", 0.0)) - float(data.get("damage_less", 0.0)))
		mods["cost_mult"] = float(mods["cost_mult"]) * float(data.get("cost_mult", 1.0))
		mods["cooldown_mult"] = float(mods["cooldown_mult"]) * float(data.get("cooldown_mult", 1.0))
		mods["extra_projectiles"] = int(mods["extra_projectiles"]) + int(data.get("extra_projectiles", 0))
		mods["echo"] = int(mods["echo"]) + int(data.get("echo", 0))
		mods["chain_bonus"] = int(mods["chain_bonus"]) + int(data.get("chain_bonus", 0))
		mods["trigger_rift"] = int(mods["trigger_rift"]) + int(data.get("trigger_rift", 0))
		mods["trigger_trap"] = int(mods["trigger_trap"]) + int(data.get("trigger_trap", 0))
	return mods
