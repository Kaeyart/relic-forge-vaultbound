class_name RVItemDB
extends RefCounted

const SLOTS: Array[String] = ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring", "relic"]

static func make_starter_weapon() -> Dictionary:
	var base: Dictionary = RVItemAffixDB.base_item("ember_wand")
	var prefixes: Array = [RVItemAffixDB.materialize_affix({"id": "apprentice_spell", "name": "Apprentice", "stat": "Spell Damage", "tags": ["Spell", "Damage"], "values": [0.08]}, "prefix", 1, 1)]
	var suffixes: Array = []
	return _build_item_from_parts(base, "Magic", 1, prefixes, suffixes, 14, {}, [], [], "A simple starter wand with room to grow.")

static func craft_basic_item(state: RVGameState) -> Dictionary:
	var base: Dictionary = RVItemAffixDB.random_base_for_level(state.rng, max(1, state.level))
	var prefixes: Array = []
	var suffixes: Array = []
	var existing_ids: Array[String] = []
	var first_prefix: Dictionary = RVItemAffixDB.random_affix(state.rng, "prefix", str(base.get("slot", "relic")), max(1, state.level), existing_ids)
	if not first_prefix.is_empty():
		prefixes.append(first_prefix)
		existing_ids.append(str(first_prefix.get("id", "")))
	var first_suffix: Dictionary = RVItemAffixDB.random_affix(state.rng, "suffix", str(base.get("slot", "relic")), max(1, state.level), existing_ids)
	if not first_suffix.is_empty():
		suffixes.append(first_suffix)
	return _build_item_from_parts(base, "Crafted", max(1, state.level), prefixes, suffixes, 18, {}, [], [], "A forged base item. It is not finished yet.")

static func generate_drop(state: RVGameState, depth: int) -> Dictionary:
	var item_level: int = max(1, int(state.level) + max(0, depth - 1))
	var rarity: String = _roll_rarity(state.rng, item_level)
	if rarity == "Unique":
		var unique_template: Dictionary = RVItemAffixDB.random_unique_for_level(state.rng, item_level)
		if not unique_template.is_empty():
			return _build_unique(unique_template, item_level)
		rarity = "Rare"
	var base: Dictionary = RVItemAffixDB.random_base_for_level(state.rng, item_level)
	var affix_counts: Dictionary = _affix_counts_for_rarity(state.rng, rarity)
	var prefixes: Array = []
	var suffixes: Array = []
	var existing_ids: Array[String] = []
	for i: int in range(int(affix_counts.get("prefix", 0))):
		var prefix: Dictionary = RVItemAffixDB.random_affix(state.rng, "prefix", str(base.get("slot", "relic")), item_level, existing_ids)
		if not prefix.is_empty():
			prefixes.append(prefix)
			existing_ids.append(str(prefix.get("id", "")))
	for j: int in range(int(affix_counts.get("suffix", 0))):
		var suffix: Dictionary = RVItemAffixDB.random_affix(state.rng, "suffix", str(base.get("slot", "relic")), item_level, existing_ids)
		if not suffix.is_empty():
			suffixes.append(suffix)
			existing_ids.append(str(suffix.get("id", "")))
	var potential: int = _forge_potential_for(rarity, item_level, state.rng)
	return _build_item_from_parts(base, rarity, item_level, prefixes, suffixes, potential, {}, [], [], "A rough item with craftable potential.")

static func normalize_item(item: Dictionary) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	if not result.has("item_level"):
		result["item_level"] = int(result.get("level", 1))
	if not result.has("base_name"):
		result["base_name"] = str(result.get("name", "Item"))
	if not result.has("base_type"):
		result["base_type"] = str(result.get("slot", "Item")).capitalize()
	if not result.has("implicit_stats"):
		result["implicit_stats"] = {}
	if not result.has("prefixes"):
		result["prefixes"] = []
	if not result.has("suffixes"):
		result["suffixes"] = []
	if not result.has("build_flags"):
		result["build_flags"] = result.get("flags", [])
	if not result.has("unique_effects"):
		result["unique_effects"] = []
	if not result.has("forge_potential"):
		if str(result.get("rarity", "Normal")) == "Unique":
			result["forge_potential"] = 0
		else:
			result["forge_potential"] = 8
	if not result.has("stats"):
		result["stats"] = RVItemAffixDB.aggregate_stats(result.get("implicit_stats", {}), result.get("prefixes", []), result.get("suffixes", []))
	if not result.has("affixes"):
		result["affixes"] = RVItemAffixDB.affix_names(result.get("prefixes", []), result.get("suffixes", []))
	return result

