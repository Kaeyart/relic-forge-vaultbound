class_name RVMapSystem
extends RefCounted

const MAP_TIER_ALL: int = 0
const MAX_MAP_TIER: int = 16

static func normalize_map_item(map_item: Dictionary, source: String = "map_system", state: RVGameState = null) -> Dictionary:
	return RVMapItemSystem.normalize_map_item(map_item, source, state)

static func is_map_item(value: Variant) -> bool:
	return RVMapItemSystem.is_map_item(value)

static func ensure_defaults(state: RVGameState) -> void:
	if state == null:
		return
	if int(state.get("map_tier_filter")) < 0 or int(state.get("map_tier_filter")) > MAX_MAP_TIER:
		state.set("map_tier_filter", MAP_TIER_ALL)
	if state.get("completed_maps") == null:
		state.set("completed_maps", {})
	if state.get("map_system_seeded") == null:
		state.set("map_system_seeded", false)
	_normalize_existing_maps(state)
	var seeded: bool = bool(state.get("map_system_seeded"))
	if not seeded and state.map_stash.is_empty() and _count_backpack_maps(state) == 0:
		state.map_stash.append(_normalize_map_item(RVMapDB.make_map(state.rng, max(1, state.level), "ash_cistern"), "starter", state))
		state.map_stash.append(_normalize_map_item(RVMapDB.make_map(state.rng, max(1, state.level + 2), "iron_catacomb"), "starter", state))
		state.set("map_system_seeded", true)
	_ensure_cursor_on_filter(state)

static func add_random_map_drop(state: RVGameState, map_level: int, source: String = "drop") -> Dictionary:
	ensure_defaults(state)
	var map_item: Dictionary = RVMapItemSystem.normalize_map_item(RVMapDB.make_map(state.rng, max(1, map_level)), source, state)
	state.backpack.append(map_item)
	state.add_notice("Map item found: " + str(map_item.get("name", "Map")) + " (Backpack)")
	return map_item

static func deposit_all_maps_from_backpack_to_map_stash(state: RVGameState) -> int:
	ensure_defaults(state)
	var moved: int = 0
	for i: int in range(state.backpack.size() - 1, -1, -1):
		var value: Variant = state.backpack[i]
		if _is_map_item(value):
			var map_item: Dictionary = RVMapItemSystem.normalize_map_item(Dictionary(value), "backpack", state)
			state.map_stash.append(map_item)
			state.backpack.remove_at(i)
			moved += 1
	if moved > 0:
		state.map_cursor = state.map_stash.size() - 1
		state.add_notice("Stored " + str(moved) + " map item" + ("s" if moved != 1 else "") + " in Map Tab")
	else:
		state.add_notice("No map items in backpack")
	_ensure_cursor_on_filter(state)
	return moved

static func withdraw_selected_map_to_backpack(state: RVGameState) -> bool:
	ensure_defaults(state)
	var index: int = selected_map_index(state)
	if index < 0 or index >= state.map_stash.size():
		state.add_notice("No stored map selected")
		return false
	var map_item: Dictionary = RVMapItemSystem.normalize_map_item(Dictionary(state.map_stash[index]), "map_tab", state)
	state.map_stash.remove_at(index)
	state.backpack.append(map_item)
	state.add_notice("Moved map to backpack: " + str(map_item.get("name", "Map")))
	_ensure_cursor_on_filter(state)
	return true

static func cycle_tier_filter(state: RVGameState, delta: int) -> bool:
	ensure_defaults(state)
	var next_filter: int = wrapi(int(state.get("map_tier_filter")) + delta, 0, MAX_MAP_TIER + 1)
	state.set("map_tier_filter", next_filter)
	_ensure_cursor_on_filter(state)
	return true

