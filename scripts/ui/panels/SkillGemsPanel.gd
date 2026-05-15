class_name RVSkillGemsPanel
extends RVUIPanelBase

# Patch 043: runtime menu for uncut skill/spirit/support gems.
# Right-click an uncut gem to choose its effect. Support gems use a two-step menu:
# choose target gem, then choose a compatible support effect.

var current_state: RVGameState = null
var root_box: VBoxContainer = null
var list_row: HBoxContainer = null
var choice_box: VBoxContainer = null
var detail_label: RichTextLabel = null
var last_signature: String = ""
var choice_mode: String = ""
var pending_support_index: int = -1
var pending_target_type: String = ""
var pending_target_index: int = -1

func _ready() -> void:
	super._ready()
	_build_runtime_layout()

func update_from_state(state: RVGameState) -> void:
	current_state = state
	var signature: String = _state_signature(state)
	if signature == last_signature:
		return
	last_signature = signature
	_refresh_lists()

func _build_runtime_layout() -> void:
	for child: Node in get_children():
		if child.name == "RuntimeGemUI":
			child.queue_free()
	root_box = VBoxContainer.new()
	root_box.name = "RuntimeGemUI"
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_box.offset_left = 18.0
	root_box.offset_top = 18.0
	root_box.offset_right = -18.0
	root_box.offset_bottom = -18.0
	root_box.add_theme_constant_override("separation", 8)
	add_child(root_box)

	var header: Label = Label.new()
	header.text = "SKILL GEMS / UNCUT GEM CRAFTING"
	header.add_theme_font_size_override("font_size", 20)
	root_box.add_child(header)

	var help: RichTextLabel = RichTextLabel.new()
	help.bbcode_enabled = true
	help.fit_content = true
	help.text = "[color=#d8c38f]Left click[/color] selects. [color=#d8c38f]Right click[/color] cuts uncut gems. Uncut Support: choose target, then choose support effect."
	help.custom_minimum_size = Vector2(0, 38)
	root_box.add_child(help)

	list_row = HBoxContainer.new()
	list_row.add_theme_constant_override("separation", 10)
	root_box.add_child(list_row)

	choice_box = VBoxContainer.new()
	choice_box.name = "ChoiceBox"
	choice_box.add_theme_constant_override("separation", 5)
	choice_box.custom_minimum_size = Vector2(0, 120)
	root_box.add_child(choice_box)

	detail_label = RichTextLabel.new()
	detail_label.bbcode_enabled = true
	detail_label.scroll_active = true
	detail_label.custom_minimum_size = Vector2(0, 150)
	root_box.add_child(detail_label)

func _refresh_lists() -> void:
	if root_box == null:
		_build_runtime_layout()
	_clear_children(list_row)
	_clear_children(choice_box)
	if current_state == null:
		return
	list_row.add_child(_make_active_column())
	list_row.add_child(_make_support_column())
	list_row.add_child(_make_spirit_column())
	_build_choice_ui()
	_update_detail_text()

func _make_active_column() -> VBoxContainer:
	var col: VBoxContainer = _make_column("ACTIVE / UNCUT SKILL GEMS")
	for i: int in range(current_state.skill_gem_inventory.size()):
		var gem: Dictionary = current_state.skill_gem_inventory[i]
		var button: Button = _make_gem_button(gem, i == current_state.skill_gem_cursor)
		button.pressed.connect(func() -> void:
			current_state.skill_gem_cursor = i
			choice_mode = ""
			_mark_dirty()
		)
		button.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton:
				var mouse_event: InputEventMouseButton = event
				if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
					current_state.skill_gem_cursor = i
					if RVSkillGemSystem.is_uncut_skill_gem(gem):
						choice_mode = "cut_skill"
					else:
						choice_mode = ""
					_mark_dirty()
		)
		col.add_child(button)
	var equip_button: Button = Button.new()
	equip_button.text = "Equip / Unequip Selected Skill"
	equip_button.pressed.connect(func() -> void:
		RVSkillGemSystem.toggle_selected_active_gem_equipped(current_state)
		_mark_dirty()
	)
	col.add_child(equip_button)
	var socket_button: Button = Button.new()
	socket_button.text = "+ Socket to Selected Skill"
	socket_button.pressed.connect(func() -> void:
		RVSkillGemSystem.add_socket_to_selected_active(current_state)
		_mark_dirty()
	)
	col.add_child(socket_button)
	return col

