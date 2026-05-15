extends RVUIPanelBase

# Relic Forge: Vaultbound
# Inventory panel controller.
# Layout remains scene-authored. This script only updates data, runtime item overlays,
# selection state, comparison text, and action button logic.

const GRID_COLUMNS: int = 7
const GRID_ROWS: int = 7
const FALLBACK_CELL_SIZE: Vector2 = Vector2(42.0, 42.0)
const CELL_GAP: float = 4.0

const COLOR_SELECTED: Color = Color(1.0, 0.82, 0.32, 1.0)
const COLOR_COMPARE: Color = Color(0.35, 0.72, 1.0, 1.0)
const COLOR_VALID: Color = Color(0.45, 1.0, 0.45, 1.0)
const COLOR_INVALID: Color = Color(1.0, 0.25, 0.22, 1.0)
const COLOR_DIM: Color = Color(0.58, 0.58, 0.58, 1.0)

@onready var backpack_grid: Control = get_node_or_null("%BackpackGrid") as Control
@onready var equipment_root: Control = _find_equipment_root()
@onready var detail_label: Label = get_node_or_null("%DetailLabel") as Label
@onready var character_summary: Label = get_node_or_null("%CharacterSummary") as Label
@onready var materials_label: Label = get_node_or_null("%MaterialsLabel") as Label
@onready var equip_button: Button = get_node_or_null("%EquipButton") as Button
@onready var stash_button: Button = get_node_or_null("%StashButton") as Button
@onready var salvage_button: Button = get_node_or_null("%SalvageButton") as Button
@onready var unequip_button: Button = get_node_or_null("%UnequipButton") as Button
@onready var close_button: Button = get_node_or_null("%CloseButton") as Button

var current_state: RVGameState = null
var backpack_slot_buttons: Array[Button] = []
var equipment_buttons: Dictionary = {}
var runtime_layer: Control = null
var rich_detail: RichTextLabel = null
var runtime_item_buttons: Dictionary = {}

var selected_source: String = "backpack"
var selected_equipment_slot: String = ""
var comparison_slot: String = ""

var drag_index: int = -1
var drag_preview: Button = null
var drag_origin: Vector2i = Vector2i.ZERO

func _ready() -> void:
	super._ready()
	_collect_buttons()
	_connect_buttons()
	_ensure_runtime_layer()
	_ensure_rich_detail()
	_clear_static_slot_text()
	set_process(true)
	set_process_input(true)

func _process(_delta: float) -> void:
	if drag_preview == null:
		return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	drag_preview.global_position = mouse_pos + Vector2(18.0, 18.0)

func _input(event: InputEvent) -> void:
	if drag_index < 0:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			_finish_drag(mouse_event.position)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_cancel_drag()
			accept_event()
	elif event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			_cancel_drag()
			accept_event()

func update_from_state(state: RVGameState) -> void:
	current_state = state
	_collect_buttons()
	_connect_buttons()
	_ensure_runtime_layer()
	_ensure_rich_detail()
	_clear_static_slot_text()
	_ensure_backpack_positions(state)
	_update_backpack_static_cells(state)
	_rebuild_runtime_items(state)
	_update_equipment_slots(state)
	_update_details(state)
	_update_actions(state)

func _find_equipment_root() -> Control:
	var slots: Control = get_node_or_null("%EquipmentSlots") as Control
	if slots != null:
		return slots
	var grid: Control = get_node_or_null("%EquipmentGrid") as Control
	if grid != null:
		return grid
	return null

func _collect_buttons() -> void:
	backpack_slot_buttons.clear()
	equipment_buttons.clear()
	if backpack_grid != null:
		for child: Node in backpack_grid.get_children():
			if child is Button:
				backpack_slot_buttons.append(child as Button)
	equipment_root = _find_equipment_root()
	if equipment_root != null:
		_collect_equipment_buttons_recursive(equipment_root)

func _collect_equipment_buttons_recursive(root: Node) -> void:
	for child: Node in root.get_children():
		if child is Button:
			var gear_button: Button = child as Button
			var slot_name: String = _slot_name_from_button(gear_button)
			if slot_name != "":
				equipment_buttons[slot_name] = gear_button
		else:
			_collect_equipment_buttons_recursive(child)

func _slot_name_from_button(button: Button) -> String:
	var meta_slot: Variant = button.get_meta("slot", "")
	if str(meta_slot) != "":
		return RVInventorySystem.normalize_slot(str(meta_slot))
	var normalized_name: String = button.name.to_lower()
	if normalized_name.begins_with("slot"):
		normalized_name = normalized_name.trim_prefix("slot").to_lower()
	if normalized_name.begins_with("equipment"):
		normalized_name = normalized_name.trim_prefix("equipment").to_lower()
	var mapped: String = RVInventorySystem.normalize_slot(normalized_name)
	if RVInventorySystem.EQUIPMENT_ORDER.has(mapped):
		button.set_meta("slot", mapped)
		return mapped
	return ""

