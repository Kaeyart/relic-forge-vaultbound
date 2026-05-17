class_name RVItemizationSystem
extends RefCounted

static func is_equipment_item(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var item: Dictionary = Dictionary(value)
	if bool(item.get("map_item", false)):
		return false
	var slot: String = str(item.get("slot", ""))
	return RVItemBaseDB.SLOT_ORDER.has(slot) or item.has("prefixes") or item.has("suffixes") or item.has("forge_potential")

static func normalize_item(item: Dictionary) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	if result.is_empty() or bool(result.get("map_item", false)):
		return result
	if not result.has("uid") or str(result.get("uid", "")) == "":
		result["uid"] = "item_" + str(Time.get_ticks_msec()) + "_" + str(randi())
	if not result.has("rarity"):
		result["rarity"] = "Normal"
	if not result.has("item_level"):
		result["item_level"] = int(result.get("level", result.get("required_level", 1)))
	if not result.has("base_id"):
		result["base_id"] = ""
	var base: Dictionary = RVItemBaseDB.base_item(str(result.get("base_id", ""))) if str(result.get("base_id", "")) != "" else {}
	if not base.is_empty():
		if not result.has("slot"): result["slot"] = base.get("slot", "")
		if not result.has("base_name"): result["base_name"] = str(base.get("name", result.get("name", "Item")))
		if not result.has("base_type"): result["base_type"] = base.get("base_type", "Item")
		if not result.has("item_class"): result["item_class"] = base.get("item_class", result.get("base_type", "Item"))
		if not result.has("armor_class"): result["armor_class"] = base.get("armor_class", "")
		if not result.has("tags"): result["tags"] = Array(base.get("tags", [])).duplicate(true)
		if not result.has("dimensions"): result["dimensions"] = Array(base.get("dimensions", [1, 1])).duplicate(true)
		if not result.has("implicit_stats"): result["implicit_stats"] = Dictionary(base.get("implicit_stats", {})).duplicate(true)
	if not result.has("base_name"): result["base_name"] = str(result.get("name", "Item"))
	if not result.has("base_type"): result["base_type"] = str(result.get("slot", "Item")).capitalize()
	if not result.has("item_class"): result["item_class"] = str(result.get("base_type", "Item"))
	if not result.has("implicit_stats"): result["implicit_stats"] = {}
	if not result.has("prefixes"): result["prefixes"] = []
	if not result.has("suffixes"): result["suffixes"] = []
	if not result.has("crafted_mods"): result["crafted_mods"] = []
	if not result.has("sealed_mods"): result["sealed_mods"] = []
	if not result.has("fractured_mod_uid"): result["fractured_mod_uid"] = ""
	if not result.has("quality"): result["quality"] = 0
	if not result.has("corrupted"): result["corrupted"] = false
	if not result.has("influence"): result["influence"] = ""
	if not result.has("unique_effects"): result["unique_effects"] = []
	if not result.has("build_flags"): result["build_flags"] = Array(result.get("flags", [])).duplicate(true)
	if not result.has("flags"): result["flags"] = Array(result.get("build_flags", [])).duplicate(true)
	if not result.has("forge_potential"): result["forge_potential"] = default_forge_potential(result)
	if not result.has("max_forge_potential"): result["max_forge_potential"] = int(result.get("forge_potential", 0))
	var calculated_stats: Dictionary = RVItemAffixDB.aggregate_stats(Dictionary(result.get("implicit_stats", {})), Array(result.get("prefixes", [])), Array(result.get("suffixes", [])), Dictionary(result.get("extra_stats", result.get("stats", {}))), Array(result.get("crafted_mods", [])))
	result["stats"] = calculated_stats.duplicate(true)
	result["total_stats"] = calculated_stats.duplicate(true)
	result["affixes"] = RVItemAffixDB.affix_names(Array(result.get("prefixes", [])), Array(result.get("suffixes", [])), Array(result.get("crafted_mods", [])))
	result["affix_tags"] = _merged_tags(Array(result.get("tags", [])), RVItemAffixDB.affix_tags(Array(result.get("prefixes", [])), Array(result.get("suffixes", [])), Array(result.get("crafted_mods", []))))
	result["prefix_count"] = Array(result.get("prefixes", [])).size()
	result["suffix_count"] = Array(result.get("suffixes", [])).size()
	result["open_prefixes"] = max(0, max_prefixes_for_rarity(str(result.get("rarity", "Normal"))) - int(result.get("prefix_count", 0)))
	result["open_suffixes"] = max(0, max_suffixes_for_rarity(str(result.get("rarity", "Normal"))) - int(result.get("suffix_count", 0)))
	result["best_affix_tier"] = RVItemAffixDB.best_affix_tier(result)
	if not result.has("dimensions"):
		var dims: Vector2i = RVItemBaseDB.dimensions_for_item(result)
		result["dimensions"] = [dims.x, dims.y]
	var dimensions: Array = Array(result.get("dimensions", [1, 1]))
	result["inv_w"] = int(dimensions[0]) if dimensions.size() >= 1 else 1
	result["inv_h"] = int(dimensions[1]) if dimensions.size() >= 2 else 1
	return result

static func default_forge_potential(item: Dictionary) -> int:
	var rarity: String = str(item.get("rarity", "Normal"))
	if rarity == "Unique": return 0
	var ilvl: int = int(item.get("item_level", 1))
	var base: int = 18 + int(ilvl * 0.45)
	match rarity:
		"Normal": base += 14
		"Magic": base += 8
		"Rare": base += 0
	return clampi(base, 8, 72)

static func max_prefixes_for_rarity(rarity: String) -> int:
	match rarity:
		"Magic": return 1
		"Rare": return 3
		_: return 0

static func max_suffixes_for_rarity(rarity: String) -> int:
	match rarity:
		"Magic": return 1
		"Rare": return 3
		_: return 0

static func item_signal_score(item: Dictionary) -> int:
	var normalized: Dictionary = normalize_item(item)
	var score: int = int(normalized.get("item_level", 1)) + int(normalized.get("forge_potential", 0))
	match str(normalized.get("rarity", "Normal")):
		"Unique": score += 1000
		"Rare": score += 180
		"Magic": score += 80
		_: score += 20
	var best_tier: int = int(normalized.get("best_affix_tier", 0))
	if best_tier > 0: score += max(0, 7 - best_tier) * 55
	return score

static func item_detail_bbcode(item: Dictionary, header: String = "ITEM", source_line: String = "Equipment") -> String:
	var n: Dictionary = normalize_item(item)
	var lines: Array[String] = []
	lines.append("[b]" + header + "[/b]")
	lines.append("[color=#aaaaaa]" + source_line + "[/color]")
	lines.append("")
	lines.append("[color=" + rarity_color_hex(str(n.get("rarity", "Normal"))) + "][b]" + str(n.get("name", "Item")) + "[/b][/color]")
	lines.append(str(n.get("rarity", "Normal")) + " " + str(n.get("base_type", "Item")) + " · Item Level " + str(n.get("item_level", 1)))
	lines.append("Forge Potential: " + str(n.get("forge_potential", 0)) + " / " + str(n.get("max_forge_potential", n.get("forge_potential", 0))))
	lines.append("Open: " + str(n.get("open_prefixes", 0)) + " Prefix / " + str(n.get("open_suffixes", 0)) + " Suffix")
	var tags: Array = Array(n.get("affix_tags", []))
	if not tags.is_empty(): lines.append("Tags: " + ", ".join(_capitalize_array(tags)))
	_add_stat_section(lines, "Implicit", Dictionary(n.get("implicit_stats", {})))
	_add_affix_section(lines, "Prefixes", Array(n.get("prefixes", [])))
	_add_affix_section(lines, "Suffixes", Array(n.get("suffixes", [])))
	_add_affix_section(lines, "Crafted", Array(n.get("crafted_mods", [])))
	var unique_effects: Array = Array(n.get("unique_effects", []))
	if not unique_effects.is_empty():
		lines.append("")
		lines.append("[color=#ff9d3d][b]Unique Effects[/b][/color]")
		for effect_value: Variant in unique_effects: lines.append(" • " + str(effect_value))
	_add_stat_section(lines, "Total Stats", Dictionary(n.get("total_stats", {})))
	var description: String = str(n.get("description", ""))
	if description != "":
		lines.append("")
		lines.append("[color=#b9a882]" + description + "[/color]")
	return "\n".join(lines)

static func plain_item_text(item: Dictionary) -> String:
	var text: String = item_detail_bbcode(item)
	for token: String in ["[b]", "[/b]", "[i]", "[/i]"]: text = text.replace(token, "")
	var regex: RegEx = RegEx.new()
	if regex.compile("\\[/?color[^\\]]*\\]") == OK: text = regex.sub(text, "", true)
	return text

static func rarity_color_hex(rarity: String) -> String:
	match rarity:
		"Unique": return "#ff9d3d"
		"Rare": return "#f2d75c"
		"Magic": return "#82a4ff"
		"Crafted": return "#58d68d"
		_: return "#d8c9a4"

static func _add_stat_section(lines: Array[String], title: String, stats: Dictionary) -> void:
	if stats.is_empty(): return
	lines.append("")
	lines.append("[b]" + title + "[/b]")
	for key_value: Variant in stats.keys(): lines.append(" • " + _stat_line(str(key_value), float(stats[key_value])))

static func _add_affix_section(lines: Array[String], title: String, affixes: Array) -> void:
	if affixes.is_empty(): return
	lines.append("")
	lines.append("[b]" + title + "[/b]")
	for affix_value: Variant in affixes:
		if typeof(affix_value) == TYPE_DICTIONARY:
			var affix: Dictionary = Dictionary(affix_value)
			lines.append(" • T" + str(affix.get("tier", "?")) + " " + str(affix.get("name", "Affix")) + " — " + _stat_line(str(affix.get("stat", "Stat")), float(affix.get("value", 0.0))))

static func _stat_line(stat: String, value: float) -> String:
	if abs(value) < 1.0: return stat + ": +" + str(int(round(value * 100.0))) + "%"
	return stat + ": +" + str(int(round(value)))

static func _merged_tags(base_tags: Array, affix_tags: Array) -> Array[String]:
	var result: Array[String] = []
	for tag_value: Variant in base_tags + affix_tags:
		var tag: String = str(tag_value).to_lower()
		if tag != "" and not result.has(tag): result.append(tag)
	return result

static func _capitalize_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values: result.append(str(value).capitalize())
	return result
