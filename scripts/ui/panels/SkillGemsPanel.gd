class_name RVSkillGemsPanel
extends RVUIPanelBase

# Patch 054: clean scene-authored Skill Gems panel. Layout lives in SkillGemsPanel.tscn; script only binds named nodes.
# The scene owns layout. This script only binds existing nodes, updates text/states,
# and routes mouse/right-click/drag interactions into RVSkillGemSystem.

const ART_ROOT := "res://assets/ui/skill_gems/patch054/slices/"
const SOCKET_EMPTY_PATH := ART_ROOT + "sg_02_10_socket_empty_small.png"
const SOCKET_FILLED_PATH := ART_ROOT + "sg_02_11_socket_filled_red_small.png"
const SOCKET_LOCKED_PATH := ART_ROOT + "sg_02_12_socket_locked_small.png"

var current_state: RVGameState = null
var last_signature: String = ""

var selected_family: String = "active"
var choice_mode: String = ""
var pending_support_index: int = -1
var pending_target_type: String = ""
var pending_target_index: int = -1
var selected_socket_target_type: String = "active"
var selected_socket_target_index: int = 0
var selected_socket_index: int = -1

var active_buttons: Array[Button] = []
var support_buttons: Array[Button] = []
var spirit_buttons: Array[Button] = []
var socket_buttons: Array[Button] = []
var choice_buttons: Array[Button] = []
var drop_zones: Array[Dictionary] = []

var potential_drag: Dictionary = {}
var drag_data: Dictionary = {}
var drag_preview: Control = null
var drag_start_mouse: Vector2 = Vector2.ZERO
var drag_started: bool = false

@onready var detail_label: RichTextLabel = %DetailLabel
@onready var choice_title: Label = %ChoiceTitle
@onready var spirit_meter_label: Label = %SpiritMeterLabel
@onready var help_label: Label = %HelpLabel
@onready var featured_title: Label = %FeaturedTitle
@onready var featured_tags: Label = %FeaturedTags
@onready var featured_icon: TextureRect = %FeaturedGemIcon
@onready var drag_layer: Control = %DragLayer

@onready var equip_button: Button = %EquipSkillButton
@onready var add_skill_socket_button: Button = %AddSkillSocketButton
@onready var add_spirit_socket_button: Button = %AddSpiritSocketButton
@onready var enable_spirit_button: Button = %EnableSpiritButton
@onready var unsocket_button: Button = %UnsocketButton
@onready var close_button: Button = %CloseButton
@onready var close_bottom_button: Button = get_node_or_null("%CloseBottomButton") as Button

var socket_empty_texture: Texture2D = null
var socket_filled_texture: Texture2D = null
var socket_locked_texture: Texture2D = null

func _ready() -> void:
	super._ready()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_runtime_textures()
	_bind_scene_nodes()
	_connect_static_buttons()
	set_process(true)

func update_from_state(state: RVGameState) -> void:
	current_state = state
	if current_state != null:
		current_state.ensure_defaults()
	var signature: String = _state_signature(current_state)
	if signature == last_signature:
		return
	last_signature = signature
	_refresh_all()

func _process(_delta: float) -> void:
	if drag_preview != null:
		drag_preview.position = get_viewport().get_mouse_position() - global_position + Vector2(18.0, 18.0)
	if not potential_drag.is_empty() and not drag_started and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if get_viewport().get_mouse_position().distance_to(drag_start_mouse) > 7.0:
			_begin_drag_from_potential()
	if drag_started and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_drag(get_viewport().get_mouse_position())
	elif not potential_drag.is_empty() and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		potential_drag.clear()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			if drag_started or not potential_drag.is_empty():
				_cancel_drag()
				accept_event()
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if drag_started or not potential_drag.is_empty():
				_cancel_drag()
				accept_event()

func _load_runtime_textures() -> void:
	socket_empty_texture = ResourceLoader.load(SOCKET_EMPTY_PATH) as Texture2D
	socket_filled_texture = ResourceLoader.load(SOCKET_FILLED_PATH) as Texture2D
	socket_locked_texture = ResourceLoader.load(SOCKET_LOCKED_PATH) as Texture2D