func _connect_buttons() -> void:
	for i: int in range(backpack_slot_buttons.size()):
		var button: Button = backpack_slot_buttons[i]
		button.text = ""
		button.tooltip_text = "Backpack cell"
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for slot_key_variant: Variant in equipment_buttons.keys():
		var slot_key: String = str(slot_key_variant)
		var gear_button: Button = equipment_buttons[slot_key]
		gear_button.mouse_filter = Control.MOUSE_FILTER_STOP
		if not gear_button.pressed.is_connected(_on_equipment_slot_pressed.bind(slot_key)):
			gear_button.pressed.connect(_on_equipment_slot_pressed.bind(slot_key))
	if equip_button != null and not equip_button.pressed.is_connected(_on_equip_pressed):
		equip_button.pressed.connect(_on_equip_pressed)
	if stash_button != null and not stash_button.pressed.is_connected(_on_stash_pressed):
		stash_button.pressed.connect(_on_stash_pressed)
	if salvage_button != null and not salvage_button.pressed.is_connected(_on_salvage_pressed):
		salvage_button.pressed.connect(_on_salvage_pressed)
	if unequip_button != null and not unequip_button.pressed.is_connected(_on_unequip_pressed):
		unequip_button.pressed.connect(_on_unequip_pressed)
	if close_button != null and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

func _ensure_runtime_layer() -> void:
	if backpack_grid == null:
		return
	if runtime_layer != null and is_instance_valid(runtime_layer):
		_update_runtime_layer_geometry()
		return
	var parent_control: Control = backpack_grid.get_parent() as Control
	if parent_control == null:
		parent_control = self
	runtime_layer = parent_control.get_node_or_null("RuntimeTetrisLayer") as Control
	if runtime_layer == null:
		runtime_layer = Control.new()
		runtime_layer.name = "RuntimeTetrisLayer"
		parent_control.add_child(runtime_layer)
	runtime_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	runtime_layer.clip_contents = false
	_update_runtime_layer_geometry()

func _update_runtime_layer_geometry() -> void:
	if backpack_grid == null or runtime_layer == null:
		return
	runtime_layer.global_position = backpack_grid.global_position
	runtime_layer.size = _grid_total_size()
	runtime_layer.z_index = 100

func _ensure_rich_detail() -> void:
	if detail_label == null:
		return
	if rich_detail != null and is_instance_valid(rich_detail):
		_sync_rich_detail_to_label()
		return
	var parent_control: Control = detail_label.get_parent() as Control
	if parent_control == null:
		return
	rich_detail = parent_control.get_node_or_null("InventoryRichDetail") as RichTextLabel
	if rich_detail == null:
		rich_detail = RichTextLabel.new()
		rich_detail.name = "InventoryRichDetail"
		parent_control.add_child(rich_detail)
	rich_detail.bbcode_enabled = true
	rich_detail.scroll_active = true
	rich_detail.fit_content = false
	rich_detail.mouse_filter = Control.MOUSE_FILTER_PASS
	rich_detail.z_index = detail_label.z_index + 1
	_sync_rich_detail_to_label()
	detail_label.visible = false

func _sync_rich_detail_to_label() -> void:
	if rich_detail == null or detail_label == null:
		return
	rich_detail.position = detail_label.position
	rich_detail.size = detail_label.size
	rich_detail.custom_minimum_size = detail_label.custom_minimum_size

func _clear_static_slot_text() -> void:
	for button: Button in backpack_slot_buttons:
		button.text = ""
	for slot_key_variant: Variant in equipment_buttons.keys():
		var button: Button = equipment_buttons[slot_key_variant]
		button.text = ""

func _update_backpack_static_cells(_state: RVGameState) -> void:
	for button: Button in backpack_slot_buttons:
		button.text = ""
		button.tooltip_text = "Empty backpack cell"
		button.disabled = false
		button.modulate = Color.WHITE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _rebuild_runtime_items(state: RVGameState) -> void:
	_clear_runtime_item_buttons()
	if runtime_layer == null:
		return
	_update_runtime_layer_geometry()
	var cell_size: Vector2 = _cell_size()
	var pitch: Vector2 = _cell_pitch()
	for i: int in range(state.backpack.size()):
		var item: Dictionary = RVItemDB.normalize_item(state.backpack[i])
		var item_size: Vector2i = _item_grid_size(item)
		var item_pos: Vector2i = Vector2i(int(item.get("inv_x", 0)), int(item.get("inv_y", 0)))
		var item_button: Button = Button.new()
		item_button.name = "RuntimeItem_%s" % i
		item_button.text = _compact_item_label(item)
		item_button.tooltip_text = _item_name(item)
		item_button.position = Vector2(float(item_pos.x) * pitch.x, float(item_pos.y) * pitch.y)
		item_button.size = Vector2(float(item_size.x) * pitch.x - CELL_GAP, float(item_size.y) * pitch.y - CELL_GAP)
		item_button.custom_minimum_size = item_button.size
		item_button.clip_text = true
		item_button.mouse_filter = Control.MOUSE_FILTER_STOP
		item_button.modulate = _item_button_color(state, i, item)
		runtime_layer.add_child(item_button)
		runtime_item_buttons[i] = item_button
		item_button.pressed.connect(_on_backpack_item_pressed.bind(i))
		item_button.gui_input.connect(_on_backpack_item_gui_input.bind(i))

