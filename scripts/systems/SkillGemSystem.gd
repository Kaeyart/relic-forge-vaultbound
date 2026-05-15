class_name RVSkillGemSystem
extends RefCounted

# Patch 043: uncut gem crafting + support effect choice + real support modifiers.

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
			toggle_selected_active_gem_equipped(state)
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
		if str(gem.get("type", "active")) != "active":
			continue
		if bool(gem.get("equipped", false)) and str(gem.get("skill_id", "")) == skill_id:
			return gem
	return {}

static func get_supported_skill_data(state: RVGameState, skill_id: String, base_data: Dictionary) -> Dictionary:
	var result: Dictionary = base_data.duplicate(true)
	var gem: Dictionary = get_active_gem_for_skill(state, skill_id)
	var tags: Array = result.get("tags", RVSkillDB.tags(skill_id)).duplicate(true)
	var flags: Array = result.get("flags", RVSkillDB.flags(skill_id)).duplicate(true)
	var damage_mult: float = 1.0
	var mana_mult: float = 1.0
	var cooldown_mult: float = 1.0
	var radius_mult: float = 1.0
	var projectile_bonus: int = int(result.get("extra_projectiles", 0))
	var chain_bonus: int = int(result.get("chain_count", 0))
	var status_power: float = 1.0

	if not gem.is_empty():
		damage_mult *= 1.0 + (float(gem.get("level", 1)) - 1.0) * 0.06
		for support_id_value: Variant in gem.get("supports", []):
			var support_id: String = str(support_id_value)
			var support: Dictionary = RVSkillGemDB.support_data(support_id)
			if support.is_empty():
				continue
			damage_mult *= 1.0 + float(support.get("damage_more", 0.0))
			mana_mult *= 1.0 + float(support.get("mana_more", 0.0))
			cooldown_mult *= 1.0 + float(support.get("cooldown_more", 0.0))
			radius_mult *= 1.0 + float(support.get("radius_more", 0.0))
			projectile_bonus += int(support.get("extra_projectiles", 0))
			chain_bonus += int(support.get("chain_count", 0))
			status_power += float(support.get("status_power", 0.0))
			for flag_value: Variant in support.get("flags", []):
				_add_unique(flags, str(flag_value))
			for tag_value: Variant in support.get("tags", []):
				var tag: String = str(tag_value)
				if tag != "Support":
					_add_unique(tags, tag)

	result["damage"] = float(result.get("damage", 10.0)) * damage_mult
	result["mana_cost"] = max(0.0, float(result.get("mana_cost", 0.0)) * mana_mult)
	result["cooldown"] = max(0.08, float(result.get("cooldown", 0.5)) * cooldown_mult)
	if result.has("radius"):
		result["radius"] = float(result.get("radius", 0.0)) * radius_mult
	if result.has("impact_radius"):
		result["impact_radius"] = float(result.get("impact_radius", 0.0)) * radius_mult
	result["extra_projectiles"] = projectile_bonus
	result["chain_count"] = chain_bonus
	result["status_power"] = status_power
	result["flags"] = flags
	result["tags"] = tags
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
	if str(gem.get("type", "active")) != "active":
		state.add_notice("Right-click an Uncut Skill Gem to choose a skill")
		return
	var currently_equipped: bool = bool(gem.get("equipped", false))
	if currently_equipped:
		var equipped_count: int = 0
		for other: Dictionary in state.skill_gem_inventory:
			if str(other.get("type", "active")) == "active" and bool(other.get("equipped", false)):
				equipped_count += 1
		if equipped_count <= 1:
			state.add_notice("Keep at least one active skill equipped")
			return
		gem["equipped"] = false
		state.add_notice(str(gem.get("name", "Skill Gem")) + " unequipped")
	else:
		var current_count: int = 0
		for other2: Dictionary in state.skill_gem_inventory:
			if str(other2.get("type", "active")) == "active" and bool(other2.get("equipped", false)):
				current_count += 1
		if current_count >= 6:
			state.add_notice("Skill bar full")
			return
		gem["equipped"] = true
		state.add_notice(str(gem.get("name", "Skill Gem")) + " equipped")
	state.skill_gem_inventory[state.skill_gem_cursor] = gem
	state._sync_active_skills_from_equipped_gems()
	state.recompute_stats()

