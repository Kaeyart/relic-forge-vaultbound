class_name RVPassiveTreeNodeButton
extends Button

signal passive_node_pressed(node_id: String)
signal passive_node_secondary_pressed(node_id: String)

var node_id: String = ""
var node_data: Dictionary = {}
var node_state: String = "locked"

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(_on_pressed)

func setup(data: Dictionary, state: String = "locked", selected: bool = false) -> void:
	node_data = data.duplicate(true)
	node_id = str(node_data.get("id", ""))
	node_state = state
	text = _label_for_node(node_data)
	tooltip_text = str(node_data.get("name", node_id)) + "\n" + str(node_data.get("description", ""))
	_apply_visual_state(selected)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			passive_node_secondary_pressed.emit(node_id)
			accept_event()

func _on_pressed() -> void:
	passive_node_pressed.emit(node_id)

func _label_for_node(data: Dictionary) -> String:
	var type: String = str(data.get("type", "small"))
	match type:
		"start": return "●"
		"notable": return "◆"
		"keystone": return "⬢"
	return "•"

func _apply_visual_state(selected: bool) -> void:
	custom_minimum_size = Vector2(34.0, 34.0)
	match node_state:
		"unlocked":
			modulate = Color(1.0, 0.78, 0.35, 1.0)
		"available":
			modulate = Color(0.72, 0.92, 1.0, 1.0)
		_:
			modulate = Color(0.42, 0.38, 0.32, 0.88)
	if selected:
		modulate = Color(1.0, 1.0, 0.72, 1.0)
