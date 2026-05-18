class_name RVLootFilterSystem
extends RefCounted

const COLOR_HIDE: Color = Color(0.35, 0.35, 0.35, 0.25)
const COLOR_NORMAL: Color = Color(0.78, 0.72, 0.62, 1.0)
const COLOR_MAGIC: Color = Color(0.45, 0.60, 1.0, 1.0)
const COLOR_RARE: Color = Color(0.95, 0.78, 0.24, 1.0)
const COLOR_UNIQUE: Color = Color(1.0, 0.48, 0.15, 1.0)
const COLOR_MAP: Color = Color(0.55, 0.85, 0.55, 1.0)
const COLOR_GEM: Color = Color(0.80, 0.45, 1.0, 1.0)
const COLOR_CURRENCY: Color = Color(0.95, 0.82, 0.42, 1.0)
const COLOR_CRAFTING: Color = Color(0.35, 0.95, 0.78, 1.0)

static func ensure_defaults(state: Object) -> void:
	if state == null:
		return
	var preset: String = str(_state_get(state, "loot_filter_preset", RVLootFilterDB.PRESET_STARTER))
	if not RVLootFilterDB.preset_order().has(preset):
		preset = RVLootFilterDB.PRESET_STARTER
	state.set("loot_filter_preset", preset)
	var existing: Dictionary = {}
	var existing_value: Variant = state.get("loot_filter_settings")
	if typeof(existing_value) == TYPE_DICTIONARY:
		existing = Dictionary(existing_value).duplicate(true)
	var defaults: Dictionary = RVLootFilterDB.preset_settings(preset)
	for key_value: Variant in defaults.keys():
		if not existing.has(key_value):
			existing[key_value] = defaults[key_value]
	state.set("loot_filter_settings", existing)
	if state.get("loot_filter_stats") == null:
		state.set("loot_filter_stats", {"shown": 0, "hidden": 0, "highlighted": 0})

static func set_preset(state: Object, preset_id: String) -> void:
	if state == null:
		return
	if not RVLootFilterDB.preset_order().has(preset_id):
		preset_id = RVLootFilterDB.PRESET_STARTER
	state.set("loot_filter_preset", preset_id)
	state.set("loot_filter_settings", RVLootFilterDB.preset_settings(preset_id))
	_notice(state, "Loot Filter: " + preset_id)

static func cycle_preset(state: Object, delta: int = 1) -> void:
	ensure_defaults(state)
	set_preset(state, RVLootFilterDB.next_preset(str(state.get("loot_filter_preset")), delta))

static func setting(state: Object, key: String, fallback: Variant = null) -> Variant:
	ensure_defaults(state)
	var settings: Dictionary = Dictionary(state.get("loot_filter_settings"))
	return settings.get(key, fallback)

static func set_setting(state: Object, key: String, value: Variant) -> void:
	ensure_defaults(state)
	var settings: Dictionary = Dictionary(state.get("loot_filter_settings")).duplicate(true)
	settings[key] = value
	state.set("loot_filter_settings", settings)

static func toggle_bool(state: Object, key: String) -> bool:
	var next_value: bool = not bool(setting(state, key, false))
	set_setting(state, key, next_value)
	_notice(state, "Loot Filter: " + key + " = " + ("ON" if next_value else "OFF"))
	return next_value

static func adjust_int(state: Object, key: String, delta: int, min_value: int, max_value: int) -> int:
	var next_value: int = clampi(int(setting(state, key, min_value)) + delta, min_value, max_value)
	set_setting(state, key, next_value)
	_notice(state, "Loot Filter: " + key + " = " + str(next_value))
	return next_value

static func cycle_build_tag(state: Object, delta: int = 1) -> String:
	var current: String = str(setting(state, "build_filter_tag", "fire"))
	var next_tag: String = RVLootFilterDB.next_build_tag(current, delta)
	set_setting(state, "build_filter_tag", next_tag)
	_notice(state, "Build filter tag: " + next_tag.capitalize())
	return next_tag