func _bind_scene_nodes() -> void:
	active_buttons.clear()
	support_buttons.clear()
	spirit_buttons.clear()
	socket_buttons.clear()
	choice_buttons.clear()
	for i: int in range(8):
		var button: Button = get_node_or_null("%ActiveGemButton" + str(i)) as Button
		if button != null:
			active_buttons.append(button)
	for i2: int in range(16):
		var button2: Button = get_node_or_null("%SupportGemButton" + str(i2)) as Button
		if button2 != null:
			support_buttons.append(button2)
	for i3: int in range(6):
		var button3: Button = get_node_or_null("%SpiritGemButton" + str(i3)) as Button
		if button3 != null:
			spirit_buttons.append(button3)
	for i4: int in range(6):
		var button4: Button = get_node_or_null("%SocketButton" + str(i4)) as Button
		if button4 != null:
			socket_buttons.append(button4)
	for i5: int in range(18):
		var button5: Button = get_node_or_null("%ChoiceButton" + str(i5)) as Button
		if button5 != null:
			choice_buttons.append(button5)

func _connect_static_buttons() -> void:
	for i: int in range(active_buttons.size()):
		var index: int = i
		active_buttons[i].pressed.connect(func() -> void:
			_select_active(index)
		)
		active_buttons[i].gui_input.connect(func(event: InputEvent) -> void:
			_handle_gem_button_input(event, "active", index)
		)
	for i2: int in range(support_buttons.size()):
		var support_index: int = i2
		support_buttons[i2].pressed.connect(func() -> void:
			_select_support(support_index)
		)
		support_buttons[i2].gui_input.connect(func(event: InputEvent) -> void:
			_handle_gem_button_input(event, "support", support_index)
		)
	for i3: int in range(spirit_buttons.size()):
		var spirit_index: int = i3
		spirit_buttons[i3].pressed.connect(func() -> void:
			_select_spirit(spirit_index)
		)
		spirit_buttons[i3].gui_input.connect(func(event: InputEvent) -> void:
			_handle_gem_button_input(event, "spirit", spirit_index)
		)
	for i4: int in range(socket_buttons.size()):
		var socket_index: int = i4
		socket_buttons[i4].pressed.connect(func() -> void:
			_select_socket(socket_index)
		)
		socket_buttons[i4].gui_input.connect(func(event: InputEvent) -> void:
			_handle_socket_input(event, socket_index)
		)

	equip_button.pressed.connect(func() -> void:
		if current_state == null:
			return
		RVSkillGemSystem.toggle_selected_active_gem_equipped(current_state)
		_mark_dirty()
	)
	add_skill_socket_button.pressed.connect(func() -> void:
		if current_state == null:
			return
		RVSkillGemSystem.add_socket_to_selected_active(current_state)
		_mark_dirty()
	)
	add_spirit_socket_button.pressed.connect(func() -> void:
		if current_state == null:
			return
		RVSkillGemSystem.add_socket_to_selected_spirit(current_state)
		_mark_dirty()
	)
	enable_spirit_button.pressed.connect(func() -> void:
		if current_state == null:
			return
		RVSkillGemSystem.toggle_selected_spirit(current_state)
		_mark_dirty()
	)
	unsocket_button.pressed.connect(func() -> void:
		_unsocket_selected()
	)
	close_button.pressed.connect(func() -> void:
		_close_panel()
	)
	if close_bottom_button != null:
		close_bottom_button.pressed.connect(func() -> void:
			_close_panel()
		)

func _refresh_all() -> void:
	drop_zones.clear()
	_refresh_active_buttons()
	_refresh_support_buttons()
	_refresh_spirit_buttons()
	_refresh_socket_buttons()
	_refresh_choice_panel()
	_refresh_detail()
	_refresh_action_states()

func _refresh_active_buttons() -> void:
	var gems: Array = []
	if current_state != null:
		gems = current_state.skill_gem_inventory
	for i: int in range(active_buttons.size()):
		var button: Button = active_buttons[i]
		if i >= gems.size():
			_configure_empty_button(button, "Empty")
			continue
		var gem: Dictionary = Dictionary(gems[i])
		button.visible = true
		button.disabled = false
		button.text = _button_label(gem, i == current_state.skill_gem_cursor, "active")
		button.tooltip_text = _tooltip_for_gem(gem)
		button.modulate = Color(1.0, 0.86, 0.48) if i == current_state.skill_gem_cursor else Color.WHITE
		_register_zone(button, {"kind": "target", "target_type": "active", "target_index": i})

