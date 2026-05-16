class_name RVClassAscendancySystem
extends RefCounted

static func ensure_defaults(state: RVGameState) -> void:
	if not RVClassDB.has_class(state.class_id):
		state.class_id = RVClassDB.default_id()
	if state.passive_atlas_allocated.is_empty():
		state.passive_atlas_allocated.append("center")
	if not state.passive_atlas_allocated.has("center"):
		state.passive_atlas_allocated.insert(0, "center")
	if state.ascendancy_id != "":
		var legal: Array[String] = RVAscendancyDB.ids_for_class(state.class_id)
		if not legal.has(state.ascendancy_id):
			state.ascendancy_id = ""
			state.ascendancy_allocated.clear()
			state.ascendancy_refund_stack.clear()

static func handle_panel_key(state: RVGameState, keycode: int) -> bool:
	match keycode:
		KEY_A:
			cycle_passive_cursor(state, -1)
			return true
		KEY_D:
			cycle_passive_cursor(state, 1)
			return true
		KEY_ENTER:
			return allocate_selected_passive(state)
		KEY_BACKSPACE, KEY_DELETE:
			return refund_last_passive(state)
		KEY_C:
			cycle_class(state)
			return true
		KEY_V:
			cycle_ascendancy(state)
			return true
		KEY_G:
			return allocate_first_available_ascendancy(state)
	return false

static func cycle_class(state: RVGameState) -> void:
	state.class_id = RVClassDB.next_id(state.class_id)
	state.ascendancy_id = ""
	state.ascendancy_allocated.clear()
	state.ascendancy_refund_stack.clear()
	state.passive_atlas_cursor = 0
	state.add_notice("Class: " + RVClassDB.display_name(state.class_id))
	state.recompute_stats()

static func cycle_ascendancy(state: RVGameState) -> void:
	if state.level < 10:
		state.add_notice("Ascendancy unlocks at level 10")
		return
	state.ascendancy_id = RVAscendancyDB.next_for_class(state.class_id, state.ascendancy_id)
	state.ascendancy_allocated.clear()
	state.ascendancy_refund_stack.clear()
	state.ascendancy_cursor = 0
	state.add_notice("Ascendancy: " + RVAscendancyDB.display_name(state.ascendancy_id))
	state.recompute_stats()

static func cycle_passive_cursor(state: RVGameState, direction: int) -> void:
	var ids_for_tree: Array[String] = RVPassiveAtlasDB.node_ids_for_class(state.class_id)
	if ids_for_tree.is_empty():
		return
	state.passive_atlas_cursor = wrapi(state.passive_atlas_cursor + direction, 0, ids_for_tree.size())

static func allocate_selected_passive(state: RVGameState) -> bool:
	var node_id: String = RVPassiveAtlasDB.selected_node_id(state)
	if node_id == "center":
		state.add_notice("Center is already allocated")
		return true
	if state.mastery_points <= 0:
		state.add_notice("No mastery points")
		return true
	if not RVPassiveAtlasDB.can_allocate(state, node_id):
		state.add_notice("Passive requires a connected node")
		return true
	state.passive_atlas_allocated.append(node_id)
	state.passive_atlas_refund_stack.append(node_id)
	state.mastery_points -= 1
	state.refund_points += 1
	state.recompute_stats()
	state.add_notice("Allocated: " + str(RVPassiveAtlasDB.node_data(node_id).get("name", node_id)))
	return true

static func refund_last_passive(state: RVGameState) -> bool:
	if state.passive_atlas_refund_stack.is_empty():
		state.add_notice("No passive to refund")
		return true
	if state.refund_points <= 0:
		state.add_notice("No refund points")
		return true
	var node_id: String = state.passive_atlas_refund_stack.pop_back()
	state.passive_atlas_allocated.erase(node_id)
	state.refund_points -= 1
	state.mastery_points += 1
	state.recompute_stats()
	state.add_notice("Refunded passive")
	return true

