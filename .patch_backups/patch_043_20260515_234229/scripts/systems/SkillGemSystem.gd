class_name RVSkillGemSystem
extends RefCounted

static func make_uncut_active_gem(state: RVGameState, gem_level: int = 1) -> Dictionary:
	return {
		"uid": _next_uid(state, "active"),
		"type": "active",
		"uncut": true,
		"gem_id": "uncut_active",
		"name": "Uncut Skill Gem",
		"level": max(1, gem_level),
		"xp": 0.0,
		"max_support_sockets": 2,
		"supports": [],
		"equipped": false,
		"description": "Right-click to engrave this into an active skill."
	}

static func make_uncut_support_gem(state: RVGameState, gem_level: int = 1) -> Dictionary:
	return {
		"uid": _next_uid(state, "support"),
		"type": "support",
		"uncut": true,
		"gem_id": "uncut_support",
		"name": "Uncut Support Gem",
		"level": max(1, gem_level),
		"xp": 0.0,
		"description": "Right-click to choose a target gem and engrave this into a support."
	}

static func make_uncut_spirit_gem(state: RVGameState, gem_level: int = 1) -> Dictionary:
	return {
		"uid": _next_uid(state, "spirit"),
		"type": "spirit",
		"uncut": true,
		"gem_id": "uncut_spirit",
		"name": "Uncut Spirit Gem",
		"level": max(1, gem_level),
		"xp": 0.0,
		"max_support_sockets": 2,
		"supports": [],
		"enabled": false,
		"description": "Right-click to engrave this into a reservation skill."
	}

static func make_active_gem(state: RVGameState, gem_id: String, gem_level: int = 1, equipped_now: bool = false) -> Dictionary:
	var data: Dictionary = RVSkillGemDB.active_data(gem_id)
	return {
		"uid": _next_uid(state, "active"),
		"type": "active",
		"uncut": false,
		"gem_id": gem_id,
		"name": str(data.get("name", gem_id.capitalize())),
		"skill_id": str(data.get("skill_id", data.get("name", gem_id.capitalize()))),
		"level": max(1, gem_level),
		"xp": 0.0,
		"max_support_sockets": int(data.get("base_sockets", 2)),
		"supports": [],
		"equipped": equipped_now,
		"description": str(data.get("description", ""))
	}

static func make_support_gem(state: RVGameState, gem_id: String, gem_level: int = 1) -> Dictionary:
	var data: Dictionary = RVSkillGemDB.support_data(gem_id)
	return {
		"uid": _next_uid(state, "support"),
		"type": "support",
		"uncut": false,
		"gem_id": gem_id,
		"name": str(data.get("name", gem_id.capitalize())),
		"level": max(1, gem_level),
		"xp": 0.0,
		"description": str(data.get("description", ""))
	}

static func make_spirit_gem(state: RVGameState, gem_id: String, gem_level: int = 1, enabled_now: bool = false) -> Dictionary:
	var data: Dictionary = RVSkillGemDB.spirit_data(gem_id)
	return {
		"uid": _next_uid(state, "spirit"),
		"type": "spirit",
		"uncut": false,
		"gem_id": gem_id,
		"name": str(data.get("name", gem_id.capitalize())),
		"level": max(1, gem_level),
		"xp": 0.0,
		"max_support_sockets": int(data.get("base_sockets", 2)),
		"supports": [],
		"enabled": enabled_now,
		"description": str(data.get("description", ""))
	}

static func _next_uid(state: RVGameState, prefix: String) -> String:
	var counter: int = int(state.gem_uid_counter)
	var uid: String = prefix + "_" + str(counter)
	state.gem_uid_counter = counter + 1
	return uid

static func ensure_gem_baseline(state: RVGameState) -> void:
	# Existing saves may contain old cut gems. Keep them. Only add a few uncut test drops if absolutely empty.
	if state.skill_gem_inventory.is_empty():
		state.skill_gem_inventory.append(make_uncut_active_gem(state, max(1, state.level)))
		state.skill_gem_inventory.append(make_active_gem(state, "fireball", max(1, state.level), true))
	if state.support_gem_inventory.is_empty():
		state.support_gem_inventory.append(make_uncut_support_gem(state, max(1, state.level)))
		state.support_gem_inventory.append(make_uncut_support_gem(state, max(1, state.level)))
	if state.spirit_gem_inventory.is_empty():
		state.spirit_gem_inventory.append(make_uncut_spirit_gem(state, max(1, state.level)))
	resync_active_skills(state)

