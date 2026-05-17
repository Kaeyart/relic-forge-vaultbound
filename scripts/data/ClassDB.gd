class_name RVClassDB
extends RefCounted

const CLASSES: Dictionary = {
	"sorceress": {
		"id": "sorceress",
		"name": "Sorceress",
		"start_node": "start_sorceress",
		"description": "Spell, elemental, mana, spirit, and cooldown specialist.",
		"stats": {"Maximum Mana": 24.0, "Spell Damage": 8.0, "Maximum Spirit": 10.0},
		"flags": ["class_sorceress", "spell_start"]
	},
	"huntress": {
		"id": "huntress",
		"name": "Huntress",
		"start_node": "start_huntress",
		"description": "Trap, crit, evasion, bleed, and mobility specialist.",
		"stats": {"Evasion": 12.0, "Critical Chance": 3.0, "Trap Damage": 8.0},
		"flags": ["class_huntress", "trap_start"]
	},
	"warrior": {
		"id": "warrior",
		"name": "Warrior",
		"start_node": "start_warrior",
		"description": "Melee, armor, life, bleed, stagger, and weapon pressure specialist.",
		"stats": {"Maximum Life": 32.0, "Armor": 18.0, "Physical Damage": 8.0},
		"flags": ["class_warrior", "melee_start"]
	}
}

static func ids() -> Array[String]:
	return ["sorceress", "huntress", "warrior"]

static func has_class(class_id: String) -> bool:
	return CLASSES.has(class_id)

static func data(class_id: String) -> Dictionary:
	return Dictionary(CLASSES.get(class_id, CLASSES["sorceress"])).duplicate(true)

static func name_for(class_id: String) -> String:
	return str(data(class_id).get("name", class_id.capitalize()))

static func next_class_id(class_id: String) -> String:
	var values: Array[String] = ids()
	var index: int = values.find(class_id)
	if index < 0:
		return values[0]
	return values[(index + 1) % values.size()]

static func start_node(class_id: String) -> String:
	return str(data(class_id).get("start_node", "start_sorceress"))
