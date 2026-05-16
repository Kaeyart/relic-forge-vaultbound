class_name RVSkillGemSystem
extends RefCounted

# Patch 056: Skill gem functionality depth pass.
# Adds gem XP/leveling, stricter socket validation, support previews,
# modified-stat calculation, clearer spirit reservation logic, and richer tooltips.

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
	for gem_variant: Variant in state.skill_gem_inventory:
		if typeof(gem_variant) != TYPE_DICTIONARY:
			continue
		var gem: Dictionary = Dictionary(gem_variant)
		if str(gem.get("type", "active")) != "active":
			continue
		if bool(gem.get("equipped", false)) and str(gem.get("skill_id", "")) == skill_id:
			return gem
	return {}

static func get_supported_skill_data(state: RVGameState, skill_id: String, base_data: Dictionary) -> Dictionary:
	var result: Dictionary = base_data.duplicate(true)
	var gem: Dictionary = get_active_gem_for_skill(state, skill_id)
	var gem_id: String = str(gem.get("gem_id", ""))
	var active_data: Dictionary = RVSkillGemDB.active_data(gem_id)
	var tags: Array = result.get("tags", RVSkillDB.tags(skill_id)).duplicate(true)
	var flags: Array = result.get("flags", RVSkillDB.flags(skill_id)).duplicate(true)

	var level: int = int(gem.get("level", 1)) if not gem.is_empty() else 1
	var damage_mult: float = _level_damage_multiplier(gem_id, level)
	var mana_mult: float = _level_mana_multiplier(gem_id, level)
	var cooldown_mult: float = 1.0
	var radius_mult: float = 1.0
	var crit_mult: float = 1.0
	var projectile_bonus: int = int(result.get("extra_projectiles", 0))
	var chain_bonus: int = int(result.get("chain_count", 0)) + int(active_data.get("base_chain_count", 0))
	var status_power: float = 1.0

	if not gem.is_empty():
		for tag_value: Variant in active_data.get("tags", []):
			_add_unique(tags, str(tag_value))
		for flag_value: Variant in active_data.get("flags", []):
			_add_unique(flags, str(flag_value))
		for support_id_value: Variant in gem.get("supports", []):
			var support_id: String = str(support_id_value)
			var support: Dictionary = RVSkillGemDB.support_data(support_id)
			if support.is_empty():
				continue
			damage_mult *= 1.0 + float(support.get("damage_more", 0.0))
			mana_mult *= 1.0 + float(support.get("mana_more", 0.0))
			cooldown_mult *= 1.0 + float(support.get("cooldown_more", 0.0))
			radius_mult *= 1.0 + float(support.get("radius_more", 0.0))
			crit_mult *= 1.0 + float(support.get("crit_chance_more", 0.0))
			projectile_bonus += int(support.get("extra_projectiles", 0))
			chain_bonus += int(support.get("chain_count", 0))
			status_power += float(support.get("status_power", 0.0))
			for flag2: Variant in support.get("flags", []):
				_add_unique(flags, str(flag2))
			for tag2: Variant in support.get("tags", []):
				var tag: String = str(tag2)
				if tag != "Support":
					_add_unique(tags, tag)

	result["damage"] = float(result.get("damage", active_data.get("base_damage", 10.0))) * damage_mult
	result["mana_cost"] = max(0.0, float(result.get("mana_cost", active_data.get("base_mana_cost", 0.0))) * mana_mult)
	result["cooldown"] = max(0.08, float(result.get("cooldown", active_data.get("base_cooldown", 0.5))) * cooldown_mult)
	result["crit_chance"] = float(result.get("crit_chance", active_data.get("base_crit", 0.05))) * crit_mult
	if result.has("radius"):
		result["radius"] = float(result.get("radius", active_data.get("base_radius", 0.0))) * radius_mult
	elif active_data.has("base_radius"):
		result["radius"] = float(active_data.get("base_radius", 0.0)) * radius_mult
	if result.has("impact_radius"):
		result["impact_radius"] = float(result.get("impact_radius", 0.0)) * radius_mult
	result["extra_projectiles"] = projectile_bonus
	result["chain_count"] = chain_bonus
	result["status_power"] = status_power
	result["flags"] = flags
	result["tags"] = tags
	result["gem_level"] = level
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
		for other_variant: Variant in state.skill_gem_inventory:
			if typeof(other_variant) == TYPE_DICTIONARY:
				var other: Dictionary = Dictionary(other_variant)
				if str(other.get("type", "active")) == "active" and bool(other.get("equipped", false)):
					equipped_count += 1
		if equipped_count <= 1:
			state.add_notice("Keep at least one active skill equipped")
			return
		gem["equipped"] = false
		state.add_notice(str(gem.get("name", "Skill Gem")) + " unequipped")
	else:
		var current_count: int = 0
		for other2_variant: Variant in state.skill_gem_inventory:
			if typeof(other2_variant) == TYPE_DICTIONARY:
				var other2: Dictionary = Dictionary(other2_variant)
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
	var level: int = clamp(int(old_gem.get("level", 1)), 1, int(data.get("max_level", 20)))
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
	var level: int = clamp(int(old_gem.get("level", 1)), 1, int(data.get("max_level", 20)))
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
	var level: int = clamp(int(support_item.get("level", 1)), 1, RVSkillGemDB.GEM_MAX_LEVEL)
	var cut_support: Dictionary = _make_support_drop(state, support_id, level)
	var result: Dictionary = can_socket_support_to_target(state, cut_support, target_type, target_index)
	if not bool(result.get("ok", false)):
		state.add_notice(str(result.get("reason", "Support cannot be socketed")))
		return
	_apply_support_to_target(state, cut_support, target_type, target_index)
	state.support_gem_inventory.remove_at(support_index)
	state.support_gem_cursor = clamp(state.support_gem_cursor, 0, max(0, state.support_gem_inventory.size() - 1))
	state.add_notice(str(cut_support.get("name", support_id)) + " socketed")
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
	socket_support_index_to_target(state, state.support_gem_cursor, "active", state.skill_gem_cursor)

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
	socket_support_index_to_target(state, state.support_gem_cursor, "spirit", state.spirit_gem_cursor)