static func resync_active_skills(state: RVGameState) -> void:
	state.active_skills.clear()
	state.unlocked_skills.clear()
	for gem_value: Variant in state.skill_gem_inventory:
		if typeof(gem_value) != TYPE_DICTIONARY:
			continue
		var gem: Dictionary = gem_value
		if bool(gem.get("uncut", false)):
			continue
		var skill_id: String = str(gem.get("skill_id", ""))
		if skill_id == "":
			continue
		if not state.unlocked_skills.has(skill_id):
			state.unlocked_skills.append(skill_id)
		if bool(gem.get("equipped", false)) and not state.active_skills.has(skill_id):
			state.active_skills.append(skill_id)
	if state.active_skills.is_empty():
		for i: int in range(state.skill_gem_inventory.size()):
			var fallback: Dictionary = state.skill_gem_inventory[i]
			if bool(fallback.get("uncut", false)):
				continue
			var fallback_skill: String = str(fallback.get("skill_id", ""))
			if fallback_skill != "":
				fallback["equipped"] = true
				state.skill_gem_inventory[i] = fallback
				state.active_skills.append(fallback_skill)
				break
	state.selected_skill_index = clamp(state.selected_skill_index, 0, max(0, state.active_skills.size() - 1))

static func engrave_active_gem(state: RVGameState, index: int, gem_id: String) -> bool:
	if index < 0 or index >= state.skill_gem_inventory.size():
		return false
	if not RVSkillGemDB.ACTIVE_GEMS.has(gem_id):
		return false
	var old_gem: Dictionary = state.skill_gem_inventory[index]
	var gem_level: int = int(old_gem.get("level", max(1, state.level)))
	var new_gem: Dictionary = make_active_gem(state, gem_id, gem_level, false)
	new_gem["uid"] = str(old_gem.get("uid", new_gem.get("uid", "")))
	new_gem["max_support_sockets"] = int(old_gem.get("max_support_sockets", new_gem.get("max_support_sockets", 2)))
	state.skill_gem_inventory[index] = new_gem
	state.skill_gem_cursor = index
	resync_active_skills(state)
	state.add_notice("Engraved " + str(new_gem.get("name", "Skill Gem")))
	return true

static func engrave_spirit_gem(state: RVGameState, index: int, gem_id: String) -> bool:
	if index < 0 or index >= state.spirit_gem_inventory.size():
		return false
	if not RVSkillGemDB.SPIRIT_GEMS.has(gem_id):
		return false
	var old_gem: Dictionary = state.spirit_gem_inventory[index]
	var gem_level: int = int(old_gem.get("level", max(1, state.level)))
	var new_gem: Dictionary = make_spirit_gem(state, gem_id, gem_level, false)
	new_gem["uid"] = str(old_gem.get("uid", new_gem.get("uid", "")))
	new_gem["max_support_sockets"] = int(old_gem.get("max_support_sockets", new_gem.get("max_support_sockets", 2)))
	state.spirit_gem_inventory[index] = new_gem
	state.spirit_gem_cursor = index
	state.recompute_stats()
	state.add_notice("Engraved " + str(new_gem.get("name", "Spirit Gem")))
	return true

static func engrave_support_gem(state: RVGameState, index: int, gem_id: String) -> bool:
	if index < 0 or index >= state.support_gem_inventory.size():
		return false
	if not RVSkillGemDB.SUPPORT_GEMS.has(gem_id):
		return false
	var old_gem: Dictionary = state.support_gem_inventory[index]
	var gem_level: int = int(old_gem.get("level", max(1, state.level)))
	var new_gem: Dictionary = make_support_gem(state, gem_id, gem_level)
	new_gem["uid"] = str(old_gem.get("uid", new_gem.get("uid", "")))
	state.support_gem_inventory[index] = new_gem
	state.support_gem_cursor = index
	state.add_notice("Engraved " + str(new_gem.get("name", "Support Gem")))
	return true

static func target_tags_for_gem(gem: Dictionary) -> Array:
	if bool(gem.get("uncut", false)):
		return []
	var gem_type: String = str(gem.get("type", ""))
	var gem_id: String = str(gem.get("gem_id", ""))
	if gem_type == "active":
		return RVSkillGemDB.active_data(gem_id).get("tags", [])
	if gem_type == "spirit":
		return RVSkillGemDB.spirit_data(gem_id).get("tags", [])
	return []