func _clear_runtime_item_buttons() -> void:
	if runtime_layer == null:
		return
	for child: Node in runtime_layer.get_children():
		child.queue_free()
	runtime_item_buttons.clear()

func _item_button_color(state: RVGameState, index: int, item: Dictionary) -> Color:
	if selected_source == "backpack" and index == int(state.inventory_cursor):
		return COLOR_SELECTED
	var rarity: String = str(item.get("rarity", "Normal"))
	match rarity:
		"Unique": return Color(0.95, 0.55, 0.18, 1.0)
		"Rare": return Color(0.92, 0.80, 0.26, 1.0)
		"Magic": return Color(0.55, 0.68, 1.0, 1.0)
		"Crafted": return Color(0.35, 0.95, 0.82, 1.0)
		_: return Color.WHITE

func _update_equipment_slots(state: RVGameState) -> void:
	comparison_slot = ""
	if selected_source == "backpack" and not state.backpack.is_empty():
		var selected_item: Dictionary = RVInventorySystem.selected_backpack_item(state)
		comparison_slot = _comparison_slot_for_item(state, selected_item)
	for slot_key_variant: Variant in equipment_buttons.keys():
		var slot_key: String = RVInventorySystem.normalize_slot(str(slot_key_variant))
		var button: Button = equipment_buttons[slot_key_variant]
		var item_value: Variant = state.equipped.get(slot_key, {})
		button.text = ""
		button.disabled = false
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		var display_slot: String = _slot_label(slot_key)
		var has_item: bool = typeof(item_value) == TYPE_DICTIONARY and not Dictionary(item_value).is_empty()
		if has_item:
			var equipped_item: Dictionary = RVItemDB.normalize_item(item_value)
			button.text = _rarity_letter(equipped_item)
			button.tooltip_text = "%s: %s" % [display_slot, _item_name(equipped_item)]
		else:
			button.tooltip_text = "%s: Empty" % display_slot
		var selected_equipment: bool = selected_source == "equipment" and RVInventorySystem.normalize_slot(selected_equipment_slot) == slot_key
		if selected_equipment:
			button.modulate = COLOR_SELECTED
		elif comparison_slot == slot_key:
			button.modulate = COLOR_COMPARE
		elif has_item:
			button.modulate = Color.WHITE
		else:
			button.modulate = COLOR_DIM

func _update_details(state: RVGameState) -> void:
	if character_summary != null:
		character_summary.text = _character_summary_text(state)
	if materials_label != null:
		materials_label.text = _materials_text(state)
	var bbcode: String = _detail_bbcode(state)
	if rich_detail != null:
		rich_detail.text = bbcode
	elif detail_label != null:
		detail_label.text = _strip_bbcode(bbcode)

func _update_actions(state: RVGameState) -> void:
	var backpack_selected: bool = selected_source == "backpack" and not state.backpack.is_empty()
	var equipped_selected: bool = selected_source == "equipment" and not RVInventorySystem.selected_equipped_item(state).is_empty()
	_set_button_state(equip_button, backpack_selected, "Equip Selected")
	_set_button_state(stash_button, backpack_selected, "Move to Stash")
	_set_button_state(salvage_button, backpack_selected, "Destroy / Salvage")
	_set_button_state(unequip_button, equipped_selected, "Unequip Gear")
	_set_button_state(close_button, true, "Close")

func _set_button_state(button: Button, enabled: bool, label: String) -> void:
	if button == null:
		return
	button.visible = true
	button.disabled = not enabled
	button.text = label
	button.modulate = Color.WHITE if enabled else COLOR_DIM

func _on_backpack_item_pressed(index: int) -> void:
	if current_state == null:
		return
	selected_source = "backpack"
	selected_equipment_slot = ""
	RVInventorySystem.select_backpack_index(current_state, index)
	update_from_state(current_state)

func _on_backpack_item_gui_input(event: InputEvent, index: int) -> void:
	if current_state == null:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_start_drag(index, mouse_event.position)
			accept_event()

func _on_equipment_slot_pressed(slot_name: String) -> void:
	if current_state == null:
		return
	selected_source = "equipment"
	selected_equipment_slot = RVInventorySystem.normalize_slot(slot_name)
	RVInventorySystem.select_equipment_slot(current_state, selected_equipment_slot)
	update_from_state(current_state)

