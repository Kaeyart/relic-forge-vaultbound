class_name RVSkillDB
extends RefCounted

const SKILLS = {
	"Fireball": {
		"cost": 12.0,
		"cooldown": 0.42,
		"damage": 22.0,
		"tags": ["Fire", "Projectile", "Spell", "Burn"],
		"color": Color(1.0, 0.34, 0.10),
		"icon": "res://assets/icons/skills/skill_fireball.svg"
	},
	"Cleave": {
		"cost": 9.0,
		"cooldown": 0.36,
		"damage": 28.0,
		"tags": ["Physical", "Melee", "Slash"],
		"color": Color(1.0, 0.80, 0.48),
		"icon": "res://assets/icons/skills/skill_cleave.svg"
	},
	"Frost Nova": {
		"cost": 18.0,
		"cooldown": 1.25,
		"damage": 18.0,
		"tags": ["Cold", "Area", "Freeze"],
		"color": Color(0.42, 0.82, 1.0),
		"icon": "res://assets/icons/skills/skill_frost_nova.svg"
	},
	"Storm Lance": {
		"cost": 14.0,
		"cooldown": 0.55,
		"damage": 24.0,
		"tags": ["Lightning", "Projectile", "Spell", "Chain"],
		"color": Color(0.72, 0.92, 1.0),
		"icon": "res://assets/icons/skills/skill_storm_lance.svg"
	},
	"Void Rift": {
		"cost": 22.0,
		"cooldown": 1.35,
		"damage": 20.0,
		"tags": ["Void", "Area", "Curse"],
		"color": Color(0.70, 0.36, 1.0),
		"icon": "res://assets/icons/skills/skill_void_rift.svg"
	},
	"Blade Trap": {
		"cost": 16.0,
		"cooldown": 0.90,
		"damage": 26.0,
		"tags": ["Trap", "Physical", "Area"],
		"color": Color(0.95, 0.72, 0.28),
		"icon": "res://assets/icons/skills/skill_blade_trap.svg"
	}
}

static func names() -> Array:
	return SKILLS.keys()


static func data(skill: String) -> Dictionary:
	return SKILLS.get(skill, {})


static func color(skill: String) -> Color:
	var d: Dictionary = data(skill)
	return d.get("color", Color(0.90, 0.84, 0.70))


static func tags(skill: String) -> Array:
	var d: Dictionary = data(skill)
	return d.get("tags", [])
