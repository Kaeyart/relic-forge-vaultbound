class_name RVInventorySystem
extends RefCounted

const EQUIPMENT_ORDER: Array[String] = ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring1", "ring2", "relic"]

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

static func normalize_slot(slot_name: String) -> String:
	var n: String = slot_name.to_lower().strip_edges()
	n = n.replace(" ", "_")
	n = n.replace("slot", "")
	n = n.replace("equipment", "")
	match n:
		"helmet", "helm", "head":
			return "head"
		"body", "armor", "body_armor", "chest":
			return "chest"
		"mainhand", "main_hand", "mh", "main", "weapon":
			return "weapon"
		"offhand", "off_hand", "shield", "focus":
			return "offhand"
		"glove", "gloves":
			return "gloves"
		"boot", "boots":
			return "boots"
		"neck", "amulet":
			return "amulet"
		"ringleft", "ring_left", "ring1", "left_ring":
			return "ring1"
		"ringright", "ring_right", "ring2", "right_ring":
			return "ring2"
		"ring":
			return "ring1"
		"relic", "charm":
			return "relic"
	return n

static func select_backpack_index(state: RVGameState, index: int) -> void:
	state.inventory_cursor = clamp(index, 0, max(0, state.backpack.size() - 1))

static func select_equipment_slot(state: RVGameState, slot_name: String) -> void:
	var slot: String = normalize_slot(slot_name)
	var index: int = EQUIPMENT_ORDER.find(slot)
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
	var item: Dictionary = RVItemDB.normalize_item(state.backpack[int(state.inventory_cursor)])
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
	var item: Dictionary = RVItemDB.normalize_item(item_value)
	state.backpack.append(item)
	state.equipped[slot] = {}
	state.recompute_stats()
	state.add_notice("Unequipped " + _item_name(item))

