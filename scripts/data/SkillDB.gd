class_name RVSkillDB
extends RefCounted

const SKILLS: Dictionary = {
	"Fireball": {"cost": 12.0, "cooldown": 0.42, "damage": 24.0, "color": Color(1.0, 0.34, 0.10)},
	"Cleave": {"cost": 9.0, "cooldown": 0.36, "damage": 30.0, "color": Color(1.0, 0.80, 0.48)},
	"Frost Nova": {"cost": 18.0, "cooldown": 1.10, "damage": 18.0, "color": Color(0.42, 0.82, 1.0)},
	"Storm Lance": {"cost": 14.0, "cooldown": 0.55, "damage": 26.0, "color": Color(0.72, 0.92, 1.0)},
	"Void Rift": {"cost": 22.0, "cooldown": 1.35, "damage": 22.0, "color": Color(0.70, 0.36, 1.0)},
	"Blade Trap": {"cost": 16.0, "cooldown": 0.90, "damage": 28.0, "color": Color(0.95, 0.72, 0.28)}
}

static func data(skill: String) -> Dictionary:
	return SKILLS.get(skill, {})

static func color(skill: String) -> Color:
	return data(skill).get("color", Color(0.90, 0.84, 0.70))