func _refresh_support_buttons() -> void:
	var gems: Array = []
	if current_state != null:
		gems = current_state.support_gem_inventory
	for i: int in range(support_buttons.size()):
		var button: Button = support_buttons[i]
		if i >= gems.size():
			_configure_empty_button(button, "Empty")
			continue
		var gem: Dictionary = Dictionary(gems[i])
		button.visible = true
		button.disabled = false
		button.text = _button_label(gem, i == current_state.support_gem_cursor, "support")
		button.tooltip_text = _tooltip_for_gem(gem)
		button.modulate = Color(1.0, 0.86, 0.48) if i == current_state.support_gem_cursor else Color.WHITE

func _refresh_spirit_buttons() -> void:
	var gems: Array = []
	if current_state != null:
		gems = current_state.spirit_gem_inventory
	for i: int in range(spirit_buttons.size()):
		var button: Button = spirit_buttons[i]
		if i >= gems.size():
			_configure_empty_button(button, "Empty")
			continue
		var gem: Dictionary = Dictionary(gems[i])
		button.visible = true
		button.disabled = false
		button.text = _button_label(gem, i == current_state.spirit_gem_cursor, "spirit")
		button.tooltip_text = _tooltip_for_gem(gem)
		button.modulate = Color(1.0, 0.86, 0.48) if i == current_state.spirit_gem_cursor else Color.WHITE
		_register_zone(button, {"kind": "target", "target_type": "spirit", "target_index": i})

func _refresh_socket_buttons() -> void:
	# Scene-authored UI rule:
	# the socket art lives in SkillGemsPanel.tscn. These Button nodes are only
	# transparent click/drop targets. Do not assign large PNG icons here, or Godot
	# will render the raw slice size over the hand-placed scene art.
	var target: Dictionary = _current_socket_target()
	var supports: Array = target.get("supports", []) if not target.is_empty() else []
	var max_sockets: int = int(target.get("max_support_sockets", 0)) if not target.is_empty() else 0
	for i: int in range(socket_buttons.size()):
		var button: Button = socket_buttons[i]
		button.visible = true
		button.disabled = false
		button.icon = null
		button.text = ""
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.modulate = Color(1.0, 1.0, 1.0, 0.01)
		if i < supports.size():
			var support_id: String = str(supports[i])
			var data: Dictionary = RVSkillGemDB.support_data(support_id)
			button.tooltip_text = "Socket " + str(i + 1) + ": " + str(data.get("name", support_id)) + "\nRight-click to remove."
		elif i < max_sockets:
			button.tooltip_text = "Empty socket. Drag or right-click an Uncut Support Gem to fill it."
		else:
			button.tooltip_text = "Locked socket. Use socket upgrade material."
		_register_zone(button, {"kind": "socket", "socket_index": i})

