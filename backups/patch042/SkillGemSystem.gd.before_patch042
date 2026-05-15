class_name RVSkillGemSystem
extends RefCounted

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
		KEY_A, KEY_LEFT:
			state.support_gem_cursor = max(0, state.support_gem_cursor - 1)
			return true
		KEY_D, KEY_RIGHT:
			state.support_gem_cursor = min(max(0, state.support_gem_inventory.size() - 1), state.support_gem_cursor + 1)
			return true
		KEY_ENTER, KEY_KP_ENTER, KEY_E:
			socket_selected_support_to_active(state)
			return true
		KEY_X, KEY_BACKSPACE:
			remove_last_support_from_active(state)
			return true
		KEY_R:
			toggle_selected_spirit(state)
			return true
		KEY_F:
			add_socket_to_selected_active(state)
			return true
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			var index: int = keycode - KEY_1
			if index < state.skill_gem_inventory.size():
				select_active_gem(state, index)
			return true
	return false


static func get_active_gem_for_skill(state: RVGameState, skill_id: String) -> Dictionary:
	for gem: Dictionary in state.skill_gem_inventory:
		if bool(gem.get("equipped", false)) and str(gem.get("skill_id", "")) == skill_id:
			return gem
	return {}


static func get_supported_skill_data(state: RVGameState, skill_id: String, base_data: Dictionary) -> Dictionary:
	var result: Dictionary = base_data.duplicate(true)
	var gem: Dictionary = get_active_gem_for_skill(state, skill_id)
	if gem.is_empty():
		return result

	var damage_mult: float = 1.0 + (float(gem.get("level", 1)) - 1.0) * 0.06
	var mana_mult: float = 1.0
	var cooldown_mult: float = 1.0
	var radius_mult: float = 1.0

	for support_id_value: Variant in gem.get("supports", []):
		var support_id: String = str(support_id_value)
		var support: Dictionary = RVSkillGemDB.support_data(support_id)
		damage_mult *= 1.0 + float(support.get("damage_more", 0.0))
		mana_mult *= 1.0 + float(support.get("mana_more", 0.0))
		cooldown_mult *= 1.0 + float(support.get("cooldown_more", 0.0))
		radius_mult *= 1.0 + float(support.get("radius_more", 0.0))

	result["damage"] = float(result.get("damage", 10.0)) * damage_mult
	result["mana_cost"] = max(0.0, float(result.get("mana_cost", 0.0)) * mana_mult)
	result["cooldown"] = max(0.08, float(result.get("cooldown", 0.5)) * cooldown_mult)
	if result.has("radius"):
		result["radius"] = float(result.get("radius", 0.0)) * radius_mult

	return result


static func select_active_gem(state: RVGameState, index: int) -> void:
	if index < 0 or index >= state.skill_gem_inventory.size():
		return
	state.skill_gem_cursor = index


static func select_support_gem(state: RVGameState, index: int) -> void:
	if index < 0 or index >= state.support_gem_inventory.size():
		return
	state.support_gem_cursor = index


static func select_spirit_gem(state: RVGameState, index: int) -> void:
	if index < 0 or index >= state.spirit_gem_inventory.size():
		return
	state.spirit_gem_cursor = index


static func toggle_selected_active_gem_equipped(state: RVGameState) -> void:
	if state.skill_gem_inventory.is_empty():
		return
	state.skill_gem_cursor = clamp(state.skill_gem_cursor, 0, state.skill_gem_inventory.size() - 1)
	var gem: Dictionary = state.skill_gem_inventory[state.skill_gem_cursor]
	var currently_equipped: bool = bool(gem.get("equipped", false))

	if currently_equipped:
		var equipped_count: int = 0
		for other: Dictionary in state.skill_gem_inventory:
			if bool(other.get("equipped", false)):
				equipped_count += 1
		if equipped_count <= 1:
			state.add_notice("Keep at least one active skill equipped")
			return
		gem["equipped"] = false
		state.add_notice(str(gem.get("name", "Skill Gem")) + " unequipped")
	else:
		var current_count: int = 0
		for other2: Dictionary in state.skill_gem_inventory:
			if bool(other2.get("equipped", false)):
				current_count += 1
		if current_count >= 6:
			state.add_notice("Skill bar full")
			return
		gem["equipped"] = true
		state.add_notice(str(gem.get("name", "Skill Gem")) + " equipped")

	state.skill_gem_inventory[state.skill_gem_cursor] = gem
	state._sync_active_skills_from_equipped_gems()
	state.recompute_stats()


