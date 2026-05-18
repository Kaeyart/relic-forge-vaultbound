class_name RVItemAffixDB
extends RefCounted

# T1 is best; T5 is weakest. Higher item levels unlock lower-numbered tiers.
const TIER_LEVELS: Dictionary = {5: 1, 4: 10, 3: 22, 2: 38, 1: 58}

const PREFIXES: Array[Dictionary] = [
	{"id":"melee_damage", "name":"Butcher's", "group":"melee_damage", "stat":"Melee Damage", "tags":["melee","attack","physical","damage"], "slots":["weapon","gloves","ring","amulet"], "weight":105, "tiers":{5:[0.08,0.12],4:[0.13,0.18],3:[0.19,0.26],2:[0.27,0.36],1:[0.38,0.52]}},
	{"id":"spell_damage", "name":"Runescribed", "group":"spell_damage", "stat":"Spell Damage", "tags":["spell","caster","damage"], "slots":["weapon","offhand","chest","ring","amulet","relic"], "weight":105, "tiers":{5:[0.07,0.11],4:[0.12,0.17],3:[0.18,0.25],2:[0.26,0.36],1:[0.38,0.54]}},
	{"id":"fire_damage", "name":"Scorching", "group":"fire_damage", "stat":"Fire Damage", "tags":["fire","elemental","damage"], "slots":["weapon","offhand","ring","amulet","relic","chest"], "weight":90, "tiers":{5:[0.07,0.11],4:[0.12,0.17],3:[0.18,0.25],2:[0.26,0.36],1:[0.38,0.54]}},
	{"id":"lightning_damage", "name":"Charged", "group":"lightning_damage", "stat":"Lightning Damage", "tags":["lightning","elemental","damage"], "slots":["weapon","offhand","ring","amulet","relic"], "weight":78, "tiers":{5:[0.07,0.11],4:[0.12,0.17],3:[0.18,0.25],2:[0.26,0.36],1:[0.38,0.54]}},
	{"id":"void_damage", "name":"Hollow", "group":"void_damage", "stat":"Void Damage", "tags":["void","damage"], "slots":["weapon","offhand","ring","amulet","relic"], "weight":70, "tiers":{5:[0.07,0.11],4:[0.12,0.17],3:[0.18,0.25],2:[0.26,0.36],1:[0.38,0.54]}},
	{"id":"trap_damage", "name":"Trapwright's", "group":"trap_damage", "stat":"Trap Damage", "tags":["trap","damage"], "slots":["weapon","offhand","gloves","ring","relic"], "weight":74, "tiers":{5:[0.08,0.12],4:[0.13,0.18],3:[0.19,0.26],2:[0.27,0.36],1:[0.38,0.52]}},
	{"id":"maximum_life", "name":"Vital", "group":"maximum_life", "stat":"Maximum Life", "tags":["life","defense"], "slots":["head","chest","gloves","boots","amulet","ring","relic","offhand"], "weight":115, "tiers":{5:[10,18],4:[19,30],3:[31,48],2:[49,72],1:[76,110]}},
	{"id":"maximum_mana", "name":"Arcane", "group":"maximum_mana", "stat":"Maximum Mana", "tags":["mana","resource","caster"], "slots":["head","chest","offhand","amulet","ring","relic"], "weight":84, "tiers":{5:[8,14],4:[15,24],3:[25,39],2:[40,60],1:[64,92]}},
	{"id":"armor_flat", "name":"Guarded", "group":"armor_flat", "stat":"Armor", "tags":["armor","defense"], "slots":["head","chest","gloves","boots","offhand"], "weight":92, "tiers":{5:[12,22],4:[23,38],3:[39,62],2:[64,98],1:[104,150]}}
]

