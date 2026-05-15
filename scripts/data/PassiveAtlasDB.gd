class_name RVPassiveAtlasDB
extends RefCounted

const BRANCHES = ["fire", "cold", "lightning", "void", "attack", "trap", "life", "mana"]

const BRANCH_DATA = {
	"fire": {"name": "Fire", "stat": "fire_damage", "color": Color(1.0, 0.34, 0.12)},
	"cold": {"name": "Cold", "stat": "cold_damage", "color": Color(0.42, 0.82, 1.0)},
	"lightning": {"name": "Lightning", "stat": "lightning_damage", "color": Color(0.72, 0.92, 1.0)},
	"void": {"name": "Void", "stat": "void_damage", "color": Color(0.70, 0.36, 1.0)},
	"attack": {"name": "Attack", "stat": "melee_damage", "color": Color(1.0, 0.80, 0.48)},
	"trap": {"name": "Trap", "stat": "trap_damage", "color": Color(0.95, 0.72, 0.30)},
	"life": {"name": "Life", "stat": "max_hp", "color": Color(1.0, 0.22, 0.18)},
	"mana": {"name": "Mana", "stat": "max_mana", "color": Color(0.35, 0.62, 1.0)}
}

static func nodes() -> Dictionary:
	var out: Dictionary = {}
	out["center"] = {
		"id": "center",
		"name": "Starting Point",
		"branch": "core",
		"kind": "start",
		"pos": Vector2.ZERO,
		"cost": 0,
		"stats": {"max_hp": 10.0, "max_mana": 10.0},
		"flags": [],
		"links": []
	}

	for b_index in range(BRANCHES.size()):
		var branch: String = BRANCHES[b_index]
		var angle: float = -PI * 0.5 + TAU * float(b_index) / float(BRANCHES.size())
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		var side: Vector2 = Vector2(-dir.y, dir.x)
		var data: Dictionary = BRANCH_DATA[branch]
		var stat_key: String = str(data["stat"])
		var prev: String = "center"

		for depth in range(1, 8):
			var id: String = branch + "_" + str(depth)
			var kind: String = "small"
			var name: String = stat_label(stat_key)
			var cost: int = 1
			var stats: Dictionary = stat_value(stat_key, depth, 1.0)
			var flags: Array = []

			if depth == 3:
				kind = "notable"
				name = str(data["name"]) + " Mastery"
				stats = stat_value(stat_key, depth, 2.0)
				flags.append(branch + "_mastery")
			elif depth == 5:
				kind = "notable"
				name = str(data["name"]) + " Specialist"
				stats = stat_value(stat_key, depth, 2.4)
				flags.append(branch + "_specialist")
			elif depth == 7:
				kind = "keystone"
				name = keystone_name(branch)
				cost = 2
				stats = stat_value(stat_key, depth, 3.0)
				flags.append(branch + "_keystone")

			out[id] = {"id": id, "name": name, "branch": branch, "kind": kind, "pos": dir * (82.0 * float(depth)), "cost": cost, "stats": stats, "flags": flags, "links": [prev]}
			out[prev]["links"].append(id)
			prev = id

			if depth == 2 or depth == 4 or depth == 6:
				for side_index in [-1, 1]:
					var side_id: String = branch + "_side_" + str(depth) + "_" + str(side_index)
					var side_stats: Dictionary = stat_value(stat_key, depth, 1.25)
					out[side_id] = {"id": side_id, "name": side_node_name(branch, side_index), "branch": branch, "kind": "small", "pos": out[id]["pos"] + side * float(side_index) * 58.0, "cost": 1, "stats": side_stats, "flags": [], "links": [id]}
					out[id]["links"].append(side_id)

	for bridge_index in range(BRANCHES.size()):
		var a: String = BRANCHES[bridge_index] + "_4"
		var b: String = BRANCHES[(bridge_index + 1) % BRANCHES.size()] + "_4"
		if out.has(a) and out.has(b):
			out[a]["links"].append(b)
			out[b]["links"].append(a)

	return out

static func stat_value(stat_key: String, depth: int, mult: float) -> Dictionary:
	if stat_key == "max_hp" or stat_key == "max_mana":
		return {stat_key: (8.0 + float(depth) * 2.0) * mult}
	return {stat_key: (0.025 + float(depth) * 0.004) * mult}

static func stat_label(stat_key: String) -> String:
	match stat_key:
		"fire_damage": return "Fire Damage"
		"cold_damage": return "Cold Damage"
		"lightning_damage": return "Lightning Damage"
		"void_damage": return "Void Damage"
		"melee_damage": return "Attack Damage"
		"trap_damage": return "Trap Damage"
		"max_hp": return "Maximum Life"
		"max_mana": return "Maximum Mana"
	return "Damage"

static func side_node_name(branch: String, side_index: int) -> String:
	if side_index < 0:
		return "Cooldown Recovery" if branch != "life" else "Life Regeneration"
	return "Critical Chance" if branch != "mana" else "Mana Regeneration"

static func keystone_name(branch: String) -> String:
	match branch:
		"fire": return "Fire Skills Ignite"
		"cold": return "Cold Skills Freeze"
		"lightning": return "Lightning Skills Chain"
		"void": return "Void Skills Pull"
		"attack": return "Attacks Bleed"
		"trap": return "Traps Repeat"
		"life": return "More Life, Less Mana"
		"mana": return "More Mana, Less Life"
	return "Keystone"