static func build_flags_from_equipped(state: RVGameState) -> Array[String]:
	var result: Array[String] = []
	for slot_name: Variant in state.equipped.keys():
		var item_value: Variant = state.equipped[slot_name]
		if typeof(item_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = normalize_item(item_value)
		for flag_value: Variant in item.get("build_flags", item.get("flags", [])):
			var flag: String = str(flag_value)
			if flag != "" and not result.has(flag):
				result.append(flag)
	return result

static func rarity_color_name(rarity: String) -> String:
	match rarity:
		"Normal":
			return "Common"
		"Magic":
			return "Magic"
		"Rare":
			return "Rare"
		"Unique":
			return "Unique"
		"Crafted":
			return "Crafted"
	return rarity

static func _build_unique(template: Dictionary, item_level: int) -> Dictionary:
	var base: Dictionary = RVItemAffixDB.base_item(str(template.get("base_id", "rusted_sword")))
	var unique_stats: Dictionary = template.get("stats", {})
	return _build_item_from_parts(
		base,
		"Unique",
		item_level,
		[],
		[],
		0,
		unique_stats,
		template.get("build_flags", []).duplicate(true),
		template.get("unique_effects", []).duplicate(true),
		str(template.get("description", "A unique item.")),
		str(template.get("name", "Unique Item"))
	)

static func _build_item_from_parts(base: Dictionary, rarity: String, item_level: int, prefixes: Array, suffixes: Array, forge_potential: int, extra_stats: Dictionary = {}, build_flags: Array = [], unique_effects: Array = [], description: String = "", forced_name: String = "") -> Dictionary:
	var base_name: String = str(base.get("name", "Item"))
	var item_name: String = forced_name
	if item_name == "":
		item_name = RVItemAffixDB.item_name_for(base_name, rarity, prefixes, suffixes)
	var implicit_stats: Dictionary = base.get("implicit_stats", {}).duplicate(true)
	var stats: Dictionary = RVItemAffixDB.aggregate_stats(implicit_stats, prefixes, suffixes, extra_stats)
	var affix_names: Array[String] = RVItemAffixDB.affix_names(prefixes, suffixes)
	return {
		"name": item_name,
		"slot": str(base.get("slot", "relic")),
		"base_name": base_name,
		"base_type": str(base.get("base_type", base_name)),
		"armor_class": str(base.get("armor_class", "")),
		"item_level": item_level,
		"rarity": rarity,
		"tags": base.get("tags", []).duplicate(true),
		"implicit_stats": implicit_stats,
		"prefixes": prefixes.duplicate(true),
		"suffixes": suffixes.duplicate(true),
		"stats": stats,
		"affixes": affix_names,
		"forge_potential": forge_potential,
		"max_forge_potential": forge_potential,
		"build_flags": build_flags.duplicate(true),
		"flags": build_flags.duplicate(true),
		"unique_effects": unique_effects.duplicate(true),
		"description": description
	}

static func _roll_rarity(rng: RandomNumberGenerator, item_level: int) -> String:
	var roll: float = rng.randf()
	var unique_chance: float = 0.018 + min(0.035, float(item_level) * 0.0015)
	if roll >= 1.0 - unique_chance:
		return "Unique"
	if roll >= 0.74:
		return "Rare"
	if roll >= 0.28:
		return "Magic"
	return "Normal"

static func _affix_counts_for_rarity(rng: RandomNumberGenerator, rarity: String) -> Dictionary:
	match rarity:
		"Normal":
			return {"prefix": 0, "suffix": 0}
		"Magic":
			if rng.randf() < 0.5:
				return {"prefix": 1, "suffix": 0}
			return {"prefix": 1, "suffix": 1}
		"Rare":
			var total: int = rng.randi_range(4, 6)
			var prefixes: int = rng.randi_range(1, min(3, total - 1))
			var suffixes: int = clamp(total - prefixes, 1, 3)
			prefixes = clamp(total - suffixes, 1, 3)
			return {"prefix": prefixes, "suffix": suffixes}
		"Crafted":
			return {"prefix": 1, "suffix": 1}
	return {"prefix": 0, "suffix": 0}

static func _forge_potential_for(rarity: String, item_level: int, rng: RandomNumberGenerator) -> int:
	var base: int = 12 + int(item_level / 2)
	match rarity:
		"Normal":
			base += 7
		"Magic":
			base += 4
		"Rare":
			base += 0
		"Crafted":
			base += 2
		"Unique":
			return 0
	return max(1, base + rng.randi_range(-2, 4))
