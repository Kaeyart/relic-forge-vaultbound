class_name RVItemAffixDB
extends RefCounted

# Patch 037-041: expanded original affix system.
# It uses the broad ARPG system shape: prefixes/suffixes, slot legality,
# item-level-gated tiers, family blocking, weighted rolls, and build-tag bias.
# The affix names/content are original Relic Forge data.

static func prefixes() -> Array[Dictionary]:
	return [
		_affix("phys_damage", "Butcher's", "prefix", "major_damage", 930, ["Physical","Damage","Melee"], ["weapon","amulet","ring","gloves"], [], _tiers("Physical Damage", [[1,1000,4.0,8.0],[8,850,9.0,16.0],[16,700,17.0,28.0],[28,500,29.0,46.0],[42,320,47.0,72.0],[58,180,73.0,108.0]])),
		_affix("bleed_damage", "Rending", "prefix", "bleed_power", 620, ["Physical","Bleed","Damage"], ["weapon","gloves","ring","amulet"], [], _tiers("Bleed Damage", [[8,900,0.07,0.12],[18,650,0.13,0.22],[34,420,0.23,0.36],[52,220,0.37,0.55]])),
		_affix("fire_damage", "Scorching", "prefix", "major_damage", 920, ["Fire","Damage"], ["weapon","offhand","ring","amulet","relic"], [], _tiers("Fire Damage", [[1,1000,0.04,0.08],[8,850,0.09,0.15],[16,680,0.16,0.24],[28,450,0.25,0.36],[42,280,0.37,0.52],[58,150,0.53,0.72]])),
		_affix("burn_power", "Ashen", "prefix", "burn_power", 620, ["Fire","Burn","Damage"], ["weapon","offhand","gloves","ring","amulet","relic"], [], _tiers2("Burn Damage", "Ignite Chance", [[10,900,0.06,0.12,0.04,0.08],[24,600,0.13,0.24,0.09,0.14],[44,300,0.25,0.40,0.15,0.22],[64,120,0.41,0.62,0.23,0.32]])),
		_affix("cold_damage", "Glacial", "prefix", "major_damage", 900, ["Cold","Damage"], ["weapon","offhand","ring","amulet","relic"], [], _tiers("Cold Damage", [[1,1000,0.04,0.08],[8,850,0.09,0.15],[16,680,0.16,0.24],[28,450,0.25,0.36],[42,280,0.37,0.52],[58,150,0.53,0.72]])),
		_affix("freeze_power", "Stillborn", "prefix", "control_power", 560, ["Cold","Freeze","Control"], ["weapon","offhand","gloves","ring","amulet","relic"], [], _tiers2("Freeze Chance", "Cold Damage", [[10,900,0.05,0.09,0.06,0.11],[26,520,0.10,0.16,0.12,0.21],[46,260,0.17,0.25,0.22,0.34]])),
		_affix("lightning_damage", "Charged", "prefix", "major_damage", 900, ["Lightning","Damage"], ["weapon","offhand","ring","amulet","relic"], [], _tiers("Lightning Damage", [[1,1000,0.04,0.08],[8,850,0.09,0.15],[16,680,0.16,0.24],[28,450,0.25,0.36],[42,280,0.37,0.52],[58,150,0.53,0.72]])),
		_affix("chain_power", "Forking", "prefix", "chain_power", 520, ["Lightning","Chain","Proc"], ["weapon","offhand","ring","amulet","relic"], [], _tiers2("Chain Chance", "Lightning Damage", [[12,800,0.03,0.06,0.07,0.13],[30,450,0.07,0.11,0.14,0.25],[52,200,0.12,0.18,0.26,0.40]])),
		_affix("void_damage", "Hollow", "prefix", "major_damage", 860, ["Void","Damage"], ["weapon","offhand","ring","amulet","relic"], [], _tiers("Void Damage", [[1,1000,0.04,0.08],[8,850,0.09,0.15],[16,680,0.16,0.24],[28,450,0.25,0.36],[42,280,0.37,0.52],[58,150,0.53,0.72]])),
		_affix("curse_power", "Accursed", "prefix", "curse_power", 540, ["Void","Curse","Damage"], ["weapon","offhand","ring","amulet","relic"], [], _tiers2("Curse Effect", "Void Damage", [[12,820,0.05,0.10,0.07,0.13],[30,460,0.11,0.18,0.14,0.25],[52,220,0.19,0.28,0.26,0.40]])),
		_affix("spell_damage", "Arcane", "prefix", "spell_power", 860, ["Spell","Damage","Mana"], ["weapon","offhand","head","chest","ring","amulet","relic"], [], _tiers2("Spell Damage", "Maximum Mana", [[1,1000,0.04,0.08,3,6],[8,850,0.09,0.14,7,12],[16,680,0.15,0.22,13,20],[28,450,0.23,0.32,21,32],[42,260,0.33,0.46,33,48],[60,140,0.47,0.64,49,70]])),
		_affix("trap_damage", "Trapwright's", "prefix", "trap_power", 760, ["Trap","Damage"], ["weapon","offhand","gloves","ring","amulet","relic"], [], _tiers("Trap Damage", [[1,1000,0.05,0.09],[8,850,0.10,0.16],[16,650,0.17,0.26],[28,420,0.27,0.40],[42,250,0.41,0.58],[60,130,0.59,0.78]])),
		_affix("trap_cooldown", "Springloaded", "prefix", "trap_utility", 420, ["Trap","Cooldown","Utility"], ["gloves","offhand","amulet","relic"], [], _tiers2("Trap Arming Speed", "Cooldown Reduction", [[12,800,0.05,0.09,0.02,0.04],[30,420,0.10,0.16,0.05,0.07],[54,180,0.17,0.25,0.08,0.11]])),
		_affix("life", "Vital", "prefix", "life", 1000, ["Life","Defense"], ["head","chest","gloves","boots","ring","amulet","offhand"], [], _tiers("Maximum Life", [[1,1000,8,16],[8,850,17,30],[16,700,31,50],[28,480,51,82],[42,300,83,126],[58,180,127,185]])),
		_affix("armor", "Guarded", "prefix", "armor", 950, ["Armor","Defense"], ["head","chest","gloves","boots","offhand"], [], _tiers("Armor", [[1,1000,8,18],[8,850,19,36],[16,700,37,66],[28,480,67,108],[42,300,109,165],[58,180,166,245]])),
		_affix("ward", "Warded", "prefix", "ward", 680, ["Ward","Defense","Mana"], ["head","chest","offhand","amulet","relic"], [], _tiers("Ward", [[6,900,10,20],[16,700,21,38],[30,450,39,66],[48,240,67,104]])),
		_affix("spirit", "Commanding", "prefix", "spirit", 540, ["Spirit","Resource"], ["head","chest","amulet","relic"], [], _tiers("Maximum Spirit", [[8,850,2,4],[18,650,5,8],[34,420,9,13],[52,220,14,20]])),
		_affix("mana", "Deepwell", "prefix", "mana_pool", 760, ["Mana","Resource"], ["head","chest","offhand","ring","amulet","relic"], [], _tiers("Maximum Mana", [[1,1000,7,14],[10,820,15,28],[22,580,29,48],[40,320,49,76],[60,160,77,112]])),
		_affix("area_size", "Expansive", "prefix", "area", 420, ["Area","Damage"], ["weapon","offhand","amulet","relic"], [], _tiers("Area Size", [[12,800,0.05,0.09],[30,420,0.10,0.16],[54,180,0.17,0.25]])),
		_affix("projectile_count", "Splintering", "prefix", "projectile", 280, ["Projectile","Damage"], ["weapon","offhand","amulet","relic"], [], _tiers("Additional Projectiles", [[24,420,1,1],[62,120,2,2]])),
		_affix("skill_fireball", "Pyromancer's", "prefix", "skill_level_fireball", 250, ["Fire","Skill","Fireball"], ["weapon","offhand","amulet","relic"], [], _tiers("Fireball Level", [[18,600,1,1],[46,220,2,2],[72,80,3,3]])),
		_affix("skill_cleave", "Executioner's", "prefix", "skill_level_cleave", 250, ["Physical","Skill","Cleave"], ["weapon","gloves","amulet","relic"], [], _tiers("Cleave Level", [[18,600,1,1],[46,220,2,2],[72,80,3,3]])),
		_affix("skill_frost_nova", "Cryomancer's", "prefix", "skill_level_frost_nova", 240, ["Cold","Skill","Frost Nova"], ["weapon","offhand","head","amulet","relic"], [], _tiers("Frost Nova Level", [[18,600,1,1],[46,220,2,2],[72,80,3,3]])),
		_affix("skill_storm_lance", "Stormcaller’s", "prefix", "skill_level_storm_lance", 240, ["Lightning","Skill","Storm Lance"], ["weapon","offhand","amulet","ring","relic"], [], _tiers("Storm Lance Level", [[18,600,1,1],[46,220,2,2],[72,80,3,3]])),
		_affix("skill_void_rift", "Rift-Sung", "prefix", "skill_level_void_rift", 240, ["Void","Skill","Void Rift"], ["offhand","amulet","relic"], [], _tiers("Void Rift Level", [[18,600,1,1],[46,220,2,2],[72,80,3,3]])),
		_affix("skill_blade_trap", "Mechanist's", "prefix", "skill_level_blade_trap", 240, ["Trap","Skill","Blade Trap"], ["gloves","amulet","relic"], [], _tiers("Blade Trap Level", [[18,600,1,1],[46,220,2,2],[72,80,3,3]]))
	]