const SUFFIXES: Array[Dictionary] = [
	{"id":"fire_resistance", "name":"of Flameward", "group":"fire_resistance", "stat":"Fire Resistance", "tags":["fire","resistance","defense"], "slots":["head","chest","gloves","boots","amulet","ring","offhand"], "weight":86, "tiers":{5:[0.08,0.13],4:[0.14,0.20],3:[0.21,0.29],2:[0.30,0.40],1:[0.42,0.55]}},
	{"id":"cold_resistance", "name":"of Frostward", "group":"cold_resistance", "stat":"Cold Resistance", "tags":["cold","resistance","defense"], "slots":["head","chest","gloves","boots","amulet","ring","offhand"], "weight":86, "tiers":{5:[0.08,0.13],4:[0.14,0.20],3:[0.21,0.29],2:[0.30,0.40],1:[0.42,0.55]}},
	{"id":"lightning_resistance", "name":"of Stormward", "group":"lightning_resistance", "stat":"Lightning Resistance", "tags":["lightning","resistance","defense"], "slots":["head","chest","gloves","boots","amulet","ring","offhand"], "weight":86, "tiers":{5:[0.08,0.13],4:[0.14,0.20],3:[0.21,0.29],2:[0.30,0.40],1:[0.42,0.55]}},
	{"id":"void_resistance", "name":"of the Abyss", "group":"void_resistance", "stat":"Void Resistance", "tags":["void","resistance","defense"], "slots":["head","chest","gloves","boots","amulet","ring","offhand"], "weight":72, "tiers":{5:[0.08,0.13],4:[0.14,0.20],3:[0.21,0.29],2:[0.30,0.40],1:[0.42,0.55]}},
	{"id":"critical_chance", "name":"of Precision", "group":"critical_chance", "stat":"Critical Chance", "tags":["critical","damage"], "slots":["weapon","gloves","amulet","ring"], "weight":72, "tiers":{5:[0.035,0.050],4:[0.055,0.075],3:[0.080,0.105],2:[0.110,0.145],1:[0.155,0.210]}},
	{"id":"critical_damage", "name":"of Ruin", "group":"critical_damage", "stat":"Critical Damage", "tags":["critical","damage"], "slots":["weapon","amulet","ring"], "weight":62, "tiers":{5:[0.10,0.16],4:[0.17,0.24],3:[0.25,0.35],2:[0.36,0.50],1:[0.54,0.76]}},
	{"id":"attack_speed", "name":"of Haste", "group":"attack_speed", "stat":"Attack Speed", "tags":["speed","attack"], "slots":["weapon","gloves","ring"], "weight":70, "tiers":{5:[0.03,0.045],4:[0.05,0.07],3:[0.075,0.10],2:[0.105,0.135],1:[0.145,0.19]}},
	{"id":"movement_speed", "name":"of Swiftness", "group":"movement_speed", "stat":"Movement Speed", "tags":["movement","speed"], "slots":["boots","amulet"], "weight":64, "tiers":{5:[0.03,0.045],4:[0.05,0.07],3:[0.075,0.095],2:[0.10,0.125],1:[0.13,0.16]}},
	{"id":"cooldown_reduction", "name":"of Focus", "group":"cooldown_reduction", "stat":"Cooldown Reduction", "tags":["cooldown","utility"], "slots":["offhand","amulet","ring","relic","gloves"], "weight":54, "tiers":{5:[0.025,0.035],4:[0.04,0.055],3:[0.06,0.080],2:[0.085,0.115],1:[0.12,0.16]}},
	{"id":"life_on_kill", "name":"of Recovery", "group":"life_on_kill", "stat":"Life on Kill", "tags":["recovery","life"], "slots":["weapon","chest","gloves","ring","relic"], "weight":68, "tiers":{5:[3,5],4:[6,9],3:[10,14],2:[15,22],1:[24,36]}}
]

