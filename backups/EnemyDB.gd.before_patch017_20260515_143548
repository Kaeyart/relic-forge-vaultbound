class_name RVEnemyDB
extends RefCounted

const TYPES = {
	"Ash Grunt": {
		"role": "chaser",
		"hp": 62.0,
		"radius": 16.0,
		"speed": 82.0,
		"damage": 11.0,
		"color": Color(0.72, 0.25, 0.15)
	},
	"Bone Archer": {
		"role": "shooter",
		"hp": 48.0,
		"radius": 14.0,
		"speed": 58.0,
		"damage": 9.0,
		"color": Color(0.82, 0.77, 0.62)
	},
	"Cinder Spitter": {
		"role": "spitter",
		"hp": 66.0,
		"radius": 15.0,
		"speed": 52.0,
		"damage": 11.0,
		"color": Color(0.95, 0.48, 0.12)
	},
	"Iron Brute": {
		"role": "brute",
		"hp": 150.0,
		"radius": 24.0,
		"speed": 46.0,
		"damage": 22.0,
		"color": Color(0.42, 0.45, 0.49)
	}
}

static func make(enemy_type: String, pos: Vector2, threat: float, index: int) -> Dictionary:
	var d: Dictionary = TYPES.get(enemy_type, TYPES["Ash Grunt"])
	var hp: float = float(d["hp"]) * threat

	return {
		"id": enemy_type.to_lower().replace(" ", "_") + "_" + str(index),
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
		"color": d["color"]
	}
