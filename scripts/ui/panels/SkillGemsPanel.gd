extends RVUIPanelBase

func refresh(state: Object) -> void:
	super.refresh(state)
	var active: Array = _arr(state, "active_skills")
	var sockets: Dictionary = _dict(state, "skill_gem_sockets")
	var support_inventory: Dictionary = _dict(state, "support_gem_inventory")
	var spirit_enabled: Dictionary = _dict(state, "spirit_gems_enabled")
	var text: String = "SKILL GEMS\n\nActive Skills\n"
	for skill in active:
		text += "- " + str(skill) + "\n"
		var supports: Array = sockets.get(skill, [])
		for support in supports:
			text += "    + " + str(support).replace("_", " ").capitalize() + "\n"
	var detail: String = "SUPPORT INVENTORY\n\n"
	for key in support_inventory.keys():
		detail += "- " + str(key).replace("_", " ").capitalize() + ": " + str(support_inventory[key]) + "\n"
	detail += "\nSPIRIT\nReserved: " + str(_int(state, "spirit_reserved", 0)) + "/" + str(_int(state, "spirit_max", 0)) + "\n"
	for spirit in spirit_enabled.keys():
		detail += "- " + str(spirit).replace("_", " ").capitalize() + ": " + str(spirit_enabled[spirit]) + "\n"
	_set_rich_text("Body", text)
	_set_rich_text("Detail", detail)