const UNIQUES: Array[Dictionary] = [
	{"id":"nightfall_reaver", "name":"Nightfall Reaver", "base_id":"iron_axe", "required_level":6, "stats":{"Void Damage":0.24,"Critical Damage":0.18,"Melee Damage":0.10}, "build_flags":["fireball_void_conversion","void_crit_wave"], "unique_effects":["Fireball also scales with Void Damage and counts as Void.","Critical strikes can trigger a shadow wave."], "description":"Turns simple fire casting into a Void build engine."},
	{"id":"furnace_crown", "name":"Furnace Crown", "base_id":"iron_helm", "required_level":5, "stats":{"Fire Damage":0.18,"Melee Damage":0.10,"Maximum Life":24.0}, "build_flags":["cleave_fire_conversion","cleave_larger_area"], "unique_effects":["Cleave also counts as Fire.","Cleave gains increased area."], "description":"Makes melee builds lean into fire explosions."},
	{"id":"trapdoor_grips", "name":"Trapdoor Grips", "base_id":"trapwright_grips", "required_level":4, "stats":{"Trap Damage":0.22,"Void Damage":0.12,"Cooldown Reduction":0.04}, "build_flags":["blade_trap_void_conversion","trap_rift_echo"], "unique_effects":["Blade Trap also counts as Void.","Trap builds gain rift synergy."], "description":"A glove slot archetype for trap-rift builds."},
	{"id":"stormglass_ring", "name":"Stormglass Ring", "base_id":"opal_ring", "required_level":5, "stats":{"Lightning Damage":0.18,"Cold Damage":0.12,"Maximum Mana":18.0}, "build_flags":["storm_lance_cold_conversion","storm_lance_extra_radius"], "unique_effects":["Storm Lance also counts as Cold.","Storm Lance gains a wider hit profile."], "description":"A bridge between lightning chaining and freeze setups."}
]

static func affix_def_by_id(affix_id: String) -> Dictionary:
	for affix_value: Dictionary in PREFIXES + SUFFIXES:
		if str(affix_value.get("id", "")) == affix_id:
			return affix_value.duplicate(true)
	match affix_id:
		"scorching": return affix_def_by_id("fire_damage")
		"vital": return affix_def_by_id("maximum_life")
	return PREFIXES[0].duplicate(true)

static func random_unique_for_level(rng: RandomNumberGenerator, item_level: int) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for unique_value: Dictionary in UNIQUES:
		if int(unique_value.get("required_level", 1)) <= item_level:
			candidates.append(unique_value)
	if candidates.is_empty():
		return {}
	return candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)

static func tier_for_level(rng: RandomNumberGenerator, item_level: int) -> int:
	return roll_tier_for_level(rng, item_level)

static func roll_tier_for_level(rng: RandomNumberGenerator, item_level: int) -> int:
	var available: Array[int] = []
	for tier_value: Variant in TIER_LEVELS.keys():
		var tier: int = int(tier_value)
		if item_level >= int(TIER_LEVELS[tier]):
			available.append(tier)
	if available.is_empty():
		available = [5]
	available.sort()
	var roll: float = rng.randf()
	if roll < 0.08:
		return int(available[0])
	if roll < 0.24 and available.size() >= 2:
		return int(available[min(1, available.size() - 1)])
	if roll < 0.54 and available.size() >= 3:
		return int(available[min(2, available.size() - 1)])
	return int(available[available.size() - 1])

static func random_affix(rng: RandomNumberGenerator, affix_type: String, slot: String, item_level: int, existing_groups: Array[String] = [], required_tags: Array = []) -> Dictionary:
	var pool: Array[Dictionary] = PREFIXES if affix_type == "prefix" else SUFFIXES
	var candidates: Array[Dictionary] = []
	for affix_value: Dictionary in pool:
		if existing_groups.has(str(affix_value.get("group", affix_value.get("id", "")))):
			continue
		if not Array(affix_value.get("slots", [])).has(slot):
			continue
		if not _has_required_or_empty(Array(affix_value.get("tags", [])), required_tags):
			continue
		candidates.append(affix_value)
	if candidates.is_empty():
		return {}
	var selected: Dictionary = _weighted_pick(rng, candidates)
	return materialize_affix(selected, affix_type, -1, rng, item_level)