func _make_support_column() -> VBoxContainer:
	var col: VBoxContainer = _make_column("SUPPORT / UNCUT SUPPORT GEMS")
	for i: int in range(current_state.support_gem_inventory.size()):
		var gem: Dictionary = current_state.support_gem_inventory[i]
		var button: Button = _make_gem_button(gem, i == current_state.support_gem_cursor)
		button.pressed.connect(func() -> void:
			current_state.support_gem_cursor = i
			choice_mode = ""
			_mark_dirty()
		)
		button.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton:
				var mouse_event: InputEventMouseButton = event
				if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
					current_state.support_gem_cursor = i
					if RVSkillGemSystem.is_uncut_support_gem(gem):
						choice_mode = "support_target"
						pending_support_index = i
					else:
						choice_mode = ""
					_mark_dirty()
		)
		col.add_child(button)
	var socket_active_button: Button = Button.new()
	socket_active_button.text = "Socket Cut Support to Selected Skill"
	socket_active_button.pressed.connect(func() -> void:
		RVSkillGemSystem.socket_selected_support_to_active(current_state)
		_mark_dirty()
	)
	col.add_child(socket_active_button)
	var remove_button: Button = Button.new()
	remove_button.text = "Remove Last Support from Selected Skill"
	remove_button.pressed.connect(func() -> void:
		RVSkillGemSystem.remove_last_support_from_active(current_state)
		_mark_dirty()
	)
	col.add_child(remove_button)
	return col

func _make_spirit_column() -> VBoxContainer:
	var col: VBoxContainer = _make_column("SPIRIT / UNCUT SPIRIT GEMS")
	for i: int in range(current_state.spirit_gem_inventory.size()):
		var gem: Dictionary = current_state.spirit_gem_inventory[i]
		var button: Button = _make_gem_button(gem, i == current_state.spirit_gem_cursor)
		button.pressed.connect(func() -> void:
			current_state.spirit_gem_cursor = i
			choice_mode = ""
			_mark_dirty()
		)
		button.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton:
				var mouse_event: InputEventMouseButton = event
				if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
					current_state.spirit_gem_cursor = i
					if RVSkillGemSystem.is_uncut_spirit_gem(gem):
						choice_mode = "cut_spirit"
					else:
						choice_mode = ""
					_mark_dirty()
		)
		col.add_child(button)
	var enable_button: Button = Button.new()
	enable_button.text = "Enable / Disable Selected Spirit"
	enable_button.pressed.connect(func() -> void:
		RVSkillGemSystem.toggle_selected_spirit(current_state)
		_mark_dirty()
	)
	col.add_child(enable_button)
	var socket_button: Button = Button.new()
	socket_button.text = "+ Socket to Selected Spirit"
	socket_button.pressed.connect(func() -> void:
		RVSkillGemSystem.add_socket_to_selected_spirit(current_state)
		_mark_dirty()
	)
	col.add_child(socket_button)
	return col

