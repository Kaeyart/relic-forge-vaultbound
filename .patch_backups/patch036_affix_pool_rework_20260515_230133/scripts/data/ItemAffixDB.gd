class_name RVItemAffixDB
extends RefCounted

const BASE_ITEMS: Dictionary = {
	"rusted_sword": {"name": "Rusted Sword", "slot": "weapon", "base_type": "Sword", "tags": ["Weapon", "Melee", "Physical"], "implicit_stats": {"Melee Damage": 0.06}},
	"iron_axe": {"name": "Iron Axe", "slot": "weapon", "base_type": "Axe", "tags": ["Weapon", "Melee", "Physical"], "implicit_stats": {"Melee Damage": 0.08}},
	"war_mace": {"name": "War Mace", "slot": "weapon", "base_type": "Mace", "tags": ["Weapon", "Melee", "Physical"], "implicit_stats": {"Stun Damage": 0.08, "Melee Damage": 0.04}},
	"ember_wand": {"name": "Ember Wand", "slot": "weapon", "base_type": "Wand", "tags": ["Weapon", "Spell", "Fire"], "implicit_stats": {"Spell Damage": 0.06, "Fire Damage": 0.04}},
	"storm_focus": {"name": "Storm Focus", "slot": "offhand", "base_type": "Focus", "tags": ["Offhand", "Spell", "Lightning"], "implicit_stats": {"Spell Damage": 0.05, "Lightning Damage": 0.05}},
	"warden_shield": {"name": "Warden Shield", "slot": "offhand", "base_type": "Shield", "tags": ["Offhand", "Defense"], "implicit_stats": {"Armor": 12.0, "Maximum Life": 10.0}},
	"leather_hood": {"name": "Leather Hood", "slot": "head", "base_type": "Light Helmet", "armor_class": "Light", "tags": ["Armor", "Evasion"], "implicit_stats": {"Maximum Mana": 8.0}},
	"iron_helm": {"name": "Iron Helm", "slot": "head", "base_type": "Heavy Helmet", "armor_class": "Heavy", "tags": ["Armor", "Defense"], "implicit_stats": {"Armor": 14.0}},
	"chain_chest": {"name": "Chain Chest", "slot": "chest", "base_type": "Medium Armor", "armor_class": "Medium", "tags": ["Armor"], "implicit_stats": {"Armor": 22.0, "Maximum Life": 8.0}},
	"plate_chest": {"name": "Plate Chest", "slot": "chest", "base_type": "Heavy Armor", "armor_class": "Heavy", "tags": ["Armor", "Defense"], "implicit_stats": {"Armor": 34.0}},
	"silk_robes": {"name": "Silk Robes", "slot": "chest", "base_type": "Caster Armor", "armor_class": "Caster", "tags": ["Armor", "Spell"], "implicit_stats": {"Maximum Mana": 18.0, "Spell Damage": 0.03}},
	"work_gloves": {"name": "Work Gloves", "slot": "gloves", "base_type": "Gloves", "tags": ["Armor"], "implicit_stats": {"Attack Speed": 0.02}},
	"trapwright_grips": {"name": "Trapwright Grips", "slot": "gloves", "base_type": "Trap Gloves", "tags": ["Armor", "Trap"], "implicit_stats": {"Trap Damage": 0.05}},
	"travel_boots": {"name": "Travel Boots", "slot": "boots", "base_type": "Boots", "tags": ["Armor", "Movement"], "implicit_stats": {"Movement Speed": 0.03}},
	"bronze_ring": {"name": "Bronze Ring", "slot": "ring", "base_type": "Ring", "tags": ["Jewelry"], "implicit_stats": {"Maximum Life": 7.0}},
	"opal_ring": {"name": "Opal Ring", "slot": "ring", "base_type": "Caster Ring", "tags": ["Jewelry", "Spell"], "implicit_stats": {"Spell Damage": 0.04}},
	"bone_amulet": {"name": "Bone Amulet", "slot": "amulet", "base_type": "Amulet", "tags": ["Jewelry"], "implicit_stats": {"Global Damage": 0.03}},
	"relic_core": {"name": "Relic Core", "slot": "relic", "base_type": "Relic", "tags": ["Relic"], "implicit_stats": {"Maximum Spirit": 5.0}}
}