static func cut_uncut_skill_gem(state: RVGameState, index: int, active_id: String) -> void:
	if index < 0 or index >= state.skill_gem_inventory.size():
		return
	var old_gem: Dictionary = state.skill_gem_inventory[index]
	if not is_uncut_skill_gem(old_gem):
		state.add_notice("That is not an Uncut Skill Gem")
		return
	var data: Dictionary = RVSkillGemDB.active_data(active_id)
	if data.is_empty():
		state.add_notice("Unknown skill gem")
		return
	var level: int = int(old_gem.get("level", 1))
	state.skill_gem_inventory[index] = _make_active_drop(state, active_id, level)
	state.skill_gem_cursor = index
	state.add_notice("Cut gem into " + str(data.get("name", active_id)))
	state._sync_active_skills_from_equipped_gems()
	state.recompute_stats()

static func cut_uncut_spirit_gem(state: RVGameState, index: int, spirit_id: String) -> void:
	if index < 0 or index >= state.spirit_gem_inventory.size():
		return
	var old_gem: Dictionary = state.spirit_gem_inventory[index]
	if not is_uncut_spirit_gem(old_gem):
		state.add_notice("That is not an Uncut Spirit Gem")
		return
	var data: Dictionary = RVSkillGemDB.spirit_data(spirit_id)
	if data.is_empty():
		state.add_notice("Unknown spirit gem")
		return
	var level: int = int(old_gem.get("level", 1))
	state.spirit_gem_inventory[index] = _make_spirit_drop(state, spirit_id, level)
	state.spirit_gem_cursor = index
	state.add_notice("Cut spirit gem into " + str(data.get("name", spirit_id)))
	state.recompute_stats()

static func cut_uncut_support_gem_for_target(state: RVGameState, support_index: int, target_type: String, target_index: int, support_id: String) -> void:
	if support_index < 0 or support_index >= state.support_gem_inventory.size():
		return
	var support_item: Dictionary = state.support_gem_inventory[support_index]
	if not is_uncut_support_gem(support_item):
		state.add_notice("That is not an Uncut Support Gem")
		return
	var support_data: Dictionary = RVSkillGemDB.support_data(support_id)
	if support_data.is_empty():
		state.add_notice("Unknown support effect")
		return
	var target_array: Array = state.skill_gem_inventory if target_type == "active" else state.spirit_gem_inventory
	if target_index < 0 or target_index >= target_array.size():
		state.add_notice("Invalid support target")
		return
	var target: Dictionary = target_array[target_index]
	if target_type == "active" and str(target.get("type", "active")) != "active":
		state.add_notice("Choose a cut active skill gem first")
		return
	if target_type == "spirit" and str(target.get("type", "spirit")) != "spirit":
		state.add_notice("Choose a cut spirit gem first")
		return
	var target_tags: Array = target_tags_for_gem(target_type, target)
	if not RVSkillGemDB.support_compatible_with_tags(support_id, target_tags):
		state.add_notice("Support is not compatible with that target")
		return
	var supports: Array = target.get("supports", [])
	if supports.size() >= int(target.get("max_support_sockets", 2)):
		state.add_notice("No empty support socket")
		return
	if supports.has(support_id):
		state.add_notice("That support is already socketed")
		return
	supports.append(support_id)
	target["supports"] = supports
	if target_type == "active":
		state.skill_gem_inventory[target_index] = target
	else:
		state.spirit_gem_inventory[target_index] = target
	state.support_gem_inventory.remove_at(support_index)
	state.support_gem_cursor = clamp(state.support_gem_cursor, 0, max(0, state.support_gem_inventory.size() - 1))
	state.add_notice(str(support_data.get("name", support_id)) + " socketed")
	state.recompute_stats()