static func materialize_affix(template: Dictionary, affix_type: String = "prefix", tier: int = -1, rng_or_item_level: Variant = null, item_level_value: int = -1) -> Dictionary:
	var item_level: int = item_level_value
	var rng: RandomNumberGenerator = null
	if rng_or_item_level is RandomNumberGenerator:
		rng = rng_or_item_level as RandomNumberGenerator
	elif typeof(rng_or_item_level) == TYPE_INT or typeof(rng_or_item_level) == TYPE_FLOAT:
		item_level = int(rng_or_item_level)
	if item_level <= 0:
		item_level = 1
	if tier < 1:
		tier = roll_tier_for_level(rng if rng != null else RandomNumberGenerator.new(), item_level)
	if not Dictionary(template.get("tiers", {})).has(tier):
		tier = 5
	var value_range: Array = Array(Dictionary(template.get("tiers", {})).get(tier, [1.0, 1.0]))
	var min_value: float = float(value_range[0])
	var max_value: float = float(value_range[1] if value_range.size() > 1 else value_range[0])
	var amount: float = (min_value + max_value) * 0.5
	if rng != null:
		amount = rng.randf_range(min_value, max_value)
	amount = _round_amount(amount)
	return {"uid":"affix_" + str(Time.get_ticks_msec()) + "_" + str(randi()), "id":str(template.get("id","affix")), "name":str(template.get("name","Affix")), "group":str(template.get("group", template.get("id","affix"))), "type":affix_type, "tier":tier, "tier_label":"T" + str(tier), "item_level":item_level, "stat":str(template.get("stat","Global Damage")), "value":amount, "range":[min_value, max_value], "stats":{str(template.get("stat","Global Damage")): amount}, "tags":Array(template.get("tags", [])).duplicate(true)}

static func aggregate_stats(base_stats: Dictionary, prefixes: Array, suffixes: Array, extra_stats: Dictionary = {}, crafted_mods: Array = []) -> Dictionary:
	var result: Dictionary = {}
	_add_stats(result, base_stats)
	for affix_value: Variant in prefixes + suffixes + crafted_mods:
		if typeof(affix_value) == TYPE_DICTIONARY:
			_add_stats(result, Dictionary(affix_value).get("stats", {}))
	_add_stats(result, extra_stats)
	return result

static func affix_names(prefixes: Array, suffixes: Array, crafted_mods: Array = []) -> Array[String]:
	var result: Array[String] = []
	for affix_value: Variant in prefixes + suffixes:
		if typeof(affix_value) == TYPE_DICTIONARY:
			result.append("T" + str(Dictionary(affix_value).get("tier", "?")) + " " + str(Dictionary(affix_value).get("name", "Affix")))
	for crafted_value: Variant in crafted_mods:
		if typeof(crafted_value) == TYPE_DICTIONARY:
			result.append("Crafted: " + str(Dictionary(crafted_value).get("name", "Crafted Mod")))
	return result

static func affix_tags(prefixes: Array, suffixes: Array, crafted_mods: Array = []) -> Array[String]:
	var result: Array[String] = []
	for affix_value: Variant in prefixes + suffixes + crafted_mods:
		if typeof(affix_value) != TYPE_DICTIONARY:
			continue
		for tag_value: Variant in Dictionary(affix_value).get("tags", []):
			var tag: String = str(tag_value).to_lower()
			if tag != "" and not result.has(tag):
				result.append(tag)
	return result

static func item_name_for(base_name: String, rarity: String, prefixes: Array, suffixes: Array) -> String:
	if rarity == "Normal":
		return base_name
	if prefixes.size() > 0 and typeof(prefixes[0]) == TYPE_DICTIONARY:
		var prefix_name: String = str(Dictionary(prefixes[0]).get("name", ""))
		if suffixes.size() > 0 and typeof(suffixes[0]) == TYPE_DICTIONARY:
			return prefix_name + " " + base_name + " " + str(Dictionary(suffixes[0]).get("name", ""))
		return prefix_name + " " + base_name
	if suffixes.size() > 0 and typeof(suffixes[0]) == TYPE_DICTIONARY:
		return base_name + " " + str(Dictionary(suffixes[0]).get("name", ""))
	return rarity + " " + base_name