static func suffixes() -> Array[Dictionary]:
	return [
		_affix("fire_res", "of Flameward", "suffix", "fire_resistance", 900, ["Fire","Resistance"], ["head","chest","gloves","boots","ring","amulet","offhand"], [], _tiers("Fire Resistance", [[1,1000,0.08,0.16],[8,850,0.17,0.28],[18,650,0.29,0.42],[34,420,0.43,0.58],[52,220,0.59,0.76]])),
		_affix("cold_res", "of Frostward", "suffix", "cold_resistance", 900, ["Cold","Resistance"], ["head","chest","gloves","boots","ring","amulet","offhand"], [], _tiers("Cold Resistance", [[1,1000,0.08,0.16],[8,850,0.17,0.28],[18,650,0.29,0.42],[34,420,0.43,0.58],[52,220,0.59,0.76]])),
		_affix("lightning_res", "of Stormward", "suffix", "lightning_resistance", 900, ["Lightning","Resistance"], ["head","chest","gloves","boots","ring","amulet","offhand"], [], _tiers("Lightning Resistance", [[1,1000,0.08,0.16],[8,850,0.17,0.28],[18,650,0.29,0.42],[34,420,0.43,0.58],[52,220,0.59,0.76]])),
		_affix("void_res", "of the Abyss", "suffix", "void_resistance", 820, ["Void","Resistance"], ["head","chest","gloves","boots","ring","amulet","offhand"], [], _tiers("Void Resistance", [[1,1000,0.08,0.16],[8,850,0.17,0.28],[18,650,0.29,0.42],[34,420,0.43,0.58],[52,220,0.59,0.76]])),
		_affix("phys_res", "of the Bulwark", "suffix", "physical_resistance", 760, ["Physical","Resistance","Defense"], ["head","chest","gloves","boots","amulet","offhand"], [], _tiers("Physical Resistance", [[10,800,0.05,0.10],[24,520,0.11,0.18],[46,260,0.19,0.28]])),
		_affix("crit", "of Precision", "suffix", "critical", 760, ["Critical","Damage"], ["weapon","gloves","amulet","ring"], [], _tiers2("Critical Chance", "Critical Damage", [[1,1000,0.03,0.06,0.06,0.12],[10,800,0.07,0.10,0.13,0.22],[24,550,0.11,0.15,0.23,0.36],[44,280,0.16,0.22,0.37,0.55]])),
		_affix("attack_speed", "of Haste", "suffix", "attack_speed", 760, ["Speed","Attack"], ["weapon","gloves","ring"], [], _tiers("Attack Speed", [[1,1000,0.03,0.05],[12,760,0.06,0.09],[30,420,0.10,0.14],[54,180,0.15,0.21]])),
		_affix("cast_speed", "of Incantation", "suffix", "cast_speed", 720, ["Speed","Spell"], ["weapon","offhand","gloves","ring","amulet","relic"], [], _tiers("Cast Speed", [[1,1000,0.03,0.05],[12,760,0.06,0.09],[30,420,0.10,0.14],[54,180,0.15,0.21]])),
		_affix("movement", "of Swiftness", "suffix", "movement", 680, ["Movement","Speed"], ["boots","amulet"], [], _tiers("Movement Speed", [[1,1000,0.04,0.07],[12,780,0.08,0.12],[30,420,0.13,0.18],[58,160,0.19,0.24]])),
		_affix("cooldown", "of Focus", "suffix", "cooldown", 640, ["Cooldown","Utility"], ["offhand","head","amulet","ring","relic"], [], _tiers("Cooldown Reduction", [[1,1000,0.02,0.04],[12,780,0.05,0.07],[30,420,0.08,0.11],[54,180,0.12,0.17]])),
		_affix("mana_recovery", "of Recovery", "suffix", "recovery", 820, ["Mana","Recovery","Resource"], ["offhand","head","chest","ring","amulet","relic"], [], _tiers("Mana Recovery", [[1,1000,0.04,0.08],[10,800,0.09,0.15],[24,550,0.16,0.24],[44,280,0.25,0.36]])),
		_affix("life_on_kill", "of Harvesting", "suffix", "life_recovery", 620, ["Life","Recovery"], ["weapon","chest","gloves","ring","relic"], [], _tiers("Life on Kill", [[1,1000,3,6],[12,800,7,12],[30,450,13,21],[54,200,22,34]])),
		_affix("ignite", "of Cinders", "suffix", "fire_ailment", 560, ["Fire","Burn","Status"], ["weapon","offhand","gloves","ring","amulet","relic"], [], _tiers2("Ignite Chance", "Burn Damage", [[10,900,0.06,0.10,0.05,0.09],[26,520,0.11,0.17,0.10,0.18],[46,260,0.18,0.26,0.19,0.30]])),
		_affix("freeze", "of Stillness", "suffix", "cold_ailment", 540, ["Cold","Freeze","Status","Control"], ["weapon","offhand","gloves","ring","amulet","relic"], [], _tiers2("Freeze Chance", "Control Duration", [[10,900,0.05,0.09,0.04,0.08],[26,520,0.10,0.16,0.09,0.14],[46,260,0.17,0.25,0.15,0.24]])),
		_affix("shock", "of Overload", "suffix", "lightning_ailment", 540, ["Lightning","Shock","Status"], ["weapon","offhand","gloves","ring","amulet","relic"], [], _tiers2("Shock Chance", "Overload Damage", [[10,900,0.05,0.09,0.05,0.10],[26,520,0.10,0.16,0.11,0.19],[46,260,0.17,0.25,0.20,0.32]])),
		_affix("curse_effect", "of Hexing", "suffix", "curse_effect", 500, ["Void","Curse","Utility"], ["offhand","ring","amulet","relic"], [], _tiers("Curse Effect", [[12,800,0.05,0.10],[30,420,0.11,0.18],[54,180,0.19,0.28]])),
		_affix("proc_chance", "of Echoes", "suffix", "proc", 360, ["Proc","Chain"], ["weapon","offhand","amulet","relic"], [], _tiers("Proc Chance", [[18,700,0.02,0.04],[38,360,0.05,0.08],[62,150,0.09,0.13]])),
		_affix("mana_cost", "of Efficiency", "suffix", "mana_efficiency", 520, ["Mana","Resource","Utility"], ["offhand","head","ring","amulet","relic"], [], _tiers("Mana Cost Reduction", [[8,900,0.03,0.06],[24,520,0.07,0.11],[46,260,0.12,0.18]])),
		_affix("spirit_discount", "of Reservation", "suffix", "spirit_efficiency", 280, ["Spirit","Resource","Utility"], ["amulet","relic","head"], [], _tiers("Spirit Reservation Efficiency", [[22,520,0.03,0.06],[48,240,0.07,0.11],[70,80,0.12,0.16]]))
	]

