class_name RVEnemyVisualProfileDB
extends RefCounted

# Patch 060: stronger Tier-1 visual proxy profiles.
# Still not final art. Goal: each enemy role has readable silhouette language.

static func profile(enemy_type: String, role: String, radius: float, base_color: Color) -> Dictionary:
	var key: String = enemy_type.to_lower().replace(" ", "_")
	var r: String = role.to_lower()
	if key.find("boss") >= 0 or r == "boss":
		return _boss(max(radius, 34.0), base_color)
	if key.find("brute") >= 0 or r == "brute":
		return _brute(radius, base_color)
	if key.find("lunge") >= 0 or r == "lunger":
		return _lunger(radius, base_color)
	if key.find("spit") >= 0 or r == "spitter" or r == "shooter":
		return _spitter(radius, base_color)
	if key.find("binder") >= 0 or key.find("acolyte") >= 0 or r == "caster" or r == "binder":
		return _binder(radius, base_color)
	if key.find("hound") >= 0 or r == "hound":
		return _hound(radius, base_color)
	if key.find("knight") >= 0 or r == "knight":
		return _knight(radius, base_color)
	if key.find("caller") >= 0 or key.find("bell") >= 0 or r == "summoner" or r == "caller":
		return _caller(radius, base_color)
	return _grunt(radius, base_color)

static func _base(radius: float, color: Color) -> Dictionary:
	return {
		"radius": radius,
		"primary": color,
		"outline": Color(0.015, 0.013, 0.016, 1.0),
		"shadow": Color(0.0, 0.0, 0.0, 0.38),
		"accent": Color(1.0, 0.42, 0.10, 0.88),
		"threat_color": Color(1.0, 0.50, 0.15, 0.65),
		"parts": [],
		"lines": [],
		"markers": [],
		"telegraph": "ring"
	}

static func _grunt(radius: float, color: Color) -> Dictionary:
	var p: Dictionary = _base(radius, Color(0.58, 0.25, 0.13))
	p["name"] = "Ash Grunt"
	p["identity"] = "jagged melee pressure"
	p["telegraph"] = "short_line"
	p["parts"] = [
		_poly("back_spine", Vector2(-radius * 0.12, -radius * 0.04), [Vector2(-0.34, 0.66), Vector2(-0.16, -0.80), Vector2(0.10, -0.74), Vector2(0.22, 0.52)], Color(0.11, 0.08, 0.07), 0.86, -1),
		_poly("body", Vector2(0, radius * 0.04), [Vector2(-0.72, 0.58), Vector2(-0.48, -0.42), Vector2(0.08, -0.82), Vector2(0.56, -0.30), Vector2(0.62, 0.56), Vector2(0.04, 0.86)], Color(0.39, 0.20, 0.14), 1.0, 0),
		_poly("head", Vector2(radius * 0.02, -radius * 0.64), [Vector2(-0.42, 0.24), Vector2(-0.18, -0.40), Vector2(0.24, -0.36), Vector2(0.46, 0.10), Vector2(0.08, 0.42)], Color(0.62, 0.35, 0.22), 0.54, 2),
		_poly("cleaver", Vector2(radius * 0.68, radius * 0.02), [Vector2(-0.10, -0.50), Vector2(0.48, -0.34), Vector2(0.76, 0.10), Vector2(0.28, 0.44), Vector2(-0.24, 0.28)], Color(0.60, 0.50, 0.36), 0.72, 3),
		_poly("left_claw", Vector2(-radius * 0.48, radius * 0.30), [Vector2(-0.40, -0.16), Vector2(0.22, -0.18), Vector2(0.30, 0.14), Vector2(-0.28, 0.30)], Color(0.26, 0.13, 0.10), 0.50, 1)
	]
	p["lines"] = [
		_line("ember_crack", [Vector2(-radius * 0.12, -radius * 0.22), Vector2(radius * 0.05, radius * 0.02), Vector2(-radius * 0.06, radius * 0.34)], Color(1.0, 0.36, 0.08, 0.78), 2.0),
		_line("ash_binding", [Vector2(-radius * 0.44, radius * 0.16), Vector2(radius * 0.34, radius * 0.22)], Color(0.78, 0.62, 0.36, 0.38), 1.5)
	]
	p["markers"] = [_circle("weak_core", Vector2(radius * 0.08, radius * 0.10), radius * 0.12, Color(1.0, 0.24, 0.04, 0.46))]
	return p

