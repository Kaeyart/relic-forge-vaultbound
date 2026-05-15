extends RVUIPanelBase

# Scene-authored inventory controller.
# This script preserves the authored panel layout and only drives data, buttons,
# tooltips, comparison text, and the runtime tetris backpack overlay.

const GRID_COLUMNS: int = 7
const GRID_ROWS: int = 8
const CELL_GAP: float = 4.0
const FALLBACK_CELL: Vector2 = Vector2(40.0, 42.0)

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
var backpack_buttons: Array[Button] = []
var equipment_buttons: Dictionary = {}
var detail_source: String = "backpack"
var selected_equipment_slot: String = ""
var tetris_layer: Control = null
var drag_preview: Label = null
var dragging_index: int = -1
var backpack_layout: Dictionary = {}

func _ready() -> void:
	super._ready()
	set_process(true)
	_prepare_labels()
	_collect_buttons()
	_connect_buttons()
	_clear_equipment_button_text()
	_ensure_tetris_layer()

func _process(_delta: float) -> void:
	if drag_preview == null:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var offset: Vector2 = Vector2(18.0, 18.0)

	if drag_preview.get_parent() is Control:
		var parent_control: Control = drag_preview.get_parent() as Control
		drag_preview.position = mouse_pos - parent_control.global_position + offset
	else:
		drag_preview.position = mouse_pos + offset

func update_from_state(state: RVGameState) -> void:
	current_state = state
	_collect_buttons()
	_connect_buttons()
	_ensure_tetris_layer()
	_update_tetris_backpack(state)
	_update_equipment_slots(state)
	_update_details(state)
	_update_actions(state)

func _prepare_labels() -> void:
	if detail_label != null:
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_label.clip_text = true
	if character_summary != null:
		character_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		character_summary.clip_text = true
	if materials_label != null:
		materials_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		materials_label.clip_text = true

func _find_equipment_root() -> Control:
	var slots: Control = get_node_or_null("%EquipmentSlots") as Control
	if slots != null:
		return slots
	var grid: Control = get_node_or_null("%EquipmentGrid") as Control
	if grid != null:
		return grid
	return null

func _collect_buttons() -> void:
	backpack_buttons.clear()
	equipment_buttons.clear()
	if backpack_grid != null:
		for child: Node in backpack_grid.get_children():
			if child is Button:
				backpack_buttons.append(child as Button)
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
	for i: int in range(backpack_buttons.size()):
		var button: Button = backpack_buttons[i]
		if not button.pressed.is_connected(_on_backpack_slot_pressed.bind(i)):
			button.pressed.connect(_on_backpack_slot_pressed.bind(i))
	for slot_name: Variant in equipment_buttons.keys():
		var gear_button: Button = equipment_buttons[slot_name]
		if not gear_button.pressed.is_connected(_on_equipment_slot_pressed.bind(str(slot_name))):
			gear_button.pressed.connect(_on_equipment_slot_pressed.bind(str(slot_name)))
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

func _ensure_tetris_layer() -> void:
	if backpack_grid == null:
		return
	if tetris_layer == null:
		tetris_layer = Control.new()
		tetris_layer.name = "RuntimeTetrisBackpackLayer"
		tetris_layer.mouse_filter = Control.MOUSE_FILTER_PASS
		var parent: Node = backpack_grid.get_parent()
		if parent != null:
			parent.add_child(tetris_layer)
		else:
			add_child(tetris_layer)
	if tetris_layer.get_parent() == backpack_grid.get_parent():
		tetris_layer.position = backpack_grid.position
	else:
		tetris_layer.global_position = backpack_grid.global_position
	var target_size: Vector2 = backpack_grid.size
	if target_size.x < 80.0 or target_size.y < 80.0:
		target_size = Vector2(320.0, 372.0)
	tetris_layer.size = target_size
	# The authored BackpackGrid remains as the scene placement reference. Its old
	# child buttons are hidden so long text cannot leak into the art.
	for child: Node in backpack_grid.get_children():
		if child is Control:
			(child as Control).visible = false

