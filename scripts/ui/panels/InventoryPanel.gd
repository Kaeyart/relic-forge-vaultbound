extends RVUIPanelBase

func refresh(state: Object) -> void:
	super.refresh(state)
	var backpack: Array = _arr(state, "backpack")
	var equipped: Dictionary = _dict(state, "equipped")
	var text: String = "INVENTORY\n\nBackpack Items: " + str(backpack.size()) + "\n\n"
	var index: int = 0
	for item in backpack:
		text += str(index + 1) + ". " + _string_from_item(item).split("\n")[0] + "\n"
		index += 1
	if backpack.size() == 0:
		text += "Backpack is empty.\n"
	var detail: String = "EQUIPPED\n\n"
	for slot in equipped.keys():
		detail += str(slot).capitalize() + ": " + _string_from_item(equipped[slot]).split("\n")[0] + "\n"
	_set_rich_text("Body", text)
	_set_rich_text("Detail", detail)