func _build_choice_ui() -> void:
	_clear_children(choice_box)
	if current_state == null or choice_mode == "":
		return
	var title: Label = Label.new()
	title.add_theme_font_size_override("font_size", 16)
	choice_box.add_child(title)
	if choice_mode == "cut_skill":
		title.text = "Choose active skill for this Uncut Skill Gem:"
		var row: HBoxContainer = _choice_row()
		choice_box.add_child(row)
		for id_value: Variant in RVSkillGemDB.active_ids():
			var active_id: String = str(id_value)
			var data: Dictionary = RVSkillGemDB.active_data(active_id)
			row.add_child(_choice_button(str(data.get("name", active_id)), func() -> void:
				RVSkillGemSystem.cut_uncut_skill_gem(current_state, current_state.skill_gem_cursor, active_id)
				choice_mode = ""
				_mark_dirty()
			))
	elif choice_mode == "cut_spirit":
		title.text = "Choose Spirit reservation skill:"
		var row2: HBoxContainer = _choice_row()
		choice_box.add_child(row2)
		for id_value2: Variant in RVSkillGemDB.spirit_ids():
			var spirit_id: String = str(id_value2)
			var data2: Dictionary = RVSkillGemDB.spirit_data(spirit_id)
			row2.add_child(_choice_button(str(data2.get("name", spirit_id)), func() -> void:
				RVSkillGemSystem.cut_uncut_spirit_gem(current_state, current_state.spirit_gem_cursor, spirit_id)
				choice_mode = ""
				_mark_dirty()
			))
	elif choice_mode == "support_target":
		title.text = "Choose target gem for this Uncut Support Gem:"
		var row3: HBoxContainer = _choice_row()
		choice_box.add_child(row3)
		for i: int in range(current_state.skill_gem_inventory.size()):
			var active: Dictionary = current_state.skill_gem_inventory[i]
			if str(active.get("type", "active")) != "active":
				continue
			row3.add_child(_choice_button("Skill: " + str(active.get("name", "Skill")), func() -> void:
				pending_target_type = "active"
				pending_target_index = i
				choice_mode = "support_effect"
				_mark_dirty()
			))
		for j: int in range(current_state.spirit_gem_inventory.size()):
			var spirit: Dictionary = current_state.spirit_gem_inventory[j]
			if str(spirit.get("type", "spirit")) != "spirit":
				continue
			row3.add_child(_choice_button("Spirit: " + str(spirit.get("name", "Spirit")), func() -> void:
				pending_target_type = "spirit"
				pending_target_index = j
				choice_mode = "support_effect"
				_mark_dirty()
			))
	elif choice_mode == "support_effect":
		title.text = "Choose compatible support effect:"
		var target: Dictionary = {}
		if pending_target_type == "active" and pending_target_index >= 0 and pending_target_index < current_state.skill_gem_inventory.size():
			target = current_state.skill_gem_inventory[pending_target_index]
		elif pending_target_type == "spirit" and pending_target_index >= 0 and pending_target_index < current_state.spirit_gem_inventory.size():
			target = current_state.spirit_gem_inventory[pending_target_index]
		var support_ids: Array = RVSkillGemSystem.compatible_support_ids_for_target(pending_target_type, target)
		var row4: HBoxContainer = _choice_row()
		choice_box.add_child(row4)
		if support_ids.is_empty():
			var none: Label = Label.new()
			none.text = "No compatible support effects for this target."
			choice_box.add_child(none)
		for support_value: Variant in support_ids:
			var support_id: String = str(support_value)
			var support_data: Dictionary = RVSkillGemDB.support_data(support_id)
			row4.add_child(_choice_button(str(support_data.get("name", support_id)), func() -> void:
				RVSkillGemSystem.cut_uncut_support_gem_for_target(current_state, pending_support_index, pending_target_type, pending_target_index, support_id)
				choice_mode = ""
				pending_support_index = -1
				pending_target_type = ""
				pending_target_index = -1
				_mark_dirty()
			))
	var cancel: Button = Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(func() -> void:
		choice_mode = ""
		pending_support_index = -1
		pending_target_type = ""
		pending_target_index = -1
		_mark_dirty()
	)
	choice_box.add_child(cancel)