func _update_tetris_backpack(state: RVGameState) -> void:
	if tetris_layer == null:
		_update_backpack_slots_fallback(state)
		return
	for child: Node in tetris_layer.get_children():
		child.queue_free()
	backpack_layout = _auto_pack_backpack(state)
	var cell: Vector2 = _cell_size()
	for i: int in range(state.backpack.size()):
		if not backpack_layout.has(i):
			continue
		var item: Dictionary = RVItemDB.normalize_item(state.backpack[i])
		var rect: Rect2 = backpack_layout[i]
		var button: Button = Button.new()
		button.name = "Item_%03d" % i
		button.position = Vector2(rect.position.x * (cell.x + CELL_GAP), rect.position.y * (cell.y + CELL_GAP))
		button.size = Vector2(rect.size.x * cell.x + max(0.0, rect.size.x - 1.0) * CELL_GAP, rect.size.y * cell.y + max(0.0, rect.size.y - 1.0) * CELL_GAP)
		button.text = _tetris_item_label(item)
		button.tooltip_text = str(item.get("name", "Item")) + "\nClick to inspect. Drag onto gear slots, Equip, Stash, or Destroy."
		button.clip_text = true
		button.focus_mode = Control.FOCUS_NONE
		button.modulate = _rarity_color(str(item.get("rarity", "Normal")))
		if i == int(state.inventory_cursor) and detail_source == "backpack":
			button.modulate = Color(1.0, 0.88, 0.55, 1.0)
		tetris_layer.add_child(button)
		button.pressed.connect(_on_backpack_slot_pressed.bind(i))
		button.gui_input.connect(_on_tetris_button_gui_input.bind(i, button))

func _update_backpack_slots_fallback(state: RVGameState) -> void:
	for i: int in range(backpack_buttons.size()):
		var button: Button = backpack_buttons[i]
		if i < state.backpack.size():
			var item: Dictionary = RVItemDB.normalize_item(state.backpack[i])
			button.text = _grid_item_label(item)
			button.tooltip_text = str(item.get("name", "Item"))
			button.disabled = false
		else:
			button.text = ""
			button.tooltip_text = "Empty"
			button.disabled = true
		button.modulate = Color(1.0, 0.88, 0.58, 1.0) if i == int(state.inventory_cursor) and detail_source == "backpack" else Color.WHITE

func _auto_pack_backpack(state: RVGameState) -> Dictionary:
	var occupied: Array = []
	for y: int in range(GRID_ROWS):
		var row: Array[bool] = []
		for x: int in range(GRID_COLUMNS):
			row.append(false)
		occupied.append(row)
	var layout: Dictionary = {}
	for i: int in range(state.backpack.size()):
		var item: Dictionary = RVItemDB.normalize_item(state.backpack[i])
		var size: Vector2i = RVInventorySystem.item_grid_size(item)
		var placed: bool = false
		for y: int in range(GRID_ROWS):
			for x: int in range(GRID_COLUMNS):
				if _can_place(occupied, x, y, size.x, size.y):
					_mark_place(occupied, x, y, size.x, size.y)
					layout[i] = Rect2(Vector2(float(x), float(y)), Vector2(float(size.x), float(size.y)))
					placed = true
					break
			if placed:
				break
		if not placed:
			layout[i] = Rect2(Vector2(float(i % GRID_COLUMNS), float(GRID_ROWS - 1)), Vector2.ONE)
	return layout

func _can_place(occupied: Array, x: int, y: int, w: int, h: int) -> bool:
	if x + w > GRID_COLUMNS or y + h > GRID_ROWS:
		return false
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			if bool(occupied[yy][xx]):
				return false
	return true

func _mark_place(occupied: Array, x: int, y: int, w: int, h: int) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			occupied[yy][xx] = true

func _cell_size() -> Vector2:
	if tetris_layer == null:
		return FALLBACK_CELL
	var available: Vector2 = tetris_layer.size
	if available.x < 80.0 or available.y < 80.0:
		return FALLBACK_CELL
	var cell_w: float = floor((available.x - CELL_GAP * float(GRID_COLUMNS - 1)) / float(GRID_COLUMNS))
	var cell_h: float = floor((available.y - CELL_GAP * float(GRID_ROWS - 1)) / float(GRID_ROWS))
	return Vector2(max(24.0, cell_w), max(24.0, cell_h))

func _update_equipment_slots(state: RVGameState) -> void:
	for slot_name: Variant in equipment_buttons.keys():
		var slot_key: String = RVInventorySystem.normalize_slot(str(slot_name))
		var button: Button = equipment_buttons[slot_name]
		var item_value: Variant = state.equipped.get(slot_key, {})
		button.disabled = false
		var display_slot: String = RVInventorySystem._slot_label(slot_key)
		if typeof(item_value) == TYPE_DICTIONARY and not Dictionary(item_value).is_empty():
			var item: Dictionary = RVItemDB.normalize_item(item_value)
			button.text = str(item.get("rarity", "Normal")).substr(0, 1)
			button.tooltip_text = "%s: %s" % [display_slot, str(item.get("name", "Item"))]
			button.modulate = _rarity_color(str(item.get("rarity", "Normal")))
			_update_optional_equipped_name_label(slot_key, str(item.get("name", "Item")))
		else:
			button.text = ""
			button.tooltip_text = "%s: Empty" % display_slot
			button.modulate = Color.WHITE
			_update_optional_equipped_name_label(slot_key, "Empty")
		if RVInventorySystem.EQUIPMENT_ORDER.find(slot_key) == int(state.equipment_cursor) and detail_source == "equipment":
			button.modulate = Color(1.0, 0.88, 0.58, 1.0)