static func move_cursor(state: RVGameState, delta: int) -> bool:
	ensure_defaults(state)
	var indices: Array = filtered_map_indices(state)
	if indices.is_empty():
		return false
	var current_index: int = selected_map_index(state)
	var local_pos: int = indices.find(current_index)
	if local_pos < 0:
		local_pos = 0
	else:
		local_pos = wrapi(local_pos + delta, 0, indices.size())
	state.map_cursor = int(indices[local_pos])
	return true

static func filtered_map_indices(state: RVGameState) -> Array:
	var result: Array = []
	var filter_tier: int = int(state.get("map_tier_filter"))
	for i: int in range(state.map_stash.size()):
		var value: Variant = state.map_stash[i]
		if not _is_map_item(value):
			continue
		var map_item: Dictionary = Dictionary(value)
		if filter_tier == MAP_TIER_ALL or int(map_item.get("tier", 1)) == filter_tier:
			result.append(i)
	return result

static func selected_map_index(state: RVGameState) -> int:
	if state.map_stash.is_empty():
		return -1
	var indices: Array = filtered_map_indices(state)
	if indices.is_empty():
		return -1
	if indices.has(state.map_cursor):
		return state.map_cursor
	return int(indices[0])

static func selected_map_item(state: RVGameState) -> Dictionary:
	ensure_defaults(state)
	var index: int = selected_map_index(state)
	if index < 0 or index >= state.map_stash.size():
		return {}
	state.map_cursor = index
	return _normalize_map_item(Dictionary(state.map_stash[index]), "map_tab", state)

static func map_stash_text(state: RVGameState) -> String:
	ensure_defaults(state)
	var lines: Array[String] = []
	lines.append("MAP TAB")
	lines.append("W/S select · A/D tier filter · M store backpack maps · Backspace withdraw")
	lines.append("Filter: " + tier_filter_text(state) + " · Backpack maps: " + str(_count_backpack_maps(state)))
	lines.append("")
	var indices: Array = filtered_map_indices(state)
	if indices.is_empty():
		lines.append("No stored maps for this filter.")
		lines.append("Press G for a dev map drop, then M to store it.")
		return "\n".join(lines)
	for local_i: int in range(min(indices.size(), 8)):
		var index: int = int(indices[local_i])
		var map_item: Dictionary = RVMapItemSystem.normalize_map_item(Dictionary(state.map_stash[index]), "map_tab", state)
		var marker: String = "> " if index == state.map_cursor else "  "
		var done: String = "✓" if is_map_completed(state, map_item) else "□"
		lines.append(marker + done + " T" + str(map_item.get("tier", 1)) + " · " + str(map_item.get("name", "Map")))
	if indices.size() > 8:
		lines.append("  … " + str(indices.size() - 8) + " more")
	return "\n".join(lines)

static func selected_map_detail(state: RVGameState) -> String:
	ensure_defaults(state)
	var map_item: Dictionary = selected_map_item(state)
	if map_item.is_empty():
		return "No selected map."
	var lines: Array[String] = []
	lines.append(str(map_item.get("name", "Map")) + ("  ✓ COMPLETED" if is_map_completed(state, map_item) else "  □ NOT COMPLETED"))
	lines.append(str(map_item.get("area_name", "Area")))
	lines.append("Rarity: " + str(map_item.get("rarity", "Normal")) + " · Tier " + str(map_item.get("tier", 1)) + " · Level " + str(map_item.get("map_level", 1)))
	lines.append("Boss: " + str(map_item.get("boss_name", "Map Boss")))
	lines.append("Threat: " + str(snappedf(float(map_item.get("threat", 1.0)), 0.01)) + " · Pack Size: " + str(snappedf(float(map_item.get("pack_size", 1.0)), 0.01)))
	lines.append("")
	lines.append("Mods:")
	for mod_value: Variant in Array(map_item.get("mods", [])):
		lines.append("- " + str(mod_value))
	lines.append("")
	lines.append(str(map_item.get("description", "")))
	return "\n".join(lines)

