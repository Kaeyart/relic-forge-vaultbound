class_name RVSkillGemsPanel
extends Control

var current_state: RVGameState = null
var selected_kind: String = "active"
var selected_index: int = 0
var choice_mode: String = ""
var choice_context: Dictionary = {}

@onready var active_list: VBoxContainer = %ActiveGemList
@onready var support_list: VBoxContainer = %SupportGemList
@onready var spirit_list: VBoxContainer = %SpiritGemList
@onready var detail_label: RichTextLabel = %GemDetailLabel
@onready var choice_panel: PanelContainer = %ChoicePanel
@onready var choice_title: Label = %ChoiceTitle
@onready var choice_list: VBoxContainer = %ChoiceList
@onready var equip_button: Button = %EquipButton
@onready var enable_spirit_button: Button = %EnableSpiritButton
@onready var remove_support_button: Button = %RemoveSupportButton
@onready var socket_prism_button: Button = %SocketPrismButton
@onready var close_button: Button = %CloseButton
@onready var help_label: Label = %HelpLabel

func _ready() -> void:
	visible = false
	choice_panel.visible = false
	equip_button.pressed.connect(_on_equip_pressed)
	enable_spirit_button.pressed.connect(_on_enable_spirit_pressed)
	remove_support_button.pressed.connect(_on_remove_support_pressed)
	socket_prism_button.pressed.connect(_on_socket_prism_pressed)
	close_button.pressed.connect(_on_close_pressed)

func update_from_state(state: RVGameState) -> void:
	current_state = state
	if current_state != null:
		RVSkillGemSystem.ensure_gem_baseline(current_state)
	_rebuild_lists()
	_refresh_detail()

func _clear_container(container: VBoxContainer) -> void:
	for child: Node in container.get_children():
		child.queue_free()

func _rebuild_lists() -> void:
	_clear_container(active_list)
	_clear_container(support_list)
	_clear_container(spirit_list)
	if current_state == null:
		return
	_build_active_list()
	_build_support_list()
	_build_spirit_list()
	_update_action_buttons()

func _build_active_list() -> void:
	for i: int in range(current_state.skill_gem_inventory.size()):
		var gem: Dictionary = current_state.skill_gem_inventory[i]
		var button: Button = _make_gem_button(gem, selected_kind == "active" and selected_index == i)
		button.pressed.connect(_on_active_pressed.bind(i))
		button.gui_input.connect(_on_active_gui_input.bind(i))
		active_list.add_child(button)

func _build_support_list() -> void:
	for i: int in range(current_state.support_gem_inventory.size()):
		var gem: Dictionary = current_state.support_gem_inventory[i]
		var button: Button = _make_gem_button(gem, selected_kind == "support" and selected_index == i)
		button.pressed.connect(_on_support_pressed.bind(i))
		button.gui_input.connect(_on_support_gui_input.bind(i))
		support_list.add_child(button)

func _build_spirit_list() -> void:
	for i: int in range(current_state.spirit_gem_inventory.size()):
		var gem: Dictionary = current_state.spirit_gem_inventory[i]
		var button: Button = _make_gem_button(gem, selected_kind == "spirit" and selected_index == i)
		button.pressed.connect(_on_spirit_pressed.bind(i))
		button.gui_input.connect(_on_spirit_gui_input.bind(i))
		spirit_list.add_child(button)

func _make_gem_button(gem: Dictionary, selected: bool) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(230.0, 34.0)
	var prefix: String = ""
	if bool(gem.get("uncut", false)):
		prefix = "◇ "
	elif bool(gem.get("equipped", false)) or bool(gem.get("enabled", false)):
		prefix = "● "
	else:
		prefix = "○ "
	if selected:
		prefix = "> " + prefix
	button.text = prefix + RVSkillGemSystem.gem_short_text(gem)
	button.tooltip_text = RVSkillGemSystem.gem_detail_text(gem)
	return button

func _select(kind: String, index: int) -> void:
	selected_kind = kind
	selected_index = max(0, index)
	if current_state != null:
		match kind:
			"active": current_state.skill_gem_cursor = selected_index
			"support": current_state.support_gem_cursor = selected_index
			"spirit": current_state.spirit_gem_cursor = selected_index
	choice_panel.visible = false
	choice_mode = ""
	_rebuild_lists()
	_refresh_detail()

func _on_active_pressed(index: int) -> void:
	_select("active", index)

func _on_support_pressed(index: int) -> void:
	_select("support", index)

func _on_spirit_pressed(index: int) -> void:
	_select("spirit", index)