func _on_equip_pressed() -> void:
	if current_state == null:
		return
	if selected_source != "backpack":
		return
	RVInventorySystem.equip_selected_backpack_item(current_state)
	selected_source = "backpack"
	selected_equipment_slot = ""
	_ensure_backpack_positions(current_state)
	update_from_state(current_state)

func _on_stash_pressed() -> void:
	if current_state == null or selected_source != "backpack":
		return
	RVInventorySystem.stash_selected_backpack_item(current_state)
	_ensure_backpack_positions(current_state)
	update_from_state(current_state)

func _on_salvage_pressed() -> void:
	if current_state == null or selected_source != "backpack":
		return
	RVInventorySystem.salvage_selected_backpack_item(current_state)
	_ensure_backpack_positions(current_state)
	update_from_state(current_state)

func _on_unequip_pressed() -> void:
	if current_state == null or selected_source != "equipment":
		return
	RVInventorySystem.unequip_selected_item(current_state)
	selected_source = "backpack"
	selected_equipment_slot = ""
	_ensure_backpack_positions(current_state)
	update_from_state(current_state)

func _on_close_pressed() -> void:
	_cancel_drag()
	if current_state != null:
		current_state.panel_mode = ""

func _start_drag(index: int, mouse_pos: Vector2) -> void:
	if current_state == null or index < 0 or index >= current_state.backpack.size():
		return
	selected_source = "backpack"
	selected_equipment_slot = ""
	RVInventorySystem.select_backpack_index(current_state, index)
	var item: Dictionary = RVItemDB.normalize_item(current_state.backpack[index])
	drag_index = index
	drag_origin = Vector2i(int(item.get("inv_x", 0)), int(item.get("inv_y", 0)))
	if drag_preview != null and is_instance_valid(drag_preview):
		drag_preview.queue_free()
	drag_preview = Button.new()
	drag_preview.text = _compact_item_label(item)
	drag_preview.tooltip_text = _item_name(item)
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.modulate = Color(1.0, 1.0, 1.0, 0.78)
	add_child(drag_preview)
	var size_cells: Vector2i = _item_grid_size(item)
	var pitch: Vector2 = _cell_pitch()
	drag_preview.size = Vector2(float(size_cells.x) * pitch.x - CELL_GAP, float(size_cells.y) * pitch.y - CELL_GAP)
	drag_preview.global_position = mouse_pos + Vector2(18.0, 18.0)
	drag_preview.z_index = 999
	update_from_state(current_state)

func _finish_drag(mouse_pos: Vector2) -> void:
	if current_state == null or drag_index < 0:
		_cancel_drag()
		return
	if drag_index >= current_state.backpack.size():
		_cancel_drag()
		return
	if _try_drop_on_equipment(mouse_pos):
		_cancel_drag()
		update_from_state(current_state)
		return
	if _try_drop_on_action(mouse_pos):
		_cancel_drag()
		update_from_state(current_state)
		return
	if _try_drop_on_backpack(mouse_pos):
		_cancel_drag()
		update_from_state(current_state)
		return
	_cancel_drag()
	update_from_state(current_state)

func _cancel_drag() -> void:
	drag_index = -1
	if drag_preview != null and is_instance_valid(drag_preview):
		drag_preview.queue_free()
	drag_preview = null

func _try_drop_on_equipment(mouse_pos: Vector2) -> bool:
	if current_state == null or drag_index < 0:
		return false
	var item: Dictionary = RVItemDB.normalize_item(current_state.backpack[drag_index])
	for slot_key_variant: Variant in equipment_buttons.keys():
		var slot_key: String = RVInventorySystem.normalize_slot(str(slot_key_variant))
		var button: Button = equipment_buttons[slot_key_variant]
		if button.get_global_rect().has_point(mouse_pos):
			if _item_can_go_to_slot(item, slot_key):
				RVInventorySystem.select_backpack_index(current_state, drag_index)
				RVInventorySystem.equip_selected_backpack_item(current_state)
				return true
			current_state.add_notice("Wrong equipment slot")
			return true
	return false

func _try_drop_on_action(mouse_pos: Vector2) -> bool:
	if current_state == null or drag_index < 0:
		return false
	if _button_contains(equip_button, mouse_pos):
		RVInventorySystem.select_backpack_index(current_state, drag_index)
		RVInventorySystem.equip_selected_backpack_item(current_state)
		return true
	if _button_contains(stash_button, mouse_pos):
		RVInventorySystem.select_backpack_index(current_state, drag_index)
		RVInventorySystem.stash_selected_backpack_item(current_state)
		return true
	if _button_contains(salvage_button, mouse_pos):
		RVInventorySystem.select_backpack_index(current_state, drag_index)
		RVInventorySystem.salvage_selected_backpack_item(current_state)
		return true
	return false

func _button_contains(button: Button, mouse_pos: Vector2) -> bool:
	return button != null and button.visible and button.get_global_rect().has_point(mouse_pos)