static func socket_selected_support_to_active(state: RVGameState) -> void:
	if state.skill_gem_inventory.is_empty() or state.support_gem_inventory.is_empty():
		state.add_notice("Need an active gem and a support gem")
		return
	state.skill_gem_cursor = clamp(state.skill_gem_cursor, 0, state.skill_gem_inventory.size() - 1)
	state.support_gem_cursor = clamp(state.support_gem_cursor, 0, state.support_gem_inventory.size() - 1)
	var support_item: Dictionary = state.support_gem_inventory[state.support_gem_cursor]
	if is_uncut_support_gem(support_item):
		state.add_notice("Right-click Uncut Support Gem to choose target and effect")
		return
	_socket_cut_support_to_active(state, state.support_gem_cursor, state.skill_gem_cursor)

static func _socket_cut_support_to_active(state: RVGameState, support_index: int, active_index: int) -> void:
	var active: Dictionary = state.skill_gem_inventory[active_index]
	if str(active.get("type", "active")) != "active":
		state.add_notice("Choose a cut active gem")
		return
	var support_item: Dictionary = state.support_gem_inventory[support_index]
	var support_id: String = str(support_item.get("gem_id", ""))
	var active_tags: Array = target_tags_for_gem("active", active)
	if not RVSkillGemDB.support_compatible_with_tags(support_id, active_tags):
		state.add_notice("Support is not compatible")
		return
	var supports: Array = active.get("supports", [])
	if supports.size() >= int(active.get("max_support_sockets", 2)):
		state.add_notice("No empty support sockets")
		return
	supports.append(support_id)
	active["supports"] = supports
	state.skill_gem_inventory[active_index] = active
	state.support_gem_inventory.remove_at(support_index)
	state.support_gem_cursor = clamp(state.support_gem_cursor, 0, max(0, state.support_gem_inventory.size() - 1))
	state.add_notice("Support socketed")
	state.recompute_stats()

static func remove_last_support_from_active(state: RVGameState) -> void:
	if state.skill_gem_inventory.is_empty():
		return
	state.skill_gem_cursor = clamp(state.skill_gem_cursor, 0, state.skill_gem_inventory.size() - 1)
	var active: Dictionary = state.skill_gem_inventory[state.skill_gem_cursor]
	if str(active.get("type", "active")) != "active":
		return
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
	var support_item: Dictionary = state.support_gem_inventory[state.support_gem_cursor]
	if is_uncut_support_gem(support_item):
		state.add_notice("Right-click Uncut Support Gem to choose target and effect")
		return
	var support_id: String = str(support_item.get("gem_id", ""))
	var spirit: Dictionary = state.spirit_gem_inventory[state.spirit_gem_cursor]
	if str(spirit.get("type", "spirit")) != "spirit":
		state.add_notice("Choose a cut spirit gem")
		return
	var spirit_tags: Array = target_tags_for_gem("spirit", spirit)
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
	if str(spirit.get("type", "spirit")) != "spirit":
		state.add_notice("Right-click an Uncut Spirit Gem to choose an aura")
		return
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
	if str(gem.get("type", "active")) != "active":
		state.add_notice("Cut the skill gem first")
		return
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
	if str(gem.get("type", "spirit")) != "spirit":
		state.add_notice("Cut the spirit gem first")
		return
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
	if str(gem.get("type", "spirit")) != "spirit":
		return 0
	var data: Dictionary = RVSkillGemDB.spirit_data(str(gem.get("gem_id", "")))
	var reservation: float = float(data.get("base_reservation", 0))
	for support_id_value: Variant in gem.get("supports", []):
		var support_data: Dictionary = RVSkillGemDB.support_data(str(support_id_value))
		reservation *= 1.0 + float(support_data.get("spirit_more", 0.0))
	return int(ceil(max(0.0, reservation)))