static func _lunger(radius: float, color: Color) -> Dictionary:
	var p: Dictionary = _base(radius, Color(0.72, 0.18, 0.09))
	p["name"] = "Cinder Lunger"
	p["identity"] = "thin forward charge silhouette"
	p["telegraph"] = "charge_line"
	p["accent"] = Color(1.0, 0.52, 0.12, 0.90)
	p["parts"] = [
		_poly("rear_cloak", Vector2(-radius * 0.50, radius * 0.06), [Vector2(-0.60, 0.42), Vector2(-0.26, -0.46), Vector2(0.44, -0.12), Vector2(0.18, 0.56)], Color(0.13, 0.06, 0.04), 0.78, -1),
		_poly("body", Vector2(0, 0), [Vector2(-0.84, 0.42), Vector2(-0.50, -0.34), Vector2(0.34, -0.50), Vector2(0.92, 0.00), Vector2(0.30, 0.54)], Color(0.45, 0.12, 0.07), 0.98, 0),
		_poly("spear_head", Vector2(radius * 0.78, -radius * 0.08), [Vector2(-0.18, -0.34), Vector2(0.82, 0.00), Vector2(-0.18, 0.34)], Color(0.88, 0.58, 0.24), 0.66, 3),
		_poly("shoulder_spike", Vector2(radius * 0.10, -radius * 0.48), [Vector2(-0.32, 0.28), Vector2(0.06, -0.58), Vector2(0.34, 0.22)], Color(0.78, 0.34, 0.12), 0.44, 2)
	]
	p["lines"] = [
		_line("charge_spine", [Vector2(-radius * 0.62, 0), Vector2(radius * 0.84, -radius * 0.05)], Color(1.0, 0.62, 0.16, 0.78), 2.2),
		_line("heat_tail", [Vector2(-radius * 0.82, radius * 0.24), Vector2(-radius * 1.10, radius * 0.36)], Color(1.0, 0.26, 0.05, 0.42), 3.0)
	]
	return p

static func _spitter(radius: float, color: Color) -> Dictionary:
	var p: Dictionary = _base(radius, Color(0.68, 0.20, 0.08))
	p["name"] = "Ember Spitter"
	p["identity"] = "hunched ranged throat silhouette"
	p["telegraph"] = "lob_arc"
	p["parts"] = [
		_poly("hunched_body", Vector2(0, radius * 0.08), [Vector2(-0.82, 0.52), Vector2(-0.62, -0.26), Vector2(-0.10, -0.66), Vector2(0.58, -0.38), Vector2(0.80, 0.30), Vector2(0.16, 0.78)], Color(0.30, 0.10, 0.06), 1.05, 0),
		_poly("throat_sack", Vector2(radius * 0.34, -radius * 0.28), [Vector2(-0.42, 0.32), Vector2(-0.20, -0.48), Vector2(0.46, -0.38), Vector2(0.58, 0.30), Vector2(0.04, 0.52)], Color(0.95, 0.34, 0.07), 0.58, 2),
		_poly("mouth", Vector2(radius * 0.74, -radius * 0.42), [Vector2(-0.30, -0.18), Vector2(0.38, -0.06), Vector2(-0.20, 0.26)], Color(1.0, 0.80, 0.28), 0.47, 3),
		_poly("back_pustule", Vector2(-radius * 0.42, -radius * 0.26), [Vector2(-0.26, 0.24), Vector2(-0.06, -0.34), Vector2(0.30, -0.20), Vector2(0.34, 0.24)], Color(0.90, 0.18, 0.05), 0.44, 1)
	]
	p["markers"] = [
		_circle("spit_glow", Vector2(radius * 0.52, -radius * 0.25), radius * 0.18, Color(1.0, 0.34, 0.06, 0.65)),
		_circle("throat_hotspot", Vector2(radius * 0.20, -radius * 0.20), radius * 0.10, Color(1.0, 0.90, 0.25, 0.52))
	]
	return p