func _try_drop_on_backpack(mouse_pos: Vector2) -> bool:
	if current_state == null or runtime_layer == null or drag_index < 0:
		return false
	if not runtime_layer.get_global_rect().has_point(mouse_pos):
		return false
	var local: Vector2 = mouse_pos - runtime_layer.global_position
	var pitch: Vector2 = _cell_pitch()
	var target: Vector2i = Vector2i(int(floor(local.x / pitch.x)), int(floor(local.y / pitch.y)))
	var item: Dictionary = RVItemDB.normalize_item(current_state.backpack[drag_index])
	var size_cells: Vector2i = _item_grid_size(item)
	if not _can_place_at(current_state, drag_index, target, size_cells):
		current_state.add_notice("No room there")
		return true
	item["inv_x"] = target.x
	item["inv_y"] = target.y
	item["inv_w"] = size_cells.x
	item["inv_h"] = size_cells.y
	current_state.backpack[drag_index] = item
	RVInventorySystem.select_backpack_index(current_state, drag_index)
	return true

func _character_summary_text(state: RVGameState) -> String:
	var lines: Array[String] = []
	lines.append("Level %s" % state.level)
	lines.append("Life %s / %s" % [int(state.player_hp), int(state.max_hp)])
	lines.append("Mana %s / %s" % [int(state.player_mana), int(state.max_mana)])
	lines.append("Gold %s" % state.gold)
	lines.append("")
	lines.append("EQUIPPED")
	for slot_key: String in RVInventorySystem.EQUIPMENT_ORDER:
		var item_value: Variant = state.equipped.get(slot_key, {})
		if typeof(item_value) == TYPE_DICTIONARY and not Dictionary(item_value).is_empty():
			var item: Dictionary = RVItemDB.normalize_item(item_value)
			lines.append("%s: %s" % [_slot_label(slot_key), _item_name(item)])
		else:
			lines.append("%s: Empty" % _slot_label(slot_key))
	return "\n".join(lines)

func _materials_text(state: RVGameState) -> String:
	return "Embers %s   Shards %s   Runes %s   Echo %s   Socket Prisms %s" % [
		state.materials.get("embers", 0),
		state.materials.get("shards", 0),
		state.materials.get("runes", 0),
		state.materials.get("echo_glass", 0),
		state.materials.get("socket_prisms", 0)
	]

func _detail_bbcode(state: RVGameState) -> String:
	if selected_source == "equipment" and selected_equipment_slot != "":
		var slot_key: String = RVInventorySystem.normalize_slot(selected_equipment_slot)
		var item_value: Variant = state.equipped.get(slot_key, {})
		if typeof(item_value) == TYPE_DICTIONARY and not Dictionary(item_value).is_empty():
			var equipped_item: Dictionary = RVItemDB.normalize_item(item_value)
			return _item_detail_bbcode(equipped_item, "SELECTED EQUIPPED ITEM", "Equipped %s" % _slot_label(slot_key))
		return "[b]SELECTED EQUIPPED ITEM[/b]\n%s is empty." % _slot_label(slot_key)
	if state.backpack.is_empty():
		return "[b]NO ITEM SELECTED[/b]\n\nClick an item in the backpack grid or an equipped slot."
	var selected_item: Dictionary = RVInventorySystem.selected_backpack_item(state)
	var source_line: String = "Backpack Item %s" % int(state.inventory_cursor + 1)
	var text: String = _item_detail_bbcode(selected_item, "SELECTED BACKPACK ITEM", source_line)
	var target: Dictionary = RVInventorySystem.comparison_target_for_item(state, selected_item)
	text += "\n\n" + _comparison_bbcode(selected_item, target)
	return text

func _item_detail_bbcode(item: Dictionary, header: String, source_line: String) -> String:
	var rarity: String = str(item.get("rarity", "Normal"))
	var color: String = _rarity_color_hex(rarity)
	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % header)
	lines.append("[color=#aaaaaa]%s[/color]" % source_line)
	lines.append("")
	lines.append("[color=%s][b]%s[/b][/color]" % [color, _item_name(item)])
	lines.append("%s %s · Item Level %s" % [rarity, str(item.get("base_type", _slot_label(str(item.get("slot", "item"))))), int(item.get("item_level", 1))])
	lines.append("Forge Potential: %s / %s" % [int(item.get("forge_potential", 0)), int(item.get("max_forge_potential", item.get("forge_potential", 0)))])
	var implicit_stats: Dictionary = _dict_from(item.get("implicit_stats", {}))
	if not implicit_stats.is_empty():
		lines.append("")
		lines.append("[b]Implicit[/b]")
		for key: String in _sorted_stat_keys(implicit_stats):
			lines.append("  %s" % _format_stat(key, implicit_stats[key]))
	_add_affix_bbcode(lines, "Prefixes", _array_from(item.get("prefixes", [])))
	_add_affix_bbcode(lines, "Suffixes", _array_from(item.get("suffixes", [])))
	var total_stats: Dictionary = _collect_total_stats(item)
	if not total_stats.is_empty():
		lines.append("")
		lines.append("[b]Total Stats[/b]")
		for key: String in _sorted_stat_keys(total_stats):
			lines.append("  %s" % _format_stat(key, total_stats[key]))
	var unique_effects: Array = _array_from(item.get("unique_effects", []))
	if not unique_effects.is_empty():
		lines.append("")
		lines.append("[color=#ffb45a][b]Unique Effects[/b][/color]")
		for effect: Variant in unique_effects:
			lines.append("  • %s" % str(effect))
	return "\n".join(lines)