static func tier_filter_text(state: RVGameState) -> String:
	var tier: int = int(state.get("map_tier_filter"))
	return "All Tiers" if tier == MAP_TIER_ALL else "Tier " + str(tier)

static func completion_summary_text(state: RVGameState) -> String:
	ensure_defaults(state)
	var completed_count: int = Dictionary(state.get("completed_maps")).size()
	return "Completed map bases: " + str(completed_count)

static func handle_panel_key(state: RVGameState, keycode: int) -> bool:
	if state.panel_mode != "map_device":
		return false
	ensure_defaults(state)
	match keycode:
		KEY_W, KEY_UP:
			return move_cursor(state, -1)
		KEY_S, KEY_DOWN:
			return move_cursor(state, 1)
		KEY_A, KEY_LEFT:
			return cycle_tier_filter(state, -1)
		KEY_D, KEY_RIGHT:
			return cycle_tier_filter(state, 1)
		KEY_M:
			deposit_all_maps_from_backpack_to_map_stash(state)
			return true
		KEY_BACKSPACE, KEY_DELETE:
			return withdraw_selected_map_to_backpack(state)
		KEY_ENTER, KEY_KP_ENTER, KEY_R:
			prepare_selected_map_activity(state)
			return true
		KEY_G:
			add_random_map_drop(state, max(1, state.level + state.rooms_cleared), "dev")
			return true
	return false

static func prepare_selected_map_activity(state: RVGameState) -> void:
	ensure_defaults(state)
	var index: int = selected_map_index(state)
	if index < 0 or index >= state.map_stash.size():
		state.add_notice("No stored map selected")
		return
	var map_item: Dictionary = RVMapItemSystem.normalize_map_item(Dictionary(state.map_stash[index]), "map_tab", state).duplicate(true)
	state.map_stash.remove_at(index)
	_ensure_cursor_on_filter(state)
	state.pending_start_activity = {
		"id": "map_device_run",
		"name": "Map: " + str(map_item.get("area_name", "Map")),
		"kind": "map",
		"rooms": int(map_item.get("rooms", 1)),
		"threat": float(map_item.get("threat", 1.0)),
		"map": map_item,
		"layout_archetype": RVMapLayoutSystem.archetype_for_map(map_item),
		"layout_label": RVMapLayoutSystem.layout_label(RVMapLayoutSystem.archetype_for_map(map_item)),
	}
	state.panel_mode = ""
	state.add_notice("Opening map: " + str(map_item.get("name", "Map")))

static func award_map_enemy_drop(state: RVGameState, depth: int) -> void:
	if state.rng.randf() < 0.055:
		state.backpack.append(RVItemDB.generate_drop(state, depth))
		state.add_notice("Map monster dropped an item")
	if state.rng.randf() < 0.012:
		add_random_map_drop(state, depth, "monster")

static func award_map_boss_loot(state: RVGameState, map_item: Dictionary) -> void:
	var level: int = max(1, int(map_item.get("map_level", state.level)))
	mark_map_completed(state, map_item)
	state.rooms_cleared += 1
	state.gold += 45 + level * 4
	state.materials["shards"] = int(state.materials.get("shards", 0)) + 6
	state.materials["embers"] = int(state.materials.get("embers", 0)) + 4
	state.add_xp(110.0 + float(level) * 12.0)
	var drops: int = 2
	if str(map_item.get("rarity", "Normal")) == "Rare":
		drops = 3
	for i: int in range(drops):
		state.backpack.append(RVItemDB.generate_drop(state, level + i))
	if state.rng.randf() < 0.65:
		RVSkillGemSystem.award_random_gem_drop(state, level)
	if state.rng.randf() < 0.55:
		add_random_map_drop(state, level + 1, "boss")
	state.add_notice("Map completed: " + str(map_item.get("name", "Map")))

