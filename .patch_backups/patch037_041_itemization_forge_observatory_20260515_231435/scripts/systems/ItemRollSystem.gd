class_name RVItemRollSystem
extends RefCounted

# Patch 036: single source of truth for rolling original Relic Forge items.

static func generate_drop(state: RVGameState, depth: int) -> Dictionary:
	var item_level: int = max(1, int(state.level) + max(0, depth - 1))
	return roll_item(state.rng, item_level)

static func craft_basic_item(state: RVGameState) -> Dictionary:
	var item_level: int = max(1, int(state.level))
	var base: Dictionary = RVItemBaseDB.random_base_for_level(state.rng, item_level)
	var prefixes: Array = []
	var suffixes: Array = []
	var used_families: Array[String] = []
	var prefix: Dictionary = RVItemAffixDB.roll_affix(state.rng, "prefix", base, item_level, used_families)
	if not prefix.is_empty():
		prefixes.append(prefix)
		used_families.append(str(prefix.get("family", "")))
	var suffix: Dictionary = RVItemAffixDB.roll_affix(state.rng, "suffix", base, item_level, used_families)
	if not suffix.is_empty():
		suffixes.append(suffix)
	return build_item_from_parts(base, "Crafted", item_level, prefixes, suffixes, _forge_potential_for("Crafted", item_level, state.rng), {}, [], [], "A hand-forged item with controlled potential.")

static func roll_item(rng: RandomNumberGenerator, item_level: int, forced_slot: String = "", forced_rarity: String = "") -> Dictionary:
	var rarity: String = forced_rarity
	if rarity == "":
		rarity = roll_rarity(rng, item_level)
	if rarity == "Unique":
		var unique_template: Dictionary = RVItemAffixDB.random_unique_for_level(rng, item_level)
		if not unique_template.is_empty():
			return build_unique(unique_template, item_level)
		rarity = "Rare"
	var base: Dictionary = {}
	if forced_slot != "":
		base = RVItemBaseDB.random_base_for_slot(rng, item_level, forced_slot)
	else:
		base = RVItemBaseDB.random_base_for_level(rng, item_level)
	var counts: Dictionary = affix_counts_for_rarity(rng, rarity)
	var prefixes: Array = []
	var suffixes: Array = []
	var used_families: Array[String] = []
	for i: int in range(int(counts.get("prefix", 0))):
		var prefix: Dictionary = RVItemAffixDB.roll_affix(rng, "prefix", base, item_level, used_families)
		if prefix.is_empty():
			continue
		prefixes.append(prefix)
		var family: String = str(prefix.get("family", ""))
		if family != "" and not used_families.has(family):
			used_families.append(family)
	for j: int in range(int(counts.get("suffix", 0))):
		var suffix: Dictionary = RVItemAffixDB.roll_affix(rng, "suffix", base, item_level, used_families)
		if suffix.is_empty():
			continue
		suffixes.append(suffix)
		var family: String = str(suffix.get("family", ""))
		if family != "" and not used_families.has(family):
			used_families.append(family)
	var potential: int = _forge_potential_for(rarity, item_level, rng)
	return build_item_from_parts(base, rarity, item_level, prefixes, suffixes, potential, {}, [], [], "A rough item with craftable potential.")

static func build_unique(template: Dictionary, item_level: int) -> Dictionary:
	var base: Dictionary = RVItemBaseDB.get_base(str(template.get("base_id", "rusted_sword")))
	var stats: Dictionary = Dictionary(template.get("stats", {})).duplicate(true)
	var build_flags: Array = Array(template.get("build_flags", [])).duplicate(true)
	var unique_effects: Array = Array(template.get("unique_effects", [])).duplicate(true)
	return build_item_from_parts(base, "Unique", item_level, [], [], 0, stats, build_flags, unique_effects, str(template.get("description", "A unique item.")), str(template.get("name", "Unique Item")), Array(template.get("tags", [])).duplicate(true))

