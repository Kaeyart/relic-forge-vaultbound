class_name RVItemDB
extends RefCounted

const SLOTS = ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring", "relic"]

const RECIPES = [
	{"name": "Fire Weapon", "slot": "weapon", "cost": {"embers": 18, "shards": 6}, "stats": {"fire_damage": 0.20, "spell_damage": 0.08}, "flags": ["fire_weapon"], "pos": Vector2(940.0, 230.0), "color": Color(1.0, 0.34, 0.12)},
	{"name": "Cold Relic", "slot": "relic", "cost": {"embers": 12, "shards": 12, "echo_glass": 1}, "stats": {"cold_damage": 0.18, "max_mana": 12.0}, "flags": ["cold_relic"], "pos": Vector2(1035.0, 285.0), "color": Color(0.42, 0.82, 1.0)},
	{"name": "Void Offhand", "slot": "offhand", "cost": {"shards": 14, "runes": 2}, "stats": {"void_damage": 0.20, "max_mana": 18.0}, "flags": ["void_offhand"], "pos": Vector2(945.0, 345.0), "color": Color(0.70, 0.36, 1.0)},
	{"name": "Attack Weapon", "slot": "weapon", "cost": {"embers": 16, "runes": 1}, "stats": {"melee_damage": 0.30, "max_hp": 22.0}, "flags": ["attack_weapon"], "pos": Vector2(1040.0, 400.0), "color": Color(1.0, 0.78, 0.42)}
]

const AFFIXES = {
	"fire_damage": {"name": "Fire Damage", "family": "fire", "slot": "prefix"},
	"cold_damage": {"name": "Cold Damage", "family": "cold", "slot": "prefix"},
	"lightning_damage": {"name": "Lightning Damage", "family": "lightning", "slot": "prefix"},
	"void_damage": {"name": "Void Damage", "family": "void", "slot": "prefix"},
	"melee_damage": {"name": "Attack Damage", "family": "attack", "slot": "prefix"},
	"trap_damage": {"name": "Trap Damage", "family": "trap", "slot": "prefix"},
	"max_hp": {"name": "Maximum Life", "family": "life", "slot": "suffix"},
	"max_mana": {"name": "Maximum Mana", "family": "mana", "slot": "suffix"},
	"cooldown_reduction": {"name": "Cooldown Recovery", "family": "speed", "slot": "suffix"},
	"global_damage": {"name": "Global Damage", "family": "global", "slot": "prefix"}
}

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
	for k in recipe.get("stats", {}).keys():
		stats[k] = float(recipe["stats"][k]) * power
	return {"name": str(recipe["name"]) + " +" + str(max(1, state.level / 3)), "slot": str(recipe["slot"]), "rarity": "Crafted", "stats": stats, "flags": recipe.get("flags", []).duplicate(true), "desc": "Crafted item.", "forge_potential": 18, "affixes": []}

static func generate_drop(state: RVGameState, depth: int, reward_type: String = "balanced") -> Dictionary:
	var slot: String = SLOTS[state.rng.randi_range(0, SLOTS.size() - 1)]
	var roll: float = state.rng.randf()
	var rarity: String = "Magic"
	if roll > 0.94 or reward_type == "boss":
		rarity = "Legendary"
	elif roll > 0.72 or reward_type == "items":
		rarity = "Rare"

	var affix_keys: Array = AFFIXES.keys()
	var key: String = affix_keys[state.rng.randi_range(0, affix_keys.size() - 1)]
	var stats: Dictionary = {}
	stats[key] = stat_roll(key, depth, rarity)

	if rarity != "Magic":
		var key2: String = affix_keys[state.rng.randi_range(0, affix_keys.size() - 1)]
		stats[key2] = stat_roll(key2, depth, rarity)

	return {"name": rarity + " " + slot.capitalize(), "slot": slot, "rarity": rarity, "stats": stats, "flags": [], "desc": "Dropped item.", "forge_potential": 12 + depth, "affixes": stats_to_affixes(stats)}

static func stat_roll(key: String, depth: int, rarity: String) -> float:
	var mult: float = 1.0
	if rarity == "Rare": mult = 1.35
	elif rarity == "Legendary": mult = 1.75
	if key == "max_hp" or key == "max_mana":
		return (10.0 + float(depth) * 2.0) * mult
	return (0.06 + float(depth) * 0.006) * mult

static func stats_to_affixes(stats: Dictionary) -> Array:
	var out: Array = []
	for k in stats.keys():
		out.append({"id": k, "name": AFFIXES.get(k, {}).get("name", str(k)), "tier": 1, "value": stats[k], "sealed": false})
	return out