static func socket_support_index_to_target(state: RVGameState, support_index: int, target_type: String, target_index: int) -> bool:
	if support_index < 0 or support_index >= state.support_gem_inventory.size():
		state.add_notice("Invalid support gem")
		return false
	var support_item: Dictionary = state.support_gem_inventory[support_index]
	var result: Dictionary = can_socket_support_to_target(state, support_item, target_type, target_index)
	if not bool(result.get("ok", false)):
		state.add_notice(str(result.get("reason", "Support cannot be socketed")))
		return false
	_apply_support_to_target(state, support_item, target_type, target_index)
	state.support_gem_inventory.remove_at(support_index)
	state.support_gem_cursor = clamp(state.support_gem_cursor, 0, max(0, state.support_gem_inventory.size() - 1))
	state.add_notice(str(support_item.get("name", "Support")) + " socketed")
	state.recompute_stats()
	return true

static func can_socket_support_to_target(state: RVGameState, support_item: Dictionary, target_type: String, target_index: int) -> Dictionary:
	if is_uncut_support_gem(support_item):
		return {"ok": false, "reason": "Choose a support effect first"}
	var support_id: String = str(support_item.get("gem_id", ""))
	var support_data: Dictionary = RVSkillGemDB.support_data(support_id)
	if support_data.is_empty():
		return {"ok": false, "reason": "Unknown support effect"}
	var target: Dictionary = _target_gem_by_index(state, target_type, target_index)
	if target.is_empty():
		return {"ok": false, "reason": "Invalid support target"}
	var expected_type: String = "spirit" if target_type == "spirit" else "active"
	if str(target.get("type", "")) != expected_type:
		return {"ok": false, "reason": "Target must be a cut " + expected_type + " gem"}
	var supports: Array = target.get("supports", [])
	if supports.size() >= int(target.get("max_support_sockets", 2)):
		return {"ok": false, "reason": "No empty support socket"}
	if supports.has(support_id):
		return {"ok": false, "reason": "Duplicate support not allowed"}
	var target_tags: Array = target_tags_for_gem(target_type, target)
	if not RVSkillGemDB.support_compatible_with_tags(support_id, target_tags):
		return {"ok": false, "reason": "Requires one of: " + _join_array(RVSkillGemDB.support_data(support_id).get("compatible_tags", []))}
	if target_type == "spirit":
		var projected: int = projected_spirit_reservation_with_support(state, target_index, support_id)
		var previous_reserved: int = int(state.spirit_reserved)
		var currently_enabled: bool = bool(target.get("enabled", false))
		if currently_enabled:
			var current_reservation: int = spirit_reservation(target)
			var new_total: int = previous_reserved - current_reservation + projected
			if new_total > state.spirit_max:
				return {"ok": false, "reason": "Support would exceed Spirit: " + str(new_total) + "/" + str(state.spirit_max)}
	return {"ok": true, "reason": "Compatible"}

