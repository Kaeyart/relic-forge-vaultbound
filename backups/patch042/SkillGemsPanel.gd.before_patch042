extends RVUIPanelBase

@onready var summary_label: Label = %SummaryLabel
@onready var active_list: VBoxContainer = %ActiveGemList
@onready var support_list: VBoxContainer = %SupportGemList
@onready var spirit_list: VBoxContainer = %SpiritGemList
@onready var detail_label: Label = %DetailLabel
@onready var equip_button: Button = %EquipButton
@onready var socket_button: Button = %SocketButton
@onready var socket_spirit_button: Button = %SocketSpiritButton
@onready var remove_support_button: Button = %RemoveSupportButton
@onready var add_socket_button: Button = %AddSocketButton
@onready var toggle_spirit_button: Button = %ToggleSpiritButton
@onready var close_button: Button = %CloseButton

var current_state: RVGameState = null

func _ready() -> void:
	super._ready()
	_connect_static_buttons()


func update_from_state(state: RVGameState) -> void:
	current_state = state
	_rebuild_lists(state)
	_update_summary(state)
	_update_detail(state)
	_update_buttons(state)


func _connect_static_buttons() -> void:
	if equip_button != null and not equip_button.pressed.is_connected(_on_toggle_active_pressed):
		equip_button.pressed.connect(_on_toggle_active_pressed)
	if socket_button != null and not socket_button.pressed.is_connected(_on_socket_support_pressed):
		socket_button.pressed.connect(_on_socket_support_pressed)
	if socket_spirit_button != null and not socket_spirit_button.pressed.is_connected(_on_socket_spirit_pressed):
		socket_spirit_button.pressed.connect(_on_socket_spirit_pressed)
	if remove_support_button != null and not remove_support_button.pressed.is_connected(_on_remove_support_pressed):
		remove_support_button.pressed.connect(_on_remove_support_pressed)
	if add_socket_button != null and not add_socket_button.pressed.is_connected(_on_add_socket_pressed):
		add_socket_button.pressed.connect(_on_add_socket_pressed)
	if toggle_spirit_button != null and not toggle_spirit_button.pressed.is_connected(_on_toggle_spirit_pressed):
		toggle_spirit_button.pressed.connect(_on_toggle_spirit_pressed)
	if close_button != null and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)


func _rebuild_lists(state: RVGameState) -> void:
	_rebuild_active_gems(state)
	_rebuild_support_gems(state)
	_rebuild_spirit_gems(state)


func _clear_children(container: VBoxContainer) -> void:
	if container == null:
		return
	for child: Node in container.get_children():
		child.queue_free()


func _rebuild_active_gems(state: RVGameState) -> void:
	_clear_children(active_list)
	if active_list == null:
		return
	for i: int in range(state.skill_gem_inventory.size()):
		var gem: Dictionary = state.skill_gem_inventory[i]
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(210.0, 52.0)
		button.text = _active_label(gem)
		button.toggle_mode = true
		button.button_pressed = i == state.skill_gem_cursor
		button.pressed.connect(_on_active_gem_pressed.bind(i))
		active_list.add_child(button)


func _rebuild_support_gems(state: RVGameState) -> void:
	_clear_children(support_list)
	if support_list == null:
		return
	for i: int in range(state.support_gem_inventory.size()):
		var gem: Dictionary = state.support_gem_inventory[i]
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(210.0, 46.0)
		button.text = _support_label(gem)
		button.toggle_mode = true
		button.button_pressed = i == state.support_gem_cursor
		button.pressed.connect(_on_support_gem_pressed.bind(i))
		support_list.add_child(button)


