class_name RVItemDB
extends RefCounted

const SLOTS: Array[String] = ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring", "relic"]

static func make_starter_weapon() -> Dictionary:
	return {
		"name": "Starter Wand",
		"slot": "weapon",
		"rarity": "Common",
		"stats": {"Spell Damage": 0.06},
		"forge_potential": 8,
		"affixes": []
	}


static func generate_drop(state: RVGameState, depth: int) -> Dictionary:
	var slot_index: int = state.rng.randi_range(0, SLOTS.size() - 1)
	var slot_name: String = SLOTS[slot_index]
	var rarity_roll: float = state.rng.randf()
	var rarity: String = "Magic"

	if rarity_roll > 0.92:
		rarity = "Legendary"
	elif rarity_roll > 0.68:
		rarity = "Rare"

	var stat_name: String = "Fire Damage"
	var stat_roll: int = state.rng.randi_range(0, 6)

	match stat_roll:
		0:
			stat_name = "Fire Damage"
		1:
			stat_name = "Cold Damage"
		2:
			stat_name = "Lightning Damage"
		3:
			stat_name = "Void Damage"
		4:
			stat_name = "Melee Damage"
		5:
			stat_name = "Trap Damage"
		_:
			stat_name = "Maximum Life"

	var stats: Dictionary = {}
	if stat_name == "Maximum Life":
		stats[stat_name] = 8.0 + float(depth) * 2.0
	else:
		stats[stat_name] = 0.08 + float(depth) * 0.008

	return {
		"name": rarity + " " + slot_name.capitalize(),
		"slot": slot_name,
		"rarity": rarity,
		"stats": stats,
		"forge_potential": 10 + depth,
		"affixes": [stat_name],
		"description": "A simple generated item."
	}


static func craft_basic_item(state: RVGameState) -> Dictionary:
	return {
		"name": "Crafted Item",
		"slot": "relic",
		"rarity": "Crafted",
		"stats": {"Global Damage": 0.05 + float(state.level) * 0.002},
		"forge_potential": 14,
		"affixes": ["Global Damage"],
		"description": "A basic crafted item."
	}
