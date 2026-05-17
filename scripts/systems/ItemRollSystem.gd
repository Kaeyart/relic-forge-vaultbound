class_name RVItemRollSystem
extends RefCounted

static func make_starter_weapon() -> Dictionary:
	var base: Dictionary = RVItemBaseDB.get_base("ember_wand")
	var prefix_def: Dictionary = RVItemAffixDB.affix_def_by_id("spell_damage")
	var prefixes: Array = [RVItemAffixDB.materialize_affix(prefix_def, "prefix", 5, 1)]
	return build_item_from_parts(base, "Magic", 1, prefixes, [], 32, {}, [], [], "A starter wand with enough potential to teach crafting.")

static func craft_basic_item(state: Object) -> Dictionary:
	var rng: RandomNumberGenerator = _rng_from_state(state)
	var item_level: int = max(1, int(state.get("level")) if state != null else 1)
	return roll_item(rng, item_level, "", "Rare")

static func generate_drop(state: Object, depth: int) -> Dictionary:
	var rng: RandomNumberGenerator = _rng_from_state(state)
	var item_level: int = _drop_item_level(state, depth)
	var rarity: String = _roll_rarity(rng, item_level, state)
	if rarity == "Unique":
		var unique_item: Dictionary = _roll_unique(rng, item_level)
		if not unique_item.is_empty(): return unique_item
		rarity = "Rare"
	return roll_item(rng, item_level, "", rarity, _reward_bias_tags(state))

static func generate_test_item(rng: RandomNumberGenerator, item_level: int, slot: String = "", rarity: String = "") -> Dictionary:
	return roll_item(rng, max(1, item_level), _normalize_slot(slot), rarity)

static func roll_item(rng: RandomNumberGenerator, item_level: int, slot: String = "", rarity: String = "", required_tags: Array = []) -> Dictionary:
	var base: Dictionary = RVItemBaseDB.random_base_for_level(rng, max(1, item_level), _normalize_slot(slot), required_tags)
	var chosen_rarity: String = rarity if rarity != "" else _roll_rarity(rng, item_level, null)
	if chosen_rarity == "Unique":
		var unique_item: Dictionary = _roll_unique(rng, item_level, str(base.get("slot", "")))
		if not unique_item.is_empty(): return unique_item
		chosen_rarity = "Rare"
	var prefixes: Array = []
	var suffixes: Array = []
	var existing_groups: Array[String] = []
	for i: int in range(_roll_affix_count(rng, chosen_rarity)):
		var affix: Dictionary = RVItemAffixDB.random_affix(rng, "prefix", str(base.get("slot", "")), item_level, existing_groups, [])
		if not affix.is_empty():
			prefixes.append(affix)
			existing_groups.append(str(affix.get("group", affix.get("id", ""))))
	for i2: int in range(_roll_affix_count(rng, chosen_rarity)):
		var suffix: Dictionary = RVItemAffixDB.random_affix(rng, "suffix", str(base.get("slot", "")), item_level, existing_groups, [])
		if not suffix.is_empty():
			suffixes.append(suffix)
			existing_groups.append(str(suffix.get("group", suffix.get("id", ""))))
	return build_item_from_parts(base, chosen_rarity, item_level, prefixes, suffixes, _roll_forge_potential(rng, chosen_rarity, item_level, prefixes.size() + suffixes.size()))

static func build_item_from_parts(base: Dictionary, rarity: String, item_level: int, prefixes: Array, suffixes: Array, forge_potential: int, extra_stats: Dictionary = {}, unique_effects: Array = [], build_flags: Array = [], description: String = "") -> Dictionary:
	var base_name: String = str(base.get("name", "Item"))
	var item: Dictionary = {"uid":"item_" + str(Time.get_ticks_msec()) + "_" + str(randi()), "item_type":"equipment", "category":"equipment", "base_id":str(base.get("base_id", "")), "base_name":base_name, "base_type":str(base.get("base_type", base_name)), "item_class":str(base.get("item_class", base.get("base_type", "Item"))), "armor_class":str(base.get("armor_class", "")), "slot":str(base.get("slot", "")), "rarity":rarity, "item_level":max(1, item_level), "required_level":max(1, min(max(1, item_level), int(base.get("min_level", 1)) + int(item_level * 0.72))), "implicit_stats":Dictionary(base.get("implicit_stats", {})).duplicate(true), "prefixes":prefixes.duplicate(true), "suffixes":suffixes.duplicate(true), "crafted_mods":[], "sealed_mods":[], "fractured_mod_uid":"", "quality":0, "corrupted":false, "influence":"", "extra_stats":extra_stats.duplicate(true), "unique_effects":unique_effects.duplicate(true), "build_flags":build_flags.duplicate(true), "flags":build_flags.duplicate(true), "forge_potential":max(0, forge_potential), "max_forge_potential":max(0, forge_potential), "tags":Array(base.get("tags", [])).duplicate(true), "dimensions":Array(base.get("dimensions", [1, 1])).duplicate(true), "description":description}
	item["name"] = RVItemAffixDB.item_name_for(base_name, rarity, prefixes, suffixes)
	return RVItemizationSystem.normalize_item(item)