static func compatible_support_ids_for_target(target_gem: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var tags: Array = target_tags_for_gem(target_gem)
	for support_id_value: Variant in RVSkillGemDB.support_ids():
		var support_id: String = str(support_id_value)
		if RVSkillGemDB.support_compatible_with_tags(support_id, tags):
			result.append(support_id)
	return result

static func socket_support_to_target(state: RVGameState, support_index: int, target_kind: String, target_index: int, chosen_support_id: String = "") -> bool:
	if support_index < 0 or support_index >= state.support_gem_inventory.size():
		return false
	if target_kind != "active" and target_kind != "spirit":
		return false
	var target_list: Array = state.skill_gem_inventory if target_kind == "active" else state.spirit_gem_inventory
	if target_index < 0 or target_index >= target_list.size():
		return false
	var support_gem: Dictionary = state.support_gem_inventory[support_index]
	if bool(support_gem.get("uncut", false)):
		if chosen_support_id == "":
			state.add_notice("Choose support type first")
			return false
		if not engrave_support_gem(state, support_index, chosen_support_id):
			return false
		support_gem = state.support_gem_inventory[support_index]
	var support_id: String = str(support_gem.get("gem_id", ""))
	var target_gem: Dictionary = target_list[target_index]
	if bool(target_gem.get("uncut", false)):
		state.add_notice("Engrave target gem first")
		return false
	if not RVSkillGemDB.support_compatible_with_tags(support_id, target_tags_for_gem(target_gem)):
		state.add_notice("Support incompatible with target")
		return false
	var supports: Array = target_gem.get("supports", [])
	if supports.has(support_id):
		state.add_notice("Support already socketed")
		return false
	var max_sockets: int = int(target_gem.get("max_support_sockets", 2))
	if supports.size() >= max_sockets:
		state.add_notice("No empty support socket")
		return false
	supports.append(support_id)
	target_gem["supports"] = supports
	if target_kind == "active":
		state.skill_gem_inventory[target_index] = target_gem
	else:
		state.spirit_gem_inventory[target_index] = target_gem
	state.support_gem_inventory.remove_at(support_index)
	state.support_gem_cursor = clamp(state.support_gem_cursor, 0, max(0, state.support_gem_inventory.size() - 1))
	state.recompute_stats()
	resync_active_skills(state)
	state.add_notice("Socketed " + RVSkillGemDB.name_for_support(support_id))
	return true

static func remove_last_support_from_selected(state: RVGameState, target_kind: String = "active") -> bool:
	var target_list: Array = state.skill_gem_inventory if target_kind == "active" else state.spirit_gem_inventory
	var index: int = state.skill_gem_cursor if target_kind == "active" else state.spirit_gem_cursor
	if index < 0 or index >= target_list.size():
		return false
	var gem: Dictionary = target_list[index]
	var supports: Array = gem.get("supports", [])
	if supports.is_empty():
		state.add_notice("No support to remove")
		return false
	var support_id: String = str(supports.pop_back())
	gem["supports"] = supports
	if target_kind == "active":
		state.skill_gem_inventory[index] = gem
	else:
		state.spirit_gem_inventory[index] = gem
	state.support_gem_inventory.append(make_support_gem(state, support_id, max(1, int(gem.get("level", 1)))))
	state.recompute_stats()
	state.add_notice("Removed support")
	return true

static func improve_selected_socket_cap(state: RVGameState, target_kind: String = "active") -> bool:
	if int(state.materials.get("socket_prisms", 0)) <= 0:
		state.add_notice("Need Socket Prism")
		return false
	var target_list: Array = state.skill_gem_inventory if target_kind == "active" else state.spirit_gem_inventory
	var index: int = state.skill_gem_cursor if target_kind == "active" else state.spirit_gem_cursor
	if index < 0 or index >= target_list.size():
		return false
	var gem: Dictionary = target_list[index]
	if bool(gem.get("uncut", false)):
		state.add_notice("Engrave gem before improving sockets")
		return false
	var current: int = int(gem.get("max_support_sockets", 2))
	if current >= 6:
		state.add_notice("Gem already has maximum sockets")
		return false
	gem["max_support_sockets"] = current + 1
	state.materials["socket_prisms"] = int(state.materials.get("socket_prisms", 0)) - 1
	if target_kind == "active":
		state.skill_gem_inventory[index] = gem
	else:
		state.spirit_gem_inventory[index] = gem
	state.add_notice("Socket capacity improved")
	return true

static func toggle_selected_active_gem_equipped(state: RVGameState) -> bool:
	if state.skill_gem_cursor < 0 or state.skill_gem_cursor >= state.skill_gem_inventory.size():
		return false
	var gem: Dictionary = state.skill_gem_inventory[state.skill_gem_cursor]
	if bool(gem.get("uncut", false)):
		state.add_notice("Engrave this skill gem first")
		return false
	gem["equipped"] = not bool(gem.get("equipped", false))
	state.skill_gem_inventory[state.skill_gem_cursor] = gem
	resync_active_skills(state)
	state.add_notice(("Equipped " if bool(gem.get("equipped", false)) else "Unequipped ") + str(gem.get("name", "Skill Gem")))
	return true

static func toggle_selected_spirit_gem_enabled(state: RVGameState) -> bool:
	if state.spirit_gem_cursor < 0 or state.spirit_gem_cursor >= state.spirit_gem_inventory.size():
		return false
	var gem: Dictionary = state.spirit_gem_inventory[state.spirit_gem_cursor]
	if bool(gem.get("uncut", false)):
		state.add_notice("Engrave this spirit gem first")
		return false
	gem["enabled"] = not bool(gem.get("enabled", false))
	state.spirit_gem_inventory[state.spirit_gem_cursor] = gem
	state.recompute_stats()
	if bool(gem.get("enabled", false)) and state.spirit_reserved > state.spirit_max:
		gem["enabled"] = false
		state.spirit_gem_inventory[state.spirit_gem_cursor] = gem
		state.recompute_stats()
		state.add_notice("Not enough Spirit")
		return false
	state.add_notice(("Enabled " if bool(gem.get("enabled", false)) else "Disabled ") + str(gem.get("name", "Spirit Gem")))
	return true

static func get_supported_skill_data(state: RVGameState, skill_name: String, base_data: Dictionary) -> Dictionary:
	var result: Dictionary = base_data.duplicate(true)
	var active_gem: Dictionary = {}
	for gem_value: Variant in state.skill_gem_inventory:
		if typeof(gem_value) != TYPE_DICTIONARY:
			continue
		var gem: Dictionary = gem_value
		if bool(gem.get("uncut", false)):
			continue
		if str(gem.get("skill_id", "")) == skill_name and bool(gem.get("equipped", false)):
			active_gem = gem
			break
	if active_gem.is_empty():
		return result
	var level: int = int(active_gem.get("level", 1))
	result["damage"] = float(result.get("damage", 10.0)) * (1.0 + float(level - 1) * 0.055)
	result["mana_cost"] = float(result.get("mana_cost", 0.0)) * (1.0 + float(level - 1) * 0.015)
	var tags: Array = result.get("tags", RVSkillDB.tags(skill_name)).duplicate()
	var radius_multiplier: float = 1.0
	var damage_multiplier: float = 1.0
	var mana_multiplier: float = 1.0
	var cooldown_multiplier: float = 1.0
	var flags: Array = result.get("flags", []).duplicate()
	var supports: Array = active_gem.get("supports", [])
	for support_id_value: Variant in supports:
		var support_id: String = str(support_id_value)
		var support_data: Dictionary = RVSkillGemDB.support_data(support_id)
		if support_data.is_empty():
			continue
		damage_multiplier *= 1.0 + float(support_data.get("damage_more", 0.0))
		mana_multiplier *= 1.0 + float(support_data.get("mana_more", 0.0))
		cooldown_multiplier *= 1.0 + float(support_data.get("cooldown_more", 0.0))
		radius_multiplier *= 1.0 + float(support_data.get("radius_more", 0.0))
		for flag_value: Variant in support_data.get("flags", []):
			if not flags.has(str(flag_value)):
				flags.append(str(flag_value))
		for tag_value: Variant in support_data.get("tags", []):
			var tag: String = str(tag_value)
			if tag != "Support" and not tags.has(tag):
				tags.append(tag)
	result["damage"] = float(result.get("damage", 10.0)) * damage_multiplier
	result["mana_cost"] = max(0.0, float(result.get("mana_cost", 0.0)) * mana_multiplier)
	result["cooldown"] = max(0.05, float(result.get("cooldown", 0.5)) * cooldown_multiplier)
	result["radius"] = float(result.get("radius", 20.0)) * radius_multiplier
	result["tags"] = tags
	result["flags"] = flags
	return result

static func support_reservation_multiplier(support_id: String) -> float:
	var data: Dictionary = RVSkillGemDB.support_data(support_id)
	return 1.0 + float(data.get("spirit_more", 0.0))

static func spirit_reservation_for_gem(gem: Dictionary) -> int:
	if bool(gem.get("uncut", false)):
		return 0
	var data: Dictionary = RVSkillGemDB.spirit_data(str(gem.get("gem_id", "")))
	var reservation: float = float(data.get("base_reservation", 0.0))
	for support_id_value: Variant in gem.get("supports", []):
		reservation *= support_reservation_multiplier(str(support_id_value))
	return int(ceil(reservation))

static func award_random_gem_drop(state: RVGameState, room_level: int = 1) -> String:
	var gem_level: int = clamp(max(max(1, int(state.level)), room_level), 1, 20)
	var roll: float = state.rng.randf()
	if roll < 0.42:
		state.skill_gem_inventory.append(make_uncut_active_gem(state, gem_level))
		state.skill_gem_cursor = max(0, state.skill_gem_inventory.size() - 1)
		return "Uncut Skill Gem"
	elif roll < 0.78:
		state.support_gem_inventory.append(make_uncut_support_gem(state, gem_level))
		state.support_gem_cursor = max(0, state.support_gem_inventory.size() - 1)
		return "Uncut Support Gem"
	else:
		state.spirit_gem_inventory.append(make_uncut_spirit_gem(state, gem_level))
		state.spirit_gem_cursor = max(0, state.spirit_gem_inventory.size() - 1)
		return "Uncut Spirit Gem"

static func handle_panel_key(state: RVGameState, keycode: int) -> bool:
	if state.panel_mode != "skill_gems":
		return false
	match keycode:
		KEY_W, KEY_UP:
			state.skill_gem_cursor = max(0, state.skill_gem_cursor - 1)
			return true
		KEY_S, KEY_DOWN:
			state.skill_gem_cursor = min(max(0, state.skill_gem_inventory.size() - 1), state.skill_gem_cursor + 1)
			return true
		KEY_E, KEY_ENTER:
			return toggle_selected_active_gem_equipped(state)
		KEY_R:
			return remove_last_support_from_selected(state, "active")
		KEY_U:
			return improve_selected_socket_cap(state, "active")
	return false

static func gem_short_text(gem: Dictionary) -> String:
	if bool(gem.get("uncut", false)):
		return str(gem.get("name", "Uncut Gem")) + " Lv " + str(int(gem.get("level", 1)))
	var supports: Array = gem.get("supports", [])
	var sockets: int = int(gem.get("max_support_sockets", 0))
	var suffix: String = ""
	if gem.has("supports"):
		suffix = " [" + str(supports.size()) + "/" + str(sockets) + "]"
	return str(gem.get("name", "Gem")) + " Lv " + str(int(gem.get("level", 1))) + suffix

static func gem_detail_text(gem: Dictionary) -> String:
	if gem.is_empty():
		return "No gem selected."
	var text: String = str(gem.get("name", "Gem")) + "\n"
	text += "Type: " + str(gem.get("type", "gem")).capitalize() + "\n"
	text += "Level: " + str(int(gem.get("level", 1))) + "\n"
	if bool(gem.get("uncut", false)):
		text += "\nUncut gem. Right-click to choose what this becomes.\n"
		text += str(gem.get("description", "")) + "\n"
		return text
	if gem.get("type", "") == "spirit":
		text += "Reservation: " + str(spirit_reservation_for_gem(gem)) + " Spirit\n"
	if gem.has("supports"):
		text += "Sockets: " + str(Array(gem.get("supports", [])).size()) + "/" + str(int(gem.get("max_support_sockets", 2))) + "\n"
		text += "Supports: " + _support_names(Array(gem.get("supports", []))) + "\n"
	text += "\n" + str(gem.get("description", "")) + "\n"
	return text

static func _support_names(supports: Array) -> String:
	if supports.is_empty():
		return "None"
	var names: Array[String] = []
	for support_id_value: Variant in supports:
		names.append(RVSkillGemDB.name_for_support(str(support_id_value)))
	return _join_strings(names, ", ")

static func _join_strings(values: Array[String], separator: String = ", ") -> String:
	var result: String = ""
	for i: int in range(values.size()):
		if i > 0:
			result += separator
		result += values[i]
	return result
