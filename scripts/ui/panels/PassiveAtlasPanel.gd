class_name RVPassiveAtlasPanel
extends RVUIPanelBase

const PassiveDBScript := preload("res://scripts/data/PassiveAtlasDB.gd")
const PassiveTreeSystemScript := preload("res://scripts/systems/PassiveTreeSystem.gd")
const NodeButtonScene := preload("res://scenes/ui/components/PassiveTreeNodeButton.tscn")

var state_ref: Object = null
var selected_node_id: String = PassiveDBScript.START_NODE_ID
var node_buttons: Dictionary = {}

@onready var summary_label: Label = get_node_or_null("%SummaryLabel") as Label
@onready var detail_label: RichTextLabel = get_node_or_null("%DetailLabel") as RichTextLabel
@onready var tree_root: Control = _find_tree_root()
@onready var connection_canvas: Control = _find_connection_canvas()
@onready var allocate_button: Button = get_node_or_null("%AllocateButton") as Button
@onready var refund_button: Button = get_node_or_null("%RefundButton") as Button

func _ready() -> void:
	visible = false
	_connect_buttons()
	_rebuild_tree_buttons()

func update_from_state(state: RVGameState) -> void:
	state_ref = state
	PassiveTreeSystemScript.ensure_defaults(state_ref)
	if selected_node_id == "" or PassiveDBScript.node_by_id(selected_node_id).is_empty():
		selected_node_id = PassiveDBScript.START_NODE_ID
	_rebuild_tree_buttons()
	_update_text()
	_update_button_states()
	if connection_canvas != null and connection_canvas.has_method("update_from_state"):
		connection_canvas.call("update_from_state", state_ref)

func handle_panel_key(state: Object, keycode: int) -> bool:
	state_ref = state
	match keycode:
		KEY_ENTER:
			return _try_unlock_selected()
		KEY_BACKSPACE, KEY_DELETE:
			return _try_refund_selected()
		KEY_LEFT, KEY_A:
			_select_neighbor(-1)
			return true
		KEY_RIGHT, KEY_D:
			_select_neighbor(1)
			return true
	return false

func _connect_buttons() -> void:
	if allocate_button != null and not allocate_button.pressed.is_connected(_on_allocate_pressed):
		allocate_button.pressed.connect(_on_allocate_pressed)
	if refund_button != null and not refund_button.pressed.is_connected(_on_refund_pressed):
		refund_button.pressed.connect(_on_refund_pressed)

func _rebuild_tree_buttons() -> void:
	if tree_root == null:
		return
	for child: Node in tree_root.get_children():
		if child == connection_canvas:
			continue
		child.queue_free()
	node_buttons.clear()
	for node_data: Dictionary in PassiveDBScript.nodes():
		var id: String = str(node_data.get("id", ""))
		if id == "":
			continue
		var button: Button = _make_node_button()
		button.name = "PassiveNode_" + id
		button.position = _node_position(node_data)
		button.custom_minimum_size = Vector2(34, 34)
		button.size = Vector2(34, 34)
		button.tooltip_text = str(node_data.get("name", id))
		var state_name: String = "locked"
		if state_ref != null:
			state_name = PassiveTreeSystemScript.node_state(state_ref, id)
		if button.has_method("setup"):
			button.call("setup", node_data, state_name, id == selected_node_id)
		else:
			button.text = _fallback_node_label(node_data)
		if not button.pressed.is_connected(_on_node_pressed.bind(id)):
			button.pressed.connect(_on_node_pressed.bind(id))
		tree_root.add_child(button)
		node_buttons[id] = button

func _make_node_button() -> Button:
	var button: Button = null
	if NodeButtonScene != null:
		var inst: Node = NodeButtonScene.instantiate()
		if inst is Button:
			button = inst as Button
	if button == null:
		button = Button.new()
	return button

func _node_position(node_data: Dictionary) -> Vector2:
	var raw: Variant = node_data.get("pos", Vector2.ZERO)
	var pos: Vector2 = Vector2.ZERO
	if typeof(raw) == TYPE_VECTOR2:
		pos = Vector2(raw)
	elif typeof(raw) == TYPE_VECTOR2I:
		var p: Vector2i = raw
		pos = Vector2(float(p.x), float(p.y))
	elif typeof(raw) == TYPE_ARRAY:
		var arr: Array = Array(raw)
		if arr.size() >= 2:
			pos = Vector2(float(arr[0]), float(arr[1]))
	elif typeof(raw) == TYPE_DICTIONARY:
		var d: Dictionary = Dictionary(raw)
		pos = Vector2(float(d.get("x", 0)), float(d.get("y", 0)))
	return pos + Vector2(80, 80)

func _fallback_node_label(node_data: Dictionary) -> String:
	match str(node_data.get("type", "small")):
		"start": return "●"
		"notable": return "◆"
		"keystone": return "⬢"
	return "•"

func _on_node_pressed(id: String) -> void:
	selected_node_id = id
	_update_text()
	_update_button_states()
	_rebuild_tree_buttons()
	if connection_canvas != null:
		connection_canvas.queue_redraw()

func _on_allocate_pressed() -> void:
	_try_unlock_selected()

func _on_refund_pressed() -> void:
	_try_refund_selected()

func _try_unlock_selected() -> bool:
	if state_ref == null:
		return false
	var ok: bool = PassiveTreeSystemScript.unlock_node(state_ref, selected_node_id)
	_rebuild_tree_buttons()
	_update_text()
	_update_button_states()
	if connection_canvas != null and connection_canvas.has_method("update_from_state"):
		connection_canvas.call("update_from_state", state_ref)
	return ok

func _try_refund_selected() -> bool:
	if state_ref == null:
		return false
	var ok: bool = PassiveTreeSystemScript.refund_node(state_ref, selected_node_id)
	_rebuild_tree_buttons()
	_update_text()
	_update_button_states()
	if connection_canvas != null and connection_canvas.has_method("update_from_state"):
		connection_canvas.call("update_from_state", state_ref)
	return ok

func _select_neighbor(delta: int) -> void:
	var ids: Array[String] = PassiveDBScript.ordered_ids()
	if ids.is_empty():
		return
	var index: int = ids.find(selected_node_id)
	if index < 0:
		index = 0
	selected_node_id = ids[wrapi(index + delta, 0, ids.size())]
	_update_text()
	_update_button_states()
	_rebuild_tree_buttons()

func _update_text() -> void:
	if state_ref == null:
		return
	if summary_label != null:
		summary_label.text = PassiveTreeSystemScript.summary_text(state_ref)
	if detail_label != null:
		detail_label.clear()
		detail_label.append_text(PassiveTreeSystemScript.detail_text(state_ref, selected_node_id))

func _update_button_states() -> void:
	if state_ref == null:
		return
	if allocate_button != null:
		allocate_button.disabled = not PassiveTreeSystemScript.can_unlock(state_ref, selected_node_id)
	if refund_button != null:
		refund_button.disabled = not PassiveTreeSystemScript.can_refund(state_ref, selected_node_id)

func _find_tree_root() -> Control:
	for path: String in ["%TreeRoot", "%NodeLayer", "%NodeButtons", "%TreeContent", "%TreeCanvas"]:
		var node: Node = get_node_or_null(path)
		if node is Control:
			return node as Control
	return self

func _find_connection_canvas() -> Control:
	for path: String in ["%ConnectionCanvas", "%TreeConnections", "%PassiveTreeConnectionCanvas"]:
		var node: Node = get_node_or_null(path)
		if node is Control:
			return node as Control
	return null
