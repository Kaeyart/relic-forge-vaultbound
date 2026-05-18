class_name RVPassiveTreeSystem
extends RefCounted

const PassiveDBScript := preload("res://scripts/data/PassiveAtlasDB.gd")

static func ensure_defaults(state: Object) -> void:
	if state == null:
		return
	var unlocked: Array[String] = _string_array(_state_get(state, "unlocked_passive_nodes", []))
	var legacy: Array[String] = _string_array(_state_get(state, "passive_atlas_allocated", []))
	for id: String in legacy:
		if not unlocked.has(id):
			unlocked.append(id)
	if not unlocked.has(PassiveDBScript.START_NODE_ID):
		unlocked.push_front(PassiveDBScript.START_NODE_ID)
	_set_if_possible(state, "unlocked_passive_nodes", unlocked)
	_set_if_possible(state, "passive_atlas_allocated", unlocked.duplicate())
	if _state_get(state, "passive_stat_bonuses", null) == null:
		_set_if_possible(state, "passive_stat_bonuses", {})
	if _state_get(state, "passive_rules", null) == null:
		_set_if_possible(state, "passive_rules", [])
	# Point aliases: old patches used mastery/refund; new patches use passive/refund fields.
	var passive_points_value: int = max(_as_int(_state_get(state, "passive_points", 0)), _as_int(_state_get(state, "mastery_points", 0)))
	var refund_value: int = max(_as_int(_state_get(state, "passive_refund_points", 0)), _as_int(_state_get(state, "refund_points", 0)))
	_set_if_possible(state, "passive_points", passive_points_value)
	_set_if_possible(state, "mastery_points", passive_points_value)
	_set_if_possible(state, "passive_refund_points", refund_value)
	_set_if_possible(state, "refund_points", refund_value)
	apply_to_state(state)

static func unlocked_nodes(state: Object) -> Array[String]:
	if state == null:
		return []
	var raw: Variant = _state_get(state, "unlocked_passive_nodes", _state_get(state, "passive_atlas_allocated", []))
	var out: Array[String] = _string_array(Array(raw) if typeof(raw) == TYPE_ARRAY else [])
	if not out.has(PassiveDBScript.START_NODE_ID):
		out.push_front(PassiveDBScript.START_NODE_ID)
	return out

static func passive_points(state: Object) -> int:
	return max(_as_int(_state_get(state, "passive_points", 0)), _as_int(_state_get(state, "mastery_points", 0)))

static func refund_points(state: Object) -> int:
	return max(_as_int(_state_get(state, "passive_refund_points", 0)), _as_int(_state_get(state, "refund_points", 0)))

static func can_unlock(state: Object, node_id: String) -> bool:
	if state == null or node_id == "":
		return false
	ensure_defaults(state)
	var node_data: Dictionary = PassiveDBScript.node_by_id(node_id)
	if node_data.is_empty():
		return false
	var unlocked: Array[String] = unlocked_nodes(state)
	if unlocked.has(node_id):
		return false
	var cost: int = max(0, _as_int(node_data.get("cost", 1), 1))
	if cost > passive_points(state):
		return false
	if str(node_data.get("type", "")) == "start":
		return true
	for other_id: String in PassiveDBScript.connected_ids(node_id):
		if unlocked.has(other_id):
			return true
	return false

static func unlock_node(state: Object, node_id: String) -> bool:
	if not can_unlock(state, node_id):
		_notice(state, "Cannot unlock passive")
		return false
	var node_data: Dictionary = PassiveDBScript.node_by_id(node_id)
	var unlocked: Array[String] = unlocked_nodes(state)
	unlocked.append(node_id)
	_set_if_possible(state, "unlocked_passive_nodes", unlocked)
	_set_if_possible(state, "passive_atlas_allocated", unlocked.duplicate())
	var cost: int = max(0, _as_int(node_data.get("cost", 1), 1))
	var new_points: int = max(0, passive_points(state) - cost)
	_set_if_possible(state, "passive_points", new_points)
	_set_if_possible(state, "mastery_points", new_points)
	apply_to_state(state)
	_notice(state, "Unlocked " + str(node_data.get("name", node_id)))
	if state.has_method("recompute_stats"):
		state.call("recompute_stats")
	return true

static func can_refund(state: Object, node_id: String) -> bool:
	if state == null or node_id == "" or node_id == PassiveDBScript.START_NODE_ID:
		return false
	var unlocked: Array[String] = unlocked_nodes(state)
	if not unlocked.has(node_id):
		return false
	if refund_points(state) <= 0:
		return false
	return _would_remain_connected(unlocked, node_id)

static func refund_node(state: Object, node_id: String) -> bool:
	if not can_refund(state, node_id):
		_notice(state, "Cannot refund passive")
		return false
	var unlocked: Array[String] = unlocked_nodes(state)
	unlocked.erase(node_id)
	_set_if_possible(state, "unlocked_passive_nodes", unlocked)
	_set_if_possible(state, "passive_atlas_allocated", unlocked.duplicate())
	var new_refund: int = max(0, refund_points(state) - 1)
	var new_points: int = passive_points(state) + 1
	_set_if_possible(state, "passive_refund_points", new_refund)
	_set_if_possible(state, "refund_points", new_refund)
	_set_if_possible(state, "passive_points", new_points)
	_set_if_possible(state, "mastery_points", new_points)
	apply_to_state(state)
	var node_data: Dictionary = PassiveDBScript.node_by_id(node_id)
	_notice(state, "Refunded " + str(node_data.get("name", node_id)))
	if state.has_method("recompute_stats"):
		state.call("recompute_stats")
	return true