static func best_affix_tier(item: Dictionary) -> int:
	var best: int = 99
	for affix_value: Variant in Array(item.get("prefixes", [])) + Array(item.get("suffixes", [])) + Array(item.get("crafted_mods", [])):
		if typeof(affix_value) == TYPE_DICTIONARY:
			best = min(best, int(Dictionary(affix_value).get("tier", 99)))
	return 0 if best == 99 else best

static func _has_required_or_empty(tags: Array, required_tags: Array) -> bool:
	if required_tags.is_empty():
		return true
	for required_value: Variant in required_tags:
		for tag_value: Variant in tags:
			if str(required_value).to_lower() == str(tag_value).to_lower():
				return true
	return false

static func _weighted_pick(rng: RandomNumberGenerator, candidates: Array[Dictionary]) -> Dictionary:
	var total_weight: int = 0
	for candidate: Dictionary in candidates:
		total_weight += max(1, int(candidate.get("weight", 1)))
	var roll: int = rng.randi_range(1, max(1, total_weight))
	var running: int = 0
	for candidate2: Dictionary in candidates:
		running += max(1, int(candidate2.get("weight", 1)))
		if roll <= running:
			return candidate2.duplicate(true)
	return candidates[0].duplicate(true)

static func _add_stats(target: Dictionary, source: Dictionary) -> void:
	for key_value: Variant in source.keys():
		var key: String = str(key_value)
		target[key] = float(target.get(key, 0.0)) + float(source[key_value])

static func _round_amount(amount: float) -> float:
	if abs(amount) >= 2.0:
		return float(int(round(amount)))
	return snappedf(amount, 0.001)

# Patch 080B repair: compatibility helpers for legacy forgecraft and new crafting verbs.
static func max_tier_for_affix(def: Dictionary, item_level: int) -> int:
	var tiers: Array = Array(def.get("tiers", []))
	if tiers.is_empty():
		return clampi(int(def.get("max_tier", 5)), 1, 5)
	var best: int = 1
	for tier_value: Variant in tiers:
		if typeof(tier_value) != TYPE_DICTIONARY:
			continue
		var tier_data: Dictionary = Dictionary(tier_value)
		var tier_num: int = int(tier_data.get("tier", 1))
		var min_level: int = int(tier_data.get("min_item_level", tier_data.get("min_level", tier_data.get("level", 1))))
		if item_level >= min_level:
			best = max(best, tier_num)
	return clampi(best, 1, 5)

static func next_tier_affix(affix: Dictionary, rng: RandomNumberGenerator, item_level: int) -> Dictionary:
	var out: Dictionary = affix.duplicate(true)
	var def: Dictionary = affix_def_by_id(str(out.get("id", "")))
	if def.is_empty():
		def = out.duplicate(true)
	var current_tier: int = clampi(int(out.get("tier", 1)), 1, 5)
	var next_tier: int = min(current_tier + 1, max_tier_for_affix(def, item_level))
	out["tier"] = next_tier
	out["stats"] = _compat_roll_stats_for_tier(def, next_tier, rng, Dictionary(out.get("stats", {})))
	out["name"] = str(def.get("name", out.get("name", "Affix")))
	out["type"] = str(def.get("type", out.get("type", "prefix")))
	out["family"] = str(def.get("family", out.get("family", out.get("id", "affix"))))
	out["tags"] = Array(def.get("tags", out.get("tags", [])))
	return out

