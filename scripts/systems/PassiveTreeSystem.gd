class_name RVPassiveTreeSystem
extends RefCounted

static func recompute(state: RVGameState) -> void:
	var nodes: Dictionary = RVPassiveTreeDB.nodes()
	var stats: Dictionary = {}
	var flags: Array = []
	for id in state.passive_nodes_allocated:
		if not nodes.has(id):
			continue
		var node: Dictionary = nodes[id]
		var node_stats: Dictionary = node.get("stats", {})
		for k in node_stats.keys():
			stats[k] = float(stats.get(k, 0.0)) + float(node_stats[k])
		for f in node.get("flags", []):
			if not flags.has(f):
				flags.append(f)
	state.passive_stats = stats
	state.passive_flags = flags

static func visible_nodes(state: RVGameState) -> Array:
	var nodes: Dictionary = RVPassiveTreeDB.nodes()
	var result: Array = []
	for id in nodes.keys():
		var node: Dictionary = nodes[id]
		if state.passive_nodes_allocated.has(id) or can_allocate(state, id):
			result.append(node)
	result.sort_custom(func(a, b): return int(a.get("ring", 0)) < int(b.get("ring", 0)))
	return result

static func can_allocate(state: RVGameState, id: String) -> bool:
	if state.mastery_points <= 0:
		return false
	if state.passive_nodes_allocated.has(id):
		return false
	var nodes: Dictionary = RVPassiveTreeDB.nodes()
	if not nodes.has(id):
		return false
	var links: Array = nodes[id].get("links", [])
	for linked in links:
		if state.passive_nodes_allocated.has(linked):
			return true
	return false

static func selected_node(state: RVGameState) -> Dictionary:
	var list: Array = visible_nodes(state)
	if list.size() == 0:
		return {}
	state.passive_selected_index = clamp(state.passive_selected_index, 0, list.size() - 1)
	return list[state.passive_selected_index]

static func cycle_selected(state: RVGameState, dir: int) -> void:
	var list: Array = visible_nodes(state)
	if list.size() == 0:
		state.passive_selected_index = 0
		return
	state.passive_selected_index = posmod(state.passive_selected_index + dir, list.size())

static func allocate_selected(state: RVGameState) -> void:
	var node: Dictionary = selected_node(state)
	if node.is_empty():
		return
	var id: String = str(node["id"])
	if not can_allocate(state, id):
		state.add_notice("Node unavailable")
		return
	state.passive_nodes_allocated.append(id)
	state.passive_refund_history.append(id)
	state.mastery_points -= 1
	var branch: String = str(node.get("branch", "core"))
	if state.passives.has(branch):
		state.passives[branch] = int(state.passives.get(branch, 0)) + 1
	recompute(state)
	state.recompute_stats()
	state.add_notice("Allocated " + str(node.get("name", id)))

static func refund_last(state: RVGameState) -> void:
	if state.refund_points <= 0:
		state.add_notice("No refund points")
		return
	if state.passive_refund_history.size() == 0:
		state.add_notice("Nothing to refund")
		return
	var id: String = str(state.passive_refund_history.pop_back())
	if id == "root":
		return
	state.passive_nodes_allocated.erase(id)
	state.mastery_points += 1
	state.refund_points -= 1
	recompute(state)
	state.recompute_stats()
	state.add_notice("Refunded passive node")
