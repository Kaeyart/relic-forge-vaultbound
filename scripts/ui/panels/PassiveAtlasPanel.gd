class_name RVPassiveAtlasPanel
extends Control

const PassiveDBScript := preload("res://scripts/data/PassiveAtlasDB.gd")
const PassiveTreeSystemScript := preload("res://scripts/systems/PassiveTreeSystem.gd")
const NodeButtonScene := preload("res://scenes/ui/components/PassiveTreeNodeButton.tscn")

const TREE_OFFSET: Vector2 = Vector2(120.0, 120.0)
const TREE_SIZE: Vector2 = Vector2(3600.0, 2600.0)

var state_ref: Object = null
var selected_node_id: String = ""
var node_buttons: Dictionary = {}

var tree_scroll: ScrollContainer = null
var tree_content: Control = null
var connection_canvas: Control = null
var detail_text: RichTextLabel = null
var summary_label: Label = null
var allocate_button: Button = null
var refund_button: Button = null
var hint_label: Label = null

var panning: bool = false
var pan_last_global: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_bind_scene_nodes()
	_connect_buttons()
	selected_node_id = str(PassiveDBScript.START_NODE_ID)
	_rebuild_tree()
	_update_detail()

func update_from_state(state: Object) -> void:
	state_ref = state
	if state_ref != null:
		PassiveTreeSystemScript.ensure_defaults(state_ref)
		visible = str(_state_get(state_ref, "panel_mode", "")) == "passive_atlas"
	_bind_scene_nodes()
	_connect_buttons()
	if selected_node_id == "":
		selected_node_id = str(PassiveDBScript.START_NODE_ID)
	_rebuild_tree()
	_update_detail()

func refresh() -> void:
	_bind_scene_nodes()
	_rebuild_tree()
	_update_detail()

func _bind_scene_nodes() -> void:
	tree_scroll = get_node_or_null("%TreeScroll") as ScrollContainer
	tree_content = get_node_or_null("%TreeContent") as Control
	connection_canvas = get_node_or_null("%ConnectionCanvas") as Control
	detail_text = get_node_or_null("%DetailText") as RichTextLabel
	summary_label = get_node_or_null("%SummaryLabel") as Label
	allocate_button = get_node_or_null("%AllocateButton") as Button
	refund_button = get_node_or_null("%RefundButton") as Button
	hint_label = get_node_or_null("%HintLabel") as Label

	if tree_scroll == null or tree_content == null:
		push_error("PassiveAtlasPanel scene is missing %TreeScroll or %TreeContent. Reinstall patch 085J.")
		return

	tree_content.custom_minimum_size = TREE_SIZE
	tree_content.mouse_filter = Control.MOUSE_FILTER_PASS
	if not tree_content.gui_input.is_connected(Callable(self, "_on_tree_content_gui_input")):
		tree_content.gui_input.connect(Callable(self, "_on_tree_content_gui_input"))

	if connection_canvas != null:
		connection_canvas.custom_minimum_size = TREE_SIZE
		connection_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _connect_buttons() -> void:
	if allocate_button != null:
		var alloc_cb: Callable = Callable(self, "_on_allocate_pressed")
		if not allocate_button.pressed.is_connected(alloc_cb):
			allocate_button.pressed.connect(alloc_cb)
	if refund_button != null:
		var refund_cb: Callable = Callable(self, "_on_refund_pressed")
		if not refund_button.pressed.is_connected(refund_cb):
			refund_button.pressed.connect(refund_cb)

func _rebuild_tree() -> void:
	if tree_content == null:
		return
	_clear_runtime_node_buttons()
	node_buttons.clear()

	if connection_canvas != null and connection_canvas.has_method("update_from_state"):
		connection_canvas.call("update_from_state", state_ref)

	for node_data: Dictionary in _all_node_data():
		var node_id: String = str(node_data.get("id", ""))
		if node_id == "":
			continue
		var button: Button = _make_node_button(node_data)
		if button == null:
			continue
		button.position = _node_position(node_data)
		button.z_as_relative = false
		button.z_index = 30
		button.set_meta("rv_passive_runtime_button", true)
		tree_content.add_child(button)
		node_buttons[node_id] = button

	if connection_canvas != null and connection_canvas.get_parent() == tree_content:
		tree_content.move_child(connection_canvas, 0)
		connection_canvas.queue_redraw()

func _clear_runtime_node_buttons() -> void:
	if tree_content == null:
		return
	for child: Node in tree_content.get_children():
		if child == connection_canvas:
			continue
		if bool(child.get_meta("rv_passive_runtime_button", false)) or str(child.name).begins_with("Node_") or str(child.name).begins_with("PassiveNode_"):
			child.queue_free()

func _all_node_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in Array(PassiveDBScript.nodes()):
		var data: Dictionary = _node_data_from_value(value)
		if not data.is_empty():
			result.append(data)
	return result