func _on_active_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_select("active", index)
			_open_active_choice(index)

func _on_support_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_select("support", index)
			_open_support_target_choice(index)

func _on_spirit_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_select("spirit", index)
			_open_spirit_choice(index)

func _selected_gem() -> Dictionary:
	if current_state == null:
		return {}
	if selected_kind == "active" and selected_index >= 0 and selected_index < current_state.skill_gem_inventory.size():
		return current_state.skill_gem_inventory[selected_index]
	if selected_kind == "support" and selected_index >= 0 and selected_index < current_state.support_gem_inventory.size():
		return current_state.support_gem_inventory[selected_index]
	if selected_kind == "spirit" and selected_index >= 0 and selected_index < current_state.spirit_gem_inventory.size():
		return current_state.spirit_gem_inventory[selected_index]
	return {}

func _refresh_detail() -> void:
	if detail_label == null:
		return
	var gem: Dictionary = _selected_gem()
	var text: String = "[b]Skill Gem Forge[/b]\n"
	text += "Right-click uncut skill/spirit gems to choose what they become.\n"
	text += "Right-click support gems to choose a target and support type.\n\n"
	if current_state != null:
		text += "Spirit: " + str(current_state.spirit_reserved) + "/" + str(current_state.spirit_max) + "\n"
		text += "Socket Prisms: " + str(int(current_state.materials.get("socket_prisms", 0))) + "\n\n"
	text += RVSkillGemSystem.gem_detail_text(gem)
	if selected_kind == "active" or selected_kind == "spirit":
		text += "\nCompatible supports:\n"
		var compatible: Array[String] = RVSkillGemSystem.compatible_support_ids_for_target(gem)
		if compatible.is_empty():
			text += "- None until this gem is engraved.\n"
		else:
			for support_id: String in compatible:
				text += "- " + RVSkillGemDB.name_for_support(support_id) + "\n"
	detail_label.text = text
	_update_action_buttons()

func _update_action_buttons() -> void:
	var gem: Dictionary = _selected_gem()
	var has_gem: bool = not gem.is_empty()
	equip_button.disabled = not (has_gem and selected_kind == "active" and not bool(gem.get("uncut", false)))
	enable_spirit_button.disabled = not (has_gem and selected_kind == "spirit" and not bool(gem.get("uncut", false)))
	remove_support_button.disabled = not (has_gem and (selected_kind == "active" or selected_kind == "spirit") and Array(gem.get("supports", [])).size() > 0)
	socket_prism_button.disabled = not (has_gem and (selected_kind == "active" or selected_kind == "spirit") and not bool(gem.get("uncut", false)))
	if selected_kind == "active" and has_gem:
		equip_button.text = "Unequip Skill" if bool(gem.get("equipped", false)) else "Equip Skill"
	if selected_kind == "spirit" and has_gem:
		enable_spirit_button.text = "Disable Spirit" if bool(gem.get("enabled", false)) else "Enable Spirit"

func _open_active_choice(index: int) -> void:
	choice_mode = "engrave_active"
	choice_context = {"index": index}
	_show_choices("Choose Active Skill", RVSkillGemDB.active_ids(), "active")

func _open_spirit_choice(index: int) -> void:
	choice_mode = "engrave_spirit"
	choice_context = {"index": index}
	_show_choices("Choose Spirit Skill", RVSkillGemDB.spirit_ids(), "spirit")

func _open_support_target_choice(index: int) -> void:
	choice_mode = "support_target"
	choice_context = {"support_index": index}
	_clear_container(choice_list)
	choice_title.text = "Choose Support Target"
	choice_panel.visible = true
	for i: int in range(current_state.skill_gem_inventory.size()):
		var active_gem: Dictionary = current_state.skill_gem_inventory[i]
		if bool(active_gem.get("uncut", false)):
			continue
		_add_choice_button("Active: " + RVSkillGemSystem.gem_short_text(active_gem), {"kind": "active", "index": i})
	for j: int in range(current_state.spirit_gem_inventory.size()):
		var spirit_gem: Dictionary = current_state.spirit_gem_inventory[j]
		if bool(spirit_gem.get("uncut", false)):
			continue
		_add_choice_button("Spirit: " + RVSkillGemSystem.gem_short_text(spirit_gem), {"kind": "spirit", "index": j})
	if choice_list.get_child_count() == 0:
		_add_choice_button("No engraved target gems yet", {"none": true})