func _rebuild_spirit_gems(state: RVGameState) -> void:
	_clear_children(spirit_list)
	if spirit_list == null:
		return
	for i: int in range(state.spirit_gem_inventory.size()):
		var gem: Dictionary = state.spirit_gem_inventory[i]
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(210.0, 52.0)
		button.text = _spirit_label(gem)
		button.toggle_mode = true
		button.button_pressed = i == state.spirit_gem_cursor
		button.pressed.connect(_on_spirit_gem_pressed.bind(i))
		spirit_list.add_child(button)


func _update_summary(state: RVGameState) -> void:
	if summary_label == null:
		return
	var unreserved: int = max(0, state.spirit_max - state.spirit_reserved)
	summary_label.text = "Skill Gems %s · Supports %s · Spirit %s/%s · Free Spirit %s · Socket Prisms %s" % [state.skill_gem_inventory.size(), state.support_gem_inventory.size(), state.spirit_reserved, state.spirit_max, unreserved, state.materials.get("socket_prisms", 0)]


func _update_detail(state: RVGameState) -> void:
	if detail_label == null:
		return
	var lines: Array[String] = []
	lines.append("SELECTED ACTIVE GEM")
	if state.skill_gem_inventory.is_empty():
		lines.append("None")
	else:
		var active: Dictionary = state.skill_gem_inventory[clamp(state.skill_gem_cursor, 0, state.skill_gem_inventory.size() - 1)]
		lines.append(_active_detail(active))
	lines.append("")
	lines.append("SELECTED SUPPORT GEM")
	if state.support_gem_inventory.is_empty():
		lines.append("None")
	else:
		var support: Dictionary = state.support_gem_inventory[clamp(state.support_gem_cursor, 0, state.support_gem_inventory.size() - 1)]
		lines.append(_support_detail(support))
	lines.append("")
	lines.append("SELECTED SPIRIT GEM")
	if state.spirit_gem_inventory.is_empty():
		lines.append("None")
	else:
		var spirit: Dictionary = state.spirit_gem_inventory[clamp(state.spirit_gem_cursor, 0, state.spirit_gem_inventory.size() - 1)]
		lines.append(_spirit_detail(spirit))
	detail_label.text = "\n".join(lines)


func _update_buttons(state: RVGameState) -> void:
	if equip_button != null:
		equip_button.disabled = state.skill_gem_inventory.is_empty()
	if socket_button != null:
		socket_button.disabled = state.skill_gem_inventory.is_empty() or state.support_gem_inventory.is_empty()
	if socket_spirit_button != null:
		socket_spirit_button.disabled = state.spirit_gem_inventory.is_empty() or state.support_gem_inventory.is_empty()
	if remove_support_button != null:
		remove_support_button.disabled = state.skill_gem_inventory.is_empty()
	if add_socket_button != null:
		add_socket_button.disabled = state.skill_gem_inventory.is_empty() or int(state.materials.get("socket_prisms", 0)) <= 0
	if toggle_spirit_button != null:
		toggle_spirit_button.disabled = state.spirit_gem_inventory.is_empty()


func _active_label(gem: Dictionary) -> String:
	var equipped_text: String = ""
	if bool(gem.get("equipped", false)):
		equipped_text = " [Equipped]"
	return str(gem.get("name", "Skill Gem")) + equipped_text + "\nLv " + str(gem.get("level", 1)) + " · Supports " + str((gem.get("supports", []) as Array).size()) + "/" + str(gem.get("max_support_sockets", 2))


func _support_label(gem: Dictionary) -> String:
	return str(gem.get("name", "Support Gem")) + "\nLv " + str(gem.get("level", 1))


func _spirit_label(gem: Dictionary) -> String:
	var enabled_text: String = ""
	if bool(gem.get("enabled", false)):
		enabled_text = " [On]"
	return str(gem.get("name", "Spirit Gem")) + enabled_text + "\nReserve " + str(RVSkillGemSystem.spirit_reservation(gem)) + " · Supports " + str((gem.get("supports", []) as Array).size()) + "/" + str(gem.get("max_support_sockets", 2))