const PREFIXES: Array[Dictionary] = [
	{"id": "scorching", "name": "Scorching", "stat": "Fire Damage", "tags": ["Fire", "Damage"], "slots": ["weapon", "offhand", "ring", "amulet", "relic"], "values": [0.07, 0.11, 0.16, 0.22, 0.30], "weight": 12},
	{"id": "glacial", "name": "Glacial", "stat": "Cold Damage", "tags": ["Cold", "Damage"], "slots": ["weapon", "offhand", "ring", "amulet", "relic"], "values": [0.07, 0.11, 0.16, 0.22, 0.30], "weight": 10},
	{"id": "charged", "name": "Charged", "stat": "Lightning Damage", "tags": ["Lightning", "Damage"], "slots": ["weapon", "offhand", "ring", "amulet", "relic"], "values": [0.07, 0.11, 0.16, 0.22, 0.30], "weight": 10},
	{"id": "hollow", "name": "Hollow", "stat": "Void Damage", "tags": ["Void", "Damage"], "slots": ["weapon", "offhand", "ring", "amulet", "relic"], "values": [0.07, 0.11, 0.16, 0.22, 0.30], "weight": 9},
	{"id": "butchers", "name": "Butcher's", "stat": "Melee Damage", "tags": ["Melee", "Physical", "Damage"], "slots": ["weapon", "gloves", "amulet", "ring"], "values": [0.08, 0.12, 0.18, 0.25, 0.34], "weight": 11},
	{"id": "trapwrights", "name": "Trapwright's", "stat": "Trap Damage", "tags": ["Trap", "Damage"], "slots": ["weapon", "offhand", "gloves", "ring", "relic"], "values": [0.08, 0.12, 0.18, 0.25, 0.34], "weight": 9},
	{"id": "vital", "name": "Vital", "stat": "Maximum Life", "tags": ["Life", "Defense"], "slots": ["head", "chest", "gloves", "boots", "amulet", "ring", "relic", "offhand"], "values": [10.0, 18.0, 29.0, 43.0, 62.0], "weight": 14},
	{"id": "arcane", "name": "Arcane", "stat": "Maximum Mana", "tags": ["Mana", "Resource"], "slots": ["head", "chest", "offhand", "amulet", "ring", "relic"], "values": [8.0, 15.0, 25.0, 38.0, 56.0], "weight": 10},
	{"id": "guarded", "name": "Guarded", "stat": "Armor", "tags": ["Armor", "Defense"], "slots": ["head", "chest", "gloves", "boots", "offhand"], "values": [12.0, 22.0, 36.0, 55.0, 80.0], "weight": 11},
	{"id": "commanding", "name": "Commanding", "stat": "Maximum Spirit", "tags": ["Spirit", "Resource"], "slots": ["amulet", "relic", "head", "chest"], "values": [3.0, 5.0, 8.0, 12.0, 18.0], "weight": 4}
]

const SUFFIXES: Array[Dictionary] = [
	{"id": "of_flameward", "name": "of Flameward", "stat": "Fire Resistance", "tags": ["Fire", "Resistance"], "slots": ["head", "chest", "gloves", "boots", "amulet", "ring", "offhand"], "values": [0.08, 0.14, 0.21, 0.29, 0.39], "weight": 10},
	{"id": "of_frostward", "name": "of Frostward", "stat": "Cold Resistance", "tags": ["Cold", "Resistance"], "slots": ["head", "chest", "gloves", "boots", "amulet", "ring", "offhand"], "values": [0.08, 0.14, 0.21, 0.29, 0.39], "weight": 10},
	{"id": "of_stormward", "name": "of Stormward", "stat": "Lightning Resistance", "tags": ["Lightning", "Resistance"], "slots": ["head", "chest", "gloves", "boots", "amulet", "ring", "offhand"], "values": [0.08, 0.14, 0.21, 0.29, 0.39], "weight": 10},
	{"id": "of_the_abyss", "name": "of the Abyss", "stat": "Void Resistance", "tags": ["Void", "Resistance"], "slots": ["head", "chest", "gloves", "boots", "amulet", "ring", "offhand"], "values": [0.08, 0.14, 0.21, 0.29, 0.39], "weight": 9},
	{"id": "of_precision", "name": "of Precision", "stat": "Critical Chance", "tags": ["Critical", "Damage"], "slots": ["weapon", "gloves", "amulet", "ring"], "values": [0.035, 0.055, 0.08, 0.11, 0.15], "weight": 8},
	{"id": "of_ruin", "name": "of Ruin", "stat": "Critical Damage", "tags": ["Critical", "Damage"], "slots": ["weapon", "amulet", "ring"], "values": [0.10, 0.17, 0.25, 0.36, 0.50], "weight": 7},
	{"id": "of_haste", "name": "of Haste", "stat": "Attack Speed", "tags": ["Speed"], "slots": ["weapon", "gloves", "ring"], "values": [0.03, 0.05, 0.075, 0.105, 0.14], "weight": 8},
	{"id": "of_swiftness", "name": "of Swiftness", "stat": "Movement Speed", "tags": ["Movement", "Speed"], "slots": ["boots", "amulet"], "values": [0.03, 0.05, 0.075, 0.10, 0.13], "weight": 7},
	{"id": "of_focus", "name": "of Focus", "stat": "Cooldown Reduction", "tags": ["Cooldown", "Utility"], "slots": ["offhand", "amulet", "ring", "relic"], "values": [0.025, 0.04, 0.06, 0.085, 0.12], "weight": 6},
	{"id": "of_recovery", "name": "of Recovery", "stat": "Life on Kill", "tags": ["Recovery", "Life"], "slots": ["weapon", "chest", "gloves", "ring", "relic"], "values": [3.0, 6.0, 10.0, 15.0, 22.0], "weight": 8}
]

