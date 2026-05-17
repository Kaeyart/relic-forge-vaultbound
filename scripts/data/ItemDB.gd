class_name RVItemDB
extends RefCounted

const SLOTS: Array[String] = ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring", "relic"]

static func make_starter_weapon() -> Dictionary:
	return RVItemRollSystem.make_starter_weapon()

static func craft_basic_item(state: RVGameState) -> Dictionary:
	return RVItemRollSystem.craft_basic_item(state)

static func generate_drop(state: RVGameState, depth: int) -> Dictionary:
	return RVItemRollSystem.generate_drop(state, depth)

static func generate_test_item(rng: RandomNumberGenerator, item_level: int, slot: String = "", rarity: String = "") -> Dictionary:
	return RVItemRollSystem.generate_test_item(rng, item_level, slot, rarity)

static func normalize_item(item: Dictionary) -> Dictionary:
	return RVItemizationSystem.normalize_item(item)

static func rebuild_item(item: Dictionary) -> Dictionary:
	return RVItemRollSystem.rebuild_item(item)

static func build_flags_from_equipped(state: RVGameState) -> Array[String]:
	var result: Array[String] = []
	for slot_name: Variant in state.equipped.keys():
		var item_value: Variant = state.equipped[slot_name]
		if typeof(item_value) != TYPE_DICTIONARY: continue
		var item: Dictionary = normalize_item(Dictionary(item_value))
		for flag_value: Variant in item.get("build_flags", item.get("flags", [])):
			var flag: String = str(flag_value)
			if flag != "" and not result.has(flag): result.append(flag)
	return result

static func rarity_color_name(rarity: String) -> String:
	match rarity:
		"Normal": return "Common"
		"Magic": return "Magic"
		"Rare": return "Rare"
		"Unique": return "Unique"
		"Crafted": return "Crafted"
	return rarity

static func rarity_sort_value(rarity: String) -> int:
	match rarity:
		"Normal": return 0
		"Magic": return 1
		"Rare": return 2
		"Crafted": return 3
		"Unique": return 4
	return 0

static func item_detail_bbcode(item: Dictionary, header: String = "ITEM", source_line: String = "Equipment") -> String:
	return RVItemizationSystem.item_detail_bbcode(item, header, source_line)

static func item_signal_score(item: Dictionary) -> int:
	return RVItemizationSystem.item_signal_score(item)