static func award_random_gem_drop(state: RVGameState, depth: int) -> String:
	var level: int = max(1, min(20, int(depth / 2) + state.rng.randi_range(1, 2)))
	var roll: float = state.rng.randf()
	if roll < 0.36:
		state.skill_gem_inventory.append(_make_uncut_skill_drop(state, level))
		state.ensure_defaults()
		return "Uncut Skill Gem"
	elif roll < 0.78:
		state.support_gem_inventory.append(_make_uncut_support_drop(state, level))
		return "Uncut Support Gem"
	else:
		state.spirit_gem_inventory.append(_make_uncut_spirit_drop(state, level))
		return "Uncut Spirit Gem"

static func grant_uncut_bundle(state: RVGameState) -> void:
	state.skill_gem_inventory.append(_make_uncut_skill_drop(state, max(1, state.level)))
	state.skill_gem_inventory.append(_make_uncut_skill_drop(state, max(1, state.level)))
	state.support_gem_inventory.append(_make_uncut_support_drop(state, max(1, state.level)))
	state.support_gem_inventory.append(_make_uncut_support_drop(state, max(1, state.level)))
	state.support_gem_inventory.append(_make_uncut_support_drop(state, max(1, state.level)))
	state.spirit_gem_inventory.append(_make_uncut_spirit_drop(state, max(1, state.level)))
	state.add_notice("Uncut gem bundle added")

static func target_tags_for_gem(target_type: String, gem: Dictionary) -> Array:
	if target_type == "spirit":
		return RVSkillGemDB.spirit_data(str(gem.get("gem_id", ""))).get("tags", [])
	return RVSkillGemDB.active_data(str(gem.get("gem_id", ""))).get("tags", [])

static func compatible_support_ids_for_target(target_type: String, gem: Dictionary) -> Array:
	return RVSkillGemDB.compatible_support_ids_for_tags(target_tags_for_gem(target_type, gem))

static func is_uncut_skill_gem(gem: Dictionary) -> bool:
	return str(gem.get("type", "")) == "uncut_skill" or str(gem.get("gem_id", "")) == "uncut_skill"

static func is_uncut_support_gem(gem: Dictionary) -> bool:
	return str(gem.get("type", "")) == "uncut_support" or str(gem.get("gem_id", "")) == "uncut_support"

static func is_uncut_spirit_gem(gem: Dictionary) -> bool:
	return str(gem.get("type", "")) == "uncut_spirit" or str(gem.get("gem_id", "")) == "uncut_spirit"

static func _make_uncut_skill_drop(state: RVGameState, level: int) -> Dictionary:
	return {
		"uid": _next_uid(state, "uncut_skill"),
		"type": "uncut_skill",
		"gem_id": "uncut_skill",
		"name": "Uncut Skill Gem",
		"level": level,
		"xp": 0.0,
		"description": "Right-click to choose an active skill."
	}

static func _make_uncut_support_drop(state: RVGameState, level: int) -> Dictionary:
	return {
		"uid": _next_uid(state, "uncut_support"),
		"type": "uncut_support",
		"gem_id": "uncut_support",
		"name": "Uncut Support Gem",
		"level": level,
		"xp": 0.0,
		"description": "Right-click to choose a target gem and support effect."
	}

static func _make_uncut_spirit_drop(state: RVGameState, level: int) -> Dictionary:
	return {
		"uid": _next_uid(state, "uncut_spirit"),
		"type": "uncut_spirit",
		"gem_id": "uncut_spirit",
		"name": "Uncut Spirit Gem",
		"level": level,
		"xp": 0.0,
		"description": "Right-click to choose a Spirit reservation skill."
	}

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

static func _add_unique(values: Array, value: String) -> void:
	if value == "":
		return
	if not values.has(value):
		values.append(value)