static func _apply_support_to_target(state: RVGameState, support_item: Dictionary, target_type: String, target_index: int) -> void:
	var support_id: String = str(support_item.get("gem_id", ""))
	if target_type == "spirit":
		var spirit: Dictionary = state.spirit_gem_inventory[target_index]
		var spirit_supports: Array = spirit.get("supports", [])
		spirit_supports.append(support_id)
		spirit["supports"] = spirit_supports
		state.spirit_gem_inventory[target_index] = spirit
	else:
		var active: Dictionary = state.skill_gem_inventory[target_index]
		var active_supports: Array = active.get("supports", [])
		active_supports.append(support_id)
		active["supports"] = active_supports
		state.skill_gem_inventory[target_index] = active

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
	state.support_gem_inventory.append(_make_support_drop(state, support_id, int(active.get("level", 1))))
	state.add_notice("Support removed")
	state.recompute_stats()

static func remove_last_support_from_spirit(state: RVGameState) -> void:
	if state.spirit_gem_inventory.is_empty():
		return
	state.spirit_gem_cursor = clamp(state.spirit_gem_cursor, 0, state.spirit_gem_inventory.size() - 1)
	var spirit: Dictionary = state.spirit_gem_inventory[state.spirit_gem_cursor]
	if str(spirit.get("type", "spirit")) != "spirit":
		return
	var supports: Array = spirit.get("supports", [])
	if supports.is_empty():
		state.add_notice("No support to remove")
		return
	var support_id: String = str(supports.pop_back())
	spirit["supports"] = supports
	state.spirit_gem_inventory[state.spirit_gem_cursor] = spirit
	state.support_gem_inventory.append(_make_support_drop(state, support_id, int(spirit.get("level", 1))))
	state.add_notice("Spirit support removed")
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
	var level: int = int(gem.get("level", 1))
	reservation *= 1.0 + max(0, level - 1) * 0.01
	for support_id_value: Variant in gem.get("supports", []):
		var support_data: Dictionary = RVSkillGemDB.support_data(str(support_id_value))
		reservation *= 1.0 + float(support_data.get("spirit_more", 0.0))
	return int(ceil(max(0.0, reservation)))

static func projected_spirit_reservation_with_support(state: RVGameState, spirit_index: int, support_id: String) -> int:
	if spirit_index < 0 or spirit_index >= state.spirit_gem_inventory.size():
		return 0
	var spirit: Dictionary = Dictionary(state.spirit_gem_inventory[spirit_index]).duplicate(true)
	var supports: Array = spirit.get("supports", [])
	if not supports.has(support_id):
		supports.append(support_id)
	spirit["supports"] = supports
	return spirit_reservation(spirit)

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

