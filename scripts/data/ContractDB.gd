class_name RVContractDB
extends RefCounted

const CONTRACTS = [
	{
		"id": "dungeon_run",
		"name": "Dungeon Run",
		"mode": "Dungeon Run",
		"goal": "Clear 6 rooms and return with loot.",
		"tier": 1,
		"biome": "Crypt",
		"threat": 1.0,
		"length": 6,
		"pos": Vector2(500.0, 160.0),
		"color": Color(1.0, 0.34, 0.14),
		"reward": "balanced"
	},
	{
		"id": "material_hunt",
		"name": "Material Hunt",
		"mode": "Material Hunt",
		"goal": "Clear 4 rooms with bonus crafting materials.",
		"tier": 1,
		"biome": "Mine",
		"threat": 0.95,
		"length": 4,
		"pos": Vector2(615.0, 135.0),
		"color": Color(0.95, 0.78, 0.34),
		"reward": "materials"
	},
	{
		"id": "elite_hunt",
		"name": "Elite Hunt",
		"mode": "Elite Hunt",
		"goal": "Defeat elite packs for better item drops.",
		"tier": 2,
		"biome": "Ruins",
		"threat": 1.45,
		"length": 5,
		"pos": Vector2(730.0, 160.0),
		"color": Color(1.0, 0.70, 0.30),
		"reward": "items"
	},
	{
		"id": "boss_trial",
		"name": "Boss Trial",
		"mode": "Boss Trial",
		"goal": "Clear 2 rooms, then defeat a boss.",
		"tier": 2,
		"biome": "Boss Arena",
		"threat": 1.65,
		"length": 3,
		"pos": Vector2(845.0, 205.0),
		"color": Color(1.0, 0.22, 0.14),
		"reward": "boss"
	},
	{
		"id": "endless_rift",
		"name": "Endless Rift",
		"mode": "Endless Rift",
		"goal": "Push scaling rooms until you return or die.",
		"tier": 3,
		"biome": "Rift",
		"threat": 1.25,
		"length": 999,
		"pos": Vector2(615.0, 220.0),
		"color": Color(0.70, 0.36, 1.0),
		"reward": "scaling"
	}
]

static func all() -> Array:
	return CONTRACTS.duplicate(true)

static func by_id(id: String) -> Dictionary:
	for contract in CONTRACTS:
		if str(contract.get("id", "")) == id:
			return contract.duplicate(true)
	return CONTRACTS[0].duplicate(true)
