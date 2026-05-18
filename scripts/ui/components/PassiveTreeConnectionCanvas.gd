class_name RVPassiveTreeConnectionCanvas
extends Control

const PassiveDBScript := preload("res://scripts/data/PassiveAtlasDB.gd")
const TREE_OFFSET: Vector2 = Vector2(120.0, 120.0)
const NODE_CENTER_OFFSET: Vector2 = Vector2(42.0, 20.0)

var node_positions: Dictionary = {}
var connection_pairs: Array = []
var state_ref: Object = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild_positions()
	queue_redraw()

func update_from_state(state: Object) -> void:
	state_ref = state
	_rebuild_positions()
	queue_redraw()

func refresh() -> void:
	_rebuild_positions()
	queue_redraw()

func _rebuild_positions() -> void:
	node_positions.clear()
	connection_pairs.clear()
	for value: Variant in Array(PassiveDBScript.nodes()):
		var node_data: Dictionary = _node_data_from_value(value)
		if node_data.is_empty():
			continue
		var node_id: String = str(node_data.get("id", ""))
		if node_id == "":
			continue
		node_positions[node_id] = _node_position(node_data) + NODE_CENTER_OFFSET
	_rebuild_connections()

func _rebuild_connections() -> void:
	var seen: Dictionary = {}
	for key_value: Variant in node_positions.keys():
		var node_id: String = str(key_value)
		for other_value: Variant in Array(PassiveDBScript.connected_ids(node_id)):
			var other_id: String = str(other_value)
			if other_id == "" or not node_positions.has(other_id):
				continue
			var a: String = node_id
			var b: String = other_id
			if a > b:
				var temp: String = a
				a = b
				b = temp
			var pair_key: String = a + "::" + b
			if seen.has(pair_key):
				continue
			seen[pair_key] = true
			connection_pairs.append([a, b])

func _draw() -> void:
	for pair_value: Variant in connection_pairs:
		var pair: Array = Array(pair_value)
		if pair.size() < 2:
			continue
		var a_id: String = str(pair[0])
		var b_id: String = str(pair[1])
		if not node_positions.has(a_id) or not node_positions.has(b_id):
			continue
		var a: Vector2 = Vector2(node_positions[a_id])
		var b: Vector2 = Vector2(node_positions[b_id])
		var color: Color = Color(0.45, 0.31, 0.15, 0.78)
		var width: float = 2.0
		if _is_unlocked(a_id) and _is_unlocked(b_id):
			color = Color(1.00, 0.68, 0.25, 0.98)
			width = 4.0
		draw_line(a, b, color, width, true)

func _node_data_from_value(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return Dictionary(value).duplicate(true)
	var node_id: String = str(value)
	if node_id == "":
		return {}
	return PassiveDBScript.node_by_id(node_id)

func _node_position(node_data: Dictionary) -> Vector2:
	var raw_pos: Variant = node_data.get("pos", Vector2.ZERO)
	var pos: Vector2 = Vector2.ZERO
	if typeof(raw_pos) == TYPE_VECTOR2:
		pos = Vector2(raw_pos)
	elif typeof(raw_pos) == TYPE_VECTOR2I:
		var pos_i: Vector2i = raw_pos
		pos = Vector2(float(pos_i.x), float(pos_i.y))
	elif typeof(raw_pos) == TYPE_DICTIONARY:
		var d: Dictionary = Dictionary(raw_pos)
		pos = Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
	elif typeof(raw_pos) == TYPE_ARRAY:
		var arr: Array = Array(raw_pos)
		if arr.size() >= 2:
			pos = Vector2(float(arr[0]), float(arr[1]))
	return pos + TREE_OFFSET

func _is_unlocked(node_id: String) -> bool:
	if state_ref == null:
		return false
	var unlocked_value: Variant = state_ref.get("unlocked_passive_nodes")
	if typeof(unlocked_value) == TYPE_ARRAY and Array(unlocked_value).has(node_id):
		return true
	var legacy_value: Variant = state_ref.get("passive_atlas_allocated")
	if typeof(legacy_value) == TYPE_ARRAY and Array(legacy_value).has(node_id):
		return true
	return false
