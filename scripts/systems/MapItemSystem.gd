class_name RVMapItemSystem
extends RefCounted

const MAX_MAP_TIER: int = 16

static func is_map_item(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var item: Dictionary = Dictionary(value)
	return (
		bool(item.get("map_item", false))
		or str(item.get("item_type", "")) == "map"
		or str(item.get("category", "")) == "map"
		or str(item.get("slot", "")) == "map"
		or item.has("map_level") and item.has("tier") and item.has("boss_name")
	)

static func normalize_map_item(value: Dictionary, source: String = "inventory", state: Object = null) -> Dictionary:
	var out: Dictionary = value.duplicate(true)
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
	out["stash_tab"] = "maps"
	out["usable_context"] = "map_device"
	out["stack_size"] = 1
	out["quantity"] = 1
	out["source"] = str(out.get("source", source))
	out["tier"] = tier
	out["map_level"] = map_level
	out["item_level"] = int(out.get("item_level", map_level))
	out["inv_w"] = clampi(int(out.get("inv_w", 1)), 1, 1)
	out["inv_h"] = clampi(int(out.get("inv_h", 1)), 1, 1)
	out["completion_key"] = str(out.get("completion_key", id + "_t" + str(tier)))
	out["completed"] = bool(out.get("completed", false))
	if state != null:
		var completed_value: Variant = state.get("completed_maps")
		if typeof(completed_value) == TYPE_DICTIONARY and Dictionary(completed_value).has(str(out.get("completion_key", ""))):
			out["completed"] = true
	if not out.has("rarity"):
		out["rarity"] = "Normal"
	if not out.has("name"):
		out["name"] = str(out.get("rarity", "Normal")) + " Map"
	return out

static func normalize_inventory_value(value: Variant, source: String = "inventory", state: Object = null) -> Dictionary:
	if is_map_item(value):
		return normalize_map_item(Dictionary(value), source, state)
	if typeof(value) == TYPE_DICTIONARY:
		return RVItemDB.normalize_item(Dictionary(value))
	return RVItemDB.normalize_item(value)

static func map_item_label(value: Dictionary) -> String:
	var item: Dictionary = normalize_map_item(value)
	var done: String = "✓" if bool(item.get("completed", false)) else "□"
	return "%s\nT%s MAP" % [done, int(item.get("tier", 1))]

static func map_item_name(value: Dictionary) -> String:
	var item: Dictionary = normalize_map_item(value)
	return str(item.get("name", "Map"))

static func map_button_color(value: Dictionary, selected: bool = false) -> Color:
	if selected:
		return Color(1.0, 0.82, 0.32, 1.0)
	var item: Dictionary = normalize_map_item(value)
	if bool(item.get("completed", false)):
		return Color(0.32, 0.82, 0.44, 1.0)
	match str(item.get("rarity", "Normal")):
		"Rare": return Color(0.95, 0.72, 0.22, 1.0)
		"Magic": return Color(0.46, 0.60, 1.0, 1.0)
		"Unique": return Color(1.0, 0.48, 0.15, 1.0)
		_: return Color(0.78, 0.66, 0.46, 1.0)

static func map_rarity_hex(rarity: String) -> String:
	match rarity:
		"Unique": return "#ff9d3d"
		"Rare": return "#f2d75c"
		"Magic": return "#82a4ff"
		_: return "#d8c9a4"

static func map_detail_bbcode(value: Dictionary, state: Object = null, header: String = "SELECTED MAP ITEM", source_line: String = "Physical map item") -> String:
	var item: Dictionary = normalize_map_item(value, "detail", state)
	var rarity: String = str(item.get("rarity", "Normal"))
	var color: String = map_rarity_hex(rarity)
	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % header)
	lines.append("[color=#aaaaaa]%s[/color]" % source_line)
	lines.append("")
	lines.append("[color=%s][b]%s[/b][/color]" % [color, str(item.get("name", "Map"))])
	lines.append("%s Map · Tier %s · Area Level %s" % [rarity, int(item.get("tier", 1)), int(item.get("map_level", item.get("item_level", 1)))])
	lines.append("Area: %s" % str(item.get("area_name", "Unknown Area")))
	lines.append("Boss: %s" % str(item.get("boss_name", "Map Boss")))
	lines.append("Completion: %s" % ("Completed" if bool(item.get("completed", false)) else "Not completed"))
	lines.append("Pack Size: %s · Threat: %s" % [str(snappedf(float(item.get("pack_size", 1.0)), 0.01)), str(snappedf(float(item.get("threat", 1.0)), 0.01))])
	var mods: Array = Array(item.get("mods", []))
	if not mods.is_empty():
		lines.append("")
		lines.append("[b]Map Modifiers[/b]")
		for mod_value: Variant in mods:
			lines.append(" • %s" % str(mod_value))
	var desc: String = str(item.get("description", ""))
	if desc != "":
		lines.append("")
		lines.append("[color=#b9a882]%s[/color]" % desc)
	lines.append("")
	lines.append("[color=#d8a95b]Use:[/color] store in the Map Tab, then activate it at the Map Device.")
	return "\n".join(lines)

