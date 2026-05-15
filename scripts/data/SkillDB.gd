class_name RVSkillDB
extends RefCounted

const SKILLS: Dictionary = {
	"Fireball": {
		"damage": 22.0,
		"mana_cost": 12.0,
		"cooldown": 0.42,
		"speed": 540.0,
		"radius": 8.0,
		"tags": ["Fire", "Projectile", "Spell"],
		"color": Color(1.0, 0.32, 0.08)
	},
	"Cleave": {
		"damage": 30.0,
		"mana_cost": 9.0,
		"cooldown": 0.38,
		"radius": 78.0,
		"tags": ["Physical", "Melee", "Area"],
		"color": Color(1.0, 0.78, 0.42)
	},
	"Frost Nova": {
		"damage": 18.0,
		"mana_cost": 18.0,
		"cooldown": 1.15,
		"radius": 145.0,
		"tags": ["Cold", "Area", "Spell"],
		"color": Color(0.44, 0.82, 1.0)
	},
	"Storm Lance": {
		"damage": 24.0,
		"mana_cost": 14.0,
		"cooldown": 0.55,
		"speed": 740.0,
		"radius": 6.0,
		"tags": ["Lightning", "Projectile", "Spell"],
		"color": Color(0.72, 0.92, 1.0)
	},
	"Void Rift": {
		"damage": 21.0,
		"mana_cost": 22.0,
		"cooldown": 1.35,
		"radius": 92.0,
		"tags": ["Void", "Area", "Spell"],
		"color": Color(0.68, 0.34, 1.0)
	},
	"Blade Trap": {
		"damage": 26.0,
		"mana_cost": 16.0,
		"cooldown": 0.90,
		"radius": 64.0,
		"tags": ["Trap", "Physical", "Area"],
		"color": Color(0.94, 0.70, 0.28)
	}
}

static func names() -> Array:
	return SKILLS.keys()


static func data(skill_name: String) -> Dictionary:
	return SKILLS.get(skill_name, {})


static func color(skill_name: String) -> Color:
	var skill_data: Dictionary = data(skill_name)
	return skill_data.get("color", Color(0.9, 0.84, 0.70))


static func tags(skill_name: String) -> Array:
	var skill_data: Dictionary = data(skill_name)
	return skill_data.get("tags", [])