static func roll_affix(rng: RandomNumberGenerator, affix_type: String, base: Dictionary, item_level: int, blocked_families: Array[String] = [], wanted_tags: Array = []) -> Dictionary:
	var candidates: Array = []
	for def_value: Variant in _compat_fallback_affix_defs():
		if typeof(def_value) != TYPE_DICTIONARY:
			continue
		var def: Dictionary = Dictionary(def_value)
		if str(def.get("type", "")) != affix_type:
			continue
		var family: String = str(def.get("family", def.get("id", "")))
		if blocked_families.has(family):
			continue
		if not _compat_def_allows_base(def, base):
			continue
		candidates.append(def)
	if candidates.is_empty():
		return {}
	var weighted: Array = []
	for candidate_value: Variant in candidates:
		var candidate: Dictionary = Dictionary(candidate_value)
		var weight: int = int(candidate.get("weight", 100))
		var tags: Array = Array(candidate.get("tags", []))
		for wanted_value: Variant in wanted_tags:
			if tags.has(str(wanted_value)) or tags.has(wanted_value):
				weight += 40
		for _i: int in range(max(1, weight / 20)):
			weighted.append(candidate)
	var picked: Dictionary = Dictionary(weighted[rng.randi_range(0, weighted.size() - 1)] if weighted.size() > 0 else candidates[0])
	var max_tier: int = max_tier_for_affix(picked, item_level)
	var tier: int = _compat_roll_tier(rng, max_tier)
	return _compat_make_rolled_affix(picked, tier, rng)

static func _compat_make_rolled_affix(def: Dictionary, tier: int, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"id": str(def.get("id", "affix")),
		"name": str(def.get("name", "Affix")),
		"type": str(def.get("type", "prefix")),
		"family": str(def.get("family", def.get("id", "affix"))),
		"tier": clampi(tier, 1, 5),
		"tags": Array(def.get("tags", [])),
		"stats": _compat_roll_stats_for_tier(def, tier, rng),
	}

static func _compat_roll_tier(rng: RandomNumberGenerator, max_tier: int) -> int:
	max_tier = clampi(max_tier, 1, 5)
	var roll: float = rng.randf()
	if max_tier >= 5 and roll < 0.08:
		return 5
	if max_tier >= 4 and roll < 0.20:
		return 4
	if max_tier >= 3 and roll < 0.42:
		return 3
	if max_tier >= 2 and roll < 0.70:
		return 2
	return 1

static func _compat_roll_stats_for_tier(def: Dictionary, tier: int, rng: RandomNumberGenerator, fallback_stats: Dictionary = {}) -> Dictionary:
	var stats: Dictionary = {}
	var tier_data: Dictionary = _compat_tier_data(def, tier)
	var stat_ranges: Dictionary = Dictionary(tier_data.get("stats", def.get("stats", {})))
	if stat_ranges.is_empty() and not fallback_stats.is_empty():
		var scale: float = 1.0 + 0.18 * float(max(0, tier - 1))
		for key_value: Variant in fallback_stats.keys():
			stats[str(key_value)] = _compat_number_round(float(fallback_stats[key_value]) * scale)
		return stats
	for stat_key_value: Variant in stat_ranges.keys():
		var stat_key: String = str(stat_key_value)
		var range_value: Variant = stat_ranges[stat_key_value]
		if typeof(range_value) == TYPE_ARRAY:
			var arr: Array = Array(range_value)
			if arr.size() >= 2:
				stats[stat_key] = rng.randi_range(int(arr[0]), int(arr[1]))
			elif arr.size() == 1:
				stats[stat_key] = arr[0]
		elif typeof(range_value) == TYPE_DICTIONARY:
			var r: Dictionary = Dictionary(range_value)
			stats[stat_key] = rng.randi_range(int(r.get("min", 1)), int(r.get("max", 1)))
		else:
			stats[stat_key] = range_value
	return stats

static func _compat_tier_data(def: Dictionary, tier: int) -> Dictionary:
	var tiers: Array = Array(def.get("tiers", []))
	var best: Dictionary = {}
	for tier_value: Variant in tiers:
		if typeof(tier_value) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = Dictionary(tier_value)
		if int(data.get("tier", 1)) == tier:
			return data
		if best.is_empty() or int(data.get("tier", 1)) < tier:
			best = data
	return best

static func _compat_number_round(value: float) -> Variant:
	if abs(value - round(value)) < 0.001:
		return int(round(value))
	return snappedf(value, 0.01)