static func map_plain_text(value: Dictionary, state: Object = null) -> String:
	var text: String = map_detail_bbcode(value, state)
	for token: String in ["[b]", "[/b]", "[i]", "[/i]"]:
		text = text.replace(token, "")
	var regex: RegEx = RegEx.new()
	if regex.compile("\\[/?color[^\\]]*\\]") == OK:
		text = regex.sub(text, "", true)
	return text

static func deposit_selected_backpack_map_to_map_tab(state: RVGameState) -> bool:
	return move_backpack_map_to_map_tab(state, int(state.inventory_cursor))

static func move_backpack_map_to_map_tab(state: RVGameState, backpack_index: int) -> bool:
	if state == null or backpack_index < 0 or backpack_index >= state.backpack.size():
		return false
	var value: Variant = state.backpack[backpack_index]
	if not is_map_item(value):
		return false
	var map_item: Dictionary = normalize_map_item(Dictionary(value), "backpack", state)
	state.backpack.remove_at(backpack_index)
	state.map_stash.append(map_item)
	state.map_cursor = state.map_stash.size() - 1
	state.inventory_cursor = clampi(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
	state.add_notice("Stored map in Map Tab: " + str(map_item.get("name", "Map")))
	return true

static func deposit_all_backpack_maps_to_map_tab(state: RVGameState) -> int:
	if state == null:
		return 0
	var moved: int = 0
	for i: int in range(state.backpack.size() - 1, -1, -1):
		var value: Variant = state.backpack[i]
		if is_map_item(value):
			state.map_stash.append(normalize_map_item(Dictionary(value), "backpack", state))
			state.backpack.remove_at(i)
			moved += 1
	if moved > 0:
		state.map_cursor = state.map_stash.size() - 1
		state.inventory_cursor = clampi(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
		state.add_notice("Stored " + str(moved) + " map item" + ("s" if moved != 1 else "") + " in Map Tab")
	return moved

static func move_selected_map_tab_item_to_backpack(state: RVGameState) -> bool:
	if state == null:
		return false
	var index: int = selected_map_index(state)
	return move_map_tab_item_to_backpack(state, index)

static func move_map_tab_item_to_backpack(state: RVGameState, map_index: int) -> bool:
	if state == null or map_index < 0 or map_index >= state.map_stash.size():
		return false
	var map_item: Dictionary = normalize_map_item(Dictionary(state.map_stash[map_index]), "map_tab", state)
	state.map_stash.remove_at(map_index)
	state.backpack.append(map_item)
	state.map_cursor = clampi(int(state.map_cursor), 0, max(0, state.map_stash.size() - 1))
	state.inventory_cursor = state.backpack.size() - 1
	state.add_notice("Withdrew map to backpack: " + str(map_item.get("name", "Map")))
	return true

static func move_general_stash_map_to_map_tab(state: RVGameState, stash_index: int) -> bool:
	if state == null or stash_index < 0 or stash_index >= state.stash.size():
		return false
	var value: Variant = state.stash[stash_index]
	if not is_map_item(value):
		return false
	var map_item: Dictionary = normalize_map_item(Dictionary(value), "general_stash", state)
	state.stash.remove_at(stash_index)
	state.map_stash.append(map_item)
	state.map_cursor = state.map_stash.size() - 1
	state.stash_cursor = clampi(int(state.stash_cursor), 0, max(0, state.stash.size() - 1))
	state.add_notice("Moved map from Stash to Map Tab: " + str(map_item.get("name", "Map")))
	return true

static func deposit_all_non_map_backpack_items_to_stash(state: RVGameState) -> int:
	if state == null:
		return 0
	var moved: int = 0
	for i: int in range(state.backpack.size() - 1, -1, -1):
		var value: Variant = state.backpack[i]
		if is_map_item(value):
			continue
		state.stash.append(value)
		state.backpack.remove_at(i)
		moved += 1
	state.inventory_cursor = clampi(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
	if moved > 0:
		state.add_notice("Deposited " + str(moved) + " non-map item" + ("s" if moved != 1 else "") + " to Stash")
	return moved

static func filtered_map_indices(state: RVGameState) -> Array:
	var result: Array = []
	var filter_tier: int = int(state.get("map_tier_filter"))
	for i: int in range(state.map_stash.size()):
		var value: Variant = state.map_stash[i]
		if not is_map_item(value):
			continue
		var item: Dictionary = normalize_map_item(Dictionary(value), "map_tab", state)
		state.map_stash[i] = item
		if filter_tier == 0 or int(item.get("tier", 1)) == filter_tier:
			result.append(i)
	return result

static func selected_map_index(state: RVGameState) -> int:
	var indices: Array = filtered_map_indices(state)
	if indices.is_empty():
		return -1
	if indices.has(int(state.map_cursor)):
		return int(state.map_cursor)
	return int(indices[0])

static func tier_filter_text(state: RVGameState) -> String:
	var tier: int = int(state.get("map_tier_filter"))
	return "All Tiers" if tier == 0 else "Tier " + str(tier)

static func cycle_tier_filter(state: RVGameState, delta: int) -> void:
	var tier: int = int(state.get("map_tier_filter"))
	state.set("map_tier_filter", wrapi(tier + delta, 0, MAX_MAP_TIER + 1))
	var indices: Array = filtered_map_indices(state)
	if not indices.is_empty():
		state.map_cursor = int(indices[0])
