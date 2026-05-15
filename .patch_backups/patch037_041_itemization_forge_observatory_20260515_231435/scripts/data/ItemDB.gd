class_name RVItemDB
extends RefCounted

# Patch 036: ItemDB now delegates item generation to RVItemRollSystem.
# This keeps old call sites stable while the item model becomes tiered, slot-legal, and affix-family aware.

const SLOTS: Array[String] = ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring", "relic"]

static func make_starter_weapon() -> Dictionary:
	var base: Dictionary = RVItemBaseDB.get_base("ember_wand")
	var prefix_def: Dictionary = RVItemAffixDB.affix_def_by_id("spell_damage")
	var prefixes: Array = [RVItemAffixDB.materialize_affix(prefix_def, "prefix", 1, null)]
	return RVItemRollSystem.build_item_from_parts(base, "Magic", 1, prefixes, [], 22, {}, [], [], "A simple starter wand with enough potential to teach crafting.")

static func craft_basic_item(state: RVGameState) -> Dictionary:
	return RVItemRollSystem.craft_basic_item(state)

static func generate_drop(state: RVGameState, depth: int) -> Dictionary:
	return RVItemRollSystem.generate_drop(state, depth)

static func generate_test_item(rng: RandomNumberGenerator, item_level: int, slot: String = "", rarity: String = "") -> Dictionary:
	return RVItemRollSystem.roll_item(rng, max(1, item_level), slot, rarity)

static func normalize_item(item: Dictionary) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	if not result.has("item_level"):
		result["item_level"] = int(result.get("level", 1))
	if not result.has("base_id"):
		result["base_id"] = ""
	if not result.has("base_name"):
		result["base_name"] = str(result.get("name", "Item"))
	if not result.has("base_type"):
		result["base_type"] = str(result.get("slot", "Item")).capitalize()
	if not result.has("item_class"):
		result["item_class"] = "Item"
	if not result.has("armor_class"):
		result["armor_class"] = ""
	if not result.has("implicit_stats"):
		result["implicit_stats"] = {}
	if not result.has("prefixes"):
		result["prefixes"] = []
	if not result.has("suffixes"):
		result["suffixes"] = []
	if not result.has("build_flags"):
		result["build_flags"] = result.get("flags", [])
	if not result.has("flags"):
		result["flags"] = result.get("build_flags", [])
	if not result.has("unique_effects"):
		result["unique_effects"] = []
	if not result.has("forge_potential"):
		if str(result.get("rarity", "Normal")) == "Unique":
			result["forge_potential"] = 0
		else:
			result["forge_potential"] = 8
	if not result.has("max_forge_potential"):
		result["max_forge_potential"] = int(result.get("forge_potential", 0))
	var calculated_stats: Dictionary = RVItemAffixDB.aggregate_stats(
		Dictionary(result.get("implicit_stats", {})),
		Array(result.get("prefixes", [])),
		Array(result.get("suffixes", [])),
		Dictionary(result.get("extra_stats", {}))
	)
	if result.has("stats") and typeof(result["stats"]) == TYPE_DICTIONARY:
		for key_value: Variant in Dictionary(result["stats"]).keys():
			if not calculated_stats.has(str(key_value)):
				calculated_stats[str(key_value)] = float(Dictionary(result["stats"])[key_value])
	result["stats"] = calculated_stats.duplicate(true)
	result["total_stats"] = calculated_stats.duplicate(true)
	if not result.has("affixes"):
		result["affixes"] = RVItemAffixDB.affix_names(Array(result.get("prefixes", [])), Array(result.get("suffixes", [])))
	if not result.has("dimensions"):
		var dims: Vector2i = RVItemBaseDB.dimensions_for_item(result)
		result["dimensions"] = [dims.x, dims.y]
	if not result.has("inv_w") or not result.has("inv_h"):
		var dimensions: Array = Array(result.get("dimensions", [1, 1]))
		result["inv_w"] = int(dimensions[0]) if dimensions.size() >= 2 else 1
		result["inv_h"] = int(dimensions[1]) if dimensions.size() >= 2 else 1
	return result

static func build_flags_from_equipped(state: RVGameState) -> Array[String]:
	var result: Array[String] = []
	for slot_name: Variant in state.equipped.keys():
		var item_value: Variant = state.equipped[slot_name]
		if typeof(item_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = normalize_item(Dictionary(item_value))
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

static func rarity_sort_value(rarity: String) -> int:
	match rarity:
		"Normal":
			return 0
		"Magic":
			return 1
		"Rare":
			return 2
		"Crafted":
			return 3
		"Unique":
			return 4
	return 0