func _refresh_choice_panel() -> void:
	for button: Button in choice_buttons:
		button.visible = false
		button.disabled = true
		button.text = ""
	choice_title.text = "No choice pending. Right-click an Uncut Skill, Spirit, or Support Gem."
	if current_state == null or choice_mode == "":
		return
	var labels: Array[Dictionary] = []
	if choice_mode == "cut_skill":
		choice_title.text = "Choose active skill for this Uncut Skill Gem"
		for id_value: Variant in RVSkillGemDB.active_ids():
			var active_id: String = str(id_value)
			var data: Dictionary = RVSkillGemDB.active_data(active_id)
			labels.append({"label": str(data.get("name", active_id)), "id": active_id, "kind": "cut_skill"})
	elif choice_mode == "cut_spirit":
		choice_title.text = "Choose Spirit reservation skill"
		for spirit_value: Variant in RVSkillGemDB.spirit_ids():
			var spirit_id: String = str(spirit_value)
			var spirit_data: Dictionary = RVSkillGemDB.spirit_data(spirit_id)
			labels.append({"label": str(spirit_data.get("name", spirit_id)), "id": spirit_id, "kind": "cut_spirit"})
	elif choice_mode == "support_target":
		choice_title.text = "Choose target gem for this Uncut Support Gem"
		for i: int in range(current_state.skill_gem_inventory.size()):
			var active: Dictionary = Dictionary(current_state.skill_gem_inventory[i])
			if str(active.get("type", "active")) == "active":
				labels.append({"label": "Skill: " + str(active.get("name", "Skill")), "target_type": "active", "target_index": i, "kind": "target"})
		for j: int in range(current_state.spirit_gem_inventory.size()):
			var spirit: Dictionary = Dictionary(current_state.spirit_gem_inventory[j])
			if str(spirit.get("type", "spirit")) == "spirit":
				labels.append({"label": "Spirit: " + str(spirit.get("name", "Spirit")), "target_type": "spirit", "target_index": j, "kind": "target"})
	elif choice_mode == "support_effect":
		choice_title.text = "Choose compatible support effect"
		var target: Dictionary = _pending_target_gem()
		for support_value: Variant in RVSkillGemSystem.compatible_support_ids_for_target(pending_target_type, target):
			var support_id: String = str(support_value)
			var support_data: Dictionary = RVSkillGemDB.support_data(support_id)
			labels.append({"label": str(support_data.get("name", support_id)), "id": support_id, "kind": "support_effect"})
		if labels.is_empty():
			choice_title.text = "No compatible support effects for this target."

	for i2: int in range(min(choice_buttons.size(), labels.size())):
		var info: Dictionary = labels[i2]
		var button: Button = choice_buttons[i2]
		button.visible = true
		button.disabled = false
		button.text = str(info.get("label", "Choice"))
		if button.pressed.get_connections().size() > 0:
			for connection: Dictionary in button.pressed.get_connections():
				button.pressed.disconnect(connection["callable"])
		button.pressed.connect(func() -> void:
			_apply_choice(info)
		)

func _refresh_detail() -> void:
	if current_state == null:
		detail_label.text = "No state."
		return
	var target: Dictionary = _current_socket_target()
	var title: String = "No gem selected"
	if not target.is_empty():
		title = str(target.get("name", "Gem"))
	featured_title.text = title
	featured_tags.text = _tags_for_display(target)
	var text: String = "[b]Selected[/b]\n"
	text += _gem_detail(target, selected_socket_target_type) + "\n"
	if current_state.support_gem_inventory.size() > 0:
		var support: Dictionary = Dictionary(current_state.support_gem_inventory[clamp(current_state.support_gem_cursor, 0, current_state.support_gem_inventory.size() - 1)])
		text += "\n[b]Selected Support[/b]\n" + _gem_detail(support, "support")
	text += "\n[b]Equipped Skill Bar[/b]\n"
	for skill_name: String in current_state.active_skills:
		text += RVSkillSystem.skill_summary(current_state, skill_name) + "\n"
	detail_label.text = text
	var reserved: int = int(current_state.spirit_reserved)
	var maximum: int = max(1, int(current_state.spirit_max))
	spirit_meter_label.text = "Spirit: " + str(reserved) + " / " + str(maximum) + " reserved   Available: " + str(maximum - reserved)

func _refresh_action_states() -> void:
	var has_active: bool = current_state != null and not current_state.skill_gem_inventory.is_empty()
	var has_support: bool = current_state != null and not current_state.support_gem_inventory.is_empty()
	var has_spirit: bool = current_state != null and not current_state.spirit_gem_inventory.is_empty()
	equip_button.disabled = not has_active
	add_skill_socket_button.disabled = not has_active
	add_spirit_socket_button.disabled = not has_spirit
	enable_spirit_button.disabled = not has_spirit
	unsocket_button.disabled = _current_socket_target().is_empty()

func _configure_empty_button(button: Button, label: String) -> void:
	button.visible = true
	button.disabled = true
	button.text = label
	button.tooltip_text = ""
	button.modulate = Color(0.55, 0.55, 0.55)

func _handle_gem_button_input(event: InputEvent, family: String, index: int) -> void:
	if current_state == null:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(family, index)
			accept_event()
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			potential_drag = {"family": family, "index": index}
			drag_start_mouse = get_viewport().get_mouse_position()

