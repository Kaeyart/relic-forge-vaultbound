class_name RVItemDB
extends RefCounted

const SLOTS = ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring", "relic"]

const RECIPES = [
	{
		"name": "Ashen Conductor",
		"slot": "weapon",
		"cost": {"embers": 18, "shards": 6},
		"stats": {"fire_damage": 0.20, "lightning_damage": 0.10, "spell_damage": 0.08},
		"flags": ["fire_calls_lance", "cascade_engine"],
		"pos": Vector2(940.0, 230.0),
		"color": Color(1.0, 0.34, 0.12)
	},
	{
		"name": "Frostfire Reactor",
		"slot": "relic",
		"cost": {"embers": 12, "shards": 12, "echo_glass": 1},
		"stats": {"fire_damage": 0.12, "cold_damage": 0.18, "freeze_duration": 0.25},
		"flags": ["frostfire_steam", "nova_calls_fire"],
		"pos": Vector2(1035.0, 285.0),
		"color": Color(0.42, 0.82, 1.0)
	},
	{
		"name": "Void Trap Engine",
		"slot": "offhand",
		"cost": {"shards": 14, "runes": 2},
		"stats": {"void_damage": 0.20, "trap_damage": 0.18, "max_mana": 18.0},
		"flags": ["trap_calls_rift", "rift_calls_trap", "rift_pull"],
		"pos": Vector2(945.0, 345.0),
		"color": Color(0.70, 0.36, 1.0)
	},
	{
		"name": "Butcher Moon Cleaver",
		"slot": "weapon",
		"cost": {"embers": 16, "runes": 1},
		"stats": {"melee_damage": 0.30, "max_hp": 22.0},
		"flags": ["slash_bleed", "cleave_wave", "execute_low_hp"],
		"pos": Vector2(1040.0, 400.0),
		"color": Color(1.0, 0.78, 0.42)
	}
]

static func recipes() -> Array:
	return RECIPES.duplicate(true)


static func can_pay(state: RVGameState, cost: Dictionary) -> bool:
	for k in cost.keys():
		if int(state.materials.get(k, 0)) < int(cost[k]):
			return false
	return true


static func pay(state: RVGameState, cost: Dictionary) -> void:
	for k in cost.keys():
		state.materials[k] = int(state.materials.get(k, 0)) - int(cost[k])


static func craft(state: RVGameState, recipe: Dictionary) -> Dictionary:
	var stats: Dictionary = {}
	var power: float = 1.0 + float(state.level) * 0.025
	var source_stats: Dictionary = recipe.get("stats", {})

	for k in source_stats.keys():
		stats[k] = float(source_stats[k]) * power

	return {
		"name": str(recipe["name"]) + " +" + str(max(1, int(state.level / 3))),
		"slot": str(recipe["slot"]),
		"rarity": "Crafted",
		"stats": stats,
		"flags": recipe.get("flags", []).duplicate(true),
		"desc": "Crafted at level " + str(state.level) + "."
	}


static func generate_drop(state: RVGameState, depth: int) -> Dictionary:
	var slot_index: int = state.rng.randi_range(0, SLOTS.size() - 1)
	var slot: String = SLOTS[slot_index]
	var roll: float = state.rng.randf()

	var rarity: String = "Magic"
	if roll > 0.94:
		rarity = "Legendary"
	elif roll > 0.72:
		rarity = "Rare"

	var family_index: int = state.rng.randi_range(0, 7)
	var family: String = "Ash"
	var stats: Dictionary = {}
	var flags: Array = []

	match family_index:
		0:
			family = "Ash"
			stats = {"fire_damage": 0.08 + float(depth) * 0.006}
			if rarity == "Legendary": flags.append("fire_calls_lance")
		1:
			family = "Frost"
			stats = {"cold_damage": 0.08 + float(depth) * 0.006}
			if rarity == "Legendary": flags.append("frostfire_steam")
		2:
			family = "Storm"
			stats = {"lightning_damage": 0.08 + float(depth) * 0.006, "cooldown_reduction": 0.01}
			if rarity != "Magic": flags.append("chain_plus")
		3:
			family = "Void"
			stats = {"void_damage": 0.08 + float(depth) * 0.006, "max_mana": 5.0 + float(depth)}
			if rarity != "Magic": flags.append("rift_pull")
		4:
			family = "Butcher"
			stats = {"melee_damage": 0.09 + float(depth) * 0.006, "max_hp": 5.0 + float(depth)}
			if rarity != "Magic": flags.append("slash_bleed")
		5:
			family = "Trapwright"
			stats = {"trap_damage": 0.10 + float(depth) * 0.006}
			if rarity != "Magic": flags.append("double_trap")
		6:
			family = "Blood"
			stats = {"spell_damage": 0.06 + float(depth) * 0.005, "max_hp": 8.0 + float(depth)}
			if rarity == "Legendary": flags.append("blood_cast")
		_:
			family = "Relic-Bound"
			stats = {"global_damage": 0.04 + float(depth) * 0.004}
			if rarity == "Legendary": flags.append("contract_eater")

	if rarity == "Rare":
		stats["max_mana"] = float(stats.get("max_mana", 0.0)) + 8.0 + float(depth)

	if rarity == "Legendary":
		stats["global_damage"] = float(stats.get("global_damage", 0.0)) + 0.08
		flags.append("cascade_engine")

	return {
		"name": rarity + " " + family + " " + slot.capitalize(),
		"slot": slot,
		"rarity": rarity,
		"stats": stats,
		"flags": flags,
		"desc": "Dropped at depth " + str(depth) + "."
	}
