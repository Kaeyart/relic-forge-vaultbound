class_name RVClassAscendancySystem
extends RefCounted

static func ensure_defaults(state: Object) -> void:
	if str(state.get("character_slot_id")) == "":
		state.set("character_slot_id", "slot_0")
	if str(state.get("character_name")) == "":
		state.set("character_name", "Character 1")
	if str(state.get("character_class_id")) == "":
		state.set("character_class_id", "sorceress")
	if not RVClassDB.has_class(str(state.get("character_class_id"))):
		state.set("character_class_id", "sorceress")
	if state.get("passive_atlas_allocated") == null:
		state.set("passive_atlas_allocated", [])
	if state.get("passive_atlas_refund_stack") == null:
		state.set("passive_atlas_refund_stack", [])
	if state.get("ascendancy_allocated") == null:
		state.set("ascendancy_allocated", [])
	var allocated: Array = Array(state.get("passive_atlas_allocated"))
	if not allocated.has("center"):
		allocated.append("center")
	var start_node: String = RVClassDB.start_node(str(state.get("character_class_id")))
	if bool(state.get("character_class_locked")) and not allocated.has(start_node):
		allocated.append(start_node)
	state.set("passive_atlas_allocated", allocated)
	state.set("ascendancy_points", available_ascendancy_points(state))

static func class_name(state: Object) -> String:
	return RVClassDB.name_for(str(state.get("character_class_id")))

static func ascendancy_name(state: Object) -> String:
	return RVAscendancyDB.name_for(str(state.get("ascendancy_id")))

static func can_change_class(state: Object) -> bool:
	return not bool(state.get("character_class_locked")) and int(state.get("level")) <= 1

static func cycle_class(state: Object) -> bool:
	ensure_defaults(state)
	if not can_change_class(state):
		if state.has_method("add_notice"):
			state.call("add_notice", "Class is locked to this character")
		return false
	state.set("character_class_id", RVClassDB.next_class_id(str(state.get("character_class_id"))))
	state.set("ascendancy_id", "")
	state.set("ascendancy_allocated", [])
	state.set("passive_atlas_allocated", ["center"])
	ensure_defaults(state)
	if state.has_method("recompute_stats"):
		state.call("recompute_stats")
	return true

static func lock_class(state: Object) -> bool:
	ensure_defaults(state)
	if bool(state.get("character_class_locked")):
		return false
	state.set("character_class_locked", true)
	ensure_defaults(state)
	if state.has_method("add_notice"):
		state.call("add_notice", "Class chosen: " + class_name(state))
	return true

static func earned_ascendancy_points(state: Object) -> int:
	return RVAscendancyDB.earned_points_for_level(int(state.get("level")))

static func used_ascendancy_points(state: Object) -> int:
	return Array(state.get("ascendancy_allocated")).size()

static func available_ascendancy_points(state: Object) -> int:
	return max(0, earned_ascendancy_points(state) - used_ascendancy_points(state))

static func choose_or_cycle_ascendancy(state: Object) -> bool:
	ensure_defaults(state)
	if int(state.get("level")) < 20:
		if state.has_method("add_notice"):
			state.call("add_notice", "Ascendancy unlocks at level 20")
		return false
	var allocated: Array = Array(state.get("ascendancy_allocated"))
	if not allocated.is_empty():
		if state.has_method("add_notice"):
			state.call("add_notice", "Ascendancy is locked after allocating points")
		return false
	var class_id: String = str(state.get("character_class_id"))
	var current_id: String = str(state.get("ascendancy_id"))
	state.set("ascendancy_id", RVAscendancyDB.next_for_class(class_id, current_id))
	if state.has_method("add_notice"):
		state.call("add_notice", "Ascendancy: " + ascendancy_name(state))
	if state.has_method("recompute_stats"):
		state.call("recompute_stats")
	return true

static func allocate_selected_passive(state: Object) -> bool:
	ensure_defaults(state)
	if int(state.get("mastery_points")) <= 0:
		state.call("add_notice", "No passive points")
		return false
	var ids: Array[String] = RVPassiveAtlasDB.ordered_ids_for_class(str(state.get("character_class_id")))
	if ids.is_empty():
		return false
	var cursor: int = clamp(int(state.get("passive_atlas_cursor")), 0, ids.size() - 1)
	var node_id: String = ids[cursor]
	var allocated: Array = Array(state.get("passive_atlas_allocated"))
	if not RVPassiveAtlasDB.can_allocate(node_id, allocated, str(state.get("character_class_id"))):
		state.call("add_notice", "Passive unavailable")
		return false
	allocated.append(node_id)
	var refund_stack: Array = Array(state.get("passive_atlas_refund_stack"))
	refund_stack.append(node_id)
	state.set("passive_atlas_allocated", allocated)
	state.set("passive_atlas_refund_stack", refund_stack)
	state.set("mastery_points", int(state.get("mastery_points")) - 1)
	state.set("refund_points", int(state.get("refund_points")) + 1)
	state.call("add_notice", "Passive allocated: " + str(RVPassiveAtlasDB.node(node_id).get("name", node_id)))
	state.call("recompute_stats")
	return true

static func refund_last_passive(state: Object) -> bool:
	ensure_defaults(state)
	var refund_stack: Array = Array(state.get("passive_atlas_refund_stack"))
	if refund_stack.is_empty() or int(state.get("refund_points")) <= 0:
		state.call("add_notice", "No passive refund available")
		return false
	var node_id: String = str(refund_stack.pop_back())
	var allocated: Array = Array(state.get("passive_atlas_allocated"))
	allocated.erase(node_id)
	state.set("passive_atlas_allocated", allocated)
	state.set("passive_atlas_refund_stack", refund_stack)
	state.set("refund_points", int(state.get("refund_points")) - 1)
	state.set("mastery_points", int(state.get("mastery_points")) + 1)
	state.call("add_notice", "Passive refunded")
	state.call("recompute_stats")
	return true