static func socket_selected_support_to_active(state: RVGameState) -> void:
	if state.skill_gem_inventory.is_empty() or state.support_gem_inventory.is_empty():
		state.add_notice("Need an active gem and a support gem")
		return

	state.skill_gem_cursor = clamp(state.skill_gem_cursor, 0, state.skill_gem_inventory.size() - 1)
	state.support_gem_cursor = clamp(state.support_gem_cursor, 0, state.support_gem_inventory.size() - 1)
	var active: Dictionary = state.skill_gem_inventory[state.skill_gem_cursor]
	var support_item: Dictionary = state.support_gem_inventory[state.support_gem_cursor]
	var support_id: String = str(support_item.get("gem_id", ""))
	var active_data: Dictionary = RVSkillGemDB.active_data(str(active.get("gem_id", "")))
	var active_tags: Array = active_data.get("tags", [])

	if not RVSkillGemDB.support_compatible_with_tags(support_id, active_tags):
		state.add_notice("Support is not compatible")
		return

	var supports: Array = active.get("supports", [])
	if supports.size() >= int(active.get("max_support_sockets", 2)):
		state.add_notice("No empty support sockets")
		return

	supports.append(support_id)
	active["supports"] = supports
	state.skill_gem_inventory[state.skill_gem_cursor] = active
	state.support_gem_inventory.remove_at(state.support_gem_cursor)
	state.support_gem_cursor = clamp(state.support_gem_cursor, 0, max(0, state.support_gem_inventory.size() - 1))
	state.add_notice("Support socketed")
	state.recompute_stats()


static func remove_last_support_from_active(state: RVGameState) -> void:
	if state.skill_gem_inventory.is_empty():
		return
	state.skill_gem_cursor = clamp(state.skill_gem_cursor, 0, state.skill_gem_inventory.size() - 1)
	var active: Dictionary = state.skill_gem_inventory[state.skill_gem_cursor]
	var supports: Array = active.get("supports", [])
	if supports.is_empty():
		state.add_notice("No support to remove")
		return
	var support_id: String = str(supports.pop_back())
	active["supports"] = supports
	state.skill_gem_inventory[state.skill_gem_cursor] = active
	state.support_gem_inventory.append(_make_support_drop(state, support_id, 1))
	state.add_notice("Support removed")
	state.recompute_stats()


static func socket_selected_support_to_spirit(state: RVGameState) -> void:
	if state.spirit_gem_inventory.is_empty() or state.support_gem_inventory.is_empty():
		state.add_notice("Need a spirit gem and a support gem")
		return
	state.spirit_gem_cursor = clamp(state.spirit_gem_cursor, 0, state.spirit_gem_inventory.size() - 1)
	state.support_gem_cursor = clamp(state.support_gem_cursor, 0, state.support_gem_inventory.size() - 1)
	var spirit: Dictionary = state.spirit_gem_inventory[state.spirit_gem_cursor]
	var support_item: Dictionary = state.support_gem_inventory[state.support_gem_cursor]
	var support_id: String = str(support_item.get("gem_id", ""))
	var spirit_data: Dictionary = RVSkillGemDB.spirit_data(str(spirit.get("gem_id", "")))
	var spirit_tags: Array = spirit_data.get("tags", [])

	if not RVSkillGemDB.support_compatible_with_tags(support_id, spirit_tags):
		state.add_notice("Support is not compatible with this spirit gem")
		return

	var supports: Array = spirit.get("supports", [])
	if supports.size() >= int(spirit.get("max_support_sockets", 2)):
		state.add_notice("No empty spirit support sockets")
		return

	supports.append(support_id)
	spirit["supports"] = supports
	state.spirit_gem_inventory[state.spirit_gem_cursor] = spirit
	state.support_gem_inventory.remove_at(state.support_gem_cursor)
	state.support_gem_cursor = clamp(state.support_gem_cursor, 0, max(0, state.support_gem_inventory.size() - 1))
	state.add_notice("Spirit support socketed")
	state.recompute_stats()


static func toggle_selected_spirit(state: RVGameState) -> void:
	if state.spirit_gem_inventory.is_empty():
		return
	state.spirit_gem_cursor = clamp(state.spirit_gem_cursor, 0, state.spirit_gem_inventory.size() - 1)
	var spirit: Dictionary = state.spirit_gem_inventory[state.spirit_gem_cursor]
	var will_enable: bool = not bool(spirit.get("enabled", false))

	if will_enable:
		var reservation: int = spirit_reservation(spirit)
		state._recompute_spirit_reserved()
		if state.spirit_reserved + reservation > state.spirit_max:
			state.add_notice("Not enough unreserved spirit")
			return
		spirit["enabled"] = true
		state.add_notice(str(spirit.get("name", "Spirit Gem")) + " enabled")
	else:
		spirit["enabled"] = false
		state.add_notice(str(spirit.get("name", "Spirit Gem")) + " disabled")

	state.spirit_gem_inventory[state.spirit_gem_cursor] = spirit
	state.recompute_stats()


static func add_socket_to_selected_active(state: RVGameState) -> void:
	if state.skill_gem_inventory.is_empty():
		return
	if int(state.materials.get("socket_prisms", 0)) <= 0:
		state.add_notice("Need Socket Prism")
		return
	state.skill_gem_cursor = clamp(state.skill_gem_cursor, 0, state.skill_gem_inventory.size() - 1)
	var gem: Dictionary = state.skill_gem_inventory[state.skill_gem_cursor]
	var data: Dictionary = RVSkillGemDB.active_data(str(gem.get("gem_id", "")))
	var max_sockets: int = int(data.get("max_sockets", 6))
	if int(gem.get("max_support_sockets", 2)) >= max_sockets:
		state.add_notice("Gem already has maximum sockets")
		return
	state.materials["socket_prisms"] = int(state.materials.get("socket_prisms", 0)) - 1
	gem["max_support_sockets"] = int(gem.get("max_support_sockets", 2)) + 1
	state.skill_gem_inventory[state.skill_gem_cursor] = gem
	state.add_notice("Support socket added")


