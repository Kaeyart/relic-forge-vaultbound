class_name RVEnemyVisualProfileDB
extends RefCounted

# Patch 059: Visual proxy profile data. These are not final sprites.
# They define readable silhouettes for prototype enemy roles so combat stops looking like circles.

static func profile(enemy_type: String, role: String, radius: float, base_color: Color) -> Dictionary:
	var key := enemy_type.to_lower().replace(" ", "_")
	if key.find("boss") >= 0 or role == "boss":
		return _boss(radius, base_color)
	if key.find("brute") >= 0 or role == "brute":
		return _brute(radius, base_color)
	if key.find("lunge") >= 0 or role == "lunger":
		return _lunger(radius, base_color)
	if key.find("spit") >= 0 or role == "spitter" or role == "shooter":
		return _spitter(radius, base_color)
	if key.find("binder") >= 0 or key.find("acolyte") >= 0 or role == "caster":
		return _binder(radius, base_color)
	if key.find("hound") >= 0 or role == "hound":
		return _hound(radius, base_color)
	if key.find("knight") >= 0 or role == "knight":
		return _knight(radius, base_color)
	if key.find("caller") >= 0 or key.find("bell") >= 0 or role == "summoner":
		return _caller(radius, base_color)
	return _grunt(radius, base_color)

static func _base(radius: float, color: Color) -> Dictionary:
	return {
		"radius": radius,
		"primary": color,
		"shadow": Color(0.0, 0.0, 0.0, 0.34),
		"outline": Color(0.025, 0.022, 0.026, 1.0),
		"glow": Color(1.0, 0.38, 0.10, 0.82),
		"parts": [],
		"lines": [],
		"markers": []
	}

static func _grunt(radius: float, color: Color) -> Dictionary:
	var p := _base(radius, color)
	p["name"] = "Ash Grunt"
	p["identity"] = "jagged melee pressure"
	p["parts"] = [
		_poly("body", Vector2(0, 2), [Vector2(-0.70, 0.62), Vector2(-0.46, -0.44), Vector2(0.05, -0.82), Vector2(0.55, -0.30), Vector2(0.62, 0.55), Vector2(0.05, 0.86)], _mix(color, Color(0.18, 0.14, 0.11), 0.30)),
		_poly("head", Vector2(0, -radius * 0.62), [Vector2(-0.42, 0.24), Vector2(-0.18, -0.38), Vector2(0.26, -0.34), Vector2(0.45, 0.14), Vector2(0.08, 0.43)], _lighten(color, 0.16), 0.52),
		_poly("cleaver", Vector2(radius * 0.62, 0), [Vector2(-0.10, -0.48), Vector2(0.46, -0.30), Vector2(0.72, 0.12), Vector2(0.30, 0.42), Vector2(-0.24, 0.28)], Color(0.46, 0.39, 0.31), 0.70)
	]
	p["lines"] = [_line("ember_crack", [Vector2(-0.18, -0.22), Vector2(0.04, 0.02), Vector2(-0.06, 0.34)], Color(1.0, 0.34, 0.08, 0.75), 1.8)]
	return p

static func _lunger(radius: float, color: Color) -> Dictionary:
	var p := _base(radius, color)
	p["name"] = "Cinder Lunger"
	p["identity"] = "thin forward charge silhouette"
	p["parts"] = [
		_poly("body", Vector2(0, 0), [Vector2(-0.82, 0.44), Vector2(-0.50, -0.34), Vector2(0.34, -0.50), Vector2(0.92, 0.00), Vector2(0.28, 0.52)], _mix(color, Color(0.32, 0.10, 0.07), 0.22)),
		_poly("spear_head", Vector2(radius * 0.70, -radius * 0.08), [Vector2(-0.18, -0.34), Vector2(0.74, 0.00), Vector2(-0.18, 0.34)], Color(0.78, 0.52, 0.28), 0.62),
		_poly("rear_cloak", Vector2(-radius * 0.52, radius * 0.08), [Vector2(-0.56, 0.45), Vector2(-0.30, -0.42), Vector2(0.42, -0.14), Vector2(0.20, 0.56)], Color(0.16, 0.10, 0.08), 0.72)
	]
	p["lines"] = [_line("charge_spine", [Vector2(-radius * 0.54, 0), Vector2(radius * 0.72, 0)], Color(1.0, 0.54, 0.16, 0.70), 2.0)]
	return p