const UNIQUES: Array[Dictionary] = [
	{
		"id": "nightfall_reaver",
		"name": "Nightfall Reaver",
		"base_id": "iron_axe",
		"required_level": 6,
		"stats": {"Void Damage": 0.24, "Critical Damage": 0.18, "Melee Damage": 0.10},
		"build_flags": ["fireball_void_conversion", "void_crit_wave"],
		"unique_effects": ["Fireball also scales with Void Damage and counts as Void.", "Critical strikes can trigger a shadow wave."],
		"description": "Turns simple fire casting into a Void build engine."
	},
	{
		"id": "furnace_crown",
		"name": "Furnace Crown",
		"base_id": "iron_helm",
		"required_level": 5,
		"stats": {"Fire Damage": 0.18, "Melee Damage": 0.10, "Maximum Life": 24.0},
		"build_flags": ["cleave_fire_conversion", "cleave_larger_area"],
		"unique_effects": ["Cleave also counts as Fire.", "Cleave gains increased area."],
		"description": "Makes melee builds lean into fire explosions."
	},
	{
		"id": "trapdoor_grips",
		"name": "Trapdoor Grips",
		"base_id": "trapwright_grips",
		"required_level": 4,
		"stats": {"Trap Damage": 0.22, "Void Damage": 0.12, "Cooldown Reduction": 0.04},
		"build_flags": ["blade_trap_void_conversion", "trap_rift_echo"],
		"unique_effects": ["Blade Trap also counts as Void.", "Trap builds gain rift synergy."],
		"description": "A glove slot archetype for trap-rift builds."
	},
	{
		"id": "riftwalker_boots",
		"name": "Riftwalker Boots",
		"base_id": "travel_boots",
		"required_level": 7,
		"stats": {"Movement Speed": 0.11, "Void Damage": 0.14, "Maximum Mana": 25.0},
		"build_flags": ["void_rift_larger", "void_rift_cheaper"],
		"unique_effects": ["Void Rift gains area.", "Void Rift costs less mana."],
		"description": "Makes Void Rift easier to use as a primary room-control tool."
	},
	{
		"id": "stormglass_ring",
		"name": "Stormglass Ring",
		"base_id": "opal_ring",
		"required_level": 5,
		"stats": {"Lightning Damage": 0.18, "Cold Damage": 0.12, "Maximum Mana": 18.0},
		"build_flags": ["storm_lance_cold_conversion", "storm_lance_extra_radius"],
		"unique_effects": ["Storm Lance also counts as Cold.", "Storm Lance gains a slightly wider hit profile."],
		"description": "A bridge between lightning chaining and freeze setups."
	},
	{
		"id": "choir_prism",
		"name": "Choir Prism",
		"base_id": "relic_core",
		"required_level": 8,
		"stats": {"Global Damage": 0.12, "Maximum Spirit": 10.0, "Maximum Mana": 18.0},
		"build_flags": ["support_gem_resonance", "spirit_support_discount"],
		"unique_effects": ["Supported active skills gain more damage.", "Spirit support reservation pressure is reduced slightly."],
		"description": "A relic for skill-gem and spirit-reservation builds."
	}
]

static func base_ids() -> Array:
	return BASE_ITEMS.keys()

static func base_item(base_id: String) -> Dictionary:
	return BASE_ITEMS.get(base_id, BASE_ITEMS["rusted_sword"]).duplicate(true)

static func random_base_for_level(rng: RandomNumberGenerator, item_level: int) -> Dictionary:
	var ids: Array = base_ids()
	var base_id: String = str(ids[rng.randi_range(0, ids.size() - 1)])
	return base_item(base_id)