static func add_socket_to_selected_spirit(state: RVGameState) -> void:
	if state.spirit_gem_inventory.is_empty():
		return
	if int(state.materials.get("socket_prisms", 0)) <= 0:
		state.add_notice("Need Socket Prism")
		return
	state.spirit_gem_cursor = clamp(state.spirit_gem_cursor, 0, state.spirit_gem_inventory.size() - 1)
	var gem: Dictionary = state.spirit_gem_inventory[state.spirit_gem_cursor]
	var data: Dictionary = RVSkillGemDB.spirit_data(str(gem.get("gem_id", "")))
	var max_sockets: int = int(data.get("max_sockets", 6))
	if int(gem.get("max_support_sockets", 2)) >= max_sockets:
		state.add_notice("Spirit gem already has maximum sockets")
		return
	state.materials["socket_prisms"] = int(state.materials.get("socket_prisms", 0)) - 1
	gem["max_support_sockets"] = int(gem.get("max_support_sockets", 2)) + 1
	state.spirit_gem_inventory[state.spirit_gem_cursor] = gem
	state.add_notice("Spirit support socket added")
	state.recompute_stats()


static func spirit_reservation(gem: Dictionary) -> int:
	var data: Dictionary = RVSkillGemDB.spirit_data(str(gem.get("gem_id", "")))
	var reservation: float = float(data.get("base_reservation", 0))
	for support_id_value: Variant in gem.get("supports", []):
		var support_data: Dictionary = RVSkillGemDB.support_data(str(support_id_value))
		reservation *= 1.0 + float(support_data.get("spirit_more", 0.0))
	return int(ceil(reservation))


static func award_random_gem_drop(state: RVGameState, depth: int) -> String:
	var roll: float = state.rng.randf()
	if roll < 0.34:
		var ids: Array = RVSkillGemDB.active_ids()
		var id: String = str(ids[state.rng.randi_range(0, ids.size() - 1)])
		var level: int = max(1, min(20, int(depth / 2) + state.rng.randi_range(1, 2)))
		state.skill_gem_inventory.append(_make_active_drop(state, id, level))
		state.ensure_defaults()
		return "Skill Gem: " + str(RVSkillGemDB.active_data(id).get("name", id))
	elif roll < 0.82:
		var support_ids: Array = RVSkillGemDB.support_ids()
		var support_id: String = str(support_ids[state.rng.randi_range(0, support_ids.size() - 1)])
		state.support_gem_inventory.append(_make_support_drop(state, support_id, 1))
		return "Support Gem: " + str(RVSkillGemDB.support_data(support_id).get("name", support_id))
	else:
		var spirit_ids: Array = RVSkillGemDB.spirit_ids()
		var spirit_id: String = str(spirit_ids[state.rng.randi_range(0, spirit_ids.size() - 1)])
		state.spirit_gem_inventory.append(_make_spirit_drop(state, spirit_id, 1))
		return "Spirit Gem: " + str(RVSkillGemDB.spirit_data(spirit_id).get("name", spirit_id))


static func _make_active_drop(state: RVGameState, gem_id: String, level: int) -> Dictionary:
	var data: Dictionary = RVSkillGemDB.active_data(gem_id)
	return {
		"uid": _next_uid(state, "active"),
		"type": "active",
		"gem_id": gem_id,
		"name": str(data.get("name", gem_id.capitalize())),
		"skill_id": str(data.get("skill_id", data.get("name", gem_id))),
		"level": level,
		"xp": 0.0,
		"max_support_sockets": int(data.get("base_sockets", 2)),
		"supports": [],
		"equipped": false
	}


static func _make_support_drop(state: RVGameState, gem_id: String, level: int) -> Dictionary:
	var data: Dictionary = RVSkillGemDB.support_data(gem_id)
	return {
		"uid": _next_uid(state, "support"),
		"type": "support",
		"gem_id": gem_id,
		"name": str(data.get("name", gem_id.capitalize())),
		"level": level,
		"xp": 0.0
	}


static func _make_spirit_drop(state: RVGameState, gem_id: String, level: int) -> Dictionary:
	var data: Dictionary = RVSkillGemDB.spirit_data(gem_id)
	return {
		"uid": _next_uid(state, "spirit"),
		"type": "spirit",
		"gem_id": gem_id,
		"name": str(data.get("name", gem_id.capitalize())),
		"level": level,
		"xp": 0.0,
		"max_support_sockets": int(data.get("base_sockets", 2)),
		"supports": [],
		"enabled": false
	}


static func _next_uid(state: RVGameState, prefix: String) -> String:
	var uid: String = prefix + "_" + str(state.gem_uid_counter)
	state.gem_uid_counter += 1
	return uid
