class_name RVItemizationSystem
extends RefCounted

const MAX_PREFIXES_RARE: int = 3
const MAX_SUFFIXES_RARE: int = 3
const MAX_PREFIXES_MAGIC: int = 1
const MAX_SUFFIXES_MAGIC: int = 1

static func is_equipment_item(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var item: Dictionary = Dictionary(value)
	if bool(item.get("map_item", false)):
		return false
	var item_type: String = str(item.get("item_type", "equipment")).to_lower()
	var category: String = str(item.get("category", "")).to_lower()
	var type_value: String = str(item.get("type", "")).to_lower()
	if item_type == "map" or category == "map":
		return false
	if item_type.contains("gem") or category.contains("gem") or ["active", "support", "spirit"].has(type_value):
		return false
	if item_type.contains("currency") or category.contains("currency") or item_type.contains("material"):
		return false
	return item.has("slot") or item.has("base_type") or item.has("prefixes") or item.has("suffixes") or item.has("forge_potential")

static func normalize_item(item: Dictionary) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	if result.is_empty():
		return result
	if bool(result.get("map_item", false)) or str(result.get("item_type", "")).to_lower() == "map" or str(result.get("category", "")).to_lower() == "map":
		return result
	if str(result.get("uid", "")) == "":
		result["uid"] = "item_" + str(Time.get_ticks_msec()) + "_" + str(randi())
	if not result.has("item_type"):
		result["item_type"] = "equipment"
	if not result.has("category"):
		result["category"] = "equipment"
	if not result.has("rarity"):
		result["rarity"] = "Normal"
	if not result.has("item_level"):
		result["item_level"] = int(result.get("level", result.get("required_level", 1)))
	if not result.has("required_level"):
		result["required_level"] = max(1, int(float(result.get("item_level", 1)) * 0.75))
	if not result.has("slot"):
		result["slot"] = _infer_slot(result)
	if not result.has("base_type"):
		result["base_type"] = str(result.get("slot", "item")).capitalize()
	if not result.has("base_name"):
		result["base_name"] = str(result.get("base_type", result.get("name", "Item")))
	if not result.has("item_class"):
		result["item_class"] = str(result.get("base_type", "Item"))
	if not result.has("name"):
		result["name"] = _default_name(result)
	if not result.has("implicit_stats") or typeof(result["implicit_stats"]) != TYPE_DICTIONARY:
		result["implicit_stats"] = Dictionary(result.get("base_stats", {})).duplicate(true)
	if not result.has("extra_stats") or typeof(result["extra_stats"]) != TYPE_DICTIONARY:
		result["extra_stats"] = {}
	result["prefixes"] = _normalize_affix_array(Array(result.get("prefixes", [])), "prefix")
	result["suffixes"] = _normalize_affix_array(Array(result.get("suffixes", [])), "suffix")
	result["crafted_mods"] = _normalize_affix_array(Array(result.get("crafted_mods", [])), "crafted")
	if not result.has("sealed_mods") or typeof(result["sealed_mods"]) != TYPE_ARRAY:
		result["sealed_mods"] = []
	if not result.has("unique_effects") or typeof(result["unique_effects"]) != TYPE_ARRAY:
		result["unique_effects"] = Array(result.get("effects", []))
	if not result.has("build_flags") or typeof(result["build_flags"]) != TYPE_ARRAY:
		result["build_flags"] = Array(result.get("flags", []))
	if not result.has("flags") or typeof(result["flags"]) != TYPE_ARRAY:
		result["flags"] = Array(result.get("build_flags", []))
	if not result.has("dimensions") or typeof(result["dimensions"]) != TYPE_ARRAY:
		result["dimensions"] = _default_dimensions(str(result.get("slot", "")))
	if not result.has("quality"):
		result["quality"] = 0
	if not result.has("corrupted"):
		result["corrupted"] = false
	if not result.has("influence"):
		result["influence"] = ""
	if not result.has("fractured_mod_uid"):
		result["fractured_mod_uid"] = ""
	if not result.has("forge_potential"):
		result["forge_potential"] = default_forge_potential(result)
	if not result.has("max_forge_potential"):
		result["max_forge_potential"] = int(result.get("forge_potential", 0))
	var total_stats: Dictionary = {}
	_merge_stats(total_stats, Dictionary(result.get("implicit_stats", {})))
	_merge_stats(total_stats, Dictionary(result.get("extra_stats", result.get("stats", {}))))
	_add_affix_stats(total_stats, Array(result.get("prefixes", [])))
	_add_affix_stats(total_stats, Array(result.get("suffixes", [])))
	_add_affix_stats(total_stats, Array(result.get("crafted_mods", [])))
	result["stats"] = total_stats.duplicate(true)
	result["total_stats"] = total_stats.duplicate(true)
	result["affixes"] = affix_names(Array(result.get("prefixes", [])), Array(result.get("suffixes", [])), Array(result.get("crafted_mods", [])))
	result["affix_tags"] = _merged_tags(Array(result.get("tags", [])), affix_tags(Array(result.get("prefixes", [])), Array(result.get("suffixes", [])), Array(result.get("crafted_mods", []))))
	result["prefix_count"] = Array(result.get("prefixes", [])).size()
	result["suffix_count"] = Array(result.get("suffixes", [])).size()
	result["crafted_count"] = Array(result.get("crafted_mods", [])).size()
	result["open_prefixes"] = max(0, max_prefixes_for_rarity(str(result.get("rarity", "Normal"))) - int(result.get("prefix_count", 0)) - _crafted_prefix_count(result))
	result["open_suffixes"] = max(0, max_suffixes_for_rarity(str(result.get("rarity", "Normal"))) - int(result.get("suffix_count", 0)) - _crafted_suffix_count(result))
	result["best_affix_tier"] = best_affix_tier(result)
	var dims: Array = Array(result.get("dimensions", [1, 1]))
	result["inv_w"] = max(1, int(dims[0]) if dims.size() > 0 else int(result.get("inv_w", 1)))
	result["inv_h"] = max(1, int(dims[1]) if dims.size() > 1 else int(result.get("inv_h", 1)))
	return result

static func default_forge_potential(item: Dictionary) -> int:
	if str(item.get("rarity", "Normal")) == "Unique":
		return 0
	var ilvl: int = max(1, int(item.get("item_level", 1)))
	var base: int = 18 + int(float(ilvl) * 0.45)
	match str(item.get("rarity", "Normal")):
		"Normal": base += 14
		"Magic": base += 8
		"Rare": base += 2
	return clampi(base, 6, 78)

static func max_prefixes_for_rarity(rarity: String) -> int:
	match rarity:
		"Magic": return MAX_PREFIXES_MAGIC
		"Rare": return MAX_PREFIXES_RARE
		_: return 0

static func max_suffixes_for_rarity(rarity: String) -> int:
	match rarity:
		"Magic": return MAX_SUFFIXES_MAGIC
		"Rare": return MAX_SUFFIXES_RARE
		_: return 0

static func item_signal_score(item: Dictionary) -> int:
	var n: Dictionary = normalize_item(item)
	var score: int = int(n.get("item_level", 1)) + int(n.get("forge_potential", 0))
	match str(n.get("rarity", "Normal")):
		"Unique": score += 1000
		"Rare": score += 180
		"Magic": score += 80
		_: score += 20
	var best: int = int(n.get("best_affix_tier", 0))
	if best > 0:
		score += max(0, 7 - best) * 55
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
	var tag_values: Array = Array(n.get("affix_tags", []))
	if not tag_values.is_empty():
		lines.append("Tags: " + ", ".join(_capitalize_array(tag_values)))
	_add_stat_section(lines, "Implicit", Dictionary(n.get("implicit_stats", {})))
	_add_affix_section(lines, "Prefixes", Array(n.get("prefixes", [])))
	_add_affix_section(lines, "Suffixes", Array(n.get("suffixes", [])))
	_add_affix_section(lines, "Crafted", Array(n.get("crafted_mods", [])))
	_add_stat_section(lines, "Total Stats", Dictionary(n.get("total_stats", {})))
	var effects: Array = Array(n.get("unique_effects", []))
	if not effects.is_empty():
		lines.append("")
		lines.append("[color=#ff9d3d][b]Unique Effects[/b][/color]")
		for effect_value: Variant in effects:
			lines.append(" • " + str(effect_value))
	var description: String = str(n.get("description", ""))
	if description != "":
		lines.append("")
		lines.append("[color=#b9a882]" + description + "[/color]")
	return "\n".join(lines)

static func plain_item_text(item: Dictionary) -> String:
	var text: String = item_detail_bbcode(item)
	for token: String in ["[b]", "[/b]", "[i]", "[/i]"]:
		text = text.replace(token, "")
	var regex: RegEx = RegEx.new()
	if regex.compile("\\[/?color[^\\]]*\\]") == OK:
		text = regex.sub(text, "", true)
	return text

static func rarity_color_hex(rarity: String) -> String:
	match rarity:
		"Unique": return "#ff9d3d"
		"Rare": return "#f2d75c"
		"Magic": return "#82a4ff"
		"Crafted": return "#58d68d"
		_: return "#d8c9a4"

static func affix_names(prefixes: Array, suffixes: Array, crafted: Array = []) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in prefixes + suffixes + crafted:
		if typeof(value) == TYPE_DICTIONARY:
			result.append(str(Dictionary(value).get("name", "Affix")))
		else:
			result.append(str(value))
	return result

static func affix_tags(prefixes: Array, suffixes: Array, crafted: Array = []) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in prefixes + suffixes + crafted:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		for tag_value: Variant in Array(Dictionary(value).get("tags", [])):
			var tag: String = str(tag_value).to_lower()
			if tag != "" and not result.has(tag):
				result.append(tag)
	return result

static func best_affix_tier(item: Dictionary) -> int:
	var best: int = 99
	for value: Variant in Array(item.get("prefixes", [])) + Array(item.get("suffixes", [])) + Array(item.get("crafted_mods", [])):
		if typeof(value) == TYPE_DICTIONARY:
			var tier: int = int(Dictionary(value).get("tier", 99))
			if tier > 0:
				best = min(best, tier)
	return 0 if best == 99 else best

static func _normalize_affix_array(values: Array, default_type: String) -> Array:
	var result: Array = []
	for value: Variant in values:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var affix: Dictionary = Dictionary(value).duplicate(true)
		if not affix.has("affix_type"):
			affix["affix_type"] = default_type
		if not affix.has("name"):
			affix["name"] = str(affix.get("id", default_type)).capitalize()
		if not affix.has("tier"):
			affix["tier"] = 5
		if not affix.has("stats") or typeof(affix["stats"]) != TYPE_DICTIONARY:
			var stat_name: String = str(affix.get("stat", "Power"))
			affix["stats"] = {stat_name: float(affix.get("value", 0.0))}
		if not affix.has("tags") or typeof(affix["tags"]) != TYPE_ARRAY:
			affix["tags"] = []
		result.append(affix)
	return result

static func _add_affix_stats(target: Dictionary, affixes: Array) -> void:
	for value: Variant in affixes:
		if typeof(value) == TYPE_DICTIONARY:
			_merge_stats(target, Dictionary(Dictionary(value).get("stats", {})))

static func _merge_stats(target: Dictionary, source: Dictionary) -> void:
	for key_value: Variant in source.keys():
		var key: String = str(key_value)
		target[key] = float(target.get(key, 0.0)) + float(source[key_value])

static func _add_stat_section(lines: Array[String], title: String, stats: Dictionary) -> void:
	if stats.is_empty():
		return
	lines.append("")
	lines.append("[b]" + title + "[/b]")
	for key_value: Variant in stats.keys():
		lines.append(" • " + _stat_line(str(key_value), float(stats[key_value])))

static func _add_affix_section(lines: Array[String], title: String, affixes: Array) -> void:
	if affixes.is_empty():
		return
	lines.append("")
	lines.append("[b]" + title + "[/b]")
	for value: Variant in affixes:
		if typeof(value) == TYPE_DICTIONARY:
			var affix: Dictionary = Dictionary(value)
			var stats: Dictionary = Dictionary(affix.get("stats", {}))
			var stat_text: String = ""
			if not stats.is_empty():
				var first_key: Variant = stats.keys()[0]
				stat_text = " — " + _stat_line(str(first_key), float(stats[first_key]))
			lines.append(" • T" + str(affix.get("tier", "?")) + " " + str(affix.get("name", "Affix")) + stat_text)

static func _stat_line(stat: String, value: float) -> String:
	if abs(value) < 1.0:
		return stat + ": +" + str(int(round(value * 100.0))) + "%"
	return stat + ": +" + str(int(round(value)))

static func _merged_tags(base_tags: Array, extra_tags: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in base_tags + extra_tags:
		var tag: String = str(value).to_lower()
		if tag != "" and not result.has(tag):
			result.append(tag)
	return result

static func _capitalize_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values:
		result.append(str(value).capitalize())
	return result

static func _crafted_prefix_count(item: Dictionary) -> int:
	var count: int = 0
	for value: Variant in Array(item.get("crafted_mods", [])):
		if typeof(value) == TYPE_DICTIONARY and str(Dictionary(value).get("affix_type", "prefix")) == "prefix":
			count += 1
	return count

static func _crafted_suffix_count(item: Dictionary) -> int:
	var count: int = 0
	for value: Variant in Array(item.get("crafted_mods", [])):
		if typeof(value) == TYPE_DICTIONARY and str(Dictionary(value).get("affix_type", "prefix")) == "suffix":
			count += 1
	return count

static func _infer_slot(item: Dictionary) -> String:
	var base_type: String = str(item.get("base_type", item.get("name", ""))).to_lower()
	if base_type.contains("sword") or base_type.contains("axe") or base_type.contains("wand"):
		return "weapon"
	if base_type.contains("shield") or base_type.contains("focus"):
		return "offhand"
	if base_type.contains("helm"):
		return "head"
	if base_type.contains("chest") or base_type.contains("armor") or base_type.contains("robe"):
		return "chest"
	if base_type.contains("glove") or base_type.contains("grip"):
		return "gloves"
	if base_type.contains("boot"):
		return "boots"
	if base_type.contains("ring"):
		return "ring"
	if base_type.contains("amulet"):
		return "amulet"
	return str(item.get("slot", "relic"))

static func _default_name(item: Dictionary) -> String:
	var rarity: String = str(item.get("rarity", "Normal"))
	var base_name: String = str(item.get("base_name", item.get("base_type", "Item")))
	if rarity == "Normal":
		return base_name
	return rarity + " " + base_name

static func _default_dimensions(slot: String) -> Array:
	match slot:
		"weapon": return [2, 3]
		"chest": return [2, 3]
		"offhand": return [2, 2]
		"head", "gloves", "boots": return [2, 2]
		_: return [1, 1]
