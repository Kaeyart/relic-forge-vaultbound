class_name RVEnemyDB
extends RefCounted

# Patch 058: richer enemy role database for map packs, elites, and bosses.
# This stays data-only. Combat behavior lives in EnemyActor.gd.

const TYPES: Dictionary = {
	"Grunt": {
		"role": "chaser",
		"hp": 58.0,
		"speed": 92.0,
		"damage": 9.0,
		"radius": 15.0,
		"aggro_range": 255.0,
		"attack_range": 32.0,
		"windup": 0.24,
		"recovery": 0.42,
		"xp": 9.0,
		"color": Color(0.75, 0.22, 0.14)
	},
	"Lunger": {
		"role": "lunger",
		"hp": 48.0,
		"speed": 118.0,
		"damage": 13.0,
		"radius": 14.0,
		"aggro_range": 305.0,
		"attack_range": 132.0,
		"windup": 0.42,
		"recovery": 0.72,
		"xp": 12.0,
		"color": Color(0.92, 0.38, 0.16)
	},
	"Archer": {
		"role": "shooter",
		"hp": 44.0,
		"speed": 62.0,
		"damage": 8.0,
		"radius": 14.0,
		"aggro_range": 430.0,
		"attack_range": 350.0,
		"windup": 0.36,
		"recovery": 0.84,
		"xp": 10.0,
		"color": Color(0.82, 0.78, 0.62)
	},
	"Spitter": {
		"role": "caster",
		"hp": 62.0,
		"speed": 58.0,
		"damage": 12.0,
		"radius": 15.0,
		"aggro_range": 455.0,
		"attack_range": 330.0,
		"windup": 0.62,
		"recovery": 1.05,
		"xp": 13.0,
		"color": Color(0.95, 0.47, 0.12)
	},
	"Binder": {
		"role": "binder",
		"hp": 70.0,
		"speed": 52.0,
		"damage": 7.0,
		"radius": 15.0,
		"aggro_range": 450.0,
		"attack_range": 300.0,
		"windup": 0.70,
		"recovery": 1.18,
		"xp": 15.0,
		"color": Color(0.58, 0.28, 0.92)
	},
	"Hound": {
		"role": "hound",
		"hp": 36.0,
		"speed": 144.0,
		"damage": 7.0,
		"radius": 12.0,
		"aggro_range": 310.0,
		"attack_range": 30.0,
		"windup": 0.16,
		"recovery": 0.46,
		"xp": 8.0,
		"color": Color(0.86, 0.60, 0.28)
	},
	"Knight": {
		"role": "knight",
		"hp": 105.0,
		"speed": 66.0,
		"damage": 17.0,
		"radius": 20.0,
		"aggro_range": 300.0,
		"attack_range": 54.0,
		"windup": 0.44,
		"recovery": 0.88,
		"xp": 18.0,
		"color": Color(0.74, 0.66, 0.50)
	},
	"Brute": {
		"role": "brute",
		"hp": 150.0,
		"speed": 48.0,
		"damage": 23.0,
		"radius": 24.0,
		"aggro_range": 330.0,
		"attack_range": 92.0,
		"windup": 0.72,
		"recovery": 1.18,
		"xp": 24.0,
		"color": Color(0.45, 0.47, 0.50)
	},
	"Caller": {
		"role": "caller",
		"hp": 88.0,
		"speed": 42.0,
		"damage": 5.0,
		"radius": 16.0,
		"aggro_range": 460.0,
		"attack_range": 390.0,
		"windup": 1.05,
		"recovery": 2.20,
		"xp": 20.0,
		"color": Color(0.88, 0.74, 0.30)
	},
	"Map Boss": {
		"role": "boss",
		"hp": 520.0,
		"speed": 54.0,
		"damage": 26.0,
		"radius": 34.0,
		"aggro_range": 520.0,
		"attack_range": 112.0,
		"windup": 0.62,
		"recovery": 0.92,
		"xp": 120.0,
		"color": Color(0.82, 0.28, 0.16)
	}
}

static func make(enemy_type: String, pos: Vector2, threat: float, index: int) -> Dictionary:
	var data: Dictionary = TYPES.get(enemy_type, TYPES["Grunt"])
	var hp: float = float(data.get("hp", 55.0)) * threat
	return {
		"id": enemy_type.to_lower().replace(" ", "_") + "_" + str(index) + "_" + str(Time.get_ticks_msec()),
		"type": enemy_type,
		"role": str(data.get("role", "chaser")),
		"pos": pos,
		"hp": hp,
		"max_hp": hp,
		"speed": float(data.get("speed", 80.0)),
		"damage": float(data.get("damage", 10.0)) * max(0.35, threat),
		"radius": float(data.get("radius", 16.0)),
		"cooldown": 0.0,
		"aggro_range": float(data.get("aggro_range", 300.0)),
		"attack_range": float(data.get("attack_range", 48.0)),
		"windup": float(data.get("windup", 0.35)),
		"recovery": float(data.get("recovery", 0.70)),
		"xp": float(data.get("xp", 10.0)) * max(0.45, threat),
		"color": data.get("color", Color(0.75, 0.22, 0.14)),
		"is_elite": false,
		"is_map_boss": false,
		"pack_id": "",
		"wake_radius": float(data.get("aggro_range", 300.0)),
		"leash_center": pos,
		"leash_radius": 260.0
	}

static func make_elite(enemy_type: String, pos: Vector2, threat: float, index: int, pack_id: String = "") -> Dictionary:
	var data: Dictionary = make(enemy_type, pos, threat * 1.32, index)
	data["id"] = "elite_" + str(data.get("id", "enemy"))
	data["type"] = "Elite " + enemy_type
	data["hp"] = float(data.get("hp", 1.0)) * 1.55
	data["max_hp"] = float(data.get("hp", 1.0))
	data["damage"] = float(data.get("damage", 1.0)) * 1.18
	data["radius"] = float(data.get("radius", 16.0)) + 4.0
	data["speed"] = float(data.get("speed", 80.0)) * 1.04
	data["is_elite"] = true
	data["pack_id"] = pack_id
	data["color"] = Color(1.0, 0.70, 0.25)
	return data

static func make_boss(map_item: Dictionary, pos: Vector2, threat: float) -> Dictionary:
	var data: Dictionary = make("Map Boss", pos, max(1.0, threat), 9999)
	var boss_name: String = str(map_item.get("boss_name", "Map Boss"))
	data["id"] = "map_boss_" + str(Time.get_ticks_msec())
	data["type"] = boss_name
	data["role"] = "boss"
	data["hp"] = float(data.get("hp", 520.0)) * (1.0 + float(map_item.get("tier", 1)) * 0.08)
	data["max_hp"] = float(data.get("hp", 520.0))
	data["damage"] = float(data.get("damage", 26.0)) * (1.0 + float(map_item.get("tier", 1)) * 0.045)
	data["radius"] = 36.0
	data["is_map_boss"] = true
	data["pack_id"] = "boss"
	data["wake_radius"] = 560.0
	data["leash_radius"] = 340.0
	data["color"] = _boss_color(map_item)
	return data

static func _boss_color(map_item: Dictionary) -> Color:
	var text: String = (str(map_item.get("id", "")) + " " + str(map_item.get("boss_name", ""))).to_lower()
	if text.contains("void") or text.contains("abyss"):
		return Color(0.58, 0.22, 0.92)
	if text.contains("storm"):
		return Color(0.38, 0.70, 1.0)
	if text.contains("chain") or text.contains("iron"):
		return Color(0.72, 0.66, 0.55)
	return Color(0.92, 0.34, 0.12)