static func _binder(radius: float, color: Color) -> Dictionary:
	var p: Dictionary = _base(radius, Color(0.48, 0.18, 0.82))
	p["name"] = "Chain Binder"
	p["identity"] = "tall caster/support with chain halo"
	p["telegraph"] = "sigil"
	p["accent"] = Color(0.74, 0.30, 1.0, 0.86)
	p["threat_color"] = Color(0.74, 0.30, 1.0, 0.62)
	p["parts"] = [
		_poly("robe", Vector2(0, radius * 0.10), [Vector2(-0.50, 0.76), Vector2(-0.36, -0.54), Vector2(0.0, -0.92), Vector2(0.36, -0.50), Vector2(0.50, 0.78), Vector2(0.0, 0.98)], Color(0.13, 0.06, 0.19), 1.00, 0),
		_poly("mask", Vector2(0, -radius * 0.63), [Vector2(-0.25, 0.30), Vector2(-0.16, -0.32), Vector2(0.18, -0.32), Vector2(0.28, 0.24), Vector2(0.0, 0.44)], Color(0.68, 0.58, 0.78), 0.54, 2),
		_poly("staff", Vector2(radius * 0.50, -radius * 0.02), [Vector2(-0.06, -0.80), Vector2(0.12, -0.80), Vector2(0.06, 0.78), Vector2(-0.12, 0.78)], Color(0.34, 0.22, 0.42), 0.56, 3),
		_poly("chain_weight", Vector2(-radius * 0.44, radius * 0.40), [Vector2(-0.28, -0.20), Vector2(0.28, -0.20), Vector2(0.28, 0.22), Vector2(-0.28, 0.22)], Color(0.48, 0.40, 0.54), 0.34, 3)
	]
	p["lines"] = [
		_line("chain_halo", [Vector2(-radius * 0.72, -radius * 0.60), Vector2(-radius * 0.28, -radius * 0.86), Vector2(radius * 0.26, -radius * 0.86), Vector2(radius * 0.72, -radius * 0.60)], Color(0.72, 0.42, 1.0, 0.76), 2.0),
		_line("chain_hang", [Vector2(-radius * 0.44, -radius * 0.42), Vector2(-radius * 0.54, radius * 0.18), Vector2(-radius * 0.44, radius * 0.42)], Color(0.70, 0.56, 0.80, 0.55), 1.7)
	]
	return p

static func _hound(radius: float, color: Color) -> Dictionary:
	var p: Dictionary = _base(radius, Color(0.54, 0.10, 0.08))
	p["name"] = "Ash Hound"
	p["identity"] = "low fast rushing silhouette"
	p["telegraph"] = "dash_line"
	p["parts"] = [
		_poly("body", Vector2(0, radius * 0.14), [Vector2(-0.88, 0.20), Vector2(-0.56, -0.30), Vector2(0.32, -0.36), Vector2(0.88, 0.03), Vector2(0.44, 0.38), Vector2(-0.48, 0.44)], Color(0.23, 0.06, 0.05), 0.92, 0),
		_poly("head", Vector2(radius * 0.60, -radius * 0.12), [Vector2(-0.26, -0.26), Vector2(0.40, -0.16), Vector2(0.54, 0.12), Vector2(-0.20, 0.30)], Color(0.66, 0.14, 0.08), 0.54, 2),
		_poly("tail_flame", Vector2(-radius * 0.76, -radius * 0.02), [Vector2(-0.58, -0.16), Vector2(0.10, -0.08), Vector2(0.16, 0.12), Vector2(-0.50, 0.22)], Color(0.95, 0.25, 0.06), 0.48, 1),
		_poly("fang", Vector2(radius * 0.94, -radius * 0.05), [Vector2(-0.08, -0.12), Vector2(0.20, 0.00), Vector2(-0.08, 0.12)], Color(0.86, 0.70, 0.46), 0.28, 3)
	]
	return p

