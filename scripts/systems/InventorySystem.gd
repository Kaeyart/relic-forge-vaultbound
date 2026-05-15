class_name RVInventorySystem
extends RefCounted

const EQUIPMENT_ORDER: Array[String] = [
	"weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring1", "ring2", "relic"
]

static func handle_panel_key(state: RVGameState, keycode: int) -> bool:
	match state.panel_mode:
		"inventory":
			return _handle_inventory_key(state, keycode)
		"character":
			return _handle_character_key(state, keycode)
		"stash":
			return _handle_stash_key(state, keycode)
	return false


static func _handle_inventory_key(state: RVGameState, keycode: int) -> bool:
	_clamp_inventory_cursor(state)
	match keycode:
		KEY_W, KEY_UP:
			state.inventory_cursor = max(0, int(state.inventory_cursor) - 1)
			return true
		KEY_S, KEY_DOWN:
			state.inventory_cursor = min(max(0, state.backpack.size() - 1), int(state.inventory_cursor) + 1)
			return true
		KEY_ENTER, KEY_KP_ENTER, KEY_E:
			equip_selected_backpack_item(state)
			return true
		KEY_B:
			stash_selected_backpack_item(state)
			return true
		KEY_X, KEY_DELETE:
			salvage_selected_backpack_item(state)
			return true
		KEY_TAB:
			state.panel_mode = "character"
			return true
	return false


static func _handle_character_key(state: RVGameState, keycode: int) -> bool:
	_clamp_equipment_cursor(state)
	match keycode:
		KEY_A, KEY_W, KEY_LEFT, KEY_UP:
			state.equipment_cursor = max(0, int(state.equipment_cursor) - 1)
			return true
		KEY_D, KEY_S, KEY_RIGHT, KEY_DOWN:
			state.equipment_cursor = min(EQUIPMENT_ORDER.size() - 1, int(state.equipment_cursor) + 1)
			return true
		KEY_ENTER, KEY_KP_ENTER, KEY_X, KEY_E:
			unequip_selected_item(state)
			return true
		KEY_I, KEY_TAB:
			state.panel_mode = "inventory"
			return true
	return false


static func _handle_stash_key(state: RVGameState, keycode: int) -> bool:
	_clamp_stash_cursor(state)
	match keycode:
		KEY_W, KEY_UP:
			state.stash_cursor = max(0, int(state.stash_cursor) - 1)
			return true
		KEY_S, KEY_DOWN:
			state.stash_cursor = min(max(0, state.stash.size() - 1), int(state.stash_cursor) + 1)
			return true
		KEY_ENTER, KEY_KP_ENTER, KEY_E:
			withdraw_selected_stash_item(state)
			return true
		KEY_X:
			deposit_all_backpack(state)
			return true
		KEY_I, KEY_B:
			state.panel_mode = "inventory"
			return true
	return false


static func select_backpack_index(state: RVGameState, index: int) -> void:
	state.inventory_cursor = clamp(index, 0, max(0, state.backpack.size() - 1))


static func select_equipment_slot(state: RVGameState, slot_name: String) -> void:
	var index: int = EQUIPMENT_ORDER.find(slot_name)
	if index >= 0:
		state.equipment_cursor = index


static func select_stash_index(state: RVGameState, index: int) -> void:
	state.stash_cursor = clamp(index, 0, max(0, state.stash.size() - 1))


static func equip_backpack_index(state: RVGameState, index: int) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	select_backpack_index(state, index)
	equip_selected_backpack_item(state)


static func stash_backpack_index(state: RVGameState, index: int) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	select_backpack_index(state, index)
	stash_selected_backpack_item(state)


static func salvage_backpack_index(state: RVGameState, index: int) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	select_backpack_index(state, index)
	salvage_selected_backpack_item(state)


static func unequip_slot(state: RVGameState, slot_name: String) -> void:
	select_equipment_slot(state, slot_name)
	unequip_selected_item(state)