func _show_choices(title: String, ids: Array, db_kind: String) -> void:
	_clear_container(choice_list)
	choice_title.text = title
	choice_panel.visible = true
	for id_value: Variant in ids:
		var gem_id: String = str(id_value)
		var name: String = gem_id
		if db_kind == "active":
			name = RVSkillGemDB.name_for_active(gem_id)
		elif db_kind == "support":
			name = RVSkillGemDB.name_for_support(gem_id)
		elif db_kind == "spirit":
			name = RVSkillGemDB.name_for_spirit(gem_id)
		_add_choice_button(name, {"id": gem_id})

func _add_choice_button(label: String, payload: Dictionary) -> void:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(300.0, 30.0)
	button.text = label
	button.pressed.connect(_on_choice_pressed.bind(payload))
	choice_list.add_child(button)

func _on_choice_pressed(payload: Dictionary) -> void:
	if current_state == null:
		return
	if bool(payload.get("none", false)):
		return
	if choice_mode == "engrave_active":
		RVSkillGemSystem.engrave_active_gem(current_state, int(choice_context.get("index", 0)), str(payload.get("id", "")))
		_select("active", int(choice_context.get("index", 0)))
	elif choice_mode == "engrave_spirit":
		RVSkillGemSystem.engrave_spirit_gem(current_state, int(choice_context.get("index", 0)), str(payload.get("id", "")))
		_select("spirit", int(choice_context.get("index", 0)))
	elif choice_mode == "support_target":
		choice_context["target_kind"] = str(payload.get("kind", ""))
		choice_context["target_index"] = int(payload.get("index", 0))
		_open_support_type_choice()
	elif choice_mode == "support_type":
		var support_index: int = int(choice_context.get("support_index", 0))
		var target_kind: String = str(choice_context.get("target_kind", "active"))
		var target_index: int = int(choice_context.get("target_index", 0))
		RVSkillGemSystem.socket_support_to_target(current_state, support_index, target_kind, target_index, str(payload.get("id", "")))
		_select("support", clamp(support_index, 0, max(0, current_state.support_gem_inventory.size() - 1)))
	choice_panel.visible = false
	choice_mode = ""
	_rebuild_lists()
	_refresh_detail()

func _open_support_type_choice() -> void:
	var target_kind: String = str(choice_context.get("target_kind", "active"))
	var target_index: int = int(choice_context.get("target_index", 0))
	var target_gem: Dictionary = {}
	if target_kind == "active" and target_index >= 0 and target_index < current_state.skill_gem_inventory.size():
		target_gem = current_state.skill_gem_inventory[target_index]
	elif target_kind == "spirit" and target_index >= 0 and target_index < current_state.spirit_gem_inventory.size():
		target_gem = current_state.spirit_gem_inventory[target_index]
	var support_index: int = int(choice_context.get("support_index", 0))
	var support_gem: Dictionary = current_state.support_gem_inventory[support_index]
	if bool(support_gem.get("uncut", false)):
		choice_mode = "support_type"
		_show_choices("Choose Support Type", RVSkillGemSystem.compatible_support_ids_for_target(target_gem), "support")
	else:
		RVSkillGemSystem.socket_support_to_target(current_state, support_index, target_kind, target_index, "")
		choice_panel.visible = false
		choice_mode = ""
		_rebuild_lists()
		_refresh_detail()

func _on_equip_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.toggle_selected_active_gem_equipped(current_state)
	_rebuild_lists()
	_refresh_detail()

func _on_enable_spirit_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.toggle_selected_spirit_gem_enabled(current_state)
	_rebuild_lists()
	_refresh_detail()

func _on_remove_support_pressed() -> void:
	if current_state == null:
		return
	if selected_kind == "active":
		RVSkillGemSystem.remove_last_support_from_selected(current_state, "active")
	elif selected_kind == "spirit":
		RVSkillGemSystem.remove_last_support_from_selected(current_state, "spirit")
	_rebuild_lists()
	_refresh_detail()

func _on_socket_prism_pressed() -> void:
	if current_state == null:
		return
	if selected_kind == "active":
		RVSkillGemSystem.improve_selected_socket_cap(current_state, "active")
	elif selected_kind == "spirit":
		RVSkillGemSystem.improve_selected_socket_cap(current_state, "spirit")
	_rebuild_lists()
	_refresh_detail()

func _on_close_pressed() -> void:
	if current_state != null:
		current_state.panel_mode = ""

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_ESCAPE:
				if choice_panel.visible:
					choice_panel.visible = false
					choice_mode = ""
				else:
					_on_close_pressed()