const UNIQUES: Array[Dictionary] = [
	{"id":"nightfall_reaver", "name":"Nightfall Reaver", "base_id":"iron_axe", "required_level":6, "stats":{"Void Damage":0.24,"Critical Damage":0.18,"Melee Damage":0.10}, "build_flags":["fireball_void_conversion","void_crit_wave"], "unique_effects":["Fireball also scales with Void Damage and counts as Void.","Critical strikes can trigger a shadow wave."], "description":"Turns simple fire casting into a Void build engine.", "tags":["Unique","Conversion","Proc","Void"]},
	{"id":"furnace_crown", "name":"Furnace Crown", "base_id":"iron_helm", "required_level":5, "stats":{"Fire Damage":0.18,"Melee Damage":0.10,"Maximum Life":24.0}, "build_flags":["cleave_fire_conversion","cleave_larger_area"], "unique_effects":["Cleave also counts as Fire.","Cleave gains increased area."], "description":"Makes melee builds lean into fire explosions.", "tags":["Unique","Conversion","Fire"]},
	{"id":"trapdoor_grips", "name":"Trapdoor Grips", "base_id":"trapwright_grips", "required_level":4, "stats":{"Trap Damage":0.22,"Void Damage":0.12,"Cooldown Reduction":0.04}, "build_flags":["blade_trap_void_conversion","trap_rift_echo"], "unique_effects":["Blade Trap also counts as Void.","Trap builds gain rift synergy."], "description":"A glove-slot archetype for trap-rift builds.", "tags":["Unique","Trap","Void","Proc"]},
	{"id":"riftwalker_boots", "name":"Riftwalker Boots", "base_id":"rift_boots", "required_level":7, "stats":{"Movement Speed":0.11,"Void Damage":0.14,"Maximum Mana":25.0}, "build_flags":["void_rift_larger","void_rift_cheaper"], "unique_effects":["Void Rift gains area.","Void Rift costs less mana."], "description":"Makes Void Rift easier to use as a primary room-control tool.", "tags":["Unique","Void","Mana"]},
	{"id":"stormglass_ring", "name":"Stormglass Ring", "base_id":"opal_ring", "required_level":5, "stats":{"Lightning Damage":0.18,"Cold Damage":0.12,"Maximum Mana":18.0}, "build_flags":["storm_lance_cold_conversion","storm_lance_extra_radius"], "unique_effects":["Storm Lance also counts as Cold.","Storm Lance gains a wider hit profile."], "description":"A bridge between lightning chaining and freeze setups.", "tags":["Unique","Conversion","Lightning","Cold"]},
	{"id":"choir_prism", "name":"Choir Prism", "base_id":"cascade_relic", "required_level":8, "stats":{"Global Damage":0.12,"Maximum Spirit":10.0,"Maximum Mana":18.0}, "build_flags":["support_gem_resonance","spirit_support_discount"], "unique_effects":["Supported active skills gain more damage.","Spirit support reservation pressure is reduced slightly."], "description":"A relic for skill-gem and spirit-reservation builds.", "tags":["Unique","Spirit","Proc"]},
	{"id":"blood_circuit", "name":"Blood Circuit", "base_id":"blood_ring", "required_level":16, "stats":{"Bleed Damage":0.24,"Life on Kill":12.0,"Physical Damage":0.12}, "build_flags":["cleave_bleed_spread","bleed_kill_refund"], "unique_effects":["Cleave kills spread Bleed to nearby enemies.","Bleeding kills refund a small amount of life."], "description":"A ring that turns bleed into a room-clearing engine.", "tags":["Unique","Bleed","Proc"]},
	{"id":"emberglass_focus", "name":"Emberglass Focus", "base_id":"ember_focus", "required_level":14, "stats":{"Fire Damage":0.20,"Burn Damage":0.18,"Mana Recovery":0.12}, "build_flags":["fireball_ignite_proliferation","burn_refunds_mana"], "unique_effects":["Fireball ignites can spread once.","Burning enemy deaths restore mana."], "description":"A focused low-midgame Fireball Ignite engine.", "tags":["Unique","Fire","Burn","Proc"]}
]