func _active_detail(gem: Dictionary) -> String:
	var data: Dictionary = RVSkillGemDB.active_data(str(gem.get("gem_id", "")))
	var lines: Array[String] = []
	lines.append(str(gem.get("name", "Skill Gem")) + " · Level " + str(gem.get("level", 1)))
	lines.append("Grants: " + str(gem.get("skill_id", "Skill")))
	lines.append("Tags: " + ", ".join(PackedStringArray(data.get("tags", []))))
	lines.append("Support sockets: " + str((gem.get("supports", []) as Array).size()) + "/" + str(gem.get("max_support_sockets", 2)))
	if not (gem.get("supports", []) as Array).is_empty():
		lines.append("Supports: " + ", ".join(PackedStringArray(gem.get("supports", []))))
	lines.append(str(data.get("description", "")))
	return "\n".join(lines)


func _support_detail(gem: Dictionary) -> String:
	var data: Dictionary = RVSkillGemDB.support_data(str(gem.get("gem_id", "")))
	var lines: Array[String] = []
	lines.append(str(gem.get("name", "Support Gem")) + " · Level " + str(gem.get("level", 1)))
	lines.append("Compatible: " + ", ".join(PackedStringArray(data.get("compatible_tags", []))))
	lines.append("Damage: " + _percent(data.get("damage_more", 0.0)) + " · Cost: " + _percent(data.get("mana_more", 0.0)) + " · Cooldown: " + _percent(data.get("cooldown_more", 0.0)))
	lines.append("Spirit reservation change: " + _percent(data.get("spirit_more", 0.0)))
	lines.append(str(data.get("description", "")))
	return "\n".join(lines)


func _spirit_detail(gem: Dictionary) -> String:
	var data: Dictionary = RVSkillGemDB.spirit_data(str(gem.get("gem_id", "")))
	var lines: Array[String] = []
	lines.append(str(gem.get("name", "Spirit Gem")) + " · Level " + str(gem.get("level", 1)))
	lines.append("Effect: " + str(data.get("effect", "Passive")))
	lines.append("Reservation: " + str(RVSkillGemSystem.spirit_reservation(gem)))
	lines.append("Supports: " + str((gem.get("supports", []) as Array).size()) + "/" + str(gem.get("max_support_sockets", 2)))
	lines.append(str(data.get("description", "")))
	return "\n".join(lines)


func _percent(value: Variant) -> String:
	var amount: float = float(value)
	var prefix: String = "+"
	if amount < 0.0:
		prefix = ""
	return prefix + str(int(round(amount * 100.0))) + "%"


func _on_active_gem_pressed(index: int) -> void:
	if current_state == null:
		return
	RVSkillGemSystem.select_active_gem(current_state, index)
	update_from_state(current_state)


func _on_support_gem_pressed(index: int) -> void:
	if current_state == null:
		return
	RVSkillGemSystem.select_support_gem(current_state, index)
	update_from_state(current_state)


func _on_spirit_gem_pressed(index: int) -> void:
	if current_state == null:
		return
	RVSkillGemSystem.select_spirit_gem(current_state, index)
	update_from_state(current_state)


func _on_toggle_active_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.toggle_selected_active_gem_equipped(current_state)
	update_from_state(current_state)


func _on_socket_support_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.socket_selected_support_to_active(current_state)
	update_from_state(current_state)


func _on_socket_spirit_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.socket_selected_support_to_spirit(current_state)
	update_from_state(current_state)


func _on_remove_support_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.remove_last_support_from_active(current_state)
	update_from_state(current_state)


func _on_add_socket_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.add_socket_to_selected_active(current_state)
	update_from_state(current_state)


func _on_toggle_spirit_pressed() -> void:
	if current_state == null:
		return
	RVSkillGemSystem.toggle_selected_spirit(current_state)
	update_from_state(current_state)


func _on_close_pressed() -> void:
	if current_state != null:
		current_state.panel_mode = ""