func _comparison_bbcode(new_item: Dictionary, equipped_item: Dictionary) -> String:
	if equipped_item.is_empty():
		return "[b]COMPARED AGAINST[/b]\n[color=#aaaaaa]No equipped item in this slot.[/color]"
	var lines: Array[String] = []
	lines.append("[b]COMPARED AGAINST[/b]")
	lines.append("%s: [color=%s]%s[/color]" % [_slot_label(str(equipped_item.get("slot", "item"))), _rarity_color_hex(str(equipped_item.get("rarity", "Normal"))), _item_name(equipped_item)])
	var new_stats: Dictionary = _collect_total_stats(new_item)
	var old_stats: Dictionary = _collect_total_stats(equipped_item)
	var keys: Array[String] = _merged_stat_keys(new_stats, old_stats)
	var gains: Array[String] = []
	var losses: Array[String] = []
	var neutral: Array[String] = []
	for key: String in keys:
		var delta: float = float(new_stats.get(key, 0.0)) - float(old_stats.get(key, 0.0))
		if abs(delta) < 0.0001:
			neutral.append("%s" % key)
		elif _is_positive_delta_good(key, delta):
			gains.append("[color=#65e66f]+ %s[/color]" % _format_delta_abs(key, delta))
		else:
			losses.append("[color=#ff5c57]- %s[/color]" % _format_delta_abs(key, delta))
	if gains.is_empty() and losses.is_empty():
		lines.append("[color=#cccccc]No stat changes.[/color]")
	else:
		if not gains.is_empty():
			lines.append("")
			lines.append("[color=#65e66f][b]GAINS[/b][/color]")
			for value: String in gains:
				lines.append("  %s" % value)
		if not losses.is_empty():
			lines.append("")
			lines.append("[color=#ff5c57][b]LOSSES[/b][/color]")
			for value: String in losses:
				lines.append("  %s" % value)
	if not neutral.is_empty():
		lines.append("")
		var capped_neutral: Array[String] = neutral.slice(0, min(4, neutral.size()))
		lines.append("[color=#aaaaaa]Neutral: %s[/color]" % ", ".join(capped_neutral))
	return "\n".join(lines)

func _add_affix_bbcode(lines: Array[String], title: String, affixes: Array) -> void:
	if affixes.is_empty():
		return
	lines.append("")
	lines.append("[b]%s[/b]" % title)
	for affix_value: Variant in affixes:
		if typeof(affix_value) != TYPE_DICTIONARY:
			continue
		var affix: Dictionary = Dictionary(affix_value)
		var tier: int = int(affix.get("tier", 1))
		var affix_name: String = str(affix.get("name", "Affix"))
		var stat_text: String = _affix_stat_text(affix)
		lines.append("  [color=#d5b56a]T%s[/color] %s — %s" % [tier, affix_name, stat_text])

func _affix_stat_text(affix: Dictionary) -> String:
	var stats: Dictionary = _dict_from(affix.get("stats", {}))
	if not stats.is_empty():
		var parts: PackedStringArray = PackedStringArray()
		for key: String in _sorted_stat_keys(stats):
			parts.append(_format_stat(key, stats[key]))
		return "; ".join(parts)
	var stat_name: String = str(affix.get("stat", "Stat"))
	var value: Variant = affix.get("value", 0.0)
	return _format_stat(stat_name, value)

func _ensure_backpack_positions(state: RVGameState) -> void:
	var occupied: Dictionary = {}
	for i: int in range(state.backpack.size()):
		var item: Dictionary = RVItemDB.normalize_item(state.backpack[i])
		var size_cells: Vector2i = _item_grid_size(item)
		var existing: Vector2i = Vector2i(int(item.get("inv_x", -1)), int(item.get("inv_y", -1)))
		var valid_existing: bool = existing.x >= 0 and existing.y >= 0 and _can_place_in_map(occupied, existing, size_cells)
		var final_pos: Vector2i = existing if valid_existing else _find_first_free(occupied, size_cells)
		if final_pos.x < 0:
			final_pos = Vector2i(0, 0)
		item["inv_x"] = final_pos.x
		item["inv_y"] = final_pos.y
		item["inv_w"] = size_cells.x
		item["inv_h"] = size_cells.y
		state.backpack[i] = item
		_mark_occupied(occupied, final_pos, size_cells, i)