static func _knight(radius: float, color: Color) -> Dictionary:
	var p: Dictionary = _base(radius, Color(0.62, 0.52, 0.38))
	p["name"] = "Chain Knight"
	p["identity"] = "armored melee guard"
	p["telegraph"] = "cleave_cone"
	p["parts"] = [
		_poly("shield_body", Vector2(0, radius * 0.08), [Vector2(-0.60, -0.62), Vector2(0.0, -0.88), Vector2(0.60, -0.58), Vector2(0.46, 0.68), Vector2(0.0, 0.96), Vector2(-0.46, 0.68)], Color(0.22, 0.20, 0.18), 0.98, 0),
		_poly("helm", Vector2(0, -radius * 0.63), [Vector2(-0.44, 0.12), Vector2(-0.20, -0.44), Vector2(0.24, -0.44), Vector2(0.46, 0.10), Vector2(0.0, 0.38)], Color(0.76, 0.64, 0.42), 0.52, 2),
		_poly("blade", Vector2(radius * 0.60, -radius * 0.04), [Vector2(-0.10, -0.82), Vector2(0.16, -0.82), Vector2(0.10, 0.74), Vector2(-0.14, 0.74)], Color(0.64, 0.58, 0.48), 0.52, 3),
		_poly("knee_plate", Vector2(-radius * 0.22, radius * 0.66), [Vector2(-0.28, -0.14), Vector2(0.30, -0.12), Vector2(0.20, 0.22), Vector2(-0.24, 0.24)], Color(0.44, 0.36, 0.28), 0.36, 2)
	]
	p["lines"] = [_line("chain_belt", [Vector2(-radius * 0.46, radius * 0.16), Vector2(radius * 0.46, radius * 0.16)], Color(0.72, 0.56, 0.32, 0.52), 1.8)]
	return p

static func _brute(radius: float, color: Color) -> Dictionary:
	var p: Dictionary = _base(radius, Color(0.76, 0.30, 0.12))
	p["name"] = "Furnace Brute"
	p["identity"] = "large slam body with furnace core"
	p["telegraph"] = "slam_ring"
	p["threat_color"] = Color(1.0, 0.20, 0.05, 0.66)
	p["parts"] = [
		_poly("mass", Vector2(0, 0), [Vector2(-0.90, 0.62), Vector2(-0.78, -0.36), Vector2(-0.28, -0.84), Vector2(0.54, -0.72), Vector2(0.86, -0.14), Vector2(0.72, 0.72), Vector2(0.04, 0.98)], Color(0.16, 0.10, 0.08), 1.24, 0),
		_poly("furnace_core", Vector2(radius * 0.08, radius * 0.02), [Vector2(-0.38, -0.34), Vector2(0.32, -0.30), Vector2(0.36, 0.34), Vector2(-0.32, 0.36)], Color(1.0, 0.34, 0.06), 0.74, 2),
		_poly("slam_arm", Vector2(radius * 0.66, radius * 0.08), [Vector2(-0.24, -0.40), Vector2(0.36, -0.30), Vector2(0.56, 0.24), Vector2(0.00, 0.50), Vector2(-0.38, 0.24)], Color(0.36, 0.22, 0.15), 0.82, 3),
		_poly("ash_plow", Vector2(-radius * 0.54, radius * 0.44), [Vector2(-0.46, -0.18), Vector2(0.28, -0.16), Vector2(0.36, 0.18), Vector2(-0.34, 0.28)], Color(0.20, 0.13, 0.10), 0.56, 1)
	]
	p["markers"] = [_circle("core_glow", Vector2(radius * 0.08, radius * 0.02), radius * 0.20, Color(1.0, 0.78, 0.22, 0.36))]
	return p

static func _caller(radius: float, color: Color) -> Dictionary:
	var p: Dictionary = _base(radius, Color(0.66, 0.46, 0.18))
	p["name"] = "Bell Caller"
	p["identity"] = "summoner priority target"
	p["telegraph"] = "summon_ring"
	p["accent"] = Color(1.0, 0.72, 0.24, 0.86)
	p["parts"] = [
		_poly("robe", Vector2(0, radius * 0.10), [Vector2(-0.50, 0.80), Vector2(-0.30, -0.50), Vector2(0.0, -0.84), Vector2(0.38, -0.44), Vector2(0.52, 0.82), Vector2(0.0, 1.0)], Color(0.15, 0.12, 0.07), 0.98, 0),
		_poly("bell", Vector2(0, -radius * 0.63), [Vector2(-0.42, 0.22), Vector2(-0.28, -0.36), Vector2(0.28, -0.36), Vector2(0.44, 0.22), Vector2(0.20, 0.44), Vector2(-0.20, 0.44)], Color(0.88, 0.62, 0.22), 0.62, 2),
		_poly("clapper", Vector2(0, -radius * 0.35), [Vector2(-0.12, -0.12), Vector2(0.12, -0.12), Vector2(0.12, 0.20), Vector2(-0.12, 0.20)], Color(1.0, 0.84, 0.38), 0.42, 3),
		_poly("summon_book", Vector2(-radius * 0.50, radius * 0.08), [Vector2(-0.30, -0.22), Vector2(0.34, -0.24), Vector2(0.30, 0.22), Vector2(-0.34, 0.24)], Color(0.42, 0.26, 0.12), 0.46, 2)
	]
	p["lines"] = [_line("summon_ring", [Vector2(-radius * 0.70, radius * 0.66), Vector2(0, radius * 0.84), Vector2(radius * 0.70, radius * 0.66)], Color(1.0, 0.72, 0.24, 0.70), 2.2)]
	return p