static func stash_selected_backpack_item(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	_clamp_inventory_cursor(state)
	var item: Dictionary = RVItemDB.normalize_item(state.backpack[int(state.inventory_cursor)])
	state.backpack.remove_at(int(state.inventory_cursor))
	state.stash.append(item)
	state.inventory_cursor = clamp(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
	state.add_notice("Stashed " + _item_name(item))

static func withdraw_selected_stash_item(state: RVGameState) -> void:
	if state.stash.is_empty():
		state.add_notice("Stash is empty")
		return
	_clamp_stash_cursor(state)
	var item: Dictionary = RVItemDB.normalize_item(state.stash[int(state.stash_cursor)])
	state.stash.remove_at(int(state.stash_cursor))
	state.backpack.append(item)
	state.stash_cursor = clamp(int(state.stash_cursor), 0, max(0, state.stash.size() - 1))
	state.add_notice("Withdrew " + _item_name(item))

static func deposit_all_backpack(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	var count: int = state.backpack.size()
	for item_value: Dictionary in state.backpack:
		state.stash.append(RVItemDB.normalize_item(item_value))
	state.backpack.clear()
	state.inventory_cursor = 0
	state.add_notice("Deposited " + str(count) + " item(s)")

static func salvage_selected_backpack_item(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return
	_clamp_inventory_cursor(state)
	var item: Dictionary = RVItemDB.normalize_item(state.backpack[int(state.inventory_cursor)])
	state.backpack.remove_at(int(state.inventory_cursor))
	state.inventory_cursor = clamp(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
	var rewards: Dictionary = salvage_rewards(item)
	for key_value: Variant in rewards.keys():
		var key: String = str(key_value)
		state.materials[key] = int(state.materials.get(key, 0)) + int(rewards[key])
	state.add_notice("Salvaged " + _item_name(item) + " for shards")

static func salvage_rewards(item: Dictionary) -> Dictionary:
	var normalized: Dictionary = RVItemDB.normalize_item(item)
	var rewards: Dictionary = {"embers": 1, "shards": 1}
	var rarity: String = str(normalized.get("rarity", "Normal"))
	match rarity:
		"Normal":
			rewards["embers"] = 1
			rewards["shards"] = 0
		"Magic":
			rewards["embers"] = 2
			rewards["shards"] = 1
		"Rare":
			rewards["embers"] = 4
			rewards["shards"] = 3
		"Unique":
			rewards["embers"] = 8
			rewards["shards"] = 4
			rewards["runes"] = 1
		"Crafted":
			rewards["embers"] = 3
			rewards["shards"] = 2
	for affix_value: Variant in normalized.get("prefixes", []) + normalized.get("suffixes", []):
		if typeof(affix_value) != TYPE_DICTIONARY:
			continue
		for tag_value: Variant in affix_value.get("tags", []):
			var shard_key: String = _tag_to_shard(str(tag_value))
			if shard_key != "":
				rewards[shard_key] = int(rewards.get(shard_key, 0)) + 1
	return rewards

static func selected_backpack_item(state: RVGameState) -> Dictionary:
	if state.backpack.is_empty():
		return {}
	_clamp_inventory_cursor(state)
	return RVItemDB.normalize_item(state.backpack[int(state.inventory_cursor)])

static func selected_equipped_item(state: RVGameState) -> Dictionary:
	_clamp_equipment_cursor(state)
	var slot: String = EQUIPMENT_ORDER[int(state.equipment_cursor)]
	var item_value: Variant = state.equipped.get(slot, {})
	if typeof(item_value) == TYPE_DICTIONARY:
		return RVItemDB.normalize_item(item_value)
	return {}

static func selected_stash_item(state: RVGameState) -> Dictionary:
	if state.stash.is_empty():
		return {}
	_clamp_stash_cursor(state)
	return RVItemDB.normalize_item(state.stash[int(state.stash_cursor)])

static func comparison_target_for_item(state: RVGameState, item: Dictionary) -> Dictionary:
	if item.is_empty():
		return {}
	var slot: String = str(item.get("slot", ""))
	if slot == "ring":
		var ring1: Variant = state.equipped.get("ring1", {})
		if typeof(ring1) == TYPE_DICTIONARY and not ring1.is_empty():
			return RVItemDB.normalize_item(ring1)
		var ring2: Variant = state.equipped.get("ring2", {})
		if typeof(ring2) == TYPE_DICTIONARY and not ring2.is_empty():
			return RVItemDB.normalize_item(ring2)
		return {}
	var normalized_slot: String = normalize_slot(slot)
	var equipped_value: Variant = state.equipped.get(normalized_slot, {})
	if typeof(equipped_value) == TYPE_DICTIONARY:
		return RVItemDB.normalize_item(equipped_value)
	return {}

static func item_detail_text_with_compare(state: RVGameState, item: Dictionary) -> String:
	var normalized: Dictionary = RVItemDB.normalize_item(item)
	var text: String = item_detail_text(normalized)
	var target: Dictionary = comparison_target_for_item(state, normalized)
	if target.is_empty():
		return text
	text += "\n\nCompared to equipped " + _slot_label(str(target.get("slot", "item"))) + ":"
	text += _comparison_lines(normalized, target)
	return text

static func item_detail_text(item: Dictionary) -> String:
	if item.is_empty():
		return "No item selected."
	var normalized: Dictionary = RVItemDB.normalize_item(item)
	var lines: Array[String] = []
	lines.append(_item_name(normalized))
	lines.append(str(normalized.get("rarity", "Normal")) + " " + str(normalized.get("base_type", _slot_label(str(normalized.get("slot", "item"))))))
	lines.append("Item Level " + str(int(normalized.get("item_level", 1))))
	var armor_class: String = str(normalized.get("armor_class", ""))
	if armor_class != "":
		lines.append("Armor Class: " + armor_class)
	if normalized.has("description") and str(normalized["description"]) != "":
		lines.append(str(normalized["description"]))
	_add_stat_section(lines, "Implicit", normalized.get("implicit_stats", {}))
	_add_affix_section(lines, "Prefixes", normalized.get("prefixes", []))
	_add_affix_section(lines, "Suffixes", normalized.get("suffixes", []))
	var unique_effects: Array = normalized.get("unique_effects", [])
	if not unique_effects.is_empty():
		lines.append("")
		lines.append("Unique Effects")
		for effect_value: Variant in unique_effects:
			lines.append("  - " + str(effect_value))
	var build_flags: Array = normalized.get("build_flags", normalized.get("flags", []))
	if not build_flags.is_empty():
		lines.append("")
		lines.append("Build Tags: " + _join_strings(build_flags))
	lines.append("")
	lines.append("Forge Potential: " + str(int(normalized.get("forge_potential", 0))) + " / " + str(int(normalized.get("max_forge_potential", normalized.get("forge_potential", 0)))))
	return "\n".join(lines)

static func inventory_panel_text(state: RVGameState) -> String:
	_clamp_inventory_cursor(state)
	var item: Dictionary = selected_backpack_item(state)
	return "Backpack: " + str(state.backpack.size()) + " item(s)\n\n" + item_detail_text_with_compare(state, item)

static func character_panel_text(state: RVGameState) -> String:
	_clamp_equipment_cursor(state)
	var item: Dictionary = selected_equipped_item(state)
	return "Level " + str(state.level) + " · Life " + str(int(state.player_hp)) + "/" + str(int(state.max_hp)) + " · Mana " + str(int(state.player_mana)) + "/" + str(int(state.max_mana)) + "\n\n" + equipped_summary_text(state) + "\n\n" + item_detail_text(item)

static func stash_panel_text(state: RVGameState) -> String:
	_clamp_stash_cursor(state)
	var item: Dictionary = selected_stash_item(state)
	return "Stored: " + str(state.stash.size()) + " item(s) · Backpack: " + str(state.backpack.size()) + "\n\n" + item_detail_text(item)

static func equipped_summary_text(state: RVGameState) -> String:
	var lines: Array[String] = []
	lines.append("Equipped")
	for slot: String in EQUIPMENT_ORDER:
		var item_value: Variant = state.equipped.get(slot, {})
		if typeof(item_value) == TYPE_DICTIONARY and not item_value.is_empty():
			var item: Dictionary = RVItemDB.normalize_item(item_value)
			lines.append(_slot_label(slot) + ": " + str(item.get("name", "Item")))
		else:
			lines.append(_slot_label(slot) + ": Empty")
	return "\n".join(lines)

static func equipped_short_label(state: RVGameState, slot_name: String) -> String:
	var slot: String = normalize_slot(slot_name)
	var item_value: Variant = state.equipped.get(slot, {})
	if typeof(item_value) != TYPE_DICTIONARY or item_value.is_empty():
		return ""
	var item: Dictionary = RVItemDB.normalize_item(item_value)
	return str(item.get("rarity", "Normal")).substr(0, 1)

static func _target_slot_for_item(state: RVGameState, item: Dictionary) -> String:
	var slot: String = normalize_slot(str(item.get("slot", "")))
	if slot == "ring" or str(item.get("slot", "")) == "ring":
		var ring1_value: Variant = state.equipped.get("ring1", {})
		if typeof(ring1_value) != TYPE_DICTIONARY or ring1_value.is_empty():
			return "ring1"
		return "ring2"
	if state.equipped.has(slot):
		return slot
	return ""

static func _comparison_lines(new_item: Dictionary, old_item: Dictionary) -> String:
	var result: String = ""
	var new_stats: Dictionary = new_item.get("stats", {})
	var old_stats: Dictionary = old_item.get("stats", {})
	var keys: Array[String] = []
	for key_value: Variant in new_stats.keys():
		var key: String = str(key_value)
		if not keys.has(key):
			keys.append(key)
	for old_key_value: Variant in old_stats.keys():
		var old_key: String = str(old_key_value)
		if not keys.has(old_key):
			keys.append(old_key)
	if keys.is_empty():
		return "\n  No comparable stats."
	for stat_name: String in keys:
		var delta: float = float(new_stats.get(stat_name, 0.0)) - float(old_stats.get(stat_name, 0.0))
		if abs(delta) < 0.0001:
			continue
		result += "\n  " + _format_delta(stat_name, delta)
	if result == "":
		return "\n  Comparable stats are equal."
	return result

static func _add_stat_section(lines: Array[String], title: String, stats: Dictionary) -> void:
	if stats.is_empty():
		return
	lines.append("")
	lines.append(title)
	for key_value: Variant in stats.keys():
		lines.append("  " + _format_stat(str(key_value), stats[key_value]))

static func _add_affix_section(lines: Array[String], title: String, affixes: Array) -> void:
	if affixes.is_empty():
		return
	lines.append("")
	lines.append(title)
	for affix_value: Variant in affixes:
		if typeof(affix_value) == TYPE_DICTIONARY:
			var affix: Dictionary = affix_value
			var stat_name: String = str(affix.get("stat", "Stat"))
			var value: Variant = affix.get("value", 0.0)
			lines.append("  T" + str(int(affix.get("tier", 1))) + " " + str(affix.get("name", "Affix")) + " · " + _format_stat(stat_name, value))

static func _tag_to_shard(tag: String) -> String:
	match tag:
		"Fire":
			return "fire_shards"
		"Cold":
			return "cold_shards"
		"Lightning":
			return "lightning_shards"
		"Void":
			return "void_shards"
		"Melee", "Physical":
			return "melee_shards"
		"Trap":
			return "trap_shards"
		"Life", "Defense", "Armor", "Resistance":
			return "defense_shards"
		"Mana", "Spirit", "Resource", "Cooldown", "Utility":
			return "utility_shards"
	return ""

static func _item_name(item: Dictionary) -> String:
	return str(item.get("name", "Unnamed Item"))

static func _format_stat(name: String, value: Variant) -> String:
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return name + ": " + str(value)
	var amount: float = float(value)
	var sign: String = "+"
	if amount < 0.0:
		sign = ""
	if abs(amount) < 1.0 and not name.begins_with("Maximum") and name != "Armor" and name.find("on Kill") == -1:
		return sign + str(int(round(amount * 100.0))) + "% " + name
	return sign + str(int(round(amount))) + " " + name

static func _format_delta(name: String, delta: float) -> String:
	var sign: String = "+"
	if delta < 0.0:
		sign = ""
	if abs(delta) < 1.0 and not name.begins_with("Maximum") and name != "Armor" and name.find("on Kill") == -1:
		return sign + str(int(round(delta * 100.0))) + "% " + name
	return sign + str(int(round(delta))) + " " + name

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
		"ring1":
			return "Ring 1"
		"ring2":
			return "Ring 2"
		"relic":
			return "Relic"
	return slot.capitalize()

static func _join_strings(values: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for value: Variant in values:
		parts.append(str(value))
	return ", ".join(parts)

static func _clamp_inventory_cursor(state: RVGameState) -> void:
	state.inventory_cursor = clamp(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))

static func _clamp_stash_cursor(state: RVGameState) -> void:
	state.stash_cursor = clamp(int(state.stash_cursor), 0, max(0, state.stash.size() - 1))

static func _clamp_equipment_cursor(state: RVGameState) -> void:
	state.equipment_cursor = clamp(int(state.equipment_cursor), 0, EQUIPMENT_ORDER.size() - 1)