func _find_first_free(occupied: Dictionary, size_cells: Vector2i) -> Vector2i:
	for y: int in range(GRID_ROWS):
		for x: int in range(GRID_COLUMNS):
			var pos: Vector2i = Vector2i(x, y)
			if _can_place_in_map(occupied, pos, size_cells):
				return pos
	return Vector2i(-1, -1)

func _can_place_at(state: RVGameState, ignore_index: int, pos: Vector2i, size_cells: Vector2i) -> bool:
	var occupied: Dictionary = {}
	for i: int in range(state.backpack.size()):
		if i == ignore_index:
			continue
		var item: Dictionary = RVItemDB.normalize_item(state.backpack[i])
		var item_pos: Vector2i = Vector2i(int(item.get("inv_x", 0)), int(item.get("inv_y", 0)))
		var item_size: Vector2i = _item_grid_size(item)
		_mark_occupied(occupied, item_pos, item_size, i)
	return _can_place_in_map(occupied, pos, size_cells)

func _can_place_in_map(occupied: Dictionary, pos: Vector2i, size_cells: Vector2i) -> bool:
	if pos.x < 0 or pos.y < 0:
		return false
	if pos.x + size_cells.x > GRID_COLUMNS or pos.y + size_cells.y > GRID_ROWS:
		return false
	for y: int in range(pos.y, pos.y + size_cells.y):
		for x: int in range(pos.x, pos.x + size_cells.x):
			if occupied.has("%s,%s" % [x, y]):
				return false
	return true

func _mark_occupied(occupied: Dictionary, pos: Vector2i, size_cells: Vector2i, index: int) -> void:
	for y: int in range(pos.y, pos.y + size_cells.y):
		for x: int in range(pos.x, pos.x + size_cells.x):
			occupied["%s,%s" % [x, y]] = index

func _item_grid_size(item: Dictionary) -> Vector2i:
	var explicit_w: int = int(item.get("inv_w", 0))
	var explicit_h: int = int(item.get("inv_h", 0))
	if explicit_w > 0 and explicit_h > 0:
		return Vector2i(clamp(explicit_w, 1, 3), clamp(explicit_h, 1, 4))
	var slot: String = RVInventorySystem.normalize_slot(str(item.get("slot", "")))
	var base_type: String = str(item.get("base_type", "")).to_lower()
	match slot:
		"weapon":
			if base_type.find("great") >= 0 or base_type.find("two") >= 0 or base_type.find("mace") >= 0 or base_type.find("axe") >= 0:
				return Vector2i(2, 3)
			return Vector2i(1, 3)
		"chest": return Vector2i(2, 3)
		"offhand": return Vector2i(2, 2)
		"head", "gloves", "boots": return Vector2i(2, 2)
		"amulet", "ring1", "ring2", "ring", "relic": return Vector2i(1, 1)
		_: return Vector2i(1, 1)

func _cell_size() -> Vector2:
	if backpack_slot_buttons.size() > 0:
		var first_button: Button = backpack_slot_buttons[0]
		if first_button.size.x > 1.0 and first_button.size.y > 1.0:
			return first_button.size
	return FALLBACK_CELL_SIZE

func _cell_pitch() -> Vector2:
	if backpack_slot_buttons.size() >= 2:
		var first_button: Button = backpack_slot_buttons[0]
		var second_button: Button = backpack_slot_buttons[1]
		var delta_x: float = second_button.position.x - first_button.position.x
		if delta_x > 4.0:
			return Vector2(delta_x, max(FALLBACK_CELL_SIZE.y + CELL_GAP, first_button.size.y + CELL_GAP))
	var cell_size: Vector2 = _cell_size()
	return Vector2(cell_size.x + CELL_GAP, cell_size.y + CELL_GAP)

func _grid_total_size() -> Vector2:
	var pitch: Vector2 = _cell_pitch()
	var cell: Vector2 = _cell_size()
	return Vector2(float(GRID_COLUMNS - 1) * pitch.x + cell.x, float(GRID_ROWS - 1) * pitch.y + cell.y)

func _comparison_slot_for_item(state: RVGameState, item: Dictionary) -> String:
	if item.is_empty():
		return ""
	var slot: String = RVInventorySystem.normalize_slot(str(item.get("slot", "")))
	if slot == "ring":
		var ring1: Variant = state.equipped.get("ring1", {})
		if typeof(ring1) == TYPE_DICTIONARY and not Dictionary(ring1).is_empty():
			return "ring1"
		return "ring2"
	if state.equipped.has(slot):
		return slot
	return ""

func _item_can_go_to_slot(item: Dictionary, slot_key: String) -> bool:
	var item_slot: String = RVInventorySystem.normalize_slot(str(item.get("slot", "")))
	var target: String = RVInventorySystem.normalize_slot(slot_key)
	if item_slot == "ring" and (target == "ring1" or target == "ring2"):
		return true
	return item_slot == target

