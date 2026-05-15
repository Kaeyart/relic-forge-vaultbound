class_name RVPassiveTreeDB
extends RefCounted

const BRANCHES = ["ash", "frost", "storm", "void", "steel", "trap", "blood", "relic"]

static func nodes() -> Dictionary:
	var result: Dictionary = {
		"root": {
			"id": "root",
			"name": "Vaultbound Core",
			"branch": "core",
			"ring": 0,
			"pos": Vector2(640.0, 360.0),
			"links": [],
			"stats": {"max_hp": 8.0, "max_mana": 8.0},
			"flags": []
		}
	}

	var center: Vector2 = Vector2(640.0, 360.0)
	var branch_angles: Dictionary = {
		"ash": -PI * 0.82,
		"frost": -PI * 0.57,
		"storm": -PI * 0.31,
		"void": -PI * 0.06,
		"steel": PI * 0.20,
		"trap": PI * 0.45,
		"blood": PI * 0.70,
		"relic": PI * 0.94
	}

	for branch in BRANCHES:
		var angle: float = float(branch_angles[branch])
		var prev: String = "root"
		for ring in range(1, 8):
			var id: String = branch + "_" + str(ring)
			var radial: float = 66.0 + float(ring) * 42.0
			var curve: float = sin(float(ring) * 0.8) * 22.0
			var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * radial + Vector2(-sin(angle), cos(angle)) * curve
			var stats: Dictionary = _stats_for(branch, ring)
			var flags: Array = []
			if ring == 3:
				flags.append(branch + "_minor_engine")
			if ring == 5:
				flags.append(branch + "_major_engine")
			if ring == 7:
				flags.append(branch + "_keystone")
			result[id] = {
				"id": id,
				"name": _node_name(branch, ring),
				"branch": branch,
				"ring": ring,
				"pos": pos,
				"links": [prev],
				"stats": stats,
				"flags": flags
			}
			if result.has(prev):
				result[prev]["links"].append(id)
			prev = id

	# Cross-link outer branches so the tree has pathing choices instead of straight spokes.
	_link(result, "ash_4", "frost_4")
	_link(result, "frost_4", "storm_4")
	_link(result, "storm_4", "void_4")
	_link(result, "void_4", "steel_4")
	_link(result, "steel_4", "trap_4")
	_link(result, "trap_4", "blood_4")
	_link(result, "blood_4", "relic_4")
	_link(result, "relic_4", "ash_4")
	_link(result, "ash_6", "storm_6")
	_link(result, "void_6", "trap_6")
	_link(result, "blood_6", "steel_6")
	return result

static func _link(result: Dictionary, a: String, b: String) -> void:
	if result.has(a) and result.has(b):
		if not result[a]["links"].has(b):
			result[a]["links"].append(b)
		if not result[b]["links"].has(a):
			result[b]["links"].append(a)

static func _stats_for(branch: String, ring: int) -> Dictionary:
	var amount: float = 0.025 + float(ring) * 0.008
	match branch:
		"ash":
			return {"fire_damage": amount, "burn_power": amount * 0.8}
		"frost":
			return {"cold_damage": amount, "freeze_duration": 0.03 * float(ring)}
		"storm":
			return {"lightning_damage": amount, "cooldown_reduction": 0.006 * float(ring)}
		"void":
			return {"void_damage": amount, "max_mana": float(ring) * 4.0, "spirit": float(ring)}
		"steel":
			return {"melee_damage": amount, "max_hp": float(ring) * 6.0}
		"trap":
			return {"trap_damage": amount, "area_damage": amount * 0.5}
		"blood":
			return {"spell_damage": amount, "max_hp": float(ring) * 4.0}
		"relic":
			return {"global_damage": amount * 0.7, "spirit": float(ring) * 1.5}
	return {}

static func _node_name(branch: String, ring: int) -> String:
	var titles: Dictionary = {
		"ash": ["Cinder Thread", "Combustion Vein", "Ash Engine", "Pyre Conduit", "Inferno Doctrine", "Red Furnace", "Worldburn Keystone"],
		"frost": ["Cold Thread", "Rime Vein", "Frost Engine", "Glacier Conduit", "Shatter Doctrine", "White Furnace", "Absolute Zero Keystone"],
		"storm": ["Spark Thread", "Static Vein", "Storm Engine", "Choir Conduit", "Chain Doctrine", "Blue Furnace", "Thunderhead Keystone"],
		"void": ["Abyss Thread", "Gravity Vein", "Void Engine", "Rift Conduit", "Curse Doctrine", "Black Furnace", "Event Horizon Keystone"],
		"steel": ["Iron Thread", "Blade Vein", "Steel Engine", "Execution Conduit", "Butcher Doctrine", "Grey Furnace", "Perfect Edge Keystone"],
		"trap": ["Spring Thread", "Gear Vein", "Trap Engine", "Mechanism Conduit", "Tripwire Doctrine", "Amber Furnace", "Clockwork Death Keystone"],
		"blood": ["Pulse Thread", "Wound Vein", "Blood Engine", "Debt Conduit", "Sacrifice Doctrine", "Crimson Furnace", "Life Debt Keystone"],
		"relic": ["Rune Thread", "Memory Vein", "Relic Engine", "Vault Conduit", "Echo Doctrine", "Gold Furnace", "Bound God Keystone"]
	}
	return titles.get(branch, [branch.capitalize()])[ring - 1]

static func branch_color(branch: String) -> Color:
	match branch:
		"ash": return Color(1.0, 0.34, 0.12)
		"frost": return Color(0.42, 0.82, 1.0)
		"storm": return Color(0.72, 0.92, 1.0)
		"void": return Color(0.70, 0.36, 1.0)
		"steel": return Color(0.88, 0.80, 0.62)
		"trap": return Color(0.95, 0.72, 0.30)
		"blood": return Color(1.0, 0.22, 0.18)
		"relic": return Color(0.90, 0.70, 0.36)
	return Color(0.90, 0.84, 0.70)
