extends RVUIPanelBase

@onready var content_label: Label = %ContentLabel

func update_from_state(state: RVGameState) -> void:
	if content_label == null:
		return
	content_label.text = _build_text(state)


func _build_text(state: RVGameState) -> String:
	match title:
		"Inventory":
			return "Backpack Items: %s\nPress E to equip first item.\nPress X to salvage first item." % state.backpack.size()
		"Crafting":
			return "Basic Forge\nPress F to craft a basic item.\nMaterials: Embers %s  Shards %s  Runes %s" % [state.materials.get("embers", 0), state.materials.get("shards", 0), state.materials.get("runes", 0)]
		"Passive Atlas":
			return "Mastery Points: %s\nRefund Points: %s\nPress Enter to allocate first available node.\nPress Backspace to refund first allocated node." % [state.mastery_points, state.refund_points]
		"Skill Gems":
			return "Active Skills:\n%s\n\nPress 1-6 to toggle skills." % "\n".join(state.active_skills)
		"Character":
			return "Level %s\nLife %s/%s\nMana %s/%s\nKills %s\nDeaths %s" % [state.level, int(state.player_hp), int(state.max_hp), int(state.player_mana), int(state.max_mana), state.kills, state.deaths]
		"Stash":
			return "Stash Items: %s\nPress E to deposit backpack.\nPress X to withdraw first stash item." % state.stash.size()
		"Activities":
			return "Activities live in the physical hub.\nWalk to a gate and press E."
	return ""