func _collect_total_stats(item: Dictionary) -> Dictionary:
	var existing_total: Variant = item.get("total_stats", {})
	if typeof(existing_total) == TYPE_DICTIONARY and not Dictionary(existing_total).is_empty():
		return Dictionary(existing_total).duplicate(true)
	var stats: Dictionary = {}
	_merge_stats(stats, item.get("stats", {}))
	_merge_stats(stats, item.get("implicit_stats", {}))
	for group_variant: Variant in [item.get("prefixes", []), item.get("suffixes", []), item.get("affixes", [])]:
		if typeof(group_variant) != TYPE_ARRAY:
			continue
		for affix_variant: Variant in Array(group_variant):
			if typeof(affix_variant) != TYPE_DICTIONARY:
				continue
			var affix: Dictionary = Dictionary(affix_variant)
			_merge_stats(stats, affix.get("stats", {}))
			if affix.has("stat"):
				var stat_name: String = str(affix.get("stat", "Stat"))
				stats[stat_name] = float(stats.get(stat_name, 0.0)) + float(affix.get("value", 0.0))
	return stats

func _merge_stats(target: Dictionary, source_variant: Variant) -> void:
	if typeof(source_variant) != TYPE_DICTIONARY:
		return
	var source: Dictionary = Dictionary(source_variant)
	for key_variant: Variant in source.keys():
		var key: String = str(key_variant)
		target[key] = float(target.get(key, 0.0)) + float(source[key_variant])

func _dict_from(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return Dictionary(value)
	return {}

func _array_from(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return Array(value)
	return []

func _sorted_stat_keys(stats: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key_variant: Variant in stats.keys():
		keys.append(str(key_variant))
	keys.sort()
	return keys

func _merged_stat_keys(a: Dictionary, b: Dictionary) -> Array[String]:
	var keys: Array[String] = _sorted_stat_keys(a)
	for key_variant: Variant in b.keys():
		var key: String = str(key_variant)
		if not keys.has(key):
			keys.append(key)
	keys.sort()
	return keys

func _is_positive_delta_good(stat_name: String, delta: float) -> bool:
	var lower: String = stat_name.to_lower()
	var lower_is_good: bool = lower.find("cost") >= 0 or lower.find("cooldown") >= 0 and lower.find("reduction") < 0
	return delta < 0.0 if lower_is_good else delta > 0.0

func _format_stat(name: String, value: Variant) -> String:
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return "%s: %s" % [name, str(value)]
	var amount: float = float(value)
	var sign: String = "+" if amount >= 0.0 else ""
	if abs(amount) < 1.0 and not name.begins_with("Maximum") and name != "Armor":
		return "%s%s%% %s" % [sign, int(round(amount * 100.0)), name]
	return "%s%s %s" % [sign, int(round(amount)), name]

func _format_delta_abs(name: String, delta: float) -> String:
	var amount: float = abs(delta)
	if amount < 1.0 and not name.begins_with("Maximum") and name != "Armor":
		return "%s%% %s" % [int(round(amount * 100.0)), name]
	return "%s %s" % [int(round(amount)), name]

func _compact_item_label(item: Dictionary) -> String:
	return "%s\n%s" % [_rarity_letter(item), _type_short(item)]

func _rarity_letter(item: Dictionary) -> String:
	return str(item.get("rarity", "N")).substr(0, 1)

func _type_short(item: Dictionary) -> String:
	var base_type: String = str(item.get("base_type", item.get("slot", "Item")))
	if base_type.length() <= 5:
		return base_type
	return base_type.substr(0, 5)

func _item_name(item: Dictionary) -> String:
	return str(item.get("name", "Unnamed Item"))

func _slot_label(slot: String) -> String:
	match RVInventorySystem.normalize_slot(slot):
		"weapon": return "Weapon"
		"offhand": return "Offhand"
		"head": return "Helmet"
		"chest": return "Chest"
		"gloves": return "Gloves"
		"boots": return "Boots"
		"amulet": return "Amulet"
		"ring1": return "Ring 1"
		"ring2": return "Ring 2"
		"relic": return "Relic"
		_: return slot.capitalize()

func _rarity_color_hex(rarity: String) -> String:
	match rarity:
		"Unique": return "#ff9d3d"
		"Rare": return "#f2d75c"
		"Magic": return "#82a4ff"
		"Crafted": return "#61e6cb"
		_: return "#dddddd"

func _strip_bbcode(text: String) -> String:
	var stripped: String = text
	for token: String in ["[b]", "[/b]", "[i]", "[/i]"]:
		stripped = stripped.replace(token, "")
	var regex: RegEx = RegEx.new()
	if regex.compile("\\[/?color[^\\]]*\\]") == OK:
		stripped = regex.sub(stripped, "", true)
	return stripped