func _update_optional_equipped_name_label(slot_key: String, text: String) -> void:
	var candidates: Array[String] = [
		"EquippedName" + RVInventorySystem._slot_label(slot_key).replace(" ", ""),
		"LabelEquipped" + RVInventorySystem._slot_label(slot_key).replace(" ", ""),
		"Equipped" + RVInventorySystem._slot_label(slot_key).replace(" ", "")
	]
	for node_name: String in candidates:
		var node: Node = find_child(node_name, true, false)
		if node is Label:
			var label: Label = node as Label
			label.text = _truncate(text, 24)
			return

func _clear_equipment_button_text() -> void:
	for slot_name: Variant in equipment_buttons.keys():
		var button: Button = equipment_buttons[slot_name]
		button.text = ""

func _update_details(state: RVGameState) -> void:
	if character_summary != null:
		character_summary.text = _character_text(state)
	if materials_label != null:
		materials_label.text = "Embers %s · Shards %s · Runes %s · Echo %s · Socket Prisms %s" % [
			state.materials.get("embers", 0),
			state.materials.get("shards", 0),
			state.materials.get("runes", 0),
			state.materials.get("echo_glass", 0),
			state.materials.get("socket_prisms", 0)
		]
	if detail_label == null:
		return
	if detail_source == "equipment" and selected_equipment_slot != "":
		var item_value: Variant = state.equipped.get(RVInventorySystem.normalize_slot(selected_equipment_slot), {})
		if typeof(item_value) == TYPE_DICTIONARY and not Dictionary(item_value).is_empty():
			detail_label.text = "SELECTED EQUIPPED ITEM\n\n" + RVInventorySystem.item_compact_detail_text(RVItemDB.normalize_item(item_value))
		else:
			detail_label.text = "Selected equipment slot is empty."
		return
	if not state.backpack.is_empty():
		var item: Dictionary = RVInventorySystem.selected_backpack_item(state)
		detail_label.text = "SELECTED BACKPACK ITEM\n\n" + RVInventorySystem.item_compact_detail_text(item) + "\n\n" + RVInventorySystem.item_compare_text(state, item)
	else:
		detail_label.text = "No backpack item selected.\n\nClick an item in the backpack grid or an equipped slot."

func _character_text(state: RVGameState) -> String:
	var lines: Array[String] = []
	lines.append("Character")
	lines.append("Level %s" % state.level)
	lines.append("Life %s / %s" % [int(state.player_hp), int(state.max_hp)])
	lines.append("Mana %s / %s" % [int(state.player_mana), int(state.max_mana)])
	lines.append("Gold %s" % state.gold)
	lines.append("")
	lines.append("Equipped")
	for slot: String in RVInventorySystem.EQUIPMENT_ORDER:
		var item_value: Variant = state.equipped.get(slot, {})
		if typeof(item_value) == TYPE_DICTIONARY and not Dictionary(item_value).is_empty():
			var item: Dictionary = RVItemDB.normalize_item(item_value)
			lines.append(RVInventorySystem._slot_label(slot) + ": " + _truncate(str(item.get("name", "Item")), 24))
		else:
			lines.append(RVInventorySystem._slot_label(slot) + ": Empty")
	return "\n".join(lines)

func _update_actions(state: RVGameState) -> void:
	var has_backpack_item: bool = detail_source == "backpack" and not state.backpack.is_empty()
	var has_equipped_item: bool = detail_source == "equipment" and not RVInventorySystem.selected_equipped_item(state).is_empty()
	if equip_button != null:
		equip_button.text = "Equip Selected"
		equip_button.visible = true
		equip_button.disabled = not has_backpack_item
	if stash_button != null:
		stash_button.text = "Stash Selected"
		stash_button.visible = true
		stash_button.disabled = not has_backpack_item
	if salvage_button != null:
		salvage_button.text = "Destroy / Salvage"
		salvage_button.visible = true
		salvage_button.disabled = not has_backpack_item
	if unequip_button != null:
		unequip_button.text = "Unequip Gear"
		unequip_button.visible = true
		unequip_button.disabled = not has_equipped_item
	if close_button != null:
		close_button.text = "Close"
		close_button.visible = true
		close_button.disabled = false

func _on_backpack_slot_pressed(index: int) -> void:
	if current_state == null:
		return
	detail_source = "backpack"
	selected_equipment_slot = ""
	RVInventorySystem.select_backpack_index(current_state, index)
	update_from_state(current_state)

