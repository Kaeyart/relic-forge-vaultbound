extends RVUIPanelBase

@onready var content_label: Label = %ContentLabel

func update_from_state(state: RVGameState) -> void:
	if content_label == null:
		return
	content_label.text = _build_crafting_text(state)

func _build_crafting_text(state: RVGameState) -> String:
	var lines: Array[String] = []
	lines.append("FORGECRAFT MVP")
	lines.append("Select an item in Inventory, then return here.")
	lines.append("")
	lines.append("Materials")
	lines.append("Embers: " + str(int(state.materials.get("embers", 0))) + "  Shards: " + str(int(state.materials.get("shards", 0))) + "  Runes: " + str(int(state.materials.get("runes", 0))))
	lines.append("Fire " + str(int(state.materials.get("fire_shards", 0))) + " | Cold " + str(int(state.materials.get("cold_shards", 0))) + " | Lightning " + str(int(state.materials.get("lightning_shards", 0))) + " | Void " + str(int(state.materials.get("void_shards", 0))))
	lines.append("Melee " + str(int(state.materials.get("melee_shards", 0))) + " | Trap " + str(int(state.materials.get("trap_shards", 0))) + " | Defense " + str(int(state.materials.get("defense_shards", 0))) + " | Utility " + str(int(state.materials.get("utility_shards", 0))))
	lines.append("")
	var item: Dictionary = RVForgecraftSystem.selected_crafting_item(state)
	if item.is_empty():
		lines.append("No backpack item selected.")
	else:
		lines.append("Selected Item")
		lines.append(RVInventorySystem.item_compact_detail_text(item))
		var warnings: Array[String] = RVItemValidationSystem.validate_item(item)
		if not warnings.is_empty():
			lines.append("")
			lines.append("Validation warnings")
			for warning: String in warnings:
				lines.append(" - " + warning)
	lines.append("")
	lines.append("Controls")
	lines.append("F: forge basic item")
	lines.append("A: add prefix  |  S: add suffix")
	lines.append("U: upgrade affix  |  R: reroll affix")
	lines.append("Backspace/Delete: remove affix")
	lines.append("L: seal affix  |  X: shatter selected item")
	return "\n".join(lines)