static func award_gem_xp(state: RVGameState, amount: float, reason: String = "") -> void:
	if state == null:
		return
	var leveled: Array[String] = []
	for i: int in range(state.skill_gem_inventory.size()):
		var gem: Dictionary = state.skill_gem_inventory[i]
		if str(gem.get("type", "")) == "active" and bool(gem.get("equipped", false)):
			if _add_xp_to_gem(gem, amount):
				leveled.append(str(gem.get("name", "Skill")))
			state.skill_gem_inventory[i] = gem
			var supports: Array = gem.get("supports", [])
			_add_xp_to_matching_support_inventory(state, supports, amount * 0.0)
	for j: int in range(state.spirit_gem_inventory.size()):
		var spirit: Dictionary = state.spirit_gem_inventory[j]
		if str(spirit.get("type", "")) == "spirit" and bool(spirit.get("enabled", false)):
			if _add_xp_to_gem(spirit, amount * 0.85):
				leveled.append(str(spirit.get("name", "Spirit")))
			state.spirit_gem_inventory[j] = spirit
	# Loose support gems do not gain XP. Socketed supports are represented by support ids,
	# so their level currently inherits target gem level for preview/power.
	if not leveled.is_empty():
		state.add_notice("Gem leveled: " + ", ".join(PackedStringArray(leveled.slice(0, min(3, leveled.size())))))
	state.recompute_stats()

static func xp_to_next_level(level: int) -> float:
	var lvl: int = max(1, level)
	return 80.0 + float(lvl * lvl) * 32.0

static func support_effect_preview_text(state: RVGameState, support_index: int, target_type: String, target_index: int) -> String:
	if state == null or support_index < 0 or support_index >= state.support_gem_inventory.size():
		return "No support selected."
	var support_item: Dictionary = state.support_gem_inventory[support_index]
	return support_preview_text(state, support_item, target_type, target_index)

static func support_preview_text(state: RVGameState, support_item: Dictionary, target_type: String, target_index: int) -> String:
	var support_id: String = str(support_item.get("gem_id", ""))
	if is_uncut_support_gem(support_item):
		return "Uncut Support Gem\nRight-click to choose target and support effect."
	var support_data: Dictionary = RVSkillGemDB.support_data(support_id)
	if support_data.is_empty():
		return "Unknown support."
	var target: Dictionary = _target_gem_by_index(state, target_type, target_index)
	var result: Dictionary = can_socket_support_to_target(state, support_item, target_type, target_index)
	var text: String = str(support_data.get("name", support_id)) + "\n"
	text += "Compatible Tags: " + _join_array(support_data.get("compatible_tags", [])) + "\n"
	if bool(result.get("ok", false)):
		text += "[OK] Can socket into " + str(target.get("name", "target")) + "\n"
	else:
		text += "[NO] " + str(result.get("reason", "Not compatible")) + "\n"
	text += "\nPreview:\n"
	text += _support_delta_lines(support_data)
	if not target.is_empty() and target_type == "spirit":
		text += "Projected Reservation: " + str(projected_spirit_reservation_with_support(state, target_index, support_id)) + " Spirit\n"
	return text