func _on_equipment_slot_pressed(slot_name: String) -> void:
	if current_state == null:
		return
	detail_source = "equipment"
	selected_equipment_slot = RVInventorySystem.normalize_slot(slot_name)
	RVInventorySystem.select_equipment_slot(current_state, selected_equipment_slot)
	update_from_state(current_state)

func _on_equip_pressed() -> void:
	if current_state == null:
		return
	RVInventorySystem.equip_selected_backpack_item(current_state)
	detail_source = "backpack"
	update_from_state(current_state)

func _on_stash_pressed() -> void:
	if current_state == null:
		return
	RVInventorySystem.stash_selected_backpack_item(current_state)
	update_from_state(current_state)

func _on_salvage_pressed() -> void:
	if current_state == null:
		return
	RVInventorySystem.salvage_selected_backpack_item(current_state)
	update_from_state(current_state)

func _on_unequip_pressed() -> void:
	if current_state == null:
		return
	RVInventorySystem.unequip_selected_item(current_state)
	update_from_state(current_state)

func _on_close_pressed() -> void:
	if current_state != null:
		current_state.panel_mode = ""

func _on_tetris_button_gui_input(event: InputEvent, index: int, button: Button) -> void:
	if current_state == null:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			dragging_index = index
			_start_drag_preview(button.text)
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			_finish_drag_drop(index)
	elif event is InputEventMouseMotion:
		if dragging_index == index and drag_preview == null:
			_start_drag_preview(button.text)

func _start_drag_preview(text: String) -> void:
	if drag_preview != null:
		drag_preview.queue_free()
	drag_preview = Label.new()
	drag_preview.text = text
	drag_preview.modulate = Color(1.0, 0.86, 0.45, 0.88)
	drag_preview.z_index = 500
	add_child(drag_preview)

func _finish_drag_drop(index: int) -> void:
	if current_state == null:
		_clear_drag_preview()
		return
	var global_mouse: Vector2 = get_global_mouse_position()
	RVInventorySystem.select_backpack_index(current_state, index)
	var item: Dictionary = RVInventorySystem.selected_backpack_item(current_state)
	for slot_name: Variant in equipment_buttons.keys():
		var slot_key: String = RVInventorySystem.normalize_slot(str(slot_name))
		var button: Button = equipment_buttons[slot_name]
		if button.get_global_rect().has_point(global_mouse):
			if RVInventorySystem.item_can_equip_to_slot(current_state, item, slot_key):
				RVInventorySystem.equip_backpack_item_to_slot(current_state, index, slot_key)
			else:
				current_state.add_notice("Wrong equipment slot")
			_clear_drag_preview()
			update_from_state(current_state)
			return
	if equip_button != null and equip_button.get_global_rect().has_point(global_mouse):
		RVInventorySystem.equip_selected_backpack_item(current_state)
	elif stash_button != null and stash_button.get_global_rect().has_point(global_mouse):
		RVInventorySystem.stash_selected_backpack_item(current_state)
	elif salvage_button != null and salvage_button.get_global_rect().has_point(global_mouse):
		RVInventorySystem.salvage_selected_backpack_item(current_state)
	else:
		detail_source = "backpack"
		selected_equipment_slot = ""
	_clear_drag_preview()
	update_from_state(current_state)

func _clear_drag_preview() -> void:
	dragging_index = -1
	if drag_preview != null:
		drag_preview.queue_free()
		drag_preview = null

func _tetris_item_label(item: Dictionary) -> String:
	var rarity: String = str(item.get("rarity", "Normal")).substr(0, 1)
	var slot: String = RVInventorySystem.normalize_slot(str(item.get("slot", "item")))
	return rarity + "\n" + _slot_code(slot)

func _grid_item_label(item: Dictionary) -> String:
	return str(item.get("rarity", "Normal")).substr(0, 1)

func _slot_code(slot: String) -> String:
	match slot:
		"weapon":
			return "WPN"
		"offhand":
			return "OFF"
		"head":
			return "HELM"
		"chest":
			return "CHEST"
		"gloves":
			return "GLV"
		"boots":
			return "BOOT"
		"amulet":
			return "AMU"
		"ring1", "ring2", "ring":
			return "RING"
		"relic":
			return "REL"
	return "ITM"

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Normal":
			return Color(0.88, 0.88, 0.84, 1.0)
		"Magic":
			return Color(0.62, 0.78, 1.0, 1.0)
		"Rare":
			return Color(1.0, 0.86, 0.38, 1.0)
		"Unique":
			return Color(1.0, 0.50, 0.22, 1.0)
		"Crafted":
			return Color(0.76, 1.0, 0.78, 1.0)
	return Color.WHITE

func _truncate(text: String, max_len: int) -> String:
	if text.length() <= max_len:
		return text
	return text.substr(0, max(0, max_len - 3)) + "..."
