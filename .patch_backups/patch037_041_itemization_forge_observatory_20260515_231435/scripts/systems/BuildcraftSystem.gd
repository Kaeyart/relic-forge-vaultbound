class_name RVBuildcraftSystem
extends RefCounted

static func handle_key(state: RVGameState, keycode: int) -> bool:
	if state.panel_mode == "":
		return false

	match state.panel_mode:
		"inventory":
			return handle_inventory_key(state, keycode)
		"crafting":
			return handle_crafting_key(state, keycode)
		"passive_atlas":
			return handle_passive_key(state, keycode)
		"skill_gems":
			return handle_skill_gem_key(state, keycode)
		"stash":
			return handle_stash_key(state, keycode)

	return false


static func handle_inventory_key(state: RVGameState, keycode: int) -> bool:
	if keycode == KEY_E:
		equip_first_backpack_item(state)
		return true
	if keycode == KEY_X:
		salvage_first_backpack_item(state)
		return true
	return false


static func handle_crafting_key(state: RVGameState, keycode: int) -> bool:
	if keycode == KEY_F:
		var item: Dictionary = RVItemDB.craft_basic_item(state)
		state.backpack.append(item)
		state.add_notice("Crafted Basic Item")
		return true
	return false


static func handle_passive_key(state: RVGameState, keycode: int) -> bool:
	if keycode == KEY_ENTER:
		allocate_first_available_passive(state)
		return true
	if keycode == KEY_BACKSPACE:
		refund_first_passive(state)
		return true
	return false


static func handle_skill_gem_key(state: RVGameState, keycode: int) -> bool:
	if keycode >= KEY_1 and keycode <= KEY_6:
		var index: int = keycode - KEY_1
		var skills: Array = RVSkillDB.names()
		if index >= 0 and index < skills.size():
			RVSkillSystem.toggle_skill_loadout(state, str(skills[index]))
		return true
	return false


static func handle_stash_key(state: RVGameState, keycode: int) -> bool:
	if keycode == KEY_E:
		for item: Dictionary in state.backpack:
			state.stash.append(item)
		state.backpack.clear()
		state.add_notice("Backpack deposited")
		return true

	if keycode == KEY_X:
		if state.stash.size() > 0:
			var item_value: Dictionary = state.stash[0]
			state.stash.remove_at(0)
			state.backpack.append(item_value)
			state.add_notice("Withdrew item")
		return true

	return false


static func equip_first_backpack_item(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack empty")
		return

	var item: Dictionary = state.backpack[0]
	state.backpack.remove_at(0)

	var slot_name: String = str(item.get("slot", "relic"))
	if slot_name == "ring":
		if state.equipped["ring1"].is_empty():
			slot_name = "ring1"
		else:
			slot_name = "ring2"

	if not state.equipped.has(slot_name):
		slot_name = "relic"

	var old_item: Variant = state.equipped[slot_name]
	state.equipped[slot_name] = item

	if typeof(old_item) == TYPE_DICTIONARY and not old_item.is_empty():
		state.backpack.append(old_item)

	state.recompute_stats()
	state.add_notice("Equipped " + str(item.get("name", "Item")))


static func salvage_first_backpack_item(state: RVGameState) -> void:
	if state.backpack.is_empty():
		state.add_notice("Backpack empty")
		return

	state.backpack.remove_at(0)
	state.materials["embers"] = int(state.materials.get("embers", 0)) + 3
	state.materials["shards"] = int(state.materials.get("shards", 0)) + 1
	state.add_notice("Item salvaged")


static func allocate_first_available_passive(state: RVGameState) -> void:
	if state.mastery_points <= 0:
		state.add_notice("No mastery points")
		return

	for node_id: String in state.passive_nodes.keys():
		if not bool(state.passive_nodes[node_id]):
			state.passive_nodes[node_id] = true
			state.mastery_points -= 1
			state.refund_points += 1
			state.recompute_stats()
			state.add_notice("Passive allocated")
			return

	state.add_notice("All starter passives allocated")


static func refund_first_passive(state: RVGameState) -> void:
	if state.refund_points <= 0:
		state.add_notice("No refund points")
		return

	for node_id: String in state.passive_nodes.keys():
		if bool(state.passive_nodes[node_id]):
			state.passive_nodes[node_id] = false
			state.refund_points -= 1
			state.mastery_points += 1
			state.recompute_stats()
			state.add_notice("Passive refunded")
			return