static func mark_map_completed(state: RVGameState, map_item: Dictionary) -> void:
	if state.get("completed_maps") == null:
		state.set("completed_maps", {})
	var completed: Dictionary = Dictionary(state.get("completed_maps"))
	var key: String = completion_key_for_map(map_item)
	completed[key] = {
		"id": str(map_item.get("id", "map")),
		"tier": int(map_item.get("tier", 1)),
		"name": str(map_item.get("name", "Map")),
		"completed_at_unix": Time.get_unix_time_from_system(),
	}
	state.set("completed_maps", completed)

static func is_map_completed(state: RVGameState, map_item: Dictionary) -> bool:
	var key: String = completion_key_for_map(map_item)
	var completed: Dictionary = Dictionary(state.get("completed_maps"))
	return completed.has(key) or bool(map_item.get("completed", false))

static func completion_key_for_map(map_item: Dictionary) -> String:
	return str(map_item.get("completion_key", str(map_item.get("id", "map")) + "_t" + str(int(map_item.get("tier", 1)))))

static func _ensure_cursor_on_filter(state: RVGameState) -> void:
	if state.map_stash.is_empty():
		state.map_cursor = 0
		return
	var indices: Array = filtered_map_indices(state)
	if indices.is_empty():
		state.map_cursor = clampi(state.map_cursor, 0, max(0, state.map_stash.size() - 1))
		return
	if not indices.has(state.map_cursor):
		state.map_cursor = int(indices[0])
	else:
		state.map_cursor = clampi(state.map_cursor, 0, max(0, state.map_stash.size() - 1))

static func _normalize_existing_maps(state: RVGameState) -> void:
	for i: int in range(state.map_stash.size()):
		var value: Variant = state.map_stash[i]
		if typeof(value) == TYPE_DICTIONARY:
			state.map_stash[i] = RVMapItemSystem.normalize_map_item(Dictionary(value), "map_tab", state)
	for i: int in range(state.backpack.size()):
		var value: Variant = state.backpack[i]
		if _is_map_item(value):
			state.backpack[i] = RVMapItemSystem.normalize_map_item(Dictionary(value), "backpack", state)

static func _normalize_map_item(map_item: Dictionary, source: String = "unknown", state: RVGameState = null) -> Dictionary:
	var out: Dictionary = map_item.duplicate(true)
	var tier: int = clampi(int(out.get("tier", 1)), 1, MAX_MAP_TIER)
	var map_level: int = max(1, int(out.get("map_level", out.get("item_level", tier * 8))))
	var id: String = str(out.get("id", "map"))
	if str(out.get("uid", "")) == "":
		out["uid"] = "map_" + str(Time.get_ticks_msec()) + "_" + str(randi())
	out["id"] = id
	out["item_type"] = "map"
	out["category"] = "map"
	out["slot"] = "map"
	out["base_type"] = "Map"
	out["display_type"] = "Map"
	out["map_item"] = true
	out["stack_size"] = 1
	out["quantity"] = 1
	out["source"] = str(out.get("source", source))
	out["tier"] = tier
	out["map_level"] = map_level
	out["item_level"] = int(out.get("item_level", map_level))
	out["completion_key"] = id + "_t" + str(tier)
	out["completed"] = bool(out.get("completed", false))
	if state != null and Dictionary(state.get("completed_maps")).has(str(out.get("completion_key", ""))):
		out["completed"] = true
	if not out.has("rarity"):
		out["rarity"] = "Normal"
	if not out.has("name"):
		out["name"] = str(out.get("rarity", "Normal")) + " Map"
	return out

static func _is_map_item(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var item: Dictionary = Dictionary(value)
	return bool(item.get("map_item", false)) or str(item.get("item_type", "")) == "map" or str(item.get("category", "")) == "map" or item.has("map_level") and item.has("tier") and item.has("boss_name")

static func _count_backpack_maps(state: RVGameState) -> int:
	var count: int = 0
	for value: Variant in state.backpack:
		if _is_map_item(value):
			count += 1
	return count
