extends RVUIPanelBase

func refresh(state: Object) -> void:
	super.refresh(state)
	var current: Dictionary = _dict(state, "current_contract")
	var text: String = "ACTIVITIES\n\nDungeon Run\nMaterial Hunt\nElite Hunt\nBoss Trial\nEndless Rift\n"
	var detail: String = "CURRENT ACTIVITY\n\n"
	if current.is_empty():
		detail += "No active contract.\n"
	else:
		for key in current.keys():
			detail += str(key).capitalize() + ": " + str(current[key]) + "\n"
	_set_rich_text("Body", text)
	_set_rich_text("Detail", detail)