static func _spitter(radius: float, color: Color) -> Dictionary:
	var p := _base(radius, color)
	p["name"] = "Ember Spitter"
	p["identity"] = "hunched ranged throat silhouette"
	p["parts"] = [
		_poly("hunched_body", Vector2(0, 3), [Vector2(-0.78, 0.50), Vector2(-0.62, -0.26), Vector2(-0.10, -0.66), Vector2(0.58, -0.38), Vector2(0.78, 0.32), Vector2(0.16, 0.76)], _mix(color, Color(0.22, 0.08, 0.05), 0.25)),
		_poly("throat", Vector2(radius * 0.35, -radius * 0.30), [Vector2(-0.42, 0.30), Vector2(-0.20, -0.46), Vector2(0.44, -0.38), Vector2(0.56, 0.28), Vector2(0.04, 0.50)], Color(0.86, 0.33, 0.08), 0.55),
		_poly("mouth", Vector2(radius * 0.70, -radius * 0.42), [Vector2(-0.28, -0.16), Vector2(0.34, -0.06), Vector2(-0.20, 0.24)], Color(1.0, 0.72, 0.24), 0.45)
	]
	p["markers"] = [_circle("spit_glow", Vector2(radius * 0.55, -radius * 0.28), radius * 0.18, Color(1.0, 0.34, 0.06, 0.65))]
	return p

static func _binder(radius: float, color: Color) -> Dictionary:
	var p := _base(radius, Color(0.46, 0.18, 0.78))
	p["name"] = "Chain Binder"
	p["identity"] = "tall caster/support with chain halo"
	p["glow"] = Color(0.72, 0.28, 1.0, 0.82)
	p["parts"] = [
		_poly("robe", Vector2(0, 4), [Vector2(-0.48, 0.74), Vector2(-0.36, -0.54), Vector2(0.0, -0.90), Vector2(0.34, -0.50), Vector2(0.50, 0.76), Vector2(0.0, 0.96)], Color(0.15, 0.07, 0.20), 0.95),
		_poly("mask", Vector2(0, -radius * 0.62), [Vector2(-0.24, 0.28), Vector2(-0.16, -0.30), Vector2(0.18, -0.30), Vector2(0.26, 0.24), Vector2(0.0, 0.42)], Color(0.68, 0.58, 0.74), 0.50),
		_poly("staff", Vector2(radius * 0.48, -radius * 0.02), [Vector2(-0.06, -0.76), Vector2(0.12, -0.76), Vector2(0.06, 0.74), Vector2(-0.12, 0.74)], Color(0.35, 0.24, 0.42), 0.52)
	]
	p["lines"] = [_line("chain_halo", [Vector2(-radius * 0.66, -radius * 0.58), Vector2(-radius * 0.28, -radius * 0.82), Vector2(radius * 0.26, -radius * 0.82), Vector2(radius * 0.66, -radius * 0.58)], Color(0.72, 0.42, 1.0, 0.72), 2.0)]
	return p

static func _hound(radius: float, color: Color) -> Dictionary:
	var p := _base(radius, Color(0.50, 0.12, 0.10))
	p["name"] = "Ash Hound"
	p["identity"] = "low fast rushing silhouette"
	p["parts"] = [
		_poly("body", Vector2(0, 4), [Vector2(-0.86, 0.22), Vector2(-0.56, -0.28), Vector2(0.32, -0.34), Vector2(0.86, 0.05), Vector2(0.42, 0.36), Vector2(-0.48, 0.42)], Color(0.25, 0.08, 0.06), 0.86),
		_poly("head", Vector2(radius * 0.58, -radius * 0.18), [Vector2(-0.26, -0.24), Vector2(0.38, -0.16), Vector2(0.52, 0.12), Vector2(-0.20, 0.28)], Color(0.62, 0.16, 0.10), 0.50),
		_poly("tail", Vector2(-radius * 0.70, -radius * 0.06), [Vector2(-0.52, -0.12), Vector2(0.10, -0.06), Vector2(0.12, 0.12), Vector2(-0.48, 0.18)], Color(0.72, 0.22, 0.08), 0.44)
	]
	return p

static func _knight(radius: float, color: Color) -> Dictionary:
	var p := _base(radius, Color(0.58, 0.48, 0.36))
	p["name"] = "Chain Knight"
	p["identity"] = "armored melee guard"
	p["parts"] = [
		_poly("shield_body", Vector2(0, 4), [Vector2(-0.58, -0.62), Vector2(0.0, -0.88), Vector2(0.58, -0.58), Vector2(0.44, 0.68), Vector2(0.0, 0.94), Vector2(-0.44, 0.68)], Color(0.24, 0.22, 0.20), 0.92),
		_poly("helm", Vector2(0, -radius * 0.62), [Vector2(-0.42, 0.12), Vector2(-0.20, -0.42), Vector2(0.24, -0.42), Vector2(0.44, 0.10), Vector2(0.0, 0.36)], Color(0.72, 0.62, 0.44), 0.48),
		_poly("blade", Vector2(radius * 0.58, -radius * 0.04), [Vector2(-0.10, -0.78), Vector2(0.16, -0.78), Vector2(0.10, 0.70), Vector2(-0.14, 0.70)], Color(0.58, 0.52, 0.46), 0.48)
	]
	return p

