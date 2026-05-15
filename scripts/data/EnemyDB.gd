class_name RVEnemyDB
extends RefCounted

const TYPES = {
	"Ghoul": {
		"role": "chaser",
		"hp": 62.0,
		"radius": 16.0,
		"speed": 84.0,
		"damage": 11.0,
		"color": Color(0.72, 0.25, 0.15),
		"description": "Basic melee enemy."
	},
	"Skeleton Archer": {
		"role": "shooter",
		"hp": 48.0,
		"radius": 14.0,
		"speed": 58.0,
		"damage": 9.0,
		"color": Color(0.82, 0.77, 0.62),
		"description": "Ranged enemy. Keeps distance."
	},
	"Fire Spitter": {
		"role": "spitter",
		"hp": 66.0,
		"radius": 15.0,
		"speed": 52.0,
		"damage": 12.0,
		"color": Color(0.95, 0.48, 0.12),
		"description": "Creates delayed fire danger zones."
	},
	"Armored Brute": {
		"role": "brute",
		"hp": 155.0,
		"radius": 24.0,
		"speed": 46.0,
		"damage": 22.0,
		"color": Color(0.52, 0.54, 0.58),
		"description": "Slow heavy melee enemy."
	},
	"Void Caster": {
		"role": "caster",
		"hp": 82.0,
		"radius": 17.0,
		"speed": 50.0,
		"damage": 16.0,
		"color": Color(0.70, 0.36, 1.0),
		"description": "Casts void danger zones."
	},
	"Elite Knight": {
		"role": "elite",
		"hp": 230.0,
		"radius": 25.0,
		"speed": 64.0,
		"damage": 28.0,
		"color": Color(1.0, 0.70, 0.30),
		"description": "Elite melee enemy with stronger attacks."
	},
	"Dungeon Boss": {
		"role": "boss",
		"hp": 760.0,
		"radius": 34.0,
		"speed": 48.0,
		"damage": 34.0,
		"color": Color(1.0, 0.32, 0.16),
		"description": "Boss encounter enemy."
	}
}

static func make(enemy_type: String, pos: Vector2, threat: float, index: int) -> Dictionary:
	var d: Dictionary = TYPES.get(enemy_type, TYPES["Ghoul"])
	var hp: float = float(d["hp"]) * threat
	var enemy_id: String = enemy_type.to_lower().replace(" ", "_") + "_" + str(index) + "_" + str(randi())

	return {
		"id": enemy_id,
		"name": enemy_type,
		"type": enemy_type,
		"role": str(d["role"]),
		"pos": pos,
		"hp": hp,
		"max_hp": hp,
		"radius": float(d["radius"]),
		"speed": float(d["speed"]),
		"damage": float(d["damage"]) * threat,
		"ai_cd": 0.0,
		"status": {},
		"statuses": {},
		"color": d["color"],
		"elite": enemy_type == "Elite Knight" or enemy_type == "Dungeon Boss"
	}
