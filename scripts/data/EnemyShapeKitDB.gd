class_name RVEnemyShapeKitDB
extends RefCounted

# Patch 061-063: data-driven shape-kit profiles for Godot-native enemy proxy art.
# These are not final sprites. They are readable silhouette recipes for prototype combat.

static func profile(enemy_type: String, role: String = "") -> Dictionary:
	var key: String = str(enemy_type).to_lower()
	var role_key: String = str(role).to_lower()
	var p: Dictionary = _base_profile()

	if key.find("boss") >= 0 or key.find("tax") >= 0 or role_key == "boss":
		p.merge(_boss_profile(), true)
	elif key.find("caller") >= 0 or key.find("bell") >= 0 or role_key.find("caller") >= 0:
		p.merge(_caller_profile(), true)
	elif key.find("brute") >= 0 or key.find("furnace") >= 0 or role_key == "brute":
		p.merge(_brute_profile(), true)
	elif key.find("binder") >= 0 or key.find("acolyte") >= 0 or role_key.find("caster") >= 0 or role_key.find("acolyte") >= 0:
		p.merge(_binder_profile(), true)
	elif key.find("spitter") >= 0 or role_key.find("spitter") >= 0 or role_key.find("shooter") >= 0:
		p.merge(_spitter_profile(), true)
	elif key.find("lunger") >= 0 or key.find("hound") >= 0 or role_key.find("hound") >= 0:
		p.merge(_lunger_profile(), true)
	elif key.find("knight") >= 0 or key.find("guard") >= 0:
		p.merge(_knight_profile(), true)
	elif key.find("archer") >= 0 or role_key.find("shooter") >= 0:
		p.merge(_spitter_profile(), true)
	else:
		p.merge(_grunt_profile(), true)

	return p

static func _base_profile() -> Dictionary:
	return {
		"shape": "grunt",
		"scale": 1.0,
		"body": Color(0.18, 0.16, 0.14, 1.0),
		"mid": Color(0.42, 0.34, 0.26, 1.0),
		"accent": Color(0.95, 0.32, 0.10, 1.0),
		"outline": Color(0.025, 0.022, 0.020, 1.0),
		"telegraph": Color(1.0, 0.55, 0.18, 0.62),
		"role_marker": "melee",
		"outline_width": 2.0,
		"shadow_scale": Vector2(1.20, 0.38),
	}

static func _grunt_profile() -> Dictionary:
	return {
		"shape": "grunt",
		"role_marker": "blade",
		"body": Color(0.19, 0.17, 0.15, 1.0),
		"mid": Color(0.52, 0.42, 0.32, 1.0),
		"accent": Color(0.96, 0.29, 0.10, 1.0),
		"telegraph": Color(1.0, 0.50, 0.12, 0.66),
		"scale": 1.0,
	}

static func _lunger_profile() -> Dictionary:
	return {
		"shape": "lunger",
		"role_marker": "charge",
		"body": Color(0.17, 0.14, 0.13, 1.0),
		"mid": Color(0.58, 0.30, 0.18, 1.0),
		"accent": Color(1.0, 0.62, 0.16, 1.0),
		"telegraph": Color(1.0, 0.72, 0.22, 0.72),
		"scale": 1.0,
	}

static func _spitter_profile() -> Dictionary:
	return {
		"shape": "spitter",
		"role_marker": "ranged",
		"body": Color(0.16, 0.14, 0.11, 1.0),
		"mid": Color(0.58, 0.28, 0.10, 1.0),
		"accent": Color(1.0, 0.72, 0.12, 1.0),
		"telegraph": Color(1.0, 0.68, 0.18, 0.56),
		"scale": 1.0,
	}

static func _binder_profile() -> Dictionary:
	return {
		"shape": "binder",
		"role_marker": "caster",
		"body": Color(0.11, 0.09, 0.15, 1.0),
		"mid": Color(0.30, 0.18, 0.48, 1.0),
		"accent": Color(0.74, 0.28, 1.0, 1.0),
		"telegraph": Color(0.74, 0.24, 1.0, 0.64),
		"scale": 1.02,
	}

static func _brute_profile() -> Dictionary:
	return {
		"shape": "brute",
		"role_marker": "slam",
		"body": Color(0.15, 0.13, 0.11, 1.0),
		"mid": Color(0.52, 0.21, 0.10, 1.0),
		"accent": Color(1.0, 0.42, 0.08, 1.0),
		"telegraph": Color(1.0, 0.32, 0.08, 0.70),
		"scale": 1.28,
		"shadow_scale": Vector2(1.55, 0.48),
	}

static func _caller_profile() -> Dictionary:
	return {
		"shape": "caller",
		"role_marker": "summon",
		"body": Color(0.13, 0.10, 0.10, 1.0),
		"mid": Color(0.46, 0.32, 0.20, 1.0),
		"accent": Color(1.0, 0.72, 0.28, 1.0),
		"telegraph": Color(1.0, 0.78, 0.28, 0.58),
		"scale": 1.08,
	}

static func _knight_profile() -> Dictionary:
	return {
		"shape": "knight",
		"role_marker": "guard",
		"body": Color(0.16, 0.16, 0.17, 1.0),
		"mid": Color(0.42, 0.38, 0.33, 1.0),
		"accent": Color(0.92, 0.82, 0.62, 1.0),
		"telegraph": Color(0.96, 0.82, 0.58, 0.58),
		"scale": 1.1,
	}

static func _boss_profile() -> Dictionary:
	return {
		"shape": "boss",
		"role_marker": "boss",
		"body": Color(0.11, 0.07, 0.06, 1.0),
		"mid": Color(0.44, 0.15, 0.10, 1.0),
		"accent": Color(1.0, 0.20, 0.05, 1.0),
		"telegraph": Color(1.0, 0.14, 0.06, 0.78),
		"scale": 1.70,
		"shadow_scale": Vector2(2.05, 0.62),
	}
