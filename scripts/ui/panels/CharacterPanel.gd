extends RVUIPanelBase

func refresh(state: Object) -> void:
	super.refresh(state)
	var text: String = "CHARACTER\n\n"
	text += "Level: " + str(_int(state, "level", 1)) + "\n"
	text += "XP: " + str(int(_float(state, "xp", 0.0))) + "\n"
	text += "Life: " + str(int(_float(state, "player_hp", 0.0))) + "/" + str(int(_float(state, "max_hp", 0.0))) + "\n"
	text += "Mana: " + str(int(_float(state, "player_mana", 0.0))) + "/" + str(int(_float(state, "max_mana", 0.0))) + "\n"
	text += "Spirit: " + str(_int(state, "spirit_reserved", 0)) + "/" + str(_int(state, "spirit_max", 0)) + "\n"
	text += "Gold: " + str(_int(state, "gold", 0)) + "\n"
	var passives: Dictionary = _dict(state, "passives")
	var detail: String = "PASSIVE BRANCHES\n\n"
	for key in passives.keys():
		detail += "- " + str(key).capitalize() + ": " + str(passives[key]) + "\n"
	_set_rich_text("Body", text)
	_set_rich_text("Detail", detail)