func _update_detail_text() -> void:
	if detail_label == null or current_state == null:
		return
	var text: String = ""
	if current_state.skill_gem_inventory.size() > 0:
		var active: Dictionary = current_state.skill_gem_inventory[clamp(current_state.skill_gem_cursor, 0, current_state.skill_gem_inventory.size() - 1)]
		text += "[b]Selected Skill Gem[/b]\n" + _gem_detail(active, "active") + "\n"
	if current_state.support_gem_inventory.size() > 0:
		var support: Dictionary = current_state.support_gem_inventory[clamp(current_state.support_gem_cursor, 0, current_state.support_gem_inventory.size() - 1)]
		text += "\n[b]Selected Support Gem[/b]\n" + _gem_detail(support, "support") + "\n"
	if current_state.spirit_gem_inventory.size() > 0:
		var spirit: Dictionary = current_state.spirit_gem_inventory[clamp(current_state.spirit_gem_cursor, 0, current_state.spirit_gem_inventory.size() - 1)]
		text += "\n[b]Selected Spirit Gem[/b]\n" + _gem_detail(spirit, "spirit") + "\n"
	text += "\n[b]Equipped Skill Bar[/b]\n"
	for skill_name: String in current_state.active_skills:
		text += RVSkillSystem.skill_summary(current_state, skill_name) + "\n"
	detail_label.text = text

func _gem_detail(gem: Dictionary, family: String) -> String:
	if gem.is_empty():
		return "None."
	var result: String = str(gem.get("name", "Gem")) + "  Lv " + str(int(gem.get("level", 1))) + "\n"
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

func _make_column(label_text: String) -> VBoxContainer:
	var col: VBoxContainer = VBoxContainer.new()
	col.custom_minimum_size = Vector2(360, 310)
	col.add_theme_constant_override("separation", 4)
	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 15)
	col.add_child(label)
	return col

func _make_gem_button(gem: Dictionary, selected: bool) -> Button:
	var button: Button = Button.new()
	var prefix: String = "> " if selected else "  "
	button.text = prefix + _short_gem_label(gem)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(330, 28)
	button.tooltip_text = str(gem.get("description", gem.get("name", "Gem")))
	return button

func _short_gem_label(gem: Dictionary) -> String:
	var gem_type: String = str(gem.get("type", ""))
	var name: String = str(gem.get("name", "Gem"))
	if gem_type == "active":
		name += " [" + str(Array(gem.get("supports", [])).size()) + "/" + str(int(gem.get("max_support_sockets", 2))) + "]"
		if bool(gem.get("equipped", false)):
			name += " *"
	elif gem_type == "spirit":
		name += " [" + str(Array(gem.get("supports", [])).size()) + "/" + str(int(gem.get("max_support_sockets", 2))) + "]"
		if bool(gem.get("enabled", false)):
			name += " ON"
	elif gem_type == "uncut_support":
		name += "  (right-click: target + effect)"
	elif gem_type.begins_with("uncut"):
		name += "  (right-click: choose)"
	return name

func _choice_row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	return row

func _choice_button(text_value: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(150, 32)
	button.pressed.connect(callback)
	return button

func _state_signature(state: RVGameState) -> String:
	if state == null:
		return "null"
	var parts: Array[String] = [choice_mode, str(pending_support_index), pending_target_type, str(pending_target_index)]
	parts.append(str(state.skill_gem_cursor) + "/" + str(state.support_gem_cursor) + "/" + str(state.spirit_gem_cursor))
	parts.append(_gem_sig(state.skill_gem_inventory))
	parts.append(_gem_sig(state.support_gem_inventory))
	parts.append(_gem_sig(state.spirit_gem_inventory))
	parts.append(str(state.spirit_reserved) + "/" + str(state.spirit_max))
	return "|".join(PackedStringArray(parts))

func _gem_sig(gems: Array) -> String:
	var values: Array[String] = []
	for gem: Dictionary in gems:
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

func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child: Node in node.get_children():
		child.queue_free()
