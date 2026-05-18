class_name RVPassiveTreeNodeButton
extends Button

signal passive_node_pressed(node_id: String)
signal passive_node_secondary_pressed(node_id: String)

var node_id: String = ""
var node_state_name: String = "locked"
var selected: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var cb: Callable = Callable(self, "_emit_left_press")
	if not pressed.is_connected(cb):
		pressed.connect(cb)

func setup(node_data: Dictionary, state_name: String = "locked", is_selected: bool = false) -> void:
	node_id = str(node_data.get("id", ""))
	node_state_name = state_name
	selected = is_selected
	name = "Node_" + node_id
	text = _short_label(str(node_data.get("name", node_id)), str(node_data.get("type", "small")))
	custom_minimum_size = _size_for_type(str(node_data.get("type", "small")))
	_apply_visual(str(node_data.get("type", "small")))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			passive_node_secondary_pressed.emit(node_id)
			accept_event()

func _emit_left_press() -> void:
	passive_node_pressed.emit(node_id)

func _short_label(label: String, node_type: String) -> String:
	if node_type == "small":
		return "•"
	if label.length() > 18:
		return label.substr(0, 16) + "…"
	return label

func _size_for_type(node_type: String) -> Vector2:
	match node_type:
		"start": return Vector2(116.0, 46.0)
		"keystone": return Vector2(138.0, 54.0)
		"notable": return Vector2(122.0, 46.0)
		_: return Vector2(42.0, 34.0)

func _apply_visual(node_type: String) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2

	match node_state_name:
		"unlocked":
			style.bg_color = Color(0.34, 0.19, 0.065, 0.98)
			style.border_color = Color(1.0, 0.72, 0.30, 1.0)
			add_theme_color_override("font_color", Color(1.0, 0.87, 0.50, 1.0))
		"available":
			style.bg_color = Color(0.13, 0.10, 0.055, 0.98)
			style.border_color = Color(0.88, 0.52, 0.18, 0.95)
			add_theme_color_override("font_color", Color(1.0, 0.76, 0.34, 1.0))
		_:
			style.bg_color = Color(0.035, 0.030, 0.026, 0.98)
			style.border_color = Color(0.25, 0.20, 0.15, 0.88)
			add_theme_color_override("font_color", Color(0.52, 0.45, 0.36, 1.0))

	if node_type == "keystone":
		style.corner_radius_top_left = 18
		style.corner_radius_top_right = 18
		style.corner_radius_bottom_left = 18
		style.corner_radius_bottom_right = 18
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
	if selected:
		style.border_color = Color(0.35, 0.90, 1.0, 1.0)
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4

	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