static func _brute(radius: float, color: Color) -> Dictionary:
	var p := _base(radius, Color(0.72, 0.30, 0.12))
	p["name"] = "Furnace Brute"
	p["identity"] = "large slam body with furnace core"
	p["parts"] = [
		_poly("mass", Vector2(0, 0), [Vector2(-0.86, 0.62), Vector2(-0.78, -0.34), Vector2(-0.28, -0.82), Vector2(0.54, -0.70), Vector2(0.84, -0.12), Vector2(0.70, 0.70), Vector2(0.05, 0.96)], Color(0.17, 0.12, 0.10), 1.18),
		_poly("furnace_core", Vector2(0.08, 0.02), [Vector2(-0.36, -0.34), Vector2(0.30, -0.30), Vector2(0.34, 0.32), Vector2(-0.30, 0.36)], Color(1.0, 0.36, 0.08), 0.70),
		_poly("slam_arm", Vector2(radius * 0.62, radius * 0.06), [Vector2(-0.24, -0.38), Vector2(0.34, -0.28), Vector2(0.54, 0.22), Vector2(0.02, 0.48), Vector2(-0.36, 0.24)], Color(0.34, 0.23, 0.17), 0.78)
	]
	return p

static func _caller(radius: float, color: Color) -> Dictionary:
	var p := _base(radius, Color(0.66, 0.48, 0.22))
	p["name"] = "Bell Caller"
	p["identity"] = "summoner priority target"
	p["parts"] = [
		_poly("robe", Vector2(0, 5), [Vector2(-0.48, 0.78), Vector2(-0.30, -0.48), Vector2(0.0, -0.82), Vector2(0.36, -0.42), Vector2(0.50, 0.80), Vector2(0.0, 0.98)], Color(0.16, 0.13, 0.08), 0.94),
		_poly("bell", Vector2(0, -radius * 0.62), [Vector2(-0.40, 0.22), Vector2(-0.28, -0.34), Vector2(0.28, -0.34), Vector2(0.42, 0.22), Vector2(0.20, 0.42), Vector2(-0.20, 0.42)], Color(0.84, 0.60, 0.22), 0.58),
		_poly("clapper", Vector2(0, -radius * 0.35), [Vector2(-0.12, -0.12), Vector2(0.12, -0.12), Vector2(0.12, 0.20), Vector2(-0.12, 0.20)], Color(1.0, 0.80, 0.36), 0.40)
	]
	p["lines"] = [_line("summon_ring", [Vector2(-radius * 0.68, radius * 0.64), Vector2(0, radius * 0.82), Vector2(radius * 0.68, radius * 0.64)], Color(1.0, 0.70, 0.22, 0.68), 2.0)]
	return p

static func _boss(radius: float, color: Color) -> Dictionary:
	var p := _base(max(radius, 32.0), Color(0.86, 0.20, 0.10))
	p["name"] = "Map Boss Proxy"
	p["identity"] = "large multi-part boss silhouette"
	p["parts"] = [
		_poly("boss_body", Vector2(0, 0), [Vector2(-0.90, 0.66), Vector2(-0.78, -0.28), Vector2(-0.36, -0.86), Vector2(0.28, -0.92), Vector2(0.82, -0.36), Vector2(0.92, 0.52), Vector2(0.28, 0.96), Vector2(-0.36, 0.88)], Color(0.17, 0.07, 0.06), 1.25),
		_poly("tax_seal_core", Vector2(0, -radius * 0.08), [Vector2(-0.42, -0.42), Vector2(0.42, -0.42), Vector2(0.42, 0.42), Vector2(-0.42, 0.42)], Color(1.0, 0.42, 0.08), 0.75),
		_poly("left_horn", Vector2(-radius * 0.50, -radius * 0.68), [Vector2(-0.46, 0.28), Vector2(0.02, -0.50), Vector2(0.28, 0.26)], Color(0.84, 0.66, 0.40), 0.66),
		_poly("right_horn", Vector2(radius * 0.50, -radius * 0.68), [Vector2(-0.28, 0.26), Vector2(-0.02, -0.50), Vector2(0.46, 0.28)], Color(0.84, 0.66, 0.40), 0.66)
	]
	p["lines"] = [_line("boss_crown", [Vector2(-radius * 0.72, -radius * 0.46), Vector2(0, -radius * 0.90), Vector2(radius * 0.72, -radius * 0.46)], Color(1.0, 0.70, 0.25, 0.85), 3.0)]
	return p

static func _poly(id: String, pos: Vector2, points: Array[Vector2], color: Color, scale: float = 1.0) -> Dictionary:
	return {"kind": "poly", "id": id, "pos": pos, "points": points, "color": color, "scale": scale}

static func _line(id: String, points: Array[Vector2], color: Color, width: float = 2.0) -> Dictionary:
	return {"kind": "line", "id": id, "points": points, "color": color, "width": width}

static func _circle(id: String, pos: Vector2, radius: float, color: Color) -> Dictionary:
	return {"kind": "circle", "id": id, "pos": pos, "radius": radius, "color": color}

static func _lighten(color: Color, amount: float) -> Color:
	return Color(min(color.r + amount, 1.0), min(color.g + amount, 1.0), min(color.b + amount, 1.0), color.a)

static func _mix(a: Color, b: Color, t: float) -> Color:
	return Color(lerp(a.r, b.r, t), lerp(a.g, b.g, t), lerp(a.b, b.b, t), lerp(a.a, b.a, t))