static func allocate_first_available_ascendancy(state: RVGameState) -> bool:
	if state.ascendancy_id == "":
		cycle_ascendancy(state)
		if state.ascendancy_id == "":
			return true
	if state.ascendancy_points <= 0:
		state.add_notice("No ascendancy points")
		return true
	for node_id: String in RVAscendancyDB.node_ids(state.ascendancy_id):
		if state.ascendancy_allocated.has(node_id):
			continue
		var data: Dictionary = RVAscendancyDB.node_data(node_id)
		var cost: int = int(data.get("cost", 1))
		if state.ascendancy_points < cost:
			continue
		state.ascendancy_allocated.append(node_id)
		state.ascendancy_refund_stack.append(node_id)
		state.ascendancy_points -= cost
		state.recompute_stats()
		state.add_notice("Ascendancy node allocated")
		return true
	state.add_notice("No available ascendancy node")
	return true

static func collect_stats(state: RVGameState) -> Dictionary:
	var result: Dictionary = {}
	_add_stats(result, RVClassDB.class_stats(state.class_id))
	for node_id: String in state.passive_atlas_allocated:
		var node: Dictionary = RVPassiveAtlasDB.node_data(node_id)
		_add_stats(result, Dictionary(node.get("stats", {})))
	if state.ascendancy_id != "":
		_add_stats(result, Dictionary(RVAscendancyDB.data(state.ascendancy_id).get("stats", {})))
	for asc_node_id: String in state.ascendancy_allocated:
		var asc_node: Dictionary = RVAscendancyDB.node_data(asc_node_id)
		_add_stats(result, Dictionary(asc_node.get("stats", {})))
	return result

static func collect_flags(state: RVGameState) -> Array[String]:
	var result: Array[String] = []
	_add_flags(result, RVClassDB.class_flags(state.class_id))
	for node_id: String in state.passive_atlas_allocated:
		var node: Dictionary = RVPassiveAtlasDB.node_data(node_id)
		_add_flags(result, Array(node.get("flags", [])))
	if state.ascendancy_id != "":
		_add_flags(result, Array(RVAscendancyDB.data(state.ascendancy_id).get("flags", [])))
	for asc_node_id: String in state.ascendancy_allocated:
		var asc_node: Dictionary = RVAscendancyDB.node_data(asc_node_id)
		_add_flags(result, Array(asc_node.get("flags", [])))
	return result

static func _add_stats(target: Dictionary, source: Dictionary) -> void:
	for key: Variant in source.keys():
		var name: String = str(key)
		target[name] = float(target.get(name, 0.0)) + float(source[key])

static func _add_flags(target: Array[String], source: Array) -> void:
	for value: Variant in source:
		var flag: String = str(value)
		if flag != "" and not target.has(flag):
			target.append(flag)

static func passive_summary(state: RVGameState) -> String:
	var selected_id: String = RVPassiveAtlasDB.selected_node_id(state)
	var selected: Dictionary = RVPassiveAtlasDB.node_data(selected_id)
	var text: String = "Class: " + RVClassDB.display_name(state.class_id) + "\n"
	text += "Ascendancy: " + RVAscendancyDB.display_name(state.ascendancy_id) + "\n"
	text += "Mastery Points: " + str(state.mastery_points) + "   Refund: " + str(state.refund_points) + "\n"
	text += "Ascendancy Points: " + str(state.ascendancy_points) + "\n\n"
	text += "Selected Passive: " + str(selected.get("name", selected_id)) + "\n"
	text += str(selected.get("type", "Passive")) + " — " + str(selected.get("description", "")) + "\n"
	text += "Allocated: " + ("yes" if state.passive_atlas_allocated.has(selected_id) else "no") + "\n\n"
	text += "Allocated Passives:\n"
	for node_id: String in state.passive_atlas_allocated:
		text += "- " + str(RVPassiveAtlasDB.node_data(node_id).get("name", node_id)) + "\n"
	text += "\nControls: A/D select · Enter allocate · Backspace refund · C class · V ascendancy · G ascendancy node"
	return text