static func rebuild_item(item: Dictionary) -> Dictionary:
	return RVItemizationSystem.normalize_item(item)

static func _roll_unique(rng: RandomNumberGenerator, item_level: int, preferred_slot: String = "") -> Dictionary:
	var unique_template: Dictionary = RVItemAffixDB.random_unique_for_level(rng, item_level)
	if unique_template.is_empty(): return {}
	var base: Dictionary = RVItemBaseDB.base_item(str(unique_template.get("base_id", "relic_core")))
	if preferred_slot != "" and str(base.get("slot", "")) != preferred_slot and rng.randf() < 0.65: return {}
	var item: Dictionary = build_item_from_parts(base, "Unique", max(item_level, int(unique_template.get("required_level", 1))), [], [], 0, Dictionary(unique_template.get("stats", {})), Array(unique_template.get("unique_effects", [])), Array(unique_template.get("build_flags", [])), str(unique_template.get("description", "")))
	item["unique_id"] = str(unique_template.get("id", "unique"))
	item["name"] = str(unique_template.get("name", item.get("name", "Unique Item")))
	item["required_level"] = int(unique_template.get("required_level", item.get("required_level", 1)))
	return RVItemizationSystem.normalize_item(item)

static func _roll_rarity(rng: RandomNumberGenerator, item_level: int, state: Object = null) -> String:
	var unique_chance: float = 0.018 + float(item_level) * 0.00018
	var rare_chance: float = 0.16 + min(0.16, float(item_level) * 0.002)
	var magic_chance: float = 0.34
	if state != null:
		var activity: Variant = state.get("current_activity")
		if typeof(activity) == TYPE_DICTIONARY:
			var map_item: Dictionary = Dictionary(Dictionary(activity).get("map", {}))
			if str(map_item.get("rarity", "Normal")) == "Rare":
				rare_chance += 0.08
				unique_chance += 0.008
	var roll: float = rng.randf()
	if roll < unique_chance: return "Unique"
	if roll < unique_chance + rare_chance: return "Rare"
	if roll < unique_chance + rare_chance + magic_chance: return "Magic"
	return "Normal"

static func _roll_affix_count(rng: RandomNumberGenerator, rarity: String) -> int:
	match rarity:
		"Magic": return 1 if rng.randf() < 0.82 else 0
		"Rare":
			var roll: float = rng.randf()
			if roll < 0.14: return 1
			if roll < 0.58: return 2
			return 3
	return 0

static func _roll_forge_potential(rng: RandomNumberGenerator, rarity: String, item_level: int, affix_count: int) -> int:
	if rarity == "Unique": return 0
	var base: int = 18 + int(float(item_level) * 0.52)
	match rarity:
		"Normal": base += 18
		"Magic": base += 11
		"Rare": base += 4
	base -= affix_count * 2
	base += rng.randi_range(-5, 9)
	return clampi(base, 6, 78)

static func _drop_item_level(state: Object, depth: int) -> int:
	var level: int = max(1, depth)
	if state != null:
		level = max(level, int(state.get("level")))
		var activity: Variant = state.get("current_activity")
		if typeof(activity) == TYPE_DICTIONARY:
			var map_item: Dictionary = Dictionary(Dictionary(activity).get("map", {}))
			level = max(level, int(map_item.get("map_level", map_item.get("item_level", level))))
	return max(1, level)

static func _reward_bias_tags(state: Object) -> Array:
	if state == null: return []
	var activity: Variant = state.get("current_activity")
	if typeof(activity) != TYPE_DICTIONARY: return []
	var map_item: Dictionary = Dictionary(Dictionary(activity).get("map", {}))
	var area: String = str(map_item.get("area_name", map_item.get("id", ""))).to_lower()
	if area.contains("forge") or area.contains("ember"): return ["fire"]
	if area.contains("catacomb") or area.contains("ossuary"): return ["void"]
	if area.contains("aqueduct") or area.contains("storm"): return ["lightning"]
	return []

static func _rng_from_state(state: Object) -> RandomNumberGenerator:
	if state != null:
		var value: Variant = state.get("rng")
		if value is RandomNumberGenerator: return value as RandomNumberGenerator
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng

static func _normalize_slot(slot: String) -> String:
	match slot:
		"ring1", "ring2": return "ring"
		"helmet": return "head"
		"armor": return "chest"
		_: return slot