static func all_affixes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append_array(prefixes())
	out.append_array(suffixes())
	return out

static func affix_def_by_id(affix_id: String) -> Dictionary:
	for affix: Dictionary in all_affixes():
		if str(affix.get("id", "")) == affix_id:
			return affix.duplicate(true)
	return {}

static func roll_affix(rng: RandomNumberGenerator, affix_type: String, base: Dictionary, item_level: int, blocked_families: Array[String] = [], preferred_tags: Array = []) -> Dictionary:
	var pool: Array[Dictionary] = prefixes() if affix_type == "prefix" else suffixes()
	var candidates: Array[Dictionary] = []
	var slot: String = str(base.get("slot", ""))
	var base_type: String = str(base.get("base_type", ""))
	var base_tags: Array = Array(base.get("tags", []))
	for affix: Dictionary in pool:
		if blocked_families.has(str(affix.get("family", ""))):
			continue
		if not _affix_legal_for(affix, slot, base_type, base_tags, item_level):
			continue
		candidates.append(affix)
	if candidates.is_empty() and not blocked_families.is_empty():
		return roll_affix(rng, affix_type, base, item_level, [], preferred_tags)
	if candidates.is_empty():
		return {}
	var chosen: Dictionary = _weighted_pick_affix(rng, candidates, preferred_tags)
	return materialize_affix(chosen, affix_type, rng, item_level)