func _handle_socket_input(event: InputEvent, socket_index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			selected_socket_index = socket_index
			_unsocket_selected()
			accept_event()

func _handle_right_click(family: String, index: int) -> void:
	if family == "active":
		_select_active(index)
		var gem: Dictionary = Dictionary(current_state.skill_gem_inventory[index])
		choice_mode = "cut_skill" if RVSkillGemSystem.is_uncut_skill_gem(gem) else ""
	elif family == "support":
		_select_support(index)
		var support: Dictionary = Dictionary(current_state.support_gem_inventory[index])
		if RVSkillGemSystem.is_uncut_support_gem(support):
			choice_mode = "support_target"
			pending_support_index = index
		else:
			choice_mode = ""
	elif family == "spirit":
		_select_spirit(index)
		var spirit: Dictionary = Dictionary(current_state.spirit_gem_inventory[index])
		choice_mode = "cut_spirit" if RVSkillGemSystem.is_uncut_spirit_gem(spirit) else ""
	_mark_dirty()

func _select_active(index: int) -> void:
	if current_state == null or index >= current_state.skill_gem_inventory.size():
		return
	RVSkillGemSystem.select_active_gem(current_state, index)
	selected_family = "active"
	selected_socket_target_type = "active"
	selected_socket_target_index = index
	selected_socket_index = -1
	choice_mode = ""
	_mark_dirty()

func _select_support(index: int) -> void:
	if current_state == null or index >= current_state.support_gem_inventory.size():
		return
	RVSkillGemSystem.select_support_gem(current_state, index)
	selected_family = "support"
	choice_mode = ""
	_mark_dirty()

func _select_spirit(index: int) -> void:
	if current_state == null or index >= current_state.spirit_gem_inventory.size():
		return
	RVSkillGemSystem.select_spirit_gem(current_state, index)
	selected_family = "spirit"
	selected_socket_target_type = "spirit"
	selected_socket_target_index = index
	selected_socket_index = -1
	choice_mode = ""
	_mark_dirty()

func _select_socket(socket_index: int) -> void:
	selected_socket_index = socket_index
	_mark_dirty()

func _apply_choice(info: Dictionary) -> void:
	if current_state == null:
		return
	var kind: String = str(info.get("kind", ""))
	if kind == "cut_skill":
		RVSkillGemSystem.cut_uncut_skill_gem(current_state, current_state.skill_gem_cursor, str(info.get("id", "")))
		choice_mode = ""
	elif kind == "cut_spirit":
		RVSkillGemSystem.cut_uncut_spirit_gem(current_state, current_state.spirit_gem_cursor, str(info.get("id", "")))
		choice_mode = ""
	elif kind == "target":
		pending_target_type = str(info.get("target_type", ""))
		pending_target_index = int(info.get("target_index", -1))
		choice_mode = "support_effect"
	elif kind == "support_effect":
		RVSkillGemSystem.cut_uncut_support_gem_for_target(current_state, pending_support_index, pending_target_type, pending_target_index, str(info.get("id", "")))
		choice_mode = ""
		pending_support_index = -1
		pending_target_type = ""
		pending_target_index = -1
	_mark_dirty()

func _begin_drag_from_potential() -> void:
	if potential_drag.is_empty() or current_state == null:
		return
	drag_data = potential_drag.duplicate(true)
	potential_drag.clear()
	drag_started = true
	drag_preview = Label.new()
	drag_preview.name = "DragPreview"
	drag_preview.text = _drag_label(drag_data)
	drag_preview.add_theme_font_size_override("font_size", 13)
	drag_preview.add_theme_color_override("font_color", Color(1.0, 0.88, 0.48))
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_layer.add_child(drag_preview)

func _finish_drag(mouse_pos: Vector2) -> void:
	var consumed: bool = false
	for zone: Dictionary in drop_zones:
		var node: Control = zone.get("node", null) as Control
		if node == null:
			continue
		if node.get_global_rect().has_point(mouse_pos):
			consumed = _apply_drop(zone)
			break
	_cancel_drag()
	if consumed:
		_mark_dirty()

func _cancel_drag() -> void:
	potential_drag.clear()
	drag_data.clear()
	drag_started = false
	if drag_preview != null:
		drag_preview.queue_free()
	drag_preview = null

func _apply_drop(zone: Dictionary) -> bool:
	if current_state == null or drag_data.is_empty():
		return false
	if str(drag_data.get("family", "")) != "support":
		return false
	var support_index: int = int(drag_data.get("index", -1))
	if support_index < 0 or support_index >= current_state.support_gem_inventory.size():
		return false
	var target_type: String = str(zone.get("target_type", selected_socket_target_type))
	var target_index: int = int(zone.get("target_index", selected_socket_target_index))
	if str(zone.get("kind", "")) == "socket":
		target_type = selected_socket_target_type
		target_index = selected_socket_target_index
	var support: Dictionary = Dictionary(current_state.support_gem_inventory[support_index])
	if RVSkillGemSystem.is_uncut_support_gem(support):
		pending_support_index = support_index
		pending_target_type = target_type
		pending_target_index = target_index
		choice_mode = "support_effect"
		return true
	if target_type == "active":
		current_state.support_gem_cursor = support_index
		current_state.skill_gem_cursor = target_index
		RVSkillGemSystem.socket_selected_support_to_active(current_state)
		return true
	if target_type == "spirit":
		current_state.support_gem_cursor = support_index
		current_state.spirit_gem_cursor = target_index
		RVSkillGemSystem.socket_selected_support_to_spirit(current_state)
		return true
	return false

func _register_zone(node: Control, data: Dictionary) -> void:
	var zone: Dictionary = data.duplicate(true)
	zone["node"] = node
	drop_zones.append(zone)

func _unsocket_selected() -> void:
	if current_state == null:
		return
	if selected_socket_target_type == "spirit":
		# Compatibility: current system exposes remove-last for active only in older patches.
		current_state.add_notice("Spirit socket removal uses last support removal later")
	else:
		RVSkillGemSystem.remove_last_support_from_active(current_state)
	selected_socket_index = -1
	_mark_dirty()

func _current_socket_target() -> Dictionary:
	if current_state == null:
		return {}
	if selected_socket_target_type == "spirit":
		if selected_socket_target_index >= 0 and selected_socket_target_index < current_state.spirit_gem_inventory.size():
			return Dictionary(current_state.spirit_gem_inventory[selected_socket_target_index])
	else:
		if selected_socket_target_index >= 0 and selected_socket_target_index < current_state.skill_gem_inventory.size():
			return Dictionary(current_state.skill_gem_inventory[selected_socket_target_index])
	if not current_state.skill_gem_inventory.is_empty():
		return Dictionary(current_state.skill_gem_inventory[clamp(current_state.skill_gem_cursor, 0, current_state.skill_gem_inventory.size() - 1)])
	return {}

func _pending_target_gem() -> Dictionary:
	if current_state == null:
		return {}
	if pending_target_type == "active" and pending_target_index >= 0 and pending_target_index < current_state.skill_gem_inventory.size():
		return Dictionary(current_state.skill_gem_inventory[pending_target_index])
	if pending_target_type == "spirit" and pending_target_index >= 0 and pending_target_index < current_state.spirit_gem_inventory.size():
		return Dictionary(current_state.spirit_gem_inventory[pending_target_index])
	return {}

func _button_label(gem: Dictionary, selected: bool, family: String) -> String:
	var prefix: String = "▶ " if selected else "  "
	var name: String = str(gem.get("name", "Gem"))
	var level: int = int(gem.get("level", 1))
	var gem_type: String = str(gem.get("type", family))
	var line: String = prefix + name + "  Lv " + str(level)
	if gem_type == "active" or gem_type == "spirit":
		line += "  [" + str(Array(gem.get("supports", [])).size()) + "/" + str(int(gem.get("max_support_sockets", 2))) + "]"
	if gem_type == "active" and bool(gem.get("equipped", false)):
		line += "  EQUIPPED"
	if gem_type == "spirit" and bool(gem.get("enabled", false)):
		line += "  ON"
	if gem_type.begins_with("uncut"):
		line += "  (right-click)"
	return line

func _tooltip_for_gem(gem: Dictionary) -> String:
	return str(gem.get("name", "Gem")) + "\n" + str(gem.get("description", ""))

func _drag_label(data: Dictionary) -> String:
	if current_state == null:
		return "Gem"
	if str(data.get("family", "")) == "support":
		var index: int = int(data.get("index", -1))
		if index >= 0 and index < current_state.support_gem_inventory.size():
			return str(Dictionary(current_state.support_gem_inventory[index]).get("name", "Support"))
	return "Gem"

func _gem_detail(gem: Dictionary, family: String) -> String:
	if gem.is_empty():
		return "None."
	var result: String = str(gem.get("name", "Gem")) + " Lv " + str(int(gem.get("level", 1))) + "\n"
	var gem_type: String = str(gem.get("type", family))
	if gem_type.begins_with("uncut"):
		result += str(gem.get("description", "Right-click to choose what this becomes.")) + "\n"
		return result
	if gem_type == "active":
		var data: Dictionary = RVSkillGemDB.active_data(str(gem.get("gem_id", "")))
		result += str(data.get("description", "")) + "\n"
		result += "Sockets: " + str(Array(gem.get("supports", [])).size()) + "/" + str(int(gem.get("max_support_sockets", 2))) + "\n"
		result += "Equipped: " + ("yes" if bool(gem.get("equipped", false)) else "no") + "\n"
		result += _support_line(gem)
	elif gem_type == "support":
		var support_data: Dictionary = RVSkillGemDB.support_data(str(gem.get("gem_id", "")))
		result += str(support_data.get("description", "")) + "\n"
		result += "Compatible: " + ", ".join(PackedStringArray(_string_array(support_data.get("compatible_tags", [])))) + "\n"
	elif gem_type == "spirit":
		var spirit_data: Dictionary = RVSkillGemDB.spirit_data(str(gem.get("gem_id", "")))
		result += str(spirit_data.get("description", "")) + "\n"
		result += "Reservation: " + str(RVSkillGemSystem.spirit_reservation(gem)) + " Spirit\n"
		result += "Sockets: " + str(Array(gem.get("supports", [])).size()) + "/" + str(int(gem.get("max_support_sockets", 2))) + "\n"
		result += "Enabled: " + ("yes" if bool(gem.get("enabled", false)) else "no") + "\n"
		result += _support_line(gem)
	return result

func _support_line(gem: Dictionary) -> String:
	var supports: Array = gem.get("supports", [])
	if supports.is_empty():
		return "Supports: none\n"
	var names: Array[String] = []
	for support_id_value: Variant in supports:
		var support_data: Dictionary = RVSkillGemDB.support_data(str(support_id_value))
		names.append(str(support_data.get("name", support_id_value)))
	return "Supports: " + ", ".join(PackedStringArray(names)) + "\n"

func _tags_for_display(gem: Dictionary) -> String:
	if gem.is_empty():
		return ""
	var tags: Array[String] = []
	if str(gem.get("type", "")) == "active":
		var data: Dictionary = RVSkillGemDB.active_data(str(gem.get("gem_id", "")))
		tags = _string_array(data.get("tags", []))
	elif str(gem.get("type", "")) == "spirit":
		var sdata: Dictionary = RVSkillGemDB.spirit_data(str(gem.get("gem_id", "")))
		tags = _string_array(sdata.get("tags", []))
	return "Tags: " + ", ".join(PackedStringArray(tags))

func _state_signature(state: RVGameState) -> String:
	if state == null:
		return "null"
	var parts: Array[String] = [selected_family, choice_mode, str(pending_support_index), pending_target_type, str(pending_target_index), selected_socket_target_type, str(selected_socket_target_index), str(selected_socket_index)]
	parts.append(str(state.skill_gem_cursor) + "/" + str(state.support_gem_cursor) + "/" + str(state.spirit_gem_cursor))
	parts.append(_gem_sig(state.skill_gem_inventory))
	parts.append(_gem_sig(state.support_gem_inventory))
	parts.append(_gem_sig(state.spirit_gem_inventory))
	parts.append(str(state.spirit_reserved) + "/" + str(state.spirit_max))
	return "|".join(PackedStringArray(parts))

func _gem_sig(gems: Array) -> String:
	var values: Array[String] = []
	for gem_variant: Variant in gems:
		if typeof(gem_variant) != TYPE_DICTIONARY:
			continue
		var gem: Dictionary = Dictionary(gem_variant)
		values.append(str(gem.get("uid", "")) + ":" + str(gem.get("type", "")) + ":" + str(gem.get("gem_id", "")) + ":" + str(gem.get("supports", [])) + ":" + str(gem.get("equipped", gem.get("enabled", false))))
	return ";".join(PackedStringArray(values))

func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values:
		result.append(str(value))
	return result

func _mark_dirty() -> void:
	last_signature = ""
	if current_state != null:
		current_state.ensure_defaults()
		current_state.recompute_stats()
	update_from_state(current_state)

func _close_panel() -> void:
	visible = false
	if current_state != null:
		current_state.panel_mode = ""