static func _compat_def_allows_base(def: Dictionary, base: Dictionary) -> bool:
	var slots: Array = Array(def.get("slots", []))
	if not slots.is_empty() and not slots.has(str(base.get("slot", ""))):
		return false
	var base_tags: Array = Array(base.get("tags", []))
	var required_tags: Array = Array(def.get("requires_any_tag", []))
	if required_tags.is_empty():
		return true
	for tag_value: Variant in required_tags:
		if base_tags.has(str(tag_value)) or base_tags.has(tag_value):
			return true
	return false

static func _compat_fallback_affix_defs() -> Array:
	return [
		{"id": "prefix_maximum_life", "name": "Vital", "type": "prefix", "family": "maximum_life", "tags": ["Life", "Defense"], "weight": 120, "tiers": [{"tier": 1, "min_item_level": 1, "stats": {"Maximum Life": [8, 15]}}, {"tier": 2, "min_item_level": 8, "stats": {"Maximum Life": [16, 28]}}, {"tier": 3, "min_item_level": 18, "stats": {"Maximum Life": [29, 45]}}, {"tier": 4, "min_item_level": 35, "stats": {"Maximum Life": [46, 70]}}, {"tier": 5, "min_item_level": 55, "stats": {"Maximum Life": [71, 105]}}]},
		{"id": "prefix_maximum_mana", "name": "Lucid", "type": "prefix", "family": "maximum_mana", "tags": ["Mana", "Resource"], "weight": 100, "tiers": [{"tier": 1, "min_item_level": 1, "stats": {"Maximum Mana": [6, 12]}}, {"tier": 2, "min_item_level": 8, "stats": {"Maximum Mana": [13, 24]}}, {"tier": 3, "min_item_level": 18, "stats": {"Maximum Mana": [25, 39]}}, {"tier": 4, "min_item_level": 35, "stats": {"Maximum Mana": [40, 62]}}, {"tier": 5, "min_item_level": 55, "stats": {"Maximum Mana": [63, 95]}}]},
		{"id": "prefix_spell_damage", "name": "Runic", "type": "prefix", "family": "spell_damage", "tags": ["Spell", "Damage"], "requires_any_tag": ["Spell", "Caster", "Wand", "Staff"], "slots": ["weapon", "offhand", "amulet", "relic"], "weight": 100, "tiers": [{"tier": 1, "min_item_level": 1, "stats": {"Spell Damage %": [5, 9]}}, {"tier": 2, "min_item_level": 10, "stats": {"Spell Damage %": [10, 17]}}, {"tier": 3, "min_item_level": 24, "stats": {"Spell Damage %": [18, 28]}}, {"tier": 4, "min_item_level": 42, "stats": {"Spell Damage %": [29, 43]}}, {"tier": 5, "min_item_level": 62, "stats": {"Spell Damage %": [44, 65]}}]},
		{"id": "prefix_attack_damage", "name": "Tempered", "type": "prefix", "family": "attack_damage", "tags": ["Attack", "Physical", "Damage"], "slots": ["weapon"], "weight": 110, "tiers": [{"tier": 1, "min_item_level": 1, "stats": {"Attack Damage %": [6, 12]}}, {"tier": 2, "min_item_level": 10, "stats": {"Attack Damage %": [13, 22]}}, {"tier": 3, "min_item_level": 24, "stats": {"Attack Damage %": [23, 36]}}, {"tier": 4, "min_item_level": 42, "stats": {"Attack Damage %": [37, 55]}}, {"tier": 5, "min_item_level": 62, "stats": {"Attack Damage %": [56, 82]}}]},
		{"id": "prefix_armor", "name": "Plated", "type": "prefix", "family": "armor", "tags": ["Armor", "Defense"], "slots": ["head", "chest", "gloves", "boots"], "weight": 100, "tiers": [{"tier": 1, "min_item_level": 1, "stats": {"Armor": [8, 18]}}, {"tier": 2, "min_item_level": 10, "stats": {"Armor": [19, 35]}}, {"tier": 3, "min_item_level": 24, "stats": {"Armor": [36, 60]}}, {"tier": 4, "min_item_level": 42, "stats": {"Armor": [61, 95]}}, {"tier": 5, "min_item_level": 62, "stats": {"Armor": [96, 145]}}]},
		{"id": "suffix_fire_resistance", "name": "of Ash", "type": "suffix", "family": "fire_resistance", "tags": ["Fire", "Resistance", "Defense"], "weight": 100, "tiers": [{"tier": 1, "min_item_level": 1, "stats": {"Fire Resistance %": [6, 12]}}, {"tier": 2, "min_item_level": 12, "stats": {"Fire Resistance %": [13, 22]}}, {"tier": 3, "min_item_level": 28, "stats": {"Fire Resistance %": [23, 34]}}, {"tier": 4, "min_item_level": 48, "stats": {"Fire Resistance %": [35, 48]}}, {"tier": 5, "min_item_level": 68, "stats": {"Fire Resistance %": [49, 65]}}]},
		{"id": "suffix_cold_resistance", "name": "of Rime", "type": "suffix", "family": "cold_resistance", "tags": ["Cold", "Resistance", "Defense"], "weight": 100, "tiers": [{"tier": 1, "min_item_level": 1, "stats": {"Cold Resistance %": [6, 12]}}, {"tier": 2, "min_item_level": 12, "stats": {"Cold Resistance %": [13, 22]}}, {"tier": 3, "min_item_level": 28, "stats": {"Cold Resistance %": [23, 34]}}, {"tier": 4, "min_item_level": 48, "stats": {"Cold Resistance %": [35, 48]}}, {"tier": 5, "min_item_level": 68, "stats": {"Cold Resistance %": [49, 65]}}]},
		{"id": "suffix_lightning_resistance", "name": "of Storms", "type": "suffix", "family": "lightning_resistance", "tags": ["Lightning", "Resistance", "Defense"], "weight": 100, "tiers": [{"tier": 1, "min_item_level": 1, "stats": {"Lightning Resistance %": [6, 12]}}, {"tier": 2, "min_item_level": 12, "stats": {"Lightning Resistance %": [13, 22]}}, {"tier": 3, "min_item_level": 28, "stats": {"Lightning Resistance %": [23, 34]}}, {"tier": 4, "min_item_level": 48, "stats": {"Lightning Resistance %": [35, 48]}}, {"tier": 5, "min_item_level": 68, "stats": {"Lightning Resistance %": [49, 65]}}]},
		{"id": "suffix_attack_speed", "name": "of Haste", "type": "suffix", "family": "attack_speed", "tags": ["Attack", "Speed"], "requires_any_tag": ["Attack", "Melee", "Bow"], "slots": ["weapon", "gloves", "ring1", "ring2", "amulet"], "weight": 80, "tiers": [{"tier": 1, "min_item_level": 1, "stats": {"Attack Speed %": [3, 5]}}, {"tier": 2, "min_item_level": 16, "stats": {"Attack Speed %": [6, 8]}}, {"tier": 3, "min_item_level": 36, "stats": {"Attack Speed %": [9, 12]}}, {"tier": 4, "min_item_level": 56, "stats": {"Attack Speed %": [13, 16]}}, {"tier": 5, "min_item_level": 72, "stats": {"Attack Speed %": [17, 22]}}]},
		{"id": "suffix_cast_speed", "name": "of Invocation", "type": "suffix", "family": "cast_speed", "tags": ["Spell", "Speed"], "requires_any_tag": ["Spell", "Caster", "Wand", "Staff"], "slots": ["weapon", "offhand", "gloves", "ring1", "ring2", "amulet", "relic"], "weight": 80, "tiers": [{"tier": 1, "min_item_level": 1, "stats": {"Cast Speed %": [3, 5]}}, {"tier": 2, "min_item_level": 16, "stats": {"Cast Speed %": [6, 8]}}, {"tier": 3, "min_item_level": 36, "stats": {"Cast Speed %": [9, 12]}}, {"tier": 4, "min_item_level": 56, "stats": {"Cast Speed %": [13, 16]}}, {"tier": 5, "min_item_level": 72, "stats": {"Cast Speed %": [17, 22]}}]},
	]