static func random_unique_for_level(rng: RandomNumberGenerator, item_level: int) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for unique_value: Dictionary in UNIQUES:
		if int(unique_value.get("required_level", 1)) <= item_level:
			candidates.append(unique_value)
	if candidates.is_empty():
		return {}
	return candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)

static func tier_for_level(rng: RandomNumberGenerator, item_level: int) -> int:
	var max_tier: int = clamp(1 + int(item_level / 5), 1, 5)
	var tier: int = max_tier
	if max_tier > 1 and rng.randf() < 0.35:
		tier -= 1
	if max_tier > 2 and rng.randf() < 0.16:
		tier -= 1
	return clamp(tier, 1, 5)

static func random_affix(rng: RandomNumberGenerator, affix_type: String, slot: String, item_level: int, existing_ids: Array[String]) -> Dictionary:
	var pool: Array[Dictionary] = PREFIXES
	if affix_type == "suffix":
		pool = SUFFIXES
	var candidates: Array[Dictionary] = []
	for affix_value: Dictionary in pool:
		if existing_ids.has(str(affix_value.get("id", ""))):
			continue
		var allowed_slots: Array = affix_value.get("slots", [])
		if allowed_slots.has(slot) or allowed_slots.has("any"):
			candidates.append(affix_value)
	if candidates.is_empty():
		return {}
	var selected: Dictionary = _weighted_pick(rng, candidates)
	var tier: int = tier_for_level(rng, item_level)
	return materialize_affix(selected, affix_type, tier, item_level)

static func materialize_affix(template: Dictionary, affix_type: String, tier: int, item_level: int) -> Dictionary:
	var values: Array = template.get("values", [1.0])
	var index: int = clamp(tier - 1, 0, values.size() - 1)
	var amount: float = float(values[index])
	return {
		"id": str(template.get("id", "affix")),
		"name": str(template.get("name", "Affix")),
		"type": affix_type,
		"tier": tier,
		"item_level": item_level,
		"stat": str(template.get("stat", "Global Damage")),
		"value": amount,
		"stats": {str(template.get("stat", "Global Damage")): amount},
		"tags": template.get("tags", []).duplicate(true)
	}

static func aggregate_stats(base_stats: Dictionary, prefixes: Array, suffixes: Array, extra_stats: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {}
	_add_stats(result, base_stats)
	for prefix_value: Variant in prefixes:
		if typeof(prefix_value) == TYPE_DICTIONARY:
			_add_stats(result, prefix_value.get("stats", {}))
	for suffix_value: Variant in suffixes:
		if typeof(suffix_value) == TYPE_DICTIONARY:
			_add_stats(result, suffix_value.get("stats", {}))
	_add_stats(result, extra_stats)
	return result

static func affix_names(prefixes: Array, suffixes: Array) -> Array[String]:
	var result: Array[String] = []
	for prefix_value: Variant in prefixes:
		if typeof(prefix_value) == TYPE_DICTIONARY:
			result.append(str(prefix_value.get("name", "Prefix")))
	for suffix_value: Variant in suffixes:
		if typeof(suffix_value) == TYPE_DICTIONARY:
			result.append(str(suffix_value.get("name", "Suffix")))
	return result

static func item_name_for(base_name: String, rarity: String, prefixes: Array, suffixes: Array) -> String:
	if rarity == "Normal":
		return base_name
	if prefixes.size() > 0 and typeof(prefixes[0]) == TYPE_DICTIONARY:
		var prefix_name: String = str(prefixes[0].get("name", ""))
		if suffixes.size() > 0 and typeof(suffixes[0]) == TYPE_DICTIONARY:
			return prefix_name + " " + base_name + " " + str(suffixes[0].get("name", ""))
		return prefix_name + " " + base_name
	if suffixes.size() > 0 and typeof(suffixes[0]) == TYPE_DICTIONARY:
		return base_name + " " + str(suffixes[0].get("name", ""))
	return rarity + " " + base_name

static func _weighted_pick(rng: RandomNumberGenerator, candidates: Array[Dictionary]) -> Dictionary:
	var total_weight: int = 0
	for candidate: Dictionary in candidates:
		total_weight += int(candidate.get("weight", 1))
	var roll: int = rng.randi_range(1, max(1, total_weight))
	var running: int = 0
	for candidate2: Dictionary in candidates:
		running += int(candidate2.get("weight", 1))
		if roll <= running:
			return candidate2.duplicate(true)
	return candidates[0].duplicate(true)

static func _add_stats(target: Dictionary, source: Dictionary) -> void:
	for key_value: Variant in source.keys():
		var key: String = str(key_value)
		target[key] = float(target.get(key, 0.0)) + float(source[key_value])