func _make_node_button(node_data: Dictionary) -> Button:
	var node_id: String = str(node_data.get("id", ""))
	if node_id == "":
		return null
	var button_node: Node = NodeButtonScene.instantiate()
	if not (button_node is Button):
		button_node.queue_free()
		return null
	var button: Button = button_node as Button
	var state_name: String = "locked"
	if state_ref != null:
		state_name = PassiveTreeSystemScript.node_state(state_ref, node_id)
	elif node_id == str(PassiveDBScript.START_NODE_ID):
		state_name = "unlocked"
	var is_selected: bool = selected_node_id == node_id
	if button.has_method("setup"):
		button.call("setup", node_data, state_name, is_selected)
	else:
		button.name = "Node_" + node_id
		button.text = str(node_data.get("name", node_id))
		button.custom_minimum_size = Vector2(86.0, 38.0)

	var press_cb: Callable = Callable(self, "_on_node_pressed")
	if button.has_signal("passive_node_pressed") and not button.is_connected("passive_node_pressed", press_cb):
		button.connect("passive_node_pressed", press_cb)
	else:
		var fallback_cb: Callable = Callable(self, "_on_button_pressed").bind(node_id)
		if not button.pressed.is_connected(fallback_cb):
			button.pressed.connect(fallback_cb)

	var secondary_cb: Callable = Callable(self, "_on_node_secondary_pressed")
	if button.has_signal("passive_node_secondary_pressed") and not button.is_connected("passive_node_secondary_pressed", secondary_cb):
		button.connect("passive_node_secondary_pressed", secondary_cb)

	button.tooltip_text = _tooltip_for(node_data)
	return button

func _on_button_pressed(node_id: String) -> void:
	_on_node_pressed(node_id)

func _on_node_pressed(node_id: String) -> void:
	# Left click only selects/highlights. It does not spend points.
	selected_node_id = node_id
	_rebuild_tree()
	_update_detail()

func _on_node_secondary_pressed(node_id: String) -> void:
	# Right click immediately allocates if available.
	selected_node_id = node_id
	if state_ref != null and PassiveTreeSystemScript.can_unlock(state_ref, node_id):
		PassiveTreeSystemScript.unlock_node(state_ref, node_id)
	_rebuild_tree()
	_update_detail()

func _on_allocate_pressed() -> void:
	if state_ref != null and selected_node_id != "":
		PassiveTreeSystemScript.unlock_node(state_ref, selected_node_id)
	_rebuild_tree()
	_update_detail()

func _on_refund_pressed() -> void:
	if state_ref != null and selected_node_id != "":
		PassiveTreeSystemScript.refund_node(state_ref, selected_node_id)
	_rebuild_tree()
	_update_detail()

func _on_tree_content_gui_input(event: InputEvent) -> void:
	if tree_scroll == null:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			panning = mb.pressed
			pan_last_global = mb.global_position
			if mb.pressed:
				accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			tree_scroll.scroll_vertical = max(0, tree_scroll.scroll_vertical - 72)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			tree_scroll.scroll_vertical += 72
			accept_event()
	elif event is InputEventMouseMotion and panning:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var delta: Vector2 = mm.global_position - pan_last_global
		pan_last_global = mm.global_position
		tree_scroll.scroll_horizontal = max(0, tree_scroll.scroll_horizontal - int(delta.x))
		tree_scroll.scroll_vertical = max(0, tree_scroll.scroll_vertical - int(delta.y))
		accept_event()

func _update_detail() -> void:
	if summary_label != null:
		if state_ref != null:
			summary_label.text = PassiveTreeSystemScript.summary_text(state_ref)
		else:
			summary_label.text = "Passive Tree"
	if detail_text != null:
		if state_ref != null and selected_node_id != "":
			detail_text.text = PassiveTreeSystemScript.detail_text(state_ref, selected_node_id)
		else:
			detail_text.text = "Select a passive node."
	if allocate_button != null:
		allocate_button.disabled = state_ref == null or selected_node_id == "" or not PassiveTreeSystemScript.can_unlock(state_ref, selected_node_id)
	if refund_button != null:
		refund_button.disabled = state_ref == null or selected_node_id == "" or not PassiveTreeSystemScript.can_refund(state_ref, selected_node_id)
	if hint_label != null:
		hint_label.text = "Drag empty tree space to pan. Left-click selects. Right-click allocates. Allocate/Refund buttons are fallbacks."

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

func _tooltip_for(node_data: Dictionary) -> String:
	var node_id: String = str(node_data.get("id", ""))
	var text: String = str(node_data.get("name", node_id))
	var desc: String = str(node_data.get("description", ""))
	if desc != "":
		text += "\n" + desc
	return text

func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	if state == null:
		return fallback
	var value: Variant = state.get(key)
	return fallback if value == null else value