static func gem_detail_text(state: RVGameState, gem: Dictionary, family: String = "") -> String:
	if gem.is_empty():
		return "None."
	var gem_type: String = str(gem.get("type", family))
	var text: String = str(gem.get("name", "Gem")) + "\n"
	text += _rarity_line_for_gem(gem_type) + "  Level " + str(int(gem.get("level", 1))) + "\n"
	text += "XP: " + str(int(float(gem.get("xp", 0.0)))) + " / " + str(int(xp_to_next_level(int(gem.get("level", 1))))) + "\n"
	if gem_type.begins_with("uncut"):
		text += str(gem.get("description", "Right-click to choose what this becomes.")) + "\n"
		return text
	if gem_type == "active":
		var data: Dictionary = RVSkillGemDB.active_data(str(gem.get("gem_id", "")))
		text += "Tags: " + _join_array(data.get("tags", [])) + "\n"
		text += "Identity: " + str(data.get("primary_identity", "Skill")) + "\n"
		text += str(data.get("description", "")) + "\n"
		var modified: Dictionary = get_supported_skill_data(state, str(gem.get("skill_id", data.get("skill_id", ""))), data)
		text += "\nCurrent Stats:\n"
		text += "Damage: " + _fmt_float(float(modified.get("damage", data.get("base_damage", 0.0)))) + "\n"
		text += "Mana Cost: " + _fmt_float(float(modified.get("mana_cost", data.get("base_mana_cost", 0.0)))) + "\n"
		text += "Cooldown: " + _fmt_float(float(modified.get("cooldown", data.get("base_cooldown", 0.0)))) + " sec\n"
		if int(modified.get("chain_count", 0)) > 0:
			text += "Chains: " + str(int(modified.get("chain_count", 0))) + "\n"
		if int(modified.get("extra_projectiles", 0)) > 0:
			text += "Extra Projectiles: " + str(int(modified.get("extra_projectiles", 0))) + "\n"
		text += "Sockets: " + str(Array(gem.get("supports", [])).size()) + "/" + str(int(gem.get("max_support_sockets", 2))) + "\n"
		text += "Equipped: " + ("yes" if bool(gem.get("equipped", false)) else "no") + "\n"
		text += _support_line(gem)
	elif gem_type == "support":
		var support_data: Dictionary = RVSkillGemDB.support_data(str(gem.get("gem_id", "")))
		text += "Tags: " + _join_array(support_data.get("tags", [])) + "\n"
		text += str(support_data.get("description", "")) + "\n"
		text += "Compatible: " + _join_array(support_data.get("compatible_tags", [])) + "\n"
		text += _support_delta_lines(support_data)
	elif gem_type == "spirit":
		var spirit_data: Dictionary = RVSkillGemDB.spirit_data(str(gem.get("gem_id", "")))
		text += "Tags: " + _join_array(spirit_data.get("tags", [])) + "\n"
		text += str(spirit_data.get("description", "")) + "\n"
		text += "Reservation: " + str(spirit_reservation(gem)) + " Spirit\n"
		text += "Sockets: " + str(Array(gem.get("supports", [])).size()) + "/" + str(int(gem.get("max_support_sockets", 2))) + "\n"
		text += "Enabled: " + ("yes" if bool(gem.get("enabled", false)) else "no") + "\n"
		text += _support_line(gem)
	return text

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
		"level": clamp(level, 1, int(data.get("max_level", 20))),
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
		"level": clamp(level, 1, RVSkillGemDB.GEM_MAX_LEVEL),
		"xp": 0.0
	}

static func _make_spirit_drop(state: RVGameState, gem_id: String, level: int) -> Dictionary:
	var data: Dictionary = RVSkillGemDB.spirit_data(gem_id)
	return {
		"uid": _next_uid(state, "spirit"),
		"type": "spirit",
		"gem_id": gem_id,
		"name": str(data.get("name", gem_id.capitalize())),
		"level": clamp(level, 1, RVSkillGemDB.GEM_MAX_LEVEL),
		"xp": 0.0,
		"max_support_sockets": int(data.get("base_sockets", 2)),
		"supports": [],
		"enabled": false
	}

static func _add_xp_to_gem(gem: Dictionary, amount: float) -> bool:
	if str(gem.get("type", "")).begins_with("uncut"):
		return false
	var max_level: int = RVSkillGemDB.GEM_MAX_LEVEL
	var level: int = int(gem.get("level", 1))
	if level >= max_level:
		return false
	var xp: float = float(gem.get("xp", 0.0)) + max(0.0, amount)
	var did_level: bool = false
	while level < max_level and xp >= xp_to_next_level(level):
		xp -= xp_to_next_level(level)
		level += 1
		did_level = true
	gem["level"] = level
	gem["xp"] = xp
	return did_level

static func _add_xp_to_matching_support_inventory(_state: RVGameState, _supports: Array, _amount: float) -> void:
	# Socketed supports are currently stored by id, not as full gem dictionaries.
	# This hook is kept so we can migrate to support instances later without changing callers.
	pass

