extends RVUIPanelBase

func refresh(state: Object) -> void:
	super.refresh(state)
	var stash: Array = _arr(state, "stash")
	var backpack: Array = _arr(state, "backpack")
	var text: String = "STASH\n\nStored Items: " + str(stash.size()) + "\nBackpack: " + str(backpack.size()) + "\n\n"
	var index: int = 0
	for item in stash:
		text += str(index + 1) + ". " + _string_from_item(item).split("\n")[0] + "\n"
		index += 1
	if stash.size() == 0:
		text += "Stash is empty.\n"
	_set_rich_text("Body", text)
	_set_rich_text("Detail", "Scene-authored slots are under SlotGrid/Slot_00 etc. Replace placeholders with your sliced UI frames.")