static func aggregate_stats(state: Object) -> Dictionary:
	var totals: Dictionary = {}
	for node_id: String in unlocked_nodes(state):
		var node_data: Dictionary = PassiveDBScript.node_by_id(node_id)
		for key_value: Variant in Dictionary(node_data.get("stats", {})).keys():
			var key: String = str(key_value)
			totals[key] = float(totals.get(key, 0.0)) + float(Dictionary(node_data.get("stats", {}))[key_value])
	return totals

static func aggregate_rules(state: Object) -> Array[String]:
	var out: Array[String] = []
	for node_id: String in unlocked_nodes(state):
		var node_data: Dictionary = PassiveDBScript.node_by_id(node_id)
		for value: Variant in Array(node_data.get("rules", node_data.get("flags", []))):
			var rule: String = str(value)
			if rule != "" and not out.has(rule):
				out.append(rule)
	return out

static func apply_to_state(state: Object) -> void:
	if state == null:
		return
	_set_if_possible(state, "passive_stat_bonuses", aggregate_stats(state))
	_set_if_possible(state, "passive_rules", aggregate_rules(state))

static func node_state(state: Object, node_id: String) -> String:
	var unlocked: Array[String] = unlocked_nodes(state)
	if unlocked.has(node_id):
		return "unlocked"
	if can_unlock(state, node_id):
		return "available"
	return "locked"

static func detail_text(state: Object, node_id: String) -> String:
	var node_data: Dictionary = PassiveDBScript.node_by_id(node_id)
	if node_data.is_empty():
		return "No passive selected."
	var text: String = "[b]" + str(node_data.get("name", node_id)) + "[/b]\n"
	text += str(node_data.get("type", "node")).capitalize() + " · " + str(node_data.get("cluster", "core")).capitalize() + "\n"
	text += "State: " + node_state(state, node_id).capitalize() + "\n"
	var desc: String = str(node_data.get("description", ""))
	if desc != "":
		text += "\n" + desc + "\n"
	var stats: Dictionary = Dictionary(node_data.get("stats", {}))
	if not stats.is_empty():
		text += "\n[b]Stats[/b]\n"
		for key_value: Variant in stats.keys():
			var key: String = str(key_value)
			text += "• " + key + ": " + _format_amount(float(stats[key_value])) + "\n"
	var rules: Array = Array(node_data.get("rules", []))
	if not rules.is_empty():
		text += "\n[b]Rules[/b]\n"
		for rule_value: Variant in rules:
			text += "• " + str(rule_value).replace("_", " ").capitalize() + "\n"
	var tags: PackedStringArray = PackedStringArray(_string_array(Array(node_data.get("tags", []))))
	if tags.size() > 0:
		text += "\nTags: " + ", ".join(tags)
	return text

static func summary_text(state: Object) -> String:
	ensure_defaults(state)
	var unlocked: Array[String] = unlocked_nodes(state)
	return "Passive points: " + str(passive_points(state)) + " · Refunds: " + str(refund_points(state)) + " · Nodes: " + str(unlocked.size()) + "/" + str(PassiveDBScript.node_count())

static func _would_remain_connected(unlocked: Array[String], removed_id: String) -> bool:
	var remaining: Array[String] = []
	for id: String in unlocked:
		if id != removed_id:
			remaining.append(id)
	if not remaining.has(PassiveDBScript.START_NODE_ID):
		return false
	var visited: Array[String] = []
	var frontier: Array[String] = [PassiveDBScript.START_NODE_ID]
	while not frontier.is_empty():
		var id: String = frontier.pop_back()
		if visited.has(id):
			continue
		visited.append(id)
		for next_id: String in PassiveDBScript.connected_ids(id):
			if remaining.has(next_id) and not visited.has(next_id):
				frontier.append(next_id)
	for id2: String in remaining:
		if not visited.has(id2):
			return false
	return true

static func _format_amount(amount: float) -> String:
	if abs(amount) < 1.0:
		return ("+" if amount >= 0.0 else "") + str(snappedf(amount * 100.0, 0.1)) + "%"
	return ("+" if amount >= 0.0 else "") + str(int(round(amount)))

static func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	return fallback if value == null else value

static func _set_if_possible(state: Object, key: String, value: Variant) -> void:
	if state != null:
		state.set(key, value)

static func _as_int(value: Variant, fallback: int = 0) -> int:
	if typeof(value) == TYPE_INT:
		return value
	if typeof(value) == TYPE_FLOAT:
		return int(value)
	if typeof(value) == TYPE_STRING and str(value).is_valid_int():
		return int(str(value))
	return fallback

static func _string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value: Variant in values:
		var text: String = str(value)
		if text != "" and not out.has(text):
			out.append(text)
	return out

static func _notice(state: Object, text: String) -> void:
	if state != null and state.has_method("add_notice"):
		state.call("add_notice", text)