static func classify(value: Variant) -> Dictionary:
	var out: Dictionary = {
		"kind": "unknown",
		"rarity": "Normal",
		"item_type": "",
		"is_map": false,
		"is_gem": false,
		"is_unique": false,
		"is_currency": false,
		"is_material": false,
		"is_equipment": false,
		"name": "Loot",
	}
	if typeof(value) != TYPE_DICTIONARY:
		return out
	var item: Dictionary = Dictionary(value)
	out["name"] = str(item.get("name", item.get("id", "Loot")))
	var item_type: String = str(item.get("item_type", item.get("type", ""))).to_lower()
	var category: String = str(item.get("category", "")).to_lower()
	var slot: String = str(item.get("slot", "")).to_lower()
	var base_type: String = str(item.get("base_type", "")).to_lower()
	var name_lower: String = str(out["name"]).to_lower()
	var rarity: String = str(item.get("rarity", "Normal"))
	out["rarity"] = rarity
	out["item_type"] = item_type
	out["is_map"] = RVMapItemSystem.is_map_item(item)
	out["is_gem"] = item_type.contains("gem") or category.contains("gem") or ["active", "support", "spirit"].has(item_type) or ["active", "support", "spirit"].has(str(item.get("type", "")).to_lower())
	out["is_unique"] = rarity == "Unique" or category == "unique" or slot == "unique"
	out["is_currency"] = item_type.contains("currency") or category.contains("currency") or base_type.contains("currency") or name_lower.contains("orb") or name_lower.contains("rune") or name_lower.contains("shard")
	out["is_material"] = item_type.contains("material") or category.contains("material") or item_type.contains("craft") or category.contains("craft") or base_type.contains("material") or name_lower.contains("ember") or name_lower.contains("essence")
	out["is_equipment"] = not bool(out["is_map"]) and not bool(out["is_gem"]) and not bool(out["is_currency"]) and not bool(out["is_material"]) and (slot != "" or item.has("prefixes") or item.has("suffixes") or item.has("base_id"))
	if bool(out["is_map"]):
		out["kind"] = "map"
	elif bool(out["is_gem"]):
		out["kind"] = "gem"
	elif bool(out["is_currency"]):
		out["kind"] = "currency"
	elif bool(out["is_material"]):
		out["kind"] = "material"
	elif bool(out["is_equipment"]):
		out["kind"] = "equipment"
	return out

static func decision_for_item(state: Object, value: Variant) -> Dictionary:
	ensure_defaults(state)
	var item: Dictionary = Dictionary(value) if typeof(value) == TYPE_DICTIONARY else {}
	var info: Dictionary = classify(value)
	var settings: Dictionary = Dictionary(state.get("loot_filter_settings"))
	var show: bool = true
	var highlight: bool = false
	var reason: String = "Shown"
	var color: Color = color_for_item(value)
	if bool(info.get("is_map", false)):
		var tier: int = int(item.get("tier", 1))
		show = bool(settings.get("show_maps", true)) and tier >= int(settings.get("map_min_tier", 1))
		highlight = show
		reason = "Map T" + str(tier)
		color = COLOR_MAP
	elif bool(info.get("is_gem", false)):
		show = bool(settings.get("show_gems", true))
		highlight = show
		reason = "Gem"
		color = COLOR_GEM
	elif bool(info.get("is_unique", false)):
		show = bool(settings.get("show_unique", true))
		highlight = show
		reason = "Unique"
		color = COLOR_UNIQUE
	elif bool(info.get("is_currency", false)):
		show = bool(settings.get("show_currency", true))
		highlight = show
		reason = "Currency"
		color = COLOR_CURRENCY
	elif bool(info.get("is_material", false)):
		show = bool(settings.get("show_materials", true))
		reason = "Material"
		color = COLOR_CRAFTING
	else:
		var rarity: String = str(info.get("rarity", "Normal"))
		match rarity:
			"Normal": show = bool(settings.get("show_normal", true))
			"Magic": show = bool(settings.get("show_magic", true))
			"Rare": show = bool(settings.get("show_rare", true))
			"Unique": show = bool(settings.get("show_unique", true))
			_: show = true
		var best_tier: int = best_affix_tier(item)
		var required_tier: int = int(settings.get("max_affix_tier", 99))
		var forge_potential: int = int(item.get("forge_potential", 0))
		var min_forge_potential: int = int(settings.get("min_forge_potential", 0))
		var crafting_base: bool = bool(settings.get("show_crafting_bases", true)) and forge_potential >= min_forge_potential
		var build_ok: bool = true
		if bool(settings.get("require_build_tag", false)):
			build_ok = item_has_tag(item, str(settings.get("build_filter_tag", "fire")))
		if best_tier <= required_tier:
			highlight = true
			reason = "T" + str(best_tier) + " affix"
		elif crafting_base:
			highlight = true
			reason = "Crafting base FP " + str(forge_potential)
		if show and bool(settings.get("require_build_tag", false)) and not build_ok and rarity != "Unique":
			show = false
		color = color_for_item(item)
	return {"show": show, "highlight": highlight, "reason": reason, "color": color, "kind": str(info.get("kind", "unknown"))}