static func move_cursor(state: Object, delta: int) -> bool:
	ensure_defaults(state)
	var ids: Array[String] = RVPassiveAtlasDB.ordered_ids_for_class(str(state.get("character_class_id")))
	if ids.is_empty():
		return false
	state.set("passive_atlas_cursor", wrapi(int(state.get("passive_atlas_cursor")) + delta, 0, ids.size()))
	return true

static func allocate_ascendancy_node(state: Object) -> bool:
	ensure_defaults(state)
	if str(state.get("ascendancy_id")) == "":
		if not choose_or_cycle_ascendancy(state):
			return false
	if available_ascendancy_points(state) <= 0:
		state.call("add_notice", "No ascendancy points")
		return false
	var nodes: Array[String] = RVAscendancyDB.nodes_for(str(state.get("ascendancy_id")))
	var allocated: Array = Array(state.get("ascendancy_allocated"))
	for node_id: String in nodes:
		if not allocated.has(node_id):
			allocated.append(node_id)
			state.set("ascendancy_allocated", allocated)
			state.set("ascendancy_points", available_ascendancy_points(state))
			state.call("add_notice", "Ascendancy allocated: " + str(RVPassiveAtlasDB.node(node_id).get("name", node_id)))
			state.call("recompute_stats")
			return true
	state.call("add_notice", "Ascendancy complete")
	return false

static func handle_panel_key(state: Object, keycode: int) -> bool:
	match keycode:
		KEY_A:
			return move_cursor(state, -1)
		KEY_D:
			return move_cursor(state, 1)
		KEY_ENTER:
			if not bool(state.get("character_class_locked")):
				return lock_class(state)
			return allocate_selected_passive(state)
		KEY_BACKSPACE, KEY_DELETE:
			return refund_last_passive(state)
		KEY_C:
			return cycle_class(state)
		KEY_V:
			return choose_or_cycle_ascendancy(state)
		KEY_G:
			return allocate_ascendancy_node(state)
	return false

static func collect_stats(state: Object) -> Dictionary:
	ensure_defaults(state)
	var result: Dictionary = {"stats": {}, "flags": []}
	_add_stats_and_flags(result, RVClassDB.data(str(state.get("character_class_id"))))
	var allocated: Array = Array(state.get("passive_atlas_allocated"))
	for node_id_value: Variant in allocated:
		_add_stats_and_flags(result, RVPassiveAtlasDB.node(str(node_id_value)))
	var asc_allocated: Array = Array(state.get("ascendancy_allocated"))
	for asc_node_value: Variant in asc_allocated:
		_add_stats_and_flags(result, RVPassiveAtlasDB.node(str(asc_node_value)))
	return result

static func _add_stats_and_flags(result: Dictionary, data: Dictionary) -> void:
	var stats: Dictionary = result.get("stats", {})
	var source_stats: Dictionary = data.get("stats", {})
	for key: Variant in source_stats.keys():
		var stat_name: String = str(key)
		stats[stat_name] = float(stats.get(stat_name, 0.0)) + float(source_stats[key])
	result["stats"] = stats
	var flags: Array = result.get("flags", [])
	for flag_value: Variant in data.get("flags", []):
		var flag: String = str(flag_value)
		if not flags.has(flag):
			flags.append(flag)
	result["flags"] = flags

static func panel_text(state: Object) -> String:
	ensure_defaults(state)
	var text: String = "CLASS / PASSIVE ATLAS\n"
	text += "Character: " + str(state.get("character_name")) + "  Slot: " + str(state.get("character_slot_id")) + "\n"
	text += "Class: " + class_name(state) + ("  LOCKED" if bool(state.get("character_class_locked")) else "  NOT LOCKED") + "\n"
	text += "Ascendancy: " + ascendancy_name(state) + "\n"
	text += "Passive Points: " + str(int(state.get("mastery_points"))) + "  Refund: " + str(int(state.get("refund_points"))) + "\n"
	text += "Ascendancy Points: " + str(available_ascendancy_points(state)) + " / " + str(earned_ascendancy_points(state)) + " earned at Lv20/30/40/50\n\n"
	text += "Controls: C class before lock | Enter lock/allocate | A/D select | Backspace refund | V ascendancy | G asc node\n\n"
	var ids: Array[String] = RVPassiveAtlasDB.ordered_ids_for_class(str(state.get("character_class_id")))
	var cursor: int = clamp(int(state.get("passive_atlas_cursor")), 0, max(0, ids.size() - 1))
	for i: int in range(ids.size()):
		var node_id: String = ids[i]
		var data: Dictionary = RVPassiveAtlasDB.node(node_id)
		var marker: String = "> " if i == cursor else "  "
		var allocated: String = "[x]" if Array(state.get("passive_atlas_allocated")).has(node_id) else "[ ]"
		text += marker + allocated + " " + str(data.get("name", node_id)) + " - " + str(data.get("kind", "")) + "\n"
		if i == cursor:
			text += "      " + str(data.get("description", "")) + "\n"
	if str(state.get("ascendancy_id")) != "":
		text += "\nASCENDANCY TRACK\n"
		for asc_node: String in RVAscendancyDB.nodes_for(str(state.get("ascendancy_id"))):
			var asc_data: Dictionary = RVPassiveAtlasDB.node(asc_node)
			var asc_marker: String = "[x]" if Array(state.get("ascendancy_allocated")).has(asc_node) else "[ ]"
			text += asc_marker + " " + str(asc_data.get("name", asc_node)) + "\n"
	return text