static func equip_selected_backpack_item(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	_clamp_inventory_cursor(state)
	var item: Dictionary = state.backpack[int(state.inventory_cursor)]
	var target_slot: String = _target_slot_for_item(state, item)
	if target_slot == "":
		state.add_notice("Cannot equip this item")
		return

	state.backpack.remove_at(int(state.inventory_cursor))
	var previous: Variant = state.equipped.get(target_slot, {})
	if typeof(previous) == TYPE_DICTIONARY and not previous.is_empty():
		state.backpack.append(previous)
	state.equipped[target_slot] = item
	state.inventory_cursor = clamp(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
	state.recompute_stats()
	state.add_notice("Equipped " + _item_name(item))


static func unequip_selected_item(state: RVGameState) -> void:
	_clamp_equipment_cursor(state)
	var slot: String = EQUIPMENT_ORDER[int(state.equipment_cursor)]
	var item_value: Variant = state.equipped.get(slot, {})
	if typeof(item_value) != TYPE_DICTIONARY or item_value.is_empty():
		state.add_notice(_slot_label(slot) + " is empty")
		return
	var item: Dictionary = item_value
	state.backpack.append(item)
	state.equipped[slot] = {}
	state.recompute_stats()
	state.add_notice("Unequipped " + _item_name(item))


static func stash_selected_backpack_item(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	_clamp_inventory_cursor(state)
	var item: Dictionary = state.backpack[int(state.inventory_cursor)]
	state.backpack.remove_at(int(state.inventory_cursor))
	state.stash.append(item)
	state.inventory_cursor = clamp(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
	state.add_notice("Stashed " + _item_name(item))


static func withdraw_selected_stash_item(state: RVGameState) -> void:
	if state.stash.is_empty():
		state.add_notice("Stash is empty")
		return
	_clamp_stash_cursor(state)
	var item: Dictionary = state.stash[int(state.stash_cursor)]
	state.stash.remove_at(int(state.stash_cursor))
	state.backpack.append(item)
	state.stash_cursor = clamp(int(state.stash_cursor), 0, max(0, state.stash.size() - 1))
	state.add_notice("Withdrew " + _item_name(item))


static func deposit_all_backpack(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	var count: int = state.backpack.size()
	for item: Dictionary in state.backpack:
		state.stash.append(item)
	state.backpack.clear()
	state.inventory_cursor = 0
	state.add_notice("Deposited " + str(count) + " item(s)")


static func salvage_selected_backpack_item(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	_clamp_inventory_cursor(state)
	var item: Dictionary = state.backpack[int(state.inventory_cursor)]
	state.backpack.remove_at(int(state.inventory_cursor))
	state.inventory_cursor = clamp(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))

	var rarity: String = str(item.get("rarity", "Common"))
	var embers: int = 2
	var shards: int = 1
	var runes: int = 0
	var echo_glass: int = 0
	match rarity:
		"Magic":
			embers = 3
			shards = 2
		"Rare":
			embers = 5
			shards = 4
			if state.rng.randf() < 0.35:
				runes = 1
		"Legendary":
			embers = 8
			shards = 6
			runes = 1
			echo_glass = 1
		"Crafted":
			embers = 4
			shards = 3
			runes = 1

	state.materials["embers"] = int(state.materials.get("embers", 0)) + embers
	state.materials["shards"] = int(state.materials.get("shards", 0)) + shards
	state.materials["runes"] = int(state.materials.get("runes", 0)) + runes
	state.materials["echo_glass"] = int(state.materials.get("echo_glass", 0)) + echo_glass
	state.add_notice("Salvaged " + _item_name(item))


static func selected_backpack_item(state: RVGameState) -> Dictionary:
	if state.backpack.is_empty():
		return {}
	_clamp_inventory_cursor(state)
	return state.backpack[int(state.inventory_cursor)]


static func selected_equipped_item(state: RVGameState) -> Dictionary:
	_clamp_equipment_cursor(state)
	var slot: String = EQUIPMENT_ORDER[int(state.equipment_cursor)]
	var item_value: Variant = state.equipped.get(slot, {})
	if typeof(item_value) == TYPE_DICTIONARY:
		return item_value
	return {}


static func selected_stash_item(state: RVGameState) -> Dictionary:
	if state.stash.is_empty():
		return {}
	_clamp_stash_cursor(state)
	return state.stash[int(state.stash_cursor)]


static func item_detail_text(item: Dictionary) -> String:
	if item.is_empty():
		return "No item selected."
	var lines: Array[String] = []
	lines.append(_item_name(item))
	lines.append(str(item.get("rarity", "Common")) + " " + _slot_label(str(item.get("slot", "item"))))
	if item.has("description"):
		lines.append(str(item["description"]))
	var stats: Dictionary = item.get("stats", {})
	if not stats.is_empty():
		lines.append("")
		lines.append("Stats")
		for key: Variant in stats.keys():
			lines.append("  " + _format_stat(str(key), stats[key]))
	var affixes: Array = item.get("affixes", [])
	if not affixes.is_empty():
		lines.append("")
		lines.append("Affixes: " + ", ".join(PackedStringArray(affixes)))
	var flags: Array = item.get("flags", [])
	if not flags.is_empty():
		lines.append("Special: " + ", ".join(PackedStringArray(flags)))
	if item.has("forge_potential"):
		lines.append("Forge Potential: " + str(item.get("forge_potential", 0)))
	return "\n".join(lines)


static func inventory_panel_text(state: RVGameState) -> String:
	_clamp_inventory_cursor(state)
	var item: Dictionary = selected_backpack_item(state)
	return "Backpack: " + str(state.backpack.size()) + " item(s)\n\n" + item_detail_text(item)


static func character_panel_text(state: RVGameState) -> String:
	_clamp_equipment_cursor(state)
	var item: Dictionary = selected_equipped_item(state)
	return "Level " + str(state.level) + " · Life " + str(int(state.player_hp)) + "/" + str(int(state.max_hp)) + " · Mana " + str(int(state.player_mana)) + "/" + str(int(state.max_mana)) + "\n\n" + item_detail_text(item)


static func stash_panel_text(state: RVGameState) -> String:
	_clamp_stash_cursor(state)
	var item: Dictionary = selected_stash_item(state)
	return "Stored: " + str(state.stash.size()) + " item(s) · Backpack: " + str(state.backpack.size()) + "\n\n" + item_detail_text(item)


static func _target_slot_for_item(state: RVGameState, item: Dictionary) -> String:
	var slot: String = str(item.get("slot", ""))
	if slot == "ring":
		var ring1_value: Variant = state.equipped.get("ring1", {})
		if typeof(ring1_value) != TYPE_DICTIONARY or ring1_value.is_empty():
			return "ring1"
		return "ring2"
	if state.equipped.has(slot):
		return slot
	return ""


static func _item_list_line(item: Dictionary) -> String:
	var rarity: String = str(item.get("rarity", "Common"))
	var slot: String = _slot_label(str(item.get("slot", "item")))
	return "[" + rarity + "] " + _item_name(item) + " · " + slot


static func _item_name(item: Dictionary) -> String:
	return str(item.get("name", "Unnamed Item"))


static func _format_stat(name: String, value: Variant) -> String:
	var amount: float = 0.0
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		amount = float(value)
	else:
		return name + ": " + str(value)
	if abs(amount) < 1.0 and name.find("Maximum") == -1:
		return "+" + str(int(round(amount * 100.0))) + "% " + name
	return "+" + str(int(round(amount))) + " " + name


static func _slot_label(slot: String) -> String:
	match slot:
		"weapon": return "Weapon"
		"offhand": return "Offhand"
		"head": return "Helmet"
		"chest": return "Chest"
		"gloves": return "Gloves"
		"boots": return "Boots"
		"amulet": return "Amulet"
		"ring": return "Ring"
		"ring1": return "Ring 1"
		"ring2": return "Ring 2"
		"relic": return "Relic"
	return slot.capitalize()


static func _clamp_inventory_cursor(state: RVGameState) -> void:
	state.inventory_cursor = clamp(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))


static func _clamp_stash_cursor(state: RVGameState) -> void:
	state.stash_cursor = clamp(int(state.stash_cursor), 0, max(0, state.stash.size() - 1))


static func _clamp_equipment_cursor(state: RVGameState) -> void:
	state.equipment_cursor = clamp(int(state.equipment_cursor), 0, EQUIPMENT_ORDER.size() - 1)
