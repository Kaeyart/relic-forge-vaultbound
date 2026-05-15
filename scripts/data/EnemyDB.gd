class_name RVEnemyDB
extends RefCounted

const TYPES: Dictionary = {
	"Grunt": {
		"role": "chaser",
		"hp": 55.0,
		"speed": 86.0,
		"damage": 9.0,
		"radius": 15.0,
		"color": Color(0.75, 0.22, 0.14)
	},
	"Archer": {
		"role": "shooter",
		"hp": 42.0,
		"speed": 58.0,
		"damage": 8.0,
		"radius": 14.0,
		"color": Color(0.82, 0.78, 0.62)
	},
	"Spitter": {
		"role": "caster",
		"hp": 62.0,
		"speed": 54.0,
		"damage": 11.0,
		"radius": 15.0,
		"color": Color(0.95, 0.47, 0.12)
	},
	"Brute": {
		"role": "brute",
		"hp": 140.0,
		"speed": 46.0,
		"damage": 21.0,
		"radius": 24.0,
		"color": Color(0.45, 0.47, 0.50)
	}
}

static func make(enemy_type: String, pos: Vector2, threat: float, index: int) -> Dictionary:
	var data: Dictionary = TYPES.get(enemy_type, TYPES["Grunt"])
	var hp: float = float(data.get("hp", 55.0)) * threat

	return {
		"id": enemy_type.to_lower() + "_" + str(index) + "_" + str(Time.get_ticks_msec()),
		"type": enemy_type,
		"role": str(data.get("role", "chaser")),
		"pos": pos,
		"hp": hp,
		"max_hp": hp,
		"speed": float(data.get("speed", 80.0)),
		"damage": float(data.get("damage", 10.0)) * threat,
		"radius": float(data.get("radius", 16.0)),
		"cooldown": 0.0,
		"color": data.get("color", Color(0.75, 0.22, 0.14))
	}