static func should_show_item(state: Object, value: Variant) -> bool:
	return bool(decision_for_item(state, value).get("show", true))

static func should_auto_pickup(state: Object, value: Variant) -> bool:
	ensure_defaults(state)
	var info: Dictionary = classify(value)
	var settings: Dictionary = Dictionary(state.get("loot_filter_settings"))
	if bool(info.get("is_map", false)):
		return bool(settings.get("auto_pickup_maps", false))
	if bool(info.get("is_gem", false)):
		return bool(settings.get("auto_pickup_gems", false))
	if bool(info.get("is_currency", false)):
		return bool(settings.get("auto_pickup_currency", true))
	if bool(info.get("is_material", false)):
		return bool(settings.get("auto_pickup_materials", true))
	return false

static func color_for_item(value: Variant) -> Color:
	if typeof(value) != TYPE_DICTIONARY:
		return COLOR_NORMAL
	var item: Dictionary = Dictionary(value)
	if RVMapItemSystem.is_map_item(item):
		return COLOR_MAP
	var info: Dictionary = classify(item)
	if bool(info.get("is_gem", false)):
		return COLOR_GEM
	if bool(info.get("is_currency", false)):
		return COLOR_CURRENCY
	if bool(info.get("is_material", false)):
		return COLOR_CRAFTING
	match str(item.get("rarity", "Normal")):
		"Unique": return COLOR_UNIQUE
		"Rare": return COLOR_RARE
		"Magic": return COLOR_MAGIC
		_: return COLOR_NORMAL

static func best_affix_tier(item: Dictionary) -> int:
	var best: int = 999
	for group_name_value: Variant in ["prefixes", "suffixes", "crafted_mods", "mods"]:
		var group_name: String = str(group_name_value)
		for value: Variant in Array(item.get(group_name, [])):
			if typeof(value) != TYPE_DICTIONARY:
				continue
			best = min(best, int(Dictionary(value).get("tier", 999)))
	return best

static func item_has_tag(item: Dictionary, tag: String) -> bool:
	var wanted: String = tag.to_lower()
	for key_value: Variant in ["tags", "affix_tags", "base_tags"]:
		var key: String = str(key_value)
		for value: Variant in Array(item.get(key, [])):
			if str(value).to_lower() == wanted:
				return true
	for group_name_value: Variant in ["prefixes", "suffixes", "crafted_mods", "mods"]:
		var group_name: String = str(group_name_value)
		for mod_value: Variant in Array(item.get(group_name, [])):
			if typeof(mod_value) != TYPE_DICTIONARY:
				continue
			var mod: Dictionary = Dictionary(mod_value)
			for tag_value: Variant in Array(mod.get("tags", [])):
				if str(tag_value).to_lower() == wanted:
					return true
	return false

static func update_ground_loot(state: Object, combat_root: Node) -> void:
	if state == null or combat_root == null:
		return
	ensure_defaults(state)
	var stats: Dictionary = {"shown": 0, "hidden": 0, "highlighted": 0}
	_apply_to_tree_node(state, combat_root, stats)
	state.set("loot_filter_stats", stats)

