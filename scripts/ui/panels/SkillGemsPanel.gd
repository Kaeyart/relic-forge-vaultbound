class_name RVSkillGemsPanel
extends RVUIPanelBase

# Patch 051: scene-authored Skill Gems panel.
# The scene owns layout and all interactive nodes. This script only binds data,
# updates text/visibility, and routes mouse actions.

var current_state: RVGameState = null
var selected_family: String = "active"
var selected_socket_index: int = -1

var active_buttons: Array[Button] = []
var support_buttons: Array[Button] = []
var spirit_buttons: Array[Button] = []
var socket_buttons: Array[Button] = []
var choice_buttons: Array[Button] = []
var choice_callbacks: Array[Callable] = []

var pending_support_index: int = -1
var pending_target_type: String = ""
var pending_target_index: int = -1

var dragging_support: bool = false
var drag_support_index: int = -1

@onready var title_label: Label = get_node_or_null("TitleLabel") as Label
@onready var detail_label: RichTextLabel = get_node_or_null("DetailPanel/DetailLabel") as RichTextLabel
@onready var detail_title_label: Label = get_node_or_null("DetailPanel/DetailTitleLabel") as Label
@onready var selected_context_label: Label = get_node_or_null("DetailPanel/SelectedContextLabel") as Label
@onready var spirit_meter_label: Label = get_node_or_null("SpiritPanel/SpiritMeterLabel") as Label
@onready var support_hint_label: Label = get_node_or_null("SupportPanel/SupportHintLabel") as Label
@onready var choice_panel: Control = get_node_or_null("ChoicePanel") as Control
@onready var choice_title_label: Label = get_node_or_null("ChoicePanel/ChoiceTitleLabel") as Label
@onready var drag_preview: Label = get_node_or_null("DragPreview") as Label
@onready var equip_button: Button = get_node_or_null("Actions/EquipButton") as Button
@onready var add_skill_socket_button: Button = get_node_or_null("Actions/AddSkillSocketButton") as Button
@onready var add_spirit_socket_button: Button = get_node_or_null("Actions/AddSpiritSocketButton") as Button
@onready var enable_spirit_button: Button = get_node_or_null("Actions/EnableSpiritButton") as Button
@onready var unsocket_button: Button = get_node_or_null("Actions/UnsocketButton") as Button
@onready var close_button: Button = get_node_or_null("Actions/CloseButton") as Button

func _ready() -> void:
	super._ready()
	set_process(true)
	set_process_unhandled_input(true)
	_collect_scene_nodes()
	_connect_scene_nodes()
	_hide_choice_panel()
	if drag_preview != null:
		drag_preview.visible = false

func update_from_state(state: RVGameState) -> void:
	current_state = state
	if current_state != null:
		current_state.ensure_defaults()
	_refresh_all()

func _collect_scene_nodes() -> void:
	active_buttons = _collect_buttons("ActivePanel/ActiveGemButton", 8)
	support_buttons = _collect_buttons("SupportPanel/SupportGemButton", 16)
	spirit_buttons = _collect_buttons("SpiritPanel/SpiritGemButton", 6)
	socket_buttons = _collect_buttons("DetailPanel/SocketButton", 6)
	choice_buttons = _collect_buttons("ChoicePanel/ChoiceButton", 18)

func _collect_buttons(prefix: String, count: int) -> Array[Button]:
	var result: Array[Button] = []
	for i: int in range(count):
		var button: Button = get_node_or_null(prefix + str(i)) as Button
		if button != null:
			result.append(button)
	return result

