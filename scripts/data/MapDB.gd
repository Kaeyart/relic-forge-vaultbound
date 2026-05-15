class_name RVMapDB
extends RefCounted

const MAP_TEMPLATES: Array[Dictionary] = [
	{
		"id": "ash_cistern", "name": "Ash Cistern", "area_name": "Cistern of Ash", "boss_name": "Cinder Warden",
		"enemy_mix": ["Grunt", "Archer", "Spitter"], "pack_size": 1.05, "threat": 1.0,
		"mods": ["Smoldering halls", "Extra fire packs"], "description": "A furnace-drain map with dense ash packs and a cinder boss."
	},
	{
		"id": "iron_catacomb", "name": "Iron Catacomb", "area_name": "Catacomb of Chains", "boss_name": "Chain Brute",
		"enemy_mix": ["Grunt", "Brute", "Archer"], "pack_size": 1.15, "threat": 1.1,
		"mods": ["Armored enemies", "More melee pressure"], "description": "A narrow iron burial route built for bruiser and armor testing."
	},
	{
		"id": "void_chapel", "name": "Void Chapel", "area_name": "Chapel of the Hollow Star", "boss_name": "Abyss Deacon",
		"enemy_mix": ["Spitter", "Archer", "Grunt"], "pack_size": 1.0, "threat": 1.25,
		"mods": ["Void casters", "Higher gem chance"], "description": "A caster-heavy map for testing ranged pressure and Void builds."
	},
	{
		"id": "storm_foundry", "name": "Storm Foundry", "area_name": "Foundry of Charged Steel", "boss_name": "Stormforged Behemoth",
		"enemy_mix": ["Archer", "Brute", "Spitter", "Grunt"], "pack_size": 1.25, "threat": 1.35,
		"mods": ["Large packs", "Boss has heavy pressure"], "description": "A denser endgame route for testing clear speed and boss rewards."
	}
]

static func make_map(rng: RandomNumberGenerator, map_level: int = 1, forced_id: String = "") -> Dictionary:
	var template: Dictionary = MAP_TEMPLATES[0]
	if forced_id != "":
		for candidate: Dictionary in MAP_TEMPLATES:
			if str(candidate.get("id", "")) == forced_id:
				template = candidate
				break
	else:
		template = MAP_TEMPLATES[rng.randi_range(0, MAP_TEMPLATES.size() - 1)]

	var level: int = max(1, map_level)
	var tier: int = clampi(int(ceil(float(level) / 8.0)), 1, 16)
	var rarity_roll: float = rng.randf()
	var rarity: String = "Normal"
	if rarity_roll > 0.92:
		rarity = "Rare"
	elif rarity_roll > 0.64:
		rarity = "Magic"

	var threat: float = float(template.get("threat", 1.0)) + float(tier) * 0.045
	var pack_size: float = float(template.get("pack_size", 1.0))
	var mods: Array = Array(template.get("mods", [])).duplicate(true)
	if rarity == "Magic":
		mods.append("Magic map: increased pack size")
		pack_size += 0.12
	elif rarity == "Rare":
		mods.append("Rare map: increased pack size")
		mods.append("Rare map: increased boss loot")
		pack_size += 0.22
		threat += 0.18

	return {
		"uid": "map_" + str(Time.get_ticks_msec()) + "_" + str(rng.randi()),
		"id": str(template.get("id", "map")),
		"name": rarity + " " + str(template.get("name", "Map")),
		"rarity": rarity,
		"map_level": level,
		"tier": tier,
		"area_name": str(template.get("area_name", "Unknown Area")),
		"boss_name": str(template.get("boss_name", "Map Boss")),
		"enemy_mix": Array(template.get("enemy_mix", ["Grunt"])).duplicate(true),
		"pack_size": pack_size,
		"threat": threat,
		"rooms": 1,
		"mods": mods,
		"description": str(template.get("description", "A map."))
	}
