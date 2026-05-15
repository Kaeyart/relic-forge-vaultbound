class_name RVItemValidationSystem
extends RefCounted

static func validate_item(item: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	var normalized: Dictionary = RVItemDB.normalize_item(item)
	var rarity: String = str(normalized.get("rarity", "Normal"))
	var prefixes: Array = Array(normalized.get("prefixes", []))
	var suffixes: Array = Array(normalized.get("suffixes", []))
	if rarity == "Normal" and (prefixes.size() > 0 or suffixes.size() > 0):
		warnings.append("Normal item has explicit affixes")
	if rarity == "Magic" and prefixes.size() + suffixes.size() > 2:
		warnings.append("Magic item has more than 2 explicit affixes")
	if rarity == "Rare" and (prefixes.size() > 3 or suffixes.size() > 3):
		warnings.append("Rare item exceeds 3 prefix / 3 suffix cap")
	if rarity == "Unique" and int(normalized.get("forge_potential", 0)) > 0:
		warnings.append("Unique item has forge potential")
	_validate_affix_group(normalized, prefixes, "prefix", warnings)
	_validate_affix_group(normalized, suffixes, "suffix", warnings)
	var recalculated: Dictionary = RVItemAffixDB.aggregate_stats(Dictionary(normalized.get("implicit_stats", {})), prefixes, suffixes, {})
	var total: Dictionary = Dictionary(normalized.get("total_stats", normalized.get("stats", {})))
	for key_value: Variant in recalculated.keys():
		var key: String = str(key_value)
		if abs(float(recalculated[key_value]) - float(total.get(key, 0.0))) > 0.01:
			warnings.append("Total stat mismatch: " + key)
	return warnings

static func audit_generated_items(state: RVGameState, count: int = 500) -> Dictionary:
	var malformed: int = 0
	var warnings_by_type: Dictionary = {}
	for i: int in range(count):
		var item: Dictionary = RVItemDB.generate_test_item(state.rng, max(1, state.level + i % 40))
		var warnings: Array[String] = validate_item(item)
		if not warnings.is_empty():
			malformed += 1
			for warning: String in warnings:
				warnings_by_type[warning] = int(warnings_by_type.get(warning, 0)) + 1
	return {"checked": count, "malformed": malformed, "warnings": warnings_by_type}

static func _validate_affix_group(item: Dictionary, group: Array, expected_type: String, warnings: Array[String]) -> void:
	var seen_families: Dictionary = {}
	var slot: String = str(item.get("slot", ""))
	var item_level: int = int(item.get("item_level", 1))
	for affix_value: Variant in group:
		if typeof(affix_value) != TYPE_DICTIONARY:
			warnings.append("Affix is not dictionary")
			continue
		var affix: Dictionary = Dictionary(affix_value)
		if str(affix.get("type", expected_type)) != expected_type:
			warnings.append("Wrong affix type: " + str(affix.get("name", "affix")))
		var family: String = str(affix.get("family", ""))
		if family != "":
			if seen_families.has(family):
				warnings.append("Duplicate affix family: " + family)
			seen_families[family] = true
		var def: Dictionary = RVItemAffixDB.affix_def_by_id(str(affix.get("id", "")))
		if def.is_empty():
			warnings.append("Unknown affix id: " + str(affix.get("id", "")))
			continue
		var allowed_slots: Array = Array(def.get("allowed_slots", []))
		if not allowed_slots.has(slot) and not allowed_slots.has("any"):
			warnings.append("Illegal slot affix: " + str(affix.get("name", "affix")) + " on " + slot)
		var tier: int = int(affix.get("tier", 1))
		if tier > RVItemAffixDB.max_tier_for_affix(def, item_level):
			warnings.append("Affix tier exceeds item level: " + str(affix.get("name", "affix")))