func _connect_scene_nodes() -> void:
	for i: int in range(active_buttons.size()):
		active_buttons[i].pressed.connect(_on_active_pressed.bind(i))
		active_buttons[i].gui_input.connect(_on_active_gui_input.bind(i))
	for i: int in range(support_buttons.size()):
		support_buttons[i].pressed.connect(_on_support_pressed.bind(i))
		support_buttons[i].gui_input.connect(_on_support_gui_input.bind(i))
	for i: int in range(spirit_buttons.size()):
		spirit_buttons[i].pressed.connect(_on_spirit_pressed.bind(i))
		spirit_buttons[i].gui_input.connect(_on_spirit_gui_input.bind(i))
	for i: int in range(socket_buttons.size()):
		socket_buttons[i].pressed.connect(_on_socket_pressed.bind(i))
		socket_buttons[i].gui_input.connect(_on_socket_gui_input.bind(i))
	for i: int in range(choice_buttons.size()):
		choice_buttons[i].pressed.connect(_on_choice_pressed.bind(i))
	if equip_button != null:
		equip_button.pressed.connect(_on_equip_pressed)
	if add_skill_socket_button != null:
		add_skill_socket_button.pressed.connect(_on_add_skill_socket_pressed)
	if add_spirit_socket_button != null:
		add_spirit_socket_button.pressed.connect(_on_add_spirit_socket_pressed)
	if enable_spirit_button != null:
		enable_spirit_button.pressed.connect(_on_enable_spirit_pressed)
	if unsocket_button != null:
		unsocket_button.pressed.connect(_on_unsocket_pressed)
	if close_button != null:
		close_button.pressed.connect(_on_close_pressed)
	var cancel: Button = get_node_or_null("ChoicePanel/ChoiceCancelButton") as Button
	if cancel != null:
		cancel.pressed.connect(_hide_choice_panel)