static func build_item_from_parts(base: Dictionary, rarity: String, item_level: int, prefixes: Array, suffixes: Array, forge_potential: int, extra_stats: Dictionary = {}, build_flags: Array = [], unique_effects: Array = [], description: String = "", forced_name: String = "", extra_tags: Array = []) -> Dictionary:
	var base_name: String = str(base.get("name", "Item"))
	var item_name: String = forced_name
	if item_name == "":
		item_name = RVItemAffixDB.item_name_for(base_name, rarity, prefixes, suffixes)
	var implicit_stats: Dictionary = Dictionary(base.get("implicit_stats", {})).duplicate(true)
	var total_stats: Dictionary = RVItemAffixDB.aggregate_stats(implicit_stats, prefixes, suffixes, extra_stats)
	var affix_names: Array[String] = RVItemAffixDB.affix_names(prefixes, suffixes)
	var tags: Array = Array(base.get("tags", [])).duplicate(true)
	for affix_value: Variant in prefixes + suffixes:
		if typeof(affix_value) != TYPE_DICTIONARY:
			continue
		for tag_value: Variant in Dictionary(affix_value).get("tags", []):
			var tag: String = str(tag_value)
			if tag != "" and not tags.has(tag):
				tags.append(tag)
	for tag_value: Variant in extra_tags:
		var tag: String = str(tag_value)
		if tag != "" and not tags.has(tag):
			tags.append(tag)
	var dimensions: Array = Array(base.get("dimensions", [1, 1])).duplicate(true)
	return {
		"name": item_name,
		"slot": str(base.get("slot", "relic")),
		"base_id": str(base.get("id", "")),
		"base_name": base_name,
		"base_type": str(base.get("base_type", base_name)),
		"item_class": str(base.get("item_class", "Item")),
		"armor_class": str(base.get("armor_class", "")),
		"item_level": item_level,
		"rarity": rarity,
		"tags": tags,
		"implicit_stats": implicit_stats,
		"prefixes": prefixes.duplicate(true),
		"suffixes": suffixes.duplicate(true),
		"stats": total_stats.duplicate(true),
		"total_stats": total_stats.duplicate(true),
		"affixes": affix_names,
		"forge_potential": forge_potential,
		"max_forge_potential": forge_potential,
		"build_flags": build_flags.duplicate(true),
		"flags": build_flags.duplicate(true),
		"unique_effects": unique_effects.duplicate(true),
		"description": description,
		"dimensions": dimensions,
		"inv_w": int(dimensions[0]) if dimensions.size() >= 2 else 1,
		"inv_h": int(dimensions[1]) if dimensions.size() >= 2 else 1
	}

static func roll_rarity(rng: RandomNumberGenerator, item_level: int) -> String:
	var roll: float = rng.randf()
	var unique_chance: float = 0.010 + min(0.030, float(item_level) * 0.0009)
	if roll >= 1.0 - unique_chance:
		return "Unique"
	if roll >= 0.78:
		return "Rare"
	if roll >= 0.30:
		return "Magic"
	return "Normal"

static func affix_counts_for_rarity(rng: RandomNumberGenerator, rarity: String) -> Dictionary:
	match rarity:
		"Normal":
			return {"prefix": 0, "suffix": 0}
		"Magic":
			if rng.randf() < 0.50:
				return {"prefix": 1, "suffix": 0}
			return {"prefix": 1, "suffix": 1}
		"Rare":
			var total: int = rng.randi_range(3, 6)
			var prefixes: int = rng.randi_range(1, min(3, total))
			var suffixes: int = clamp(total - prefixes, 0, 3)
			if suffixes == 0:
				suffixes = 1
				prefixes = max(1, prefixes - 1)
			return {"prefix": prefixes, "suffix": suffixes}
		"Crafted":
			return {"prefix": 1, "suffix": 1}
	return {"prefix": 0, "suffix": 0}

static func _forge_potential_for(rarity: String, item_level: int, rng: RandomNumberGenerator) -> int:
	var base_potential: int = 12 + int(float(item_level) * 0.45)
	match rarity:
		"Normal":
			base_potential += 12
		"Magic":
			base_potential += 7
		"Rare":
			base_potential += 1
		"Crafted":
			base_potential += 5
		"Unique":
			return 0
	return max(1, base_potential + rng.randi_range(-3, 5))
