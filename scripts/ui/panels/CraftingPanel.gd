extends RVUIPanelBase

func refresh(state: Object) -> void:
	super.refresh(state)
	var materials: Dictionary = _dict(state, "materials")
	var backpack: Array = _arr(state, "backpack")
	var shards: Dictionary = _dict(state, "crafting_shards")
	var focus: int = _int(state, "forge_focus_index", 0)
	var text: String = "CRAFTING\n\nMaterials\n"
	for key in materials.keys():
		text += "- " + str(key).replace("_", " ").capitalize() + ": " + str(materials[key]) + "\n"
	text += "\nAffix Shards\n"
	if shards.is_empty():
		text += "No affix shards yet.\n"
	for key2 in shards.keys():
		text += "- " + str(key2).replace("_", " ").capitalize() + ": " + str(shards[key2]) + "\n"
	var detail: String = "Focused Item\n\n"
	if backpack.size() > 0:
		focus = clamp(focus, 0, backpack.size() - 1)
		detail += _string_from_item(backpack[focus])
	else:
		detail += "Backpack empty.\n"
	_set_rich_text("Body", text)
	_set_rich_text("Detail", detail)