func _process(_delta: float) -> void:
	if not dragging_support or drag_preview == null:
		return
	drag_preview.global_position = get_viewport().get_mouse_position() + Vector2(18.0, 18.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if dragging_support and not mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_finish_support_drag(mouse_event.position)
		elif dragging_support and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_drag()
	elif event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			if dragging_support:
				_cancel_drag()
			else:
				_hide_choice_panel()

func _refresh_all() -> void:
	_refresh_active_buttons()
	_refresh_support_buttons()
	_refresh_spirit_buttons()
	_refresh_socket_buttons()
	_refresh_detail()
	_refresh_action_buttons()

func _refresh_active_buttons() -> void:
	for i: int in range(active_buttons.size()):
		var button: Button = active_buttons[i]
		if current_state == null or i >= current_state.skill_gem_inventory.size():
			_set_button_empty(button, "Empty Skill Slot")
			continue
		var gem: Dictionary = Dictionary(current_state.skill_gem_inventory[i])
		button.visible = true
		button.disabled = false
		button.text = _selection_prefix("active", i) + _gem_row_text(gem)
		button.tooltip_text = _gem_tooltip(gem)
		button.modulate = Color(1.0, 0.86, 0.55, 1.0) if selected_family == "active" and i == current_state.skill_gem_cursor else Color.WHITE

func _refresh_support_buttons() -> void:
	for i: int in range(support_buttons.size()):
		var button: Button = support_buttons[i]
		if current_state == null or i >= current_state.support_gem_inventory.size():
			_set_button_empty(button, "Empty Support Slot")
			continue
		var gem: Dictionary = Dictionary(current_state.support_gem_inventory[i])
		button.visible = true
		button.disabled = false
		button.text = _selection_prefix("support", i) + _gem_row_text(gem)
		button.tooltip_text = _gem_tooltip(gem)
		button.modulate = Color(0.82, 0.94, 1.0, 1.0) if selected_family == "support" and i == current_state.support_gem_cursor else Color.WHITE

func _refresh_spirit_buttons() -> void:
	for i: int in range(spirit_buttons.size()):
		var button: Button = spirit_buttons[i]
		if current_state == null or i >= current_state.spirit_gem_inventory.size():
			_set_button_empty(button, "Empty Spirit Slot")
			continue
		var gem: Dictionary = Dictionary(current_state.spirit_gem_inventory[i])
		button.visible = true
		button.disabled = false
		button.text = _selection_prefix("spirit", i) + _gem_row_text(gem)
		button.tooltip_text = _gem_tooltip(gem)
		button.modulate = Color(0.72, 0.62, 1.0, 1.0) if selected_family == "spirit" and i == current_state.spirit_gem_cursor else Color.WHITE
	if spirit_meter_label != null and current_state != null:
		var maximum: int = max(1, int(current_state.spirit_max))
		var reserved: int = int(current_state.spirit_reserved)
		spirit_meter_label.text = "Spirit: " + str(reserved) + " / " + str(maximum) + " reserved   " + str(maximum - reserved) + " available"

func _refresh_socket_buttons() -> void:
	var selected: Dictionary = _selected_socket_owner()
	var supports: Array = selected.get("supports", []) if not selected.is_empty() else []
	var max_sockets: int = int(selected.get("max_support_sockets", 0)) if not selected.is_empty() else 0
	for i: int in range(socket_buttons.size()):
		var button: Button = socket_buttons[i]
		button.visible = true
		button.disabled = selected.is_empty()
		if selected.is_empty():
			button.text = "-"
			button.tooltip_text = "Select an active or spirit gem."
		elif i < supports.size():
			var support_id: String = str(supports[i])
			var data: Dictionary = RVSkillGemDB.support_data(support_id)
			button.text = _short_name(str(data.get("name", support_id)), 11)
			button.tooltip_text = str(data.get("description", "Socketed support. Right-click to remove last support."))
		elif i < max_sockets:
			button.text = "Empty"
			button.tooltip_text = "Empty support socket. Drag a support gem here."
		else:
			button.text = "Locked"
			button.tooltip_text = "Use a Socket Prism to unlock another support socket."
		button.modulate = Color(1.0, 0.88, 0.48, 1.0) if i == selected_socket_index else Color.WHITE

func _refresh_detail() -> void:
	if detail_label == null:
		return
	var gem: Dictionary = _selected_gem()
	var family: String = selected_family
	if detail_title_label != null:
		detail_title_label.text = "SELECTED " + family.to_upper() + " GEM"
	if selected_context_label != null:
		selected_context_label.text = _selected_context_text()
	if gem.is_empty():
		detail_label.text = "[color=#d8c38f]No gem selected.[/color]\n\nClick a gem card to inspect it. Right-click uncut gems to choose what they become."
		return
	detail_label.text = _gem_detail(gem, family)

func _refresh_action_buttons() -> void:
	var has_state: bool = current_state != null
	if equip_button != null:
		equip_button.disabled = not has_state or current_state.skill_gem_inventory.is_empty()
	if add_skill_socket_button != null:
		add_skill_socket_button.disabled = not has_state or current_state.skill_gem_inventory.is_empty()
	if add_spirit_socket_button != null:
		add_spirit_socket_button.disabled = not has_state or current_state.spirit_gem_inventory.is_empty()
	if enable_spirit_button != null:
		enable_spirit_button.disabled = not has_state or current_state.spirit_gem_inventory.is_empty()
	if unsocket_button != null:
		unsocket_button.disabled = not has_state or _selected_socket_owner().is_empty()

func _on_active_pressed(index: int) -> void:
	if current_state == null or index >= current_state.skill_gem_inventory.size():
		return
	current_state.skill_gem_cursor = index
	selected_family = "active"
	selected_socket_index = -1
	_hide_choice_panel()
	_refresh_all()

func _on_support_pressed(index: int) -> void:
	if current_state == null or index >= current_state.support_gem_inventory.size():
		return
	current_state.support_gem_cursor = index
	selected_family = "support"
	selected_socket_index = -1
	_hide_choice_panel()
	_refresh_all()

func _on_spirit_pressed(index: int) -> void:
	if current_state == null or index >= current_state.spirit_gem_inventory.size():
		return
	current_state.spirit_gem_cursor = index
	selected_family = "spirit"
	selected_socket_index = -1
	_hide_choice_panel()
	_refresh_all()

func _on_socket_pressed(index: int) -> void:
	selected_socket_index = index
	_refresh_all()

func _on_active_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_on_active_pressed(index)
			var gem: Dictionary = Dictionary(current_state.skill_gem_inventory[index])
			if RVSkillGemSystem.is_uncut_skill_gem(gem):
				_show_cut_skill_choices()

func _on_support_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_on_support_pressed(index)
			var gem: Dictionary = Dictionary(current_state.support_gem_inventory[index])
			if RVSkillGemSystem.is_uncut_support_gem(gem):
				_show_support_target_choices(index)
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_on_support_pressed(index)
			_start_support_drag(index)

func _on_spirit_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_on_spirit_pressed(index)
			var gem: Dictionary = Dictionary(current_state.spirit_gem_inventory[index])
			if RVSkillGemSystem.is_uncut_spirit_gem(gem):
				_show_cut_spirit_choices()

func _on_socket_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			selected_socket_index = index
			_on_unsocket_pressed()

func _on_equip_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.toggle_selected_active_gem_equipped(current_state)
	selected_family = "active"
	_after_state_change()

func _on_add_skill_socket_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.add_socket_to_selected_active(current_state)
	selected_family = "active"
	_after_state_change()

func _on_add_spirit_socket_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.add_socket_to_selected_spirit(current_state)
	selected_family = "spirit"
	_after_state_change()

func _on_enable_spirit_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.toggle_selected_spirit(current_state)
	selected_family = "spirit"
	_after_state_change()

func _on_unsocket_pressed() -> void:
	if current_state == null:
		return
	if selected_family == "active":
		RVSkillGemSystem.remove_last_support_from_active(current_state)
	else:
		_remove_last_support_from_selected_spirit()
	_after_state_change()

func _on_close_pressed() -> void:
	if current_state != null:
		current_state.panel_mode = ""

func _remove_last_support_from_selected_spirit() -> void:
	if current_state == null or current_state.spirit_gem_inventory.is_empty():
		return
	current_state.spirit_gem_cursor = clamp(current_state.spirit_gem_cursor, 0, current_state.spirit_gem_inventory.size() - 1)
	var gem: Dictionary = Dictionary(current_state.spirit_gem_inventory[current_state.spirit_gem_cursor])
	var supports: Array = Array(gem.get("supports", []))
	if supports.is_empty():
		current_state.add_notice("No support to remove")
		return
	var support_id: String = str(supports.pop_back())
	gem["supports"] = supports
	current_state.spirit_gem_inventory[current_state.spirit_gem_cursor] = gem
	current_state.support_gem_inventory.append(_make_returned_support_gem(support_id))
	current_state.add_notice("Spirit support removed")
	current_state.recompute_stats()

func _make_returned_support_gem(support_id: String) -> Dictionary:
	var data: Dictionary = RVSkillGemDB.support_data(support_id)
	return {
		"uid": "returned_support_" + str(Time.get_ticks_msec()),
		"type": "support",
		"gem_id": support_id,
		"name": str(data.get("name", support_id)),
		"level": 1,
		"xp": 0.0
	}

func _show_cut_skill_choices() -> void:
	var labels: Array[String] = []
	var callbacks: Array[Callable] = []
	for value: Variant in RVSkillGemDB.active_ids():
		var active_id: String = str(value)
		var data: Dictionary = RVSkillGemDB.active_data(active_id)
		labels.append(str(data.get("name", active_id)))
		callbacks.append(func() -> void:
			RVSkillGemSystem.cut_uncut_skill_gem(current_state, current_state.skill_gem_cursor, active_id)
			selected_family = "active"
			_after_state_change()
		)
	_show_choice_panel("Choose Active Skill", labels, callbacks)

func _show_cut_spirit_choices() -> void:
	var labels: Array[String] = []
	var callbacks: Array[Callable] = []
	for value: Variant in RVSkillGemDB.spirit_ids():
		var spirit_id: String = str(value)
		var data: Dictionary = RVSkillGemDB.spirit_data(spirit_id)
		labels.append(str(data.get("name", spirit_id)))
		callbacks.append(func() -> void:
			RVSkillGemSystem.cut_uncut_spirit_gem(current_state, current_state.spirit_gem_cursor, spirit_id)
			selected_family = "spirit"
			_after_state_change()
		)
	_show_choice_panel("Choose Spirit Skill", labels, callbacks)

func _show_support_target_choices(support_index: int) -> void:
	pending_support_index = support_index
	var labels: Array[String] = []
	var callbacks: Array[Callable] = []
	if current_state == null:
		return
	for i: int in range(current_state.skill_gem_inventory.size()):
		var gem: Dictionary = Dictionary(current_state.skill_gem_inventory[i])
		if str(gem.get("type", "")) == "active":
			labels.append("Skill: " + str(gem.get("name", "Skill")))
			callbacks.append(func() -> void:
				pending_target_type = "active"
				pending_target_index = i
				_show_support_effect_choices()
			)
	for j: int in range(current_state.spirit_gem_inventory.size()):
		var spirit: Dictionary = Dictionary(current_state.spirit_gem_inventory[j])
		if str(spirit.get("type", "")) == "spirit":
			labels.append("Spirit: " + str(spirit.get("name", "Spirit")))
			callbacks.append(func() -> void:
				pending_target_type = "spirit"
				pending_target_index = j
				_show_support_effect_choices()
			)
	_show_choice_panel("Choose Support Target", labels, callbacks)

func _show_support_effect_choices() -> void:
	var target: Dictionary = _target_gem(pending_target_type, pending_target_index)
	var support_ids: Array = RVSkillGemSystem.compatible_support_ids_for_target(pending_target_type, target)
	var labels: Array[String] = []
	var callbacks: Array[Callable] = []
	for value: Variant in support_ids:
		var support_id: String = str(value)
		var data: Dictionary = RVSkillGemDB.support_data(support_id)
		labels.append(str(data.get("name", support_id)))
		callbacks.append(func() -> void:
			RVSkillGemSystem.cut_uncut_support_gem_for_target(current_state, pending_support_index, pending_target_type, pending_target_index, support_id)
			selected_family = pending_target_type if pending_target_type == "spirit" else "active"
			_after_state_change()
		)
	if labels.is_empty():
		labels.append("No compatible support effects")
		callbacks.append(func() -> void:
			_hide_choice_panel()
		)
	_show_choice_panel("Choose Support Effect", labels, callbacks)

func _show_choice_panel(title: String, labels: Array[String], callbacks: Array[Callable]) -> void:
	choice_callbacks = callbacks
	if choice_panel != null:
		choice_panel.visible = true
	if choice_title_label != null:
		choice_title_label.text = title
	for i: int in range(choice_buttons.size()):
		var button: Button = choice_buttons[i]
		if i < labels.size():
			button.visible = true
			button.disabled = false
			button.text = labels[i]
		else:
			button.visible = false
			button.disabled = true
			button.text = ""

func _hide_choice_panel() -> void:
	if choice_panel != null:
		choice_panel.visible = false
	choice_callbacks = []
	pending_support_index = -1
	pending_target_type = ""
	pending_target_index = -1

func _on_choice_pressed(index: int) -> void:
	if index >= 0 and index < choice_callbacks.size():
		choice_callbacks[index].call()

func _start_support_drag(index: int) -> void:
	if current_state == null or index < 0 or index >= current_state.support_gem_inventory.size():
		return
	dragging_support = true
	drag_support_index = index
	if drag_preview != null:
		var gem: Dictionary = Dictionary(current_state.support_gem_inventory[index])
		drag_preview.text = str(gem.get("name", "Support"))
		drag_preview.visible = true
		drag_preview.z_index = 200

func _finish_support_drag(mouse_pos: Vector2) -> void:
	if current_state == null or drag_support_index < 0 or drag_support_index >= current_state.support_gem_inventory.size():
		_cancel_drag()
		return
	var target: Dictionary = _drop_target_at(mouse_pos)
	if target.is_empty():
		_cancel_drag()
		return
	var gem: Dictionary = Dictionary(current_state.support_gem_inventory[drag_support_index])
	var target_type: String = str(target.get("type", ""))
	var target_index: int = int(target.get("index", -1))
	current_state.support_gem_cursor = drag_support_index
	if RVSkillGemSystem.is_uncut_support_gem(gem):
		_cancel_drag()
		pending_support_index = drag_support_index
		pending_target_type = target_type
		pending_target_index = target_index
		_show_support_effect_choices()
		return
	if target_type == "active":
		current_state.skill_gem_cursor = target_index
		RVSkillGemSystem.socket_selected_support_to_active(current_state)
	elif target_type == "spirit":
		current_state.spirit_gem_cursor = target_index
		RVSkillGemSystem.socket_selected_support_to_spirit(current_state)
	_cancel_drag()
	_after_state_change()

func _drop_target_at(mouse_pos: Vector2) -> Dictionary:
	for i: int in range(active_buttons.size()):
		var button: Button = active_buttons[i]
		if button.visible and button.get_global_rect().has_point(mouse_pos):
			return {"type": "active", "index": i}
	for j: int in range(spirit_buttons.size()):
		var spirit_button: Button = spirit_buttons[j]
		if spirit_button.visible and spirit_button.get_global_rect().has_point(mouse_pos):
			return {"type": "spirit", "index": j}
	for k: int in range(socket_buttons.size()):
		var socket_button: Button = socket_buttons[k]
		if socket_button.visible and socket_button.get_global_rect().has_point(mouse_pos):
			if selected_family == "spirit":
				return {"type": "spirit", "index": current_state.spirit_gem_cursor}
			return {"type": "active", "index": current_state.skill_gem_cursor}
	return {}

func _cancel_drag() -> void:
	dragging_support = false
	drag_support_index = -1
	if drag_preview != null:
		drag_preview.visible = false

func _target_gem(target_type: String, target_index: int) -> Dictionary:
	if current_state == null:
		return {}
	if target_type == "active" and target_index >= 0 and target_index < current_state.skill_gem_inventory.size():
		return Dictionary(current_state.skill_gem_inventory[target_index])
	if target_type == "spirit" and target_index >= 0 and target_index < current_state.spirit_gem_inventory.size():
		return Dictionary(current_state.spirit_gem_inventory[target_index])
	return {}

func _selected_gem() -> Dictionary:
	if current_state == null:
		return {}
	if selected_family == "support" and current_state.support_gem_inventory.size() > 0:
		current_state.support_gem_cursor = clamp(current_state.support_gem_cursor, 0, current_state.support_gem_inventory.size() - 1)
		return Dictionary(current_state.support_gem_inventory[current_state.support_gem_cursor])
	if selected_family == "spirit" and current_state.spirit_gem_inventory.size() > 0:
		current_state.spirit_gem_cursor = clamp(current_state.spirit_gem_cursor, 0, current_state.spirit_gem_inventory.size() - 1)
		return Dictionary(current_state.spirit_gem_inventory[current_state.spirit_gem_cursor])
	if current_state.skill_gem_inventory.size() > 0:
		current_state.skill_gem_cursor = clamp(current_state.skill_gem_cursor, 0, current_state.skill_gem_inventory.size() - 1)
		return Dictionary(current_state.skill_gem_inventory[current_state.skill_gem_cursor])
	return {}

func _selected_socket_owner() -> Dictionary:
	if current_state == null:
		return {}
	if selected_family == "spirit" and current_state.spirit_gem_inventory.size() > 0:
		return Dictionary(current_state.spirit_gem_inventory[clamp(current_state.spirit_gem_cursor, 0, current_state.spirit_gem_inventory.size() - 1)])
	if current_state.skill_gem_inventory.size() > 0:
		return Dictionary(current_state.skill_gem_inventory[clamp(current_state.skill_gem_cursor, 0, current_state.skill_gem_inventory.size() - 1)])
	return {}

func _selected_context_text() -> String:
	if current_state == null:
		return "No state loaded."
	if selected_family == "active":
		return "Selected: Active Gem Slot " + str(current_state.skill_gem_cursor + 1)
	if selected_family == "support":
		return "Selected: Support Gem " + str(current_state.support_gem_cursor + 1)
	return "Selected: Spirit Gem " + str(current_state.spirit_gem_cursor + 1)

func _selection_prefix(family: String, index: int) -> String:
	if current_state == null:
		return ""
	if family == "active" and selected_family == "active" and index == current_state.skill_gem_cursor:
		return "▶ "
	if family == "support" and selected_family == "support" and index == current_state.support_gem_cursor:
		return "▶ "
	if family == "spirit" and selected_family == "spirit" and index == current_state.spirit_gem_cursor:
		return "▶ "
	return "  "

func _set_button_empty(button: Button, label: String) -> void:
	button.visible = true
	button.disabled = true
	button.text = label
	button.tooltip_text = ""
	button.modulate = Color(0.42, 0.42, 0.42, 1.0)

func _gem_row_text(gem: Dictionary) -> String:
	var name: String = str(gem.get("name", "Gem"))
	var level: int = int(gem.get("level", 1))
	var result: String = _short_name(name, 24) + "  Lv " + str(level)
	var gem_type: String = str(gem.get("type", ""))
	if gem_type == "active" or gem_type == "spirit":
		result += "  [" + str(Array(gem.get("supports", [])).size()) + "/" + str(int(gem.get("max_support_sockets", 2))) + "]"
	if gem_type == "active" and bool(gem.get("equipped", false)):
		result += "  ON"
	if gem_type == "spirit" and bool(gem.get("enabled", false)):
		result += "  RES"
	if gem_type.begins_with("uncut"):
		result += "  RMB"
	return result

func _gem_tooltip(gem: Dictionary) -> String:
	return str(gem.get("description", gem.get("name", "Gem")))

func _gem_detail(gem: Dictionary, family: String) -> String:
	var text: String = ""
	var gem_type: String = str(gem.get("type", family))
	text += "[font_size=18][color=#f0d28a][b]" + str(gem.get("name", "Gem")) + "[/b][/color][/font_size]\n"
	text += "Level " + str(int(gem.get("level", 1))) + "    Type: " + gem_type + "\n\n"
	if gem_type.begins_with("uncut"):
		text += "[color=#d8c38f]" + str(gem.get("description", "Right-click to choose what this becomes.")) + "[/color]\n"
		return text
	if gem_type == "active":
		var data: Dictionary = RVSkillGemDB.active_data(str(gem.get("gem_id", "")))
		text += "[color=#d8c38f]Tags:[/color] " + _join_string_array(Array(data.get("tags", []))) + "\n"
		text += "[color=#d8c38f]Sockets:[/color] " + str(Array(gem.get("supports", [])).size()) + " / " + str(int(gem.get("max_support_sockets", 2))) + "\n"
		text += "[color=#d8c38f]Equipped:[/color] " + ("yes" if bool(gem.get("equipped", false)) else "no") + "\n\n"
		text += str(data.get("description", "")) + "\n\n"
		text += _support_line(gem)
	elif gem_type == "support":
		var support_data: Dictionary = RVSkillGemDB.support_data(str(gem.get("gem_id", "")))
		text += "[color=#d8c38f]Compatible:[/color] " + _join_string_array(Array(support_data.get("compatible_tags", []))) + "\n"
		text += str(support_data.get("description", "")) + "\n"
	elif gem_type == "spirit":
		var spirit_data: Dictionary = RVSkillGemDB.spirit_data(str(gem.get("gem_id", "")))
		text += "[color=#d8c38f]Tags:[/color] " + _join_string_array(Array(spirit_data.get("tags", []))) + "\n"
		text += "[color=#d8c38f]Reservation:[/color] " + str(RVSkillGemSystem.spirit_reservation(gem)) + " Spirit\n"
		text += "[color=#d8c38f]Sockets:[/color] " + str(Array(gem.get("supports", [])).size()) + " / " + str(int(gem.get("max_support_sockets", 2))) + "\n"
		text += "[color=#d8c38f]Enabled:[/color] " + ("yes" if bool(gem.get("enabled", false)) else "no") + "\n\n"
		text += str(spirit_data.get("description", "")) + "\n\n"
		text += _support_line(gem)
	return text

func _support_line(gem: Dictionary) -> String:
	var supports: Array = Array(gem.get("supports", []))
	if supports.is_empty():
		return "[color=#8f8372]Supports: none[/color]\n"
	var names: Array[String] = []
	for value: Variant in supports:
		var support_data: Dictionary = RVSkillGemDB.support_data(str(value))
		names.append(str(support_data.get("name", value)))
	return "[color=#f0d28a]Supports:[/color] " + ", ".join(PackedStringArray(names)) + "\n"

func _short_name(value: String, limit: int) -> String:
	if value.length() <= limit:
		return value
	return value.substr(0, max(1, limit - 1)) + "…"

func _join_string_array(values: Array) -> String:
	var strings: Array[String] = []
	for value: Variant in values:
		strings.append(str(value))
	return ", ".join(PackedStringArray(strings))

func _after_state_change() -> void:
	_hide_choice_panel()
	selected_socket_index = -1
	if current_state != null:
		current_state.ensure_defaults()
		current_state.recompute_stats()
	_refresh_all()