static func _boss(radius: float, color: Color) -> Dictionary:
	var p: Dictionary = _base(radius, Color(0.88, 0.20, 0.08))
	p["name"] = "Map Boss Proxy"
	p["identity"] = "large multi-part boss silhouette"
	p["telegraph"] = "boss_seal"
	p["accent"] = Color(1.0, 0.62, 0.16, 0.92)
	p["threat_color"] = Color(1.0, 0.16, 0.04, 0.70)
	p["parts"] = [
		_poly("cape_back", Vector2(0, radius * 0.12), [Vector2(-1.04, 0.72), Vector2(-0.72, -0.58), Vector2(0.0, -0.24), Vector2(0.72, -0.58), Vector2(1.04, 0.72), Vector2(0.0, 1.02)], Color(0.10, 0.03, 0.03), 1.15, -2),
		_poly("boss_body", Vector2(0, 0), [Vector2(-0.90, 0.66), Vector2(-0.78, -0.28), Vector2(-0.36, -0.86), Vector2(0.28, -0.92), Vector2(0.82, -0.36), Vector2(0.92, 0.52), Vector2(0.28, 0.96), Vector2(-0.36, 0.88)], Color(0.18, 0.06, 0.05), 1.25, 0),
		_poly("tax_seal_core", Vector2(0, -radius * 0.08), [Vector2(-0.42, -0.42), Vector2(0.42, -0.42), Vector2(0.42, 0.42), Vector2(-0.42, 0.42)], Color(1.0, 0.42, 0.08), 0.75, 2),
		_poly("left_horn", Vector2(-radius * 0.50, -radius * 0.68), [Vector2(-0.46, 0.28), Vector2(0.02, -0.52), Vector2(0.28, 0.26)], Color(0.86, 0.68, 0.40), 0.68, 3),
		_poly("right_horn", Vector2(radius * 0.50, -radius * 0.68), [Vector2(-0.28, 0.26), Vector2(-0.02, -0.52), Vector2(0.46, 0.28)], Color(0.86, 0.68, 0.40), 0.68, 3),
		_poly("execution_blade", Vector2(radius * 0.70, radius * 0.04), [Vector2(-0.12, -0.90), Vector2(0.20, -0.90), Vector2(0.16, 0.82), Vector2(-0.18, 0.82)], Color(0.62, 0.48, 0.32), 0.74, 4)
	]
	p["lines"] = [
		_line("boss_crown", [Vector2(-radius * 0.72, -radius * 0.46), Vector2(0, -radius * 0.92), Vector2(radius * 0.72, -radius * 0.46)], Color(1.0, 0.72, 0.25, 0.88), 3.0),
		_line("seal_cross", [Vector2(-radius * 0.24, -radius * 0.08), Vector2(radius * 0.24, -radius * 0.08)], Color(1.0, 0.82, 0.30, 0.55), 2.0)
	]
	p["markers"] = [_circle("boss_core_glow", Vector2(0, -radius * 0.08), radius * 0.18, Color(1.0, 0.80, 0.24, 0.38))]
	return p

static func _poly(id: String, pos: Vector2, points: Array, color: Color, scale: float = 1.0, z: int = 0) -> Dictionary:
	return {"kind": "poly", "id": id, "pos": pos, "points": points, "color": color, "scale": scale, "z": z}

static func _line(id: String, points: Array, color: Color, width: float = 2.0, z: int = 4) -> Dictionary:
	return {"kind": "line", "id": id, "points": points, "color": color, "width": width, "z": z}

static func _circle(id: String, pos: Vector2, radius: float, color: Color, z: int = 5) -> Dictionary:
	return {"kind": "circle", "id": id, "pos": pos, "radius": radius, "color": color, "z": z}
