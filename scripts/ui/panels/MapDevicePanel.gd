class_name RVMapDevicePanel
extends Control

@onready var list_label: Label = %MapListLabel
@onready var detail_label: Label = %MapDetailLabel
@onready var hint_label: Label = %HintLabel
@onready var selected_label: Label = %SelectedMapLabel
@onready var run_button: Button = %RunMapButton
@onready var add_button: Button = %AddDevMapButton
@onready var close_button: Button = %CloseButton

var current_state: RVGameState = null
var map_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	_bind_buttons()

func _bind_buttons() -> void:
	map_buttons.clear()
	for i: int in range(8):
		var button: Button = get_node_or_null("%MapButton" + str(i)) as Button
		if button != null:
			map_buttons.append(button)
			var index: int = i
			button.pressed.connect(func() -> void: _select_map(index))
	if run_button != null:
		run_button.pressed.connect(func() -> void:
			if current_state == null: return
			RVMapSystem.prepare_selected_map_activity(current_state)
			update_from_state(current_state)
		)
	if add_button != null:
		add_button.pressed.connect(func() -> void:
			if current_state == null: return
			RVMapSystem.add_random_map_drop(current_state, max(1, current_state.level + current_state.rooms_cleared), "dev")
			update_from_state(current_state)
		)
	if close_button != null:
		close_button.pressed.connect(func() -> void:
			if current_state != null: current_state.panel_mode = ""
			visible = false
		)

func update_from_state(state: RVGameState) -> void:
	current_state = state
	RVMapSystem.ensure_defaults(state)
	if list_label != null: list_label.text = RVMapSystem.map_stash_text(state)
	if detail_label != null: detail_label.text = RVMapSystem.selected_map_detail(state)
	if selected_label != null:
		var selected: Dictionary = RVMapSystem.selected_map(state)
		selected_label.text = "Inserted Map: " + (str(selected.get("name", "None")) if not selected.is_empty() else "None")
	if hint_label != null: hint_label.text = "Physical station: walk to Map Device and press E · W/S select · Enter/R run · G dev map · Esc close"
	_refresh_map_buttons()

func _refresh_map_buttons() -> void:
	if current_state == null: return
	for i: int in range(map_buttons.size()):
		var button: Button = map_buttons[i]
		if i >= current_state.map_stash.size():
			button.text = "Empty"
			button.disabled = true
			button.modulate = Color(0.55, 0.55, 0.55, 1.0)
			continue
		var map_item: Dictionary = Dictionary(current_state.map_stash[i])
		button.disabled = false
		button.text = RVMapSystem.map_brief(map_item)
		button.tooltip_text = str(map_item.get("description", ""))
		button.modulate = Color(1.0, 0.84, 0.42, 1.0) if i == current_state.map_cursor else Color.WHITE

func _select_map(index: int) -> void:
	if current_state == null or index < 0 or index >= current_state.map_stash.size(): return
	current_state.map_cursor = index
	update_from_state(current_state)
