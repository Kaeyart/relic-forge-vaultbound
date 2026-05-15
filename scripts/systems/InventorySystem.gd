class_name RVInventorySystem
extends RefCounted

const EQUIPMENT_ORDER: Array[String] = [
	"weapon",
	"offhand",
	"head",
	"chest",
	"gloves",
	"boots",
	"amulet",
	"ring1",
	"ring2",
	"relic",
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
			state.inventory_cursor = max(0, state.inventory_cursor - 1)
			return true
		KEY_S, KEY_DOWN:
			state.inventory_cursor = min(max(0, state.backpack.size() - 1), state.inventory_cursor + 1)
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
			state.equipment_cursor = max(0, state.equipment_cursor - 1)
			return true
		KEY_D, KEY_S, KEY_RIGHT, KEY_DOWN:
			state.equipment_cursor = min(EQUIPMENT_ORDER.size() - 1, state.equipment_cursor + 1)
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
			state.stash_cursor = max(0, state.stash_cursor - 1)
			return true
		KEY_S, KEY_DOWN:
			state.stash_cursor = min(max(0, state.stash.size() - 1), state.stash_cursor + 1)
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

static func selected_backpack_item(state: RVGameState) -> Dictionary:
	if state.backpack.is_empty():
		return {}
	_clamp_inventory_cursor(state)
	var item_value: Variant = state.backpack[state.inventory_cursor]
	if typeof(item_value) == TYPE_DICTIONARY:
		return item_value
	return {}

static func selected_equipped_item(state: RVGameState) -> Dictionary:
	_clamp_equipment_cursor(state)
	var slot: String = EQUIPMENT_ORDER[state.equipment_cursor]
	var item_value: Variant = state.equipped.get(slot, {})
	if typeof(item_value) == TYPE_DICTIONARY:
		return item_value
	return {}

static func select_backpack_index(state: RVGameState, index: int) -> void:
	state.inventory_cursor = clamp(index, 0, max(0, state.backpack.size() - 1))

static func select_equipment_slot(state: RVGameState, slot_name: String) -> void:
	var normalized_slot: String = normalize_slot(slot_name)
	var index: int = EQUIPMENT_ORDER.find(normalized_slot)
	if index >= 0:
		state.equipment_cursor = index

static func select_stash_index(state: RVGameState, index: int) -> void:
	state.stash_cursor = clamp(index, 0, max(0, state.stash.size() - 1))

static func equip_selected_backpack_item(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	_clamp_inventory_cursor(state)
	var item: Dictionary = state.backpack[state.inventory_cursor]
	var target_slot: String = _target_slot_for_item(state, item)
	if target_slot == "":
		state.add_notice("Cannot equip this item")
		return
	state.backpack.remove_at(state.inventory_cursor)
	var previous: Variant = state.equipped.get(target_slot, {})
	if typeof(previous) == TYPE_DICTIONARY and not previous.is_empty():
		state.backpack.append(previous)
	state.equipped[target_slot] = item
	state.equipment_cursor = EQUIPMENT_ORDER.find(target_slot)
	state.inventory_cursor = clamp(state.inventory_cursor, 0, max(0, state.backpack.size() - 1))
	state.recompute_stats()
	state.add_notice("Equipped " + _item_name(item))

static func unequip_selected_item(state: RVGameState) -> void:
	_clamp_equipment_cursor(state)
	var slot: String = EQUIPMENT_ORDER[state.equipment_cursor]
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
	var item: Dictionary = state.backpack[state.inventory_cursor]
	state.backpack.remove_at(state.inventory_cursor)
	state.stash.append(item)
	state.inventory_cursor = clamp(state.inventory_cursor, 0, max(0, state.backpack.size() - 1))
	state.add_notice("Stashed " + _item_name(item))


static func withdraw_stash_index(state: RVGameState, index: int) -> void:
	select_stash_index(state, index)
	withdraw_selected_stash_item(state)

static func withdraw_selected_stash_item(state: RVGameState) -> void:
	if state.stash.is_empty():
		state.add_notice("Stash is empty")
		return
	_clamp_stash_cursor(state)
	var item: Dictionary = state.stash[state.stash_cursor]
	state.stash.remove_at(state.stash_cursor)
	state.backpack.append(item)
	state.stash_cursor = clamp(state.stash_cursor, 0, max(0, state.stash.size() - 1))
	state.add_notice("Withdrew " + _item_name(item))

static func deposit_all_backpack(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	var count: int = state.backpack.size()
	for item_value: Variant in state.backpack:
		if typeof(item_value) == TYPE_DICTIONARY:
			state.stash.append(item_value)
	state.backpack.clear()
	state.inventory_cursor = 0
	state.add_notice("Deposited " + str(count) + " item(s)")

static func salvage_selected_backpack_item(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	_clamp_inventory_cursor(state)
	var item: Dictionary = state.backpack[state.inventory_cursor]
	state.backpack.remove_at(state.inventory_cursor)
	state.inventory_cursor = clamp(state.inventory_cursor, 0, max(0, state.backpack.size() - 1))
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

static func item_detail_text(item: Dictionary) -> String:
	return item_detail_text_with_compare(null, item)

static func item_detail_text_with_compare(state: Variant, item: Dictionary) -> String:
	if item.is_empty():
		return "Empty"
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
		lines.append("Affixes")
		for affix_value: Variant in affixes:
			lines.append("  " + str(affix_value))
	var flags: Array = item.get("flags", [])
	if not flags.is_empty():
		lines.append("")
		lines.append("Special")
		for flag_value: Variant in flags:
			lines.append("  " + _format_flag(str(flag_value)))
	if item.has("forge_potential"):
		lines.append("")
		lines.append("Forge Potential: " + str(item.get("forge_potential", 0)))
	if state != null and state is RVGameState:
		var equipped_item: Dictionary = comparison_target_for_item(state, item)
		if not equipped_item.is_empty() and equipped_item != item:
			lines.append("")
			lines.append("Compared to equipped")
			lines.append(_item_name(equipped_item))
			var comparison_lines: Array[String] = compare_items(item, equipped_item)
			for line: String in comparison_lines:
				lines.append("  " + line)
	return "\n".join(lines)

static func equipped_summary_text(state: RVGameState) -> String:
	var lines: Array[String] = []
	lines.append("Lv " + str(state.level) + "   Gold " + str(state.gold))
	lines.append("Life " + str(int(state.player_hp)) + "/" + str(int(state.max_hp)) + "   Mana " + str(int(state.player_mana)) + "/" + str(int(state.max_mana)))
	lines.append("")
	lines.append("Equipped")
	for slot: String in EQUIPMENT_ORDER:
		var item_value: Variant = state.equipped.get(slot, {})
		if typeof(item_value) == TYPE_DICTIONARY and not item_value.is_empty():
			lines.append(_slot_label(slot) + ": " + _item_name(item_value))
		else:
			lines.append(_slot_label(slot) + ": Empty")
	return "\n".join(lines)

static func equipped_short_label(state: RVGameState, slot: String) -> String:
	var normalized_slot: String = normalize_slot(slot)
	var item_value: Variant = state.equipped.get(normalized_slot, {})
	if typeof(item_value) == TYPE_DICTIONARY and not item_value.is_empty():
		return _short_name(item_value)
	return "Empty"

static func comparison_target_for_item(state: RVGameState, item: Dictionary) -> Dictionary:
	var slot: String = str(item.get("slot", ""))
	if slot == "ring":
		var ring1: Variant = state.equipped.get("ring1", {})
		var ring2: Variant = state.equipped.get("ring2", {})
		if typeof(ring1) == TYPE_DICTIONARY and not ring1.is_empty():
			return ring1
		if typeof(ring2) == TYPE_DICTIONARY and not ring2.is_empty():
			return ring2
		return {}
	var target_slot: String = normalize_slot(slot)
	var equipped_value: Variant = state.equipped.get(target_slot, {})
	if typeof(equipped_value) == TYPE_DICTIONARY:
		return equipped_value
	return {}

static func compare_items(candidate: Dictionary, equipped: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if equipped.is_empty():
		return lines
	var candidate_stats: Dictionary = candidate.get("stats", {})
	var equipped_stats: Dictionary = equipped.get("stats", {})
	var keys: Array[String] = []
	for key_value: Variant in candidate_stats.keys():
		var key: String = str(key_value)
		if not keys.has(key):
			keys.append(key)
	for key_value2: Variant in equipped_stats.keys():
		var key2: String = str(key_value2)
		if not keys.has(key2):
			keys.append(key2)
	if keys.is_empty():
		lines.append("No numeric stat comparison available")
		return lines
	for stat_name: String in keys:
		var new_value: float = _numeric_stat(candidate_stats.get(stat_name, 0.0))
		var old_value: float = _numeric_stat(equipped_stats.get(stat_name, 0.0))
		var delta: float = new_value - old_value
		if abs(delta) < 0.0001:
			continue
		lines.append(_format_delta(stat_name, delta))
	if lines.is_empty():
		lines.append("Stat lines are roughly equal")
	return lines

static func inventory_panel_text(state: RVGameState) -> String:
	_clamp_inventory_cursor(state)
	var lines: Array[String] = []
	lines.append("INVENTORY")
	lines.append("Backpack: " + str(state.backpack.size()) + " item(s)")
	lines.append("Controls: W/S select · Enter/E equip · B stash · X salvage · Tab character · Esc close")
	lines.append("")
	if state.backpack.is_empty():
		lines.append("Backpack is empty.")
		lines.append("Clear a combat room and open the reward chest.")
	else:
		for i: int in range(state.backpack.size()):
			var item: Dictionary = state.backpack[i]
			var marker: String = "> " if i == state.inventory_cursor else "  "
			lines.append(marker + _item_list_line(item))
	lines.append("")
	lines.append("SELECTED ITEM")
	lines.append(_selected_backpack_detail(state))
	lines.append("")
	lines.append("MATERIALS Gold " + str(state.gold) + " Embers " + str(state.materials.get("embers", 0)) + " Shards " + str(state.materials.get("shards", 0)) + " Runes " + str(state.materials.get("runes", 0)) + " Echo Glass " + str(state.materials.get("echo_glass", 0)))
	return "\n".join(lines)

static func character_panel_text(state: RVGameState) -> String:
	_clamp_equipment_cursor(state)
	var lines: Array[String] = []
	lines.append("CHARACTER")
	lines.append("Level " + str(state.level) + " · Life " + str(int(state.player_hp)) + "/" + str(int(state.max_hp)) + " · Mana " + str(int(state.player_mana)) + "/" + str(int(state.max_mana)))
	lines.append("Controls: W/S select gear · Enter/E/X unequip · I inventory · Esc close")
	lines.append("")
	lines.append("EQUIPMENT")
	for i: int in range(EQUIPMENT_ORDER.size()):
		var slot: String = EQUIPMENT_ORDER[i]
		var item_value: Variant = state.equipped.get(slot, {})
		var marker: String = "> " if i == state.equipment_cursor else "  "
		if typeof(item_value) == TYPE_DICTIONARY and not item_value.is_empty():
			lines.append(marker + _slot_label(slot) + ": " + _item_list_line(item_value))
		else:
			lines.append(marker + _slot_label(slot) + ": Empty")
	lines.append("")
	lines.append("SELECTED GEAR")
	var selected_value: Dictionary = selected_equipped_item(state)
	if not selected_value.is_empty():
		lines.append(item_detail_text(selected_value))
	else:
		var selected_slot: String = EQUIPMENT_ORDER[state.equipment_cursor]
		lines.append("No item equipped in " + _slot_label(selected_slot) + ".")
	lines.append("")
	lines.append("SUMMARY")
	lines.append("Kills " + str(state.kills) + " · Deaths " + str(state.deaths) + " · Rooms Cleared " + str(state.rooms_cleared))
	return "\n".join(lines)

static func stash_panel_text(state: RVGameState) -> String:
	_clamp_stash_cursor(state)
	var lines: Array[String] = []
	lines.append("STASH")
	lines.append("Stored: " + str(state.stash.size()) + " item(s) · Backpack: " + str(state.backpack.size()))
	lines.append("Controls: W/S select · Enter/E withdraw · X deposit all backpack · I inventory · Esc close")
	lines.append("")
	if state.stash.is_empty():
		lines.append("Stash is empty.")
		lines.append("Use B from Inventory to stash one item, or X here to deposit all backpack items.")
	else:
		for i: int in range(state.stash.size()):
			var item: Dictionary = state.stash[i]
			var marker: String = "> " if i == state.stash_cursor else "  "
			lines.append(marker + _item_list_line(item))
	lines.append("")
	lines.append("SELECTED STASH ITEM")
	if state.stash.is_empty():
		lines.append("None")
	else:
		lines.append(item_detail_text(state.stash[state.stash_cursor]))
	return "\n".join(lines)

static func _selected_backpack_detail(state: RVGameState) -> String:
	if state.backpack.is_empty():
		return "None"
	_clamp_inventory_cursor(state)
	return item_detail_text_with_compare(state, state.backpack[state.inventory_cursor])

static func _target_slot_for_item(state: RVGameState, item: Dictionary) -> String:
	var slot: String = str(item.get("slot", ""))
	if slot == "ring":
		var ring1_value: Variant = state.equipped.get("ring1", {})
		var ring1_empty: bool = typeof(ring1_value) != TYPE_DICTIONARY or ring1_value.is_empty()
		if ring1_empty:
			return "ring1"
		return "ring2"
	var normalized_slot: String = normalize_slot(slot)
	if state.equipped.has(normalized_slot):
		return normalized_slot
	return ""

static func normalize_slot(slot_name: String) -> String:
	var slot: String = slot_name.strip_edges().to_lower()
	slot = slot.replace(" ", "")
	slot = slot.replace("slot", "")
	match slot:
		"helmet", "helm", "head":
			return "head"
		"mainhand", "main", "weapon":
			return "weapon"
		"offhand", "shield":
			return "offhand"
		"body", "bodyarmor", "armor", "chest":
			return "chest"
		"glove", "gloves", "hands":
			return "gloves"
		"boot", "boots", "feet":
			return "boots"
		"neck", "necklace", "amulet":
			return "amulet"
		"ring", "ring1", "leftring":
			return "ring1" if slot == "ring1" or slot == "leftring" else "ring"
		"ring2", "rightring":
			return "ring2"
		"relic", "charm":
			return "relic"
	return slot

static func _item_list_line(item: Dictionary) -> String:
	var rarity: String = str(item.get("rarity", "Common"))
	var slot: String = _slot_label(str(item.get("slot", "item")))
	return "[" + rarity + "] " + _item_name(item) + " · " + slot

static func _item_name(item: Dictionary) -> String:
	return str(item.get("name", "Unnamed Item"))

static func _short_name(item: Dictionary) -> String:
	var name: String = _item_name(item)
	if name.length() > 16:
		return name.substr(0, 15) + "…"
	return name

static func _format_stat(name: String, value: Variant) -> String:
	var amount: float = _numeric_stat(value)
	if _is_percent_stat(name, amount):
		return _signed_percent(amount) + " " + name
	return _signed_number(amount) + " " + name

static func _format_delta(name: String, delta: float) -> String:
	var prefix: String = "+" if delta > 0.0 else ""
	if _is_percent_stat(name, delta):
		return prefix + str(int(round(delta * 100.0))) + "% " + name
	return prefix + str(int(round(delta))) + " " + name

static func _numeric_stat(value: Variant) -> float:
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)
	return 0.0

static func _is_percent_stat(name: String, amount: float) -> bool:
	if abs(amount) < 1.0:
		return true
	var lower: String = name.to_lower()
	return lower.contains("chance") or lower.contains("speed") or lower.contains("reduction") or lower.contains("damage") or lower.contains("resistance")

static func _signed_percent(amount: float) -> String:
	var prefix: String = "+" if amount >= 0.0 else ""
	return prefix + str(int(round(amount * 100.0))) + "%"

static func _signed_number(amount: float) -> String:
	var prefix: String = "+" if amount >= 0.0 else ""
	return prefix + str(int(round(amount)))

static func _format_flag(flag_name: String) -> String:
	return flag_name.replace("_", " ").capitalize()

static func _slot_label(slot: String) -> String:
	match normalize_slot(slot):
		"weapon":
			return "Weapon"
		"offhand":
			return "Offhand"
		"head":
			return "Helmet"
		"chest":
			return "Chest"
		"gloves":
			return "Gloves"
		"boots":
			return "Boots"
		"amulet":
			return "Amulet"
		"ring":
			return "Ring"
		"ring1":
			return "Ring 1"
		"ring2":
			return "Ring 2"
		"relic":
			return "Relic"
	return slot.capitalize()

static func _clamp_inventory_cursor(state: RVGameState) -> void:
	state.inventory_cursor = clamp(state.inventory_cursor, 0, max(0, state.backpack.size() - 1))

static func _clamp_stash_cursor(state: RVGameState) -> void:
	state.stash_cursor = clamp(state.stash_cursor, 0, max(0, state.stash.size() - 1))

static func _clamp_equipment_cursor(state: RVGameState) -> void:
	state.equipment_cursor = clamp(state.equipment_cursor, 0, EQUIPMENT_ORDER.size() - 1)
