class_name RVMapSystem
extends RefCounted

static func ensure_defaults(state: RVGameState) -> void:
	if state.map_stash.is_empty():
		state.map_stash.append(RVMapDB.make_map(state.rng, max(1, state.level), "ash_cistern"))
		state.map_stash.append(RVMapDB.make_map(state.rng, max(1, state.level + 2), "iron_catacomb"))
	state.map_cursor = clampi(state.map_cursor, 0, max(0, state.map_stash.size() - 1))

static func add_random_map_drop(state: RVGameState, map_level: int, source: String = "drop") -> Dictionary:
	ensure_defaults(state)
	var map_item: Dictionary = RVMapDB.make_map(state.rng, max(1, map_level))
	state.map_stash.append(map_item)
	state.map_cursor = state.map_stash.size() - 1
	state.add_notice("Map found: " + str(map_item.get("name", "Map")))
	return map_item

static func map_stash_text(state: RVGameState) -> String:
	ensure_defaults(state)
	var lines: Array[String] = []
	lines.append("MAP STASH")
	lines.append("W/S select · Enter/R run · G add dev map")
	lines.append("")
	if state.map_stash.is_empty():
		lines.append("No maps. Press G for a dev map.")
		return "\n".join(lines)
	for i: int in range(state.map_stash.size()):
		var map_item: Dictionary = state.map_stash[i]
		var marker: String = "> " if i == state.map_cursor else "  "
		lines.append(marker + str(i + 1) + ". " + str(map_item.get("name", "Map")) + "  T" + str(map_item.get("tier", 1)) + "  Lv " + str(map_item.get("map_level", 1)))
	return "\n".join(lines)

static func selected_map_detail(state: RVGameState) -> String:
	ensure_defaults(state)
	if state.map_stash.is_empty():
		return "No selected map."
	state.map_cursor = clampi(state.map_cursor, 0, state.map_stash.size() - 1)
	var map_item: Dictionary = state.map_stash[state.map_cursor]
	var lines: Array[String] = []
	lines.append(str(map_item.get("name", "Map")))
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

static func handle_panel_key(state: RVGameState, keycode: int) -> bool:
	if state.panel_mode != "map_device":
		return false
	ensure_defaults(state)
	match keycode:
		KEY_W, KEY_UP:
			state.map_cursor = wrapi(state.map_cursor - 1, 0, max(1, state.map_stash.size()))
			return true
		KEY_S, KEY_DOWN:
			state.map_cursor = wrapi(state.map_cursor + 1, 0, max(1, state.map_stash.size()))
			return true
		KEY_ENTER, KEY_KP_ENTER, KEY_R:
			prepare_selected_map_activity(state)
			return true
		KEY_G:
			add_random_map_drop(state, max(1, state.level + state.rooms_cleared), "dev")
			return true
	return false

static func prepare_selected_map_activity(state: RVGameState) -> void:
	ensure_defaults(state)
	if state.map_stash.is_empty():
		state.add_notice("No map selected")
		return
	state.map_cursor = clampi(state.map_cursor, 0, state.map_stash.size() - 1)
	var map_item: Dictionary = state.map_stash[state.map_cursor].duplicate(true)
	state.map_stash.remove_at(state.map_cursor)
	state.map_cursor = clampi(state.map_cursor, 0, max(0, state.map_stash.size() - 1))
	state.pending_start_activity = {
		"id": "map_device_run",
		"name": "Map: " + str(map_item.get("area_name", "Map")),
		"kind": "map",
		"rooms": int(map_item.get("rooms", 1)),
		"threat": float(map_item.get("threat", 1.0)),
		"map": map_item
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
	state.add_notice("Map boss defeated - loot added")
