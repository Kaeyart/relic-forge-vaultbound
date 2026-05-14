class_name RVContractDB
extends RefCounted

const CONTRACTS = [
	{
		"id": "ash_crypt",
		"name": "Ash Crypt",
		"tier": 1,
		"biome": "Ash Crypt",
		"threat": 1.0,
		"length": 5,
		"pos": Vector2(530.0, 165.0),
		"color": Color(1.0, 0.34, 0.14)
	},
	{
		"id": "bone_archive",
		"name": "Bone Archive",
		"tier": 2,
		"biome": "Bone Archive",
		"threat": 1.35,
		"length": 7,
		"pos": Vector2(640.0, 140.0),
		"color": Color(0.90, 0.82, 0.62)
	},
	{
		"id": "void_foundry",
		"name": "Void Foundry",
		"tier": 3,
		"biome": "Void Foundry",
		"threat": 1.75,
		"length": 9,
		"pos": Vector2(750.0, 165.0),
		"color": Color(0.70, 0.36, 1.0)
	},
	{
		"id": "hungry_forge",
		"name": "Hungry Forge",
		"tier": 4,
		"biome": "Hungry Forge",
		"threat": 2.25,
		"length": 11,
		"pos": Vector2(640.0, 220.0),
		"color": Color(1.0, 0.62, 0.20)
	}
]

static func all() -> Array:
	return CONTRACTS.duplicate(true)