static func _target_gem_by_index(state: RVGameState, target_type: String, target_index: int) -> Dictionary:
	if state == null:
		return {}
	if target_type == "spirit":
		if target_index >= 0 and target_index < state.spirit_gem_inventory.size():
			return Dictionary(state.spirit_gem_inventory[target_index])
	else:
		if target_index >= 0 and target_index < state.skill_gem_inventory.size():
			return Dictionary(state.skill_gem_inventory[target_index])
	return {}

static func _level_damage_multiplier(gem_id: String, level: int) -> float:
	var data: Dictionary = RVSkillGemDB.active_data(gem_id)
	return 1.0 + max(0, level - 1) * float(data.get("damage_per_level", 0.06))

static func _level_mana_multiplier(gem_id: String, level: int) -> float:
	var data: Dictionary = RVSkillGemDB.active_data(gem_id)
	return 1.0 + max(0, level - 1) * float(data.get("mana_per_level", 0.025))

static func _support_delta_lines(support_data: Dictionary) -> String:
	var lines: Array[String] = []
	_append_percent_line(lines, "Damage", float(support_data.get("damage_more", 0.0)))
	_append_percent_line(lines, "Mana Cost", float(support_data.get("mana_more", 0.0)))
	_append_percent_line(lines, "Cooldown", float(support_data.get("cooldown_more", 0.0)))
	_append_percent_line(lines, "Spirit Reservation", float(support_data.get("spirit_more", 0.0)))
	_append_percent_line(lines, "Area", float(support_data.get("radius_more", 0.0)))
	if int(support_data.get("chain_count", 0)) != 0:
		lines.append("Chain: +" + str(int(support_data.get("chain_count", 0))))
	if int(support_data.get("extra_projectiles", 0)) != 0:
		lines.append("Projectiles: +" + str(int(support_data.get("extra_projectiles", 0))))
	if lines.is_empty():
		for line_value: Variant in support_data.get("preview_lines", []):
			lines.append(str(line_value))
	return "\n".join(PackedStringArray(lines)) + "\n"

static func _append_percent_line(lines: Array[String], label: String, value: float) -> void:
	if abs(value) < 0.001:
		return
	var sign: String = "+" if value > 0.0 else ""
	lines.append(label + ": " + sign + str(int(round(value * 100.0))) + "%")

static func _support_line(gem: Dictionary) -> String:
	var supports: Array = gem.get("supports", [])
	if supports.is_empty():
		return "Supports: none\n"
	var names: Array[String] = []
	for support_id_value: Variant in supports:
		var support_data: Dictionary = RVSkillGemDB.support_data(str(support_id_value))
		names.append(str(support_data.get("name", support_id_value)))
	return "Supports: " + ", ".join(PackedStringArray(names)) + "\n"

static func _rarity_line_for_gem(gem_type: String) -> String:
	match gem_type:
		"active":
			return "Active Skill Gem"
		"support":
			return "Support Gem"
		"spirit":
			return "Spirit Gem"
		"uncut_skill":
			return "Uncut Skill Gem"
		"uncut_support":
			return "Uncut Support Gem"
		"uncut_spirit":
			return "Uncut Spirit Gem"
	return "Gem"

static func _fmt_float(value: float) -> String:
	if abs(value - round(value)) < 0.05:
		return str(int(round(value)))
	return str(snapped(value, 0.1))

static func _join_array(values: Array) -> String:
	var result: Array[String] = []
	for value: Variant in values:
		result.append(str(value))
	return ", ".join(PackedStringArray(result))

static func _next_uid(state: RVGameState, prefix: String) -> String:
	var uid: String = prefix + "_" + str(state.gem_uid_counter)
	state.gem_uid_counter += 1
	return uid

static func _add_unique(values: Array, value: String) -> void:
	if value == "":
		return
	if not values.has(value):
		values.append(value)