static func _apply_to_tree_node(state: Object, node: Node, stats: Dictionary) -> void:
	var item: Dictionary = _extract_item_from_node(node)
	if not item.is_empty():
		var decision: Dictionary = decision_for_item(state, item)
		var show: bool = bool(decision.get("show", true))
		if node is CanvasItem:
			var canvas_item: CanvasItem = node as CanvasItem
			canvas_item.visible = show
			canvas_item.modulate = decision.get("color", COLOR_NORMAL) if show else COLOR_HIDE
		if show:
			stats["shown"] = int(stats.get("shown", 0)) + 1
			if bool(decision.get("highlight", false)):
				stats["highlighted"] = int(stats.get("highlighted", 0)) + 1
		else:
			stats["hidden"] = int(stats.get("hidden", 0)) + 1
	for child in _safe_children(node):
		if child is Node:
			_apply_to_tree_node(state, child as Node, stats)

static func _extract_item_from_node(node: Node) -> Dictionary:
	if node == null:
		return {}
	for key_value: Variant in ["item", "item_data", "loot_data", "drop_data", "payload", "data"]:
		var value: Variant = node.get(str(key_value))
		if typeof(value) == TYPE_DICTIONARY:
			var data: Dictionary = Dictionary(value)
			if data.has("rarity") or data.has("item_type") or data.has("category") or data.has("tier") or data.has("map_level") or data.has("prefixes"):
				return data
	if node.has_meta("item") and typeof(node.get_meta("item")) == TYPE_DICTIONARY:
		return Dictionary(node.get_meta("item"))
	if node.has_meta("loot_item") and typeof(node.get_meta("loot_item")) == TYPE_DICTIONARY:
		return Dictionary(node.get_meta("loot_item"))
	return {}

static func panel_text(state: Object) -> String:
	ensure_defaults(state)
	var settings: Dictionary = Dictionary(state.get("loot_filter_settings"))
	var lines: Array = []
	lines.append("LOOT FILTER")
	lines.append("Preset: " + str(state.get("loot_filter_preset")))
	lines.append("")
	lines.append("Rarity: Normal %s  Magic %s  Rare %s  Unique %s" % [_onoff(settings.get("show_normal", true)), _onoff(settings.get("show_magic", true)), _onoff(settings.get("show_rare", true)), _onoff(settings.get("show_unique", true))])
	lines.append("Types: Maps %s  Gems %s  Currency %s  Materials %s" % [_onoff(settings.get("show_maps", true)), _onoff(settings.get("show_gems", true)), _onoff(settings.get("show_currency", true)), _onoff(settings.get("show_materials", true))])
	lines.append("Crafting bases: %s  Min FP: %s  Max Affix Tier: T%s" % [_onoff(settings.get("show_crafting_bases", true)), str(settings.get("min_forge_potential", 0)), str(settings.get("max_affix_tier", 99))])
	lines.append("Map min tier: T" + str(settings.get("map_min_tier", 1)))
	lines.append("Build tag: " + str(settings.get("build_filter_tag", "fire")).capitalize() + "  Required: " + _onoff(settings.get("require_build_tag", false)))
	lines.append("")
	lines.append("Auto pickup: Currency %s  Materials %s  Maps %s  Gems %s" % [_onoff(settings.get("auto_pickup_currency", true)), _onoff(settings.get("auto_pickup_materials", true)), _onoff(settings.get("auto_pickup_maps", false)), _onoff(settings.get("auto_pickup_gems", false))])
	var stats: Dictionary = Dictionary(_state_get(state, "loot_filter_stats", {}))
	lines.append("Ground loot: shown %s · hidden %s · highlighted %s" % [str(stats.get("shown", 0)), str(stats.get("hidden", 0)), str(stats.get("highlighted", 0))])
	return "\n".join(lines)

static func controls_text() -> String:
	return "P/O preset · 1 Normal · 2 Magic · 3 Rare · 4 Unique · 5 Maps · 6 Gems · 7 Crafting Bases\n8 Currency auto · 9 Materials auto · 0 Maps auto · Q/E Affix Tier · Z/X Forge Potential · C Build Tag · V Require Tag"

static func _onoff(value: Variant) -> String:
	return "ON" if bool(value) else "OFF"

static func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	var value: Variant = state.get(key)
	return fallback if value == null else value

static func _notice(state: Object, text: String) -> void:
	if state != null and state.has_method("add_notice"):
		state.call("add_notice", text)


static func _node_alive(node: Node) -> bool:
	return node != null and is_instance_valid(node) and not node.is_queued_for_deletion()

static func _safe_children(node: Node) -> Array:
	if not _node_alive(node):
		return []
	return node.get_children()
