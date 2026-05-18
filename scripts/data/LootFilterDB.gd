class_name RVLootFilterDB
extends RefCounted

const PRESET_SHOW_ALL: String = "Show All"
const PRESET_STARTER: String = "Starter"
const PRESET_STRICT: String = "Strict"
const PRESET_CRAFTING: String = "Crafting"
const PRESET_MAPS: String = "Maps"
const PRESET_BUILD: String = "Build Filter"

static func preset_order() -> Array:
	return [PRESET_SHOW_ALL, PRESET_STARTER, PRESET_STRICT, PRESET_CRAFTING, PRESET_MAPS, PRESET_BUILD]

static func build_tag_order() -> Array:
	return ["fire", "cold", "lightning", "physical", "bleed", "void", "spell", "attack", "life", "defense", "mana", "spirit"]

static func default_settings() -> Dictionary:
	return {
		"show_normal": true,
		"show_magic": true,
		"show_rare": true,
		"show_unique": true,
		"show_maps": true,
		"show_gems": true,
		"show_currency": true,
		"show_materials": true,
		"show_crafting_bases": true,
		"min_item_level": 1,
		"max_affix_tier": 4,
		"min_forge_potential": 8,
		"map_min_tier": 1,
		"build_filter_tag": "fire",
		"require_build_tag": false,
		"highlight_high_tier_affixes": true,
		"highlight_high_forge_potential": true,
		"auto_pickup_gold": true,
		"auto_pickup_shards": true,
		"auto_pickup_embers": true,
		"auto_pickup_materials": true,
		"auto_pickup_currency": true,
		"auto_pickup_maps": false,
		"auto_pickup_gems": false,
		"manual_pickup_gear": true,
		"manual_pickup_uniques": true,
		"show_hidden_auto_pickup_notice": false,
	}

static func preset_settings(preset_id: String) -> Dictionary:
	var s: Dictionary = default_settings()
	match preset_id:
		PRESET_SHOW_ALL:
			s["show_normal"] = true
			s["show_magic"] = true
			s["show_rare"] = true
			s["show_unique"] = true
			s["show_maps"] = true
			s["show_gems"] = true
			s["show_currency"] = true
			s["show_materials"] = true
			s["show_crafting_bases"] = true
			s["max_affix_tier"] = 99
			s["min_forge_potential"] = 0
		PRESET_STARTER:
			s["show_normal"] = true
			s["show_magic"] = true
			s["show_rare"] = true
			s["show_unique"] = true
			s["show_maps"] = true
			s["show_gems"] = true
			s["show_crafting_bases"] = true
			s["max_affix_tier"] = 4
			s["min_forge_potential"] = 8
		PRESET_STRICT:
			s["show_normal"] = false
			s["show_magic"] = false
			s["show_rare"] = true
			s["show_unique"] = true
			s["show_maps"] = true
			s["show_gems"] = true
			s["show_crafting_bases"] = false
			s["max_affix_tier"] = 3
			s["min_forge_potential"] = 18
		PRESET_CRAFTING:
			s["show_normal"] = true
			s["show_magic"] = true
			s["show_rare"] = true
			s["show_unique"] = true
			s["show_maps"] = true
			s["show_gems"] = true
			s["show_crafting_bases"] = true
			s["max_affix_tier"] = 3
			s["min_forge_potential"] = 22
		PRESET_MAPS:
			s["show_normal"] = false
			s["show_magic"] = false
			s["show_rare"] = true
			s["show_unique"] = true
			s["show_maps"] = true
			s["show_gems"] = false
			s["show_crafting_bases"] = false
			s["map_min_tier"] = 1
		PRESET_BUILD:
			s["show_normal"] = false
			s["show_magic"] = true
			s["show_rare"] = true
			s["show_unique"] = true
			s["show_maps"] = true
			s["show_gems"] = true
			s["require_build_tag"] = true
			s["max_affix_tier"] = 3
			s["min_forge_potential"] = 14
	return s

static func next_preset(current: String, delta: int) -> String:
	var order: Array = preset_order()
	var idx: int = order.find(current)
	if idx < 0:
		idx = order.find(PRESET_STARTER)
	return str(order[wrapi(idx + delta, 0, order.size())])

static func next_build_tag(current: String, delta: int) -> String:
	var order: Array = build_tag_order()
	var idx: int = order.find(current)
	if idx < 0:
		idx = 0
	return str(order[wrapi(idx + delta, 0, order.size())])