static func materialize_affix(template: Dictionary, affix_type: String = "", tier_or_rng: Variant = 1, rng_or_null: Variant = null, item_level: int = 1) -> Dictionary:
	var rng: RandomNumberGenerator = null
	var tier: int = 1
	if tier_or_rng is RandomNumberGenerator:
		rng = tier_or_rng
		item_level = int(rng_or_null) if typeof(rng_or_null) == TYPE_INT else item_level
		tier = _roll_tier(rng, Array(template.get("tiers", [])), item_level)
	else:
		tier = int(tier_or_rng)
		if rng_or_null is RandomNumberGenerator:
			rng = rng_or_null
	var tiers: Array = Array(template.get("tiers", []))
	var tier_def: Dictionary = _tier_def(tiers, tier)
	var stats: Dictionary = {}
	var stat_ranges: Dictionary = Dictionary(tier_def.get("stats", {}))
	for stat_key: Variant in stat_ranges.keys():
		var range_value: Variant = stat_ranges[stat_key]
		var amount: float = 0.0
		if typeof(range_value) == TYPE_ARRAY:
			var arr: Array = Array(range_value)
			var low: float = float(arr[0]) if arr.size() > 0 else 0.0
			var high: float = float(arr[1]) if arr.size() > 1 else low
			amount = rng.randf_range(low, high) if rng != null and abs(high - low) > 0.0001 else low
		else:
			amount = float(range_value)
		stats[str(stat_key)] = amount
	var stat_name: String = str(stats.keys()[0]) if stats.size() > 0 else "Global Damage"
	var value: float = float(stats[stat_name]) if stats.has(stat_name) else 0.0
	return {
		"id": str(template.get("id", "affix")),
		"name": str(template.get("name", "Affix")),
		"type": affix_type if affix_type != "" else str(template.get("type", "prefix")),
		"family": str(template.get("family", "misc")),
		"tier": int(tier_def.get("tier", tier)),
		"item_level": int(item_level),
		"stat": stat_name,
		"value": value,
		"stats": stats,
		"tags": Array(template.get("tags", [])).duplicate(true),
		"sealed": false
	}

static func next_tier_affix(affix: Dictionary, rng: RandomNumberGenerator, item_level: int) -> Dictionary:
	var def: Dictionary = affix_def_by_id(str(affix.get("id", "")))
	if def.is_empty():
		return affix.duplicate(true)
	var current_tier: int = int(affix.get("tier", 1))
	var next_tier: int = min(current_tier + 1, max_tier_for_affix(def, item_level))
	return materialize_affix(def, str(affix.get("type", def.get("type", "prefix"))), next_tier, rng, item_level)

static func max_tier_for_affix(def: Dictionary, item_level: int) -> int:
	var max_t: int = 1
	for tier_value: Variant in Array(def.get("tiers", [])):
		if typeof(tier_value) != TYPE_DICTIONARY:
			continue
		var tier_def: Dictionary = Dictionary(tier_value)
		if int(tier_def.get("min_ilvl", 1)) <= item_level:
			max_t = max(max_t, int(tier_def.get("tier", max_t)))
	return max_t

static func random_unique_for_level(rng: RandomNumberGenerator, item_level: int) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for unique_value: Dictionary in UNIQUES:
		if int(unique_value.get("required_level", 1)) <= item_level:
			candidates.append(unique_value)
	if candidates.is_empty():
		return {}
	return candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)

static func aggregate_stats(base_stats: Dictionary, prefixes_in: Array, suffixes_in: Array, extra_stats: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {}
	_add_stats(result, base_stats)
	for prefix_value: Variant in prefixes_in:
		if typeof(prefix_value) == TYPE_DICTIONARY:
			_add_stats(result, Dictionary(prefix_value).get("stats", {}))
	for suffix_value: Variant in suffixes_in:
		if typeof(suffix_value) == TYPE_DICTIONARY:
			_add_stats(result, Dictionary(suffix_value).get("stats", {}))
	_add_stats(result, extra_stats)
	return result

static func affix_names(prefixes_in: Array, suffixes_in: Array) -> Array[String]:
	var result: Array[String] = []
	for prefix_value: Variant in prefixes_in:
		if typeof(prefix_value) == TYPE_DICTIONARY:
			result.append(str(Dictionary(prefix_value).get("name", "Prefix")))
	for suffix_value: Variant in suffixes_in:
		if typeof(suffix_value) == TYPE_DICTIONARY:
			result.append(str(Dictionary(suffix_value).get("name", "Suffix")))
	return result

static func item_name_for(base_name: String, rarity: String, prefixes_in: Array, suffixes_in: Array) -> String:
	if rarity == "Normal":
		return base_name
	if prefixes_in.size() > 0 and typeof(prefixes_in[0]) == TYPE_DICTIONARY:
		var prefix_name: String = str(Dictionary(prefixes_in[0]).get("name", ""))
		if suffixes_in.size() > 0 and typeof(suffixes_in[0]) == TYPE_DICTIONARY:
			return prefix_name + " " + base_name + " " + str(Dictionary(suffixes_in[0]).get("name", ""))
		return prefix_name + " " + base_name
	if suffixes_in.size() > 0 and typeof(suffixes_in[0]) == TYPE_DICTIONARY:
		return base_name + " " + str(Dictionary(suffixes_in[0]).get("name", ""))
	return rarity + " " + base_name

static func _affix(id: String, name: String, type_name: String, family: String, weight: int, tags: Array, allowed_slots: Array, allowed_base_types: Array, tiers: Array) -> Dictionary:
	return {"id": id, "name": name, "type": type_name, "family": family, "weight": weight, "tags": tags, "allowed_slots": allowed_slots, "allowed_base_types": allowed_base_types, "tiers": tiers}

static func _tiers(stat_name: String, rows: Array) -> Array:
	var out: Array = []
	for i: int in range(rows.size()):
		var row: Array = Array(rows[i])
		out.append({"tier": i + 1, "min_ilvl": int(row[0]), "weight": int(row[1]), "stats": {stat_name: [float(row[2]), float(row[3])]}})
	return out

static func _tiers2(stat_a: String, stat_b: String, rows: Array) -> Array:
	var out: Array = []
	for i: int in range(rows.size()):
		var row: Array = Array(rows[i])
		out.append({"tier": i + 1, "min_ilvl": int(row[0]), "weight": int(row[1]), "stats": {stat_a: [float(row[2]), float(row[3])], stat_b: [float(row[4]), float(row[5])]}})
	return out

static func _affix_legal_for(affix: Dictionary, slot: String, base_type: String, base_tags: Array, item_level: int) -> bool:
	var allowed_slots: Array = Array(affix.get("allowed_slots", []))
	if not allowed_slots.has(slot) and not allowed_slots.has("any"):
		return false
	var allowed_base_types: Array = Array(affix.get("allowed_base_types", []))
	if not allowed_base_types.is_empty() and not allowed_base_types.has(base_type):
		return false
	var has_tier: bool = false
	for tier_value: Variant in Array(affix.get("tiers", [])):
		if typeof(tier_value) == TYPE_DICTIONARY and int(Dictionary(tier_value).get("min_ilvl", 1)) <= item_level:
			has_tier = true
			break
	return has_tier

static func _weighted_pick_affix(rng: RandomNumberGenerator, candidates: Array[Dictionary], preferred_tags: Array) -> Dictionary:
	var weights: Array[int] = []
	var total: int = 0
	for candidate: Dictionary in candidates:
		var w: int = int(candidate.get("weight", 1))
		for tag_value: Variant in preferred_tags:
			if Array(candidate.get("tags", [])).has(str(tag_value)):
				w = int(float(w) * 1.75) + 50
		weights.append(max(1, w))
		total += max(1, w)
	var roll: int = rng.randi_range(1, max(1, total))
	var running: int = 0
	for i: int in range(candidates.size()):
		running += weights[i]
		if roll <= running:
			return candidates[i].duplicate(true)
	return candidates[0].duplicate(true)

static func _roll_tier(rng: RandomNumberGenerator, tiers: Array, item_level: int) -> int:
	var candidates: Array[Dictionary] = []
	var total: int = 0
	for tier_value: Variant in tiers:
		if typeof(tier_value) != TYPE_DICTIONARY:
			continue
		var td: Dictionary = Dictionary(tier_value)
		if int(td.get("min_ilvl", 1)) <= item_level:
			candidates.append(td)
			total += int(td.get("weight", 1))
	if candidates.is_empty():
		return 1
	var roll: int = rng.randi_range(1, max(1, total))
	var running: int = 0
	for td2: Dictionary in candidates:
		running += int(td2.get("weight", 1))
		if roll <= running:
			return int(td2.get("tier", 1))
	return int(candidates[0].get("tier", 1))

static func _tier_def(tiers: Array, tier: int) -> Dictionary:
	var fallback: Dictionary = {}
	for tier_value: Variant in tiers:
		if typeof(tier_value) != TYPE_DICTIONARY:
			continue
		var td: Dictionary = Dictionary(tier_value)
		if fallback.is_empty():
			fallback = td
		if int(td.get("tier", 1)) == tier:
			return td
	return fallback

static func _add_stats(target: Dictionary, source: Dictionary) -> void:
	for key_value: Variant in source.keys():
		var key: String = str(key_value)
		target[key] = float(target.get(key, 0.0)) + float(source[key_value])
