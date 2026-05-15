extends RVUIPanelBase

# Patch 035: Inventory usability + variable-shape backpack visualization.
# The scene owns all screen layout. This script only updates data, creates
# dynamic item click targets inside the scene-authored BackpackBoard, and
# routes item actions.

const GRID_COLUMNS: int = 8
const GRID_ROWS: int = 7
const CELL_SIZE: Vector2 = Vector2(46.0, 46.0)
const CELL_GAP: float = 4.0

@onready var backpack_board: Control = get_node_or_null("%BackpackBoard") as Control
@onready var cell_layer: Control = get_node_or_null("%BackpackCellLayer") as Control
@onready var item_layer: Control = get_node_or_null("%BackpackItemLayer") as Control
@onready var equipment_root: Control = get_node_or_null("%EquipmentSlots") as Control
@onready var candidate_detail: RichTextLabel = get_node_or_null("%CandidateDetail") as RichTextLabel
@onready var equipped_detail: RichTextLabel = get_node_or_null("%EquippedDetail") as RichTextLabel
@onready var character_summary: Label = get_node_or_null("%CharacterSummary") as Label
@onready var materials_label: Label = get_node_or_null("%MaterialsLabel") as Label
@onready var capacity_label: Label = get_node_or_null("%CapacityLabel") as Label
@onready var action_hint_label: Label = get_node_or_null("%ActionHintLabel") as Label
@onready var equip_button: Button = get_node_or_null("%EquipButton") as Button
@onready var unequip_button: Button = get_node_or_null("%UnequipButton") as Button
@onready var stash_button: Button = get_node_or_null("%StashButton") as Button
@onready var salvage_button: Button = get_node_or_null("%SalvageButton") as Button
@onready var close_button: Button = get_node_or_null("%CloseButton") as Button

var current_state: RVGameState = null
var cell_buttons: Array[Button] = []
var item_buttons: Array[Button] = []
var equipment_buttons: Dictionary = {}
var backpack_layout: Dictionary = {}
var selected_source: String = "backpack"
var selected_equipment_slot: String = "weapon"

func _ready() -> void:
	super._ready()
	_ensure_dynamic_layers()
	_build_backpack_cells()
	_collect_equipment_buttons()
	_connect_static_buttons()

func update_from_state(state: RVGameState) -> void:
	current_state = state
	_ensure_dynamic_layers()
	_collect_equipment_buttons()
	_rebuild_backpack_items(state)
	_update_equipment_slots(state)
	_update_summary(state)
	_update_details(state)
	_update_actions(state)

func _ensure_dynamic_layers() -> void:
	if backpack_board == null:
		return
	if cell_layer == null:
		cell_layer = backpack_board.get_node_or_null("BackpackCellLayer") as Control
	if cell_layer == null:
		cell_layer = Control.new()
		cell_layer.name = "BackpackCellLayer"
		backpack_board.add_child(cell_layer)
	if item_layer == null:
		item_layer = backpack_board.get_node_or_null("BackpackItemLayer") as Control
	if item_layer == null:
		item_layer = Control.new()
		item_layer.name = "BackpackItemLayer"
		backpack_board.add_child(item_layer)
	cell_layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	item_layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	cell_layer.position = Vector2.ZERO
	item_layer.position = Vector2.ZERO
	var board_size: Vector2 = _board_size()
	cell_layer.size = board_size
	item_layer.size = board_size

func _board_size() -> Vector2:
	return Vector2(
		float(GRID_COLUMNS) * CELL_SIZE.x + float(GRID_COLUMNS - 1) * CELL_GAP,
		float(GRID_ROWS) * CELL_SIZE.y + float(GRID_ROWS - 1) * CELL_GAP
	)

func _build_backpack_cells() -> void:
	if cell_layer == null:
		return
	for child: Node in cell_layer.get_children():
		child.queue_free()
	cell_buttons.clear()
	for y: int in range(GRID_ROWS):
		for x: int in range(GRID_COLUMNS):
			var cell: Button = Button.new()
			cell.name = "Cell_%02d_%02d" % [x, y]
			cell.text = ""
			cell.disabled = true
			cell.focus_mode = Control.FOCUS_NONE
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.position = _cell_position(x, y)
			cell.size = CELL_SIZE
			cell.modulate = Color(0.38, 0.36, 0.34, 0.42)
			cell_layer.add_child(cell)
			cell_buttons.append(cell)

func _cell_position(x: int, y: int) -> Vector2:
	return Vector2(float(x) * (CELL_SIZE.x + CELL_GAP), float(y) * (CELL_SIZE.y + CELL_GAP))

func _collect_equipment_buttons() -> void:
	equipment_buttons.clear()
	if equipment_root == null:
		equipment_root = get_node_or_null("%EquipmentGrid") as Control
	if equipment_root == null:
		return
	_collect_equipment_buttons_recursive(equipment_root)

func _collect_equipment_buttons_recursive(root: Node) -> void:
	for child: Node in root.get_children():
		if child is Button:
			var button: Button = child as Button
			var slot_name: String = _slot_from_button(button)
			if slot_name != "":
				equipment_buttons[slot_name] = button
		else:
			_collect_equipment_buttons_recursive(child)

func _slot_from_button(button: Button) -> String:
	var meta_slot: String = str(button.get_meta("slot", ""))
	if meta_slot != "":
		return _normalize_slot(meta_slot)
	var node_name: String = button.name.to_lower()
	var slot: String = _normalize_slot(node_name)
	if slot != "":
		button.set_meta("slot", slot)
	return slot

func _connect_static_buttons() -> void:
	if equip_button != null and not equip_button.pressed.is_connected(_on_equip_pressed):
		equip_button.pressed.connect(_on_equip_pressed)
	if unequip_button != null and not unequip_button.pressed.is_connected(_on_unequip_pressed):
		unequip_button.pressed.connect(_on_unequip_pressed)
	if stash_button != null and not stash_button.pressed.is_connected(_on_stash_pressed):
		stash_button.pressed.connect(_on_stash_pressed)
	if salvage_button != null and not salvage_button.pressed.is_connected(_on_salvage_pressed):
		salvage_button.pressed.connect(_on_salvage_pressed)
	if close_button != null and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

func _rebuild_backpack_items(state: RVGameState) -> void:
	if item_layer == null:
		return
	for child: Node in item_layer.get_children():
		child.queue_free()
	item_buttons.clear()
	backpack_layout = _pack_backpack_items(state.backpack)
	var hidden_count: int = 0
	for i: int in range(state.backpack.size()):
		if not backpack_layout.has(i):
			hidden_count += 1
			continue
		var item: Dictionary = state.backpack[i]
		var rect: Rect2i = backpack_layout[i]
		var button: Button = Button.new()
		button.name = "BackpackItem_%03d" % i
		button.text = _item_button_text(item)
		button.tooltip_text = str(item.get("name", "Item"))
		button.focus_mode = Control.FOCUS_NONE
		button.clip_text = true
		button.position = _cell_position(rect.position.x, rect.position.y)
		button.size = Vector2(
			float(rect.size.x) * CELL_SIZE.x + float(max(0, rect.size.x - 1)) * CELL_GAP,
			float(rect.size.y) * CELL_SIZE.y + float(max(0, rect.size.y - 1)) * CELL_GAP
		)
		button.modulate = _rarity_color(str(item.get("rarity", "Normal")), i == int(state.inventory_cursor) and selected_source == "backpack")
		button.pressed.connect(_on_backpack_item_pressed.bind(i))
		item_layer.add_child(button)
		item_buttons.append(button)
	if capacity_label != null:
		var visible_count: int = state.backpack.size() - hidden_count
		capacity_label.text = "Backpack %s item(s) · %s visible · %s hidden" % [state.backpack.size(), visible_count, hidden_count]

func _pack_backpack_items(items: Array) -> Dictionary:
	var result: Dictionary = {}
	var occupied: Array = []
	for y: int in range(GRID_ROWS):
		var row: Array[bool] = []
		for x: int in range(GRID_COLUMNS):
			row.append(false)
		occupied.append(row)
	for i: int in range(items.size()):
		var item_value: Variant = items[i]
		if typeof(item_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_value
		var shape: Vector2i = _item_shape(item)
		var origin: Vector2i = _find_space(occupied, shape)
		if origin.x < 0:
			continue
		_mark_space(occupied, origin, shape)
		result[i] = Rect2i(origin, shape)
	return result

func _find_space(occupied: Array, shape: Vector2i) -> Vector2i:
	for y: int in range(GRID_ROWS - shape.y + 1):
		for x: int in range(GRID_COLUMNS - shape.x + 1):
			if _space_is_free(occupied, x, y, shape):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _space_is_free(occupied: Array, start_x: int, start_y: int, shape: Vector2i) -> bool:
	for yy: int in range(shape.y):
		for xx: int in range(shape.x):
			var row: Array = occupied[start_y + yy]
			if bool(row[start_x + xx]):
				return false
	return true

func _mark_space(occupied: Array, origin: Vector2i, shape: Vector2i) -> void:
	for yy: int in range(shape.y):
		for xx: int in range(shape.x):
			var row: Array = occupied[origin.y + yy]
			row[origin.x + xx] = true

func _item_shape(item: Dictionary) -> Vector2i:
	var slot: String = _normalize_slot(str(item.get("slot", "")))
	var base_type: String = str(item.get("base_type", "")).to_lower()
	var name: String = str(item.get("name", "")).to_lower()
	if slot == "weapon":
		if base_type.contains("wand") or name.contains("wand"):
			return Vector2i(1, 3)
		if base_type.contains("staff") or name.contains("staff"):
			return Vector2i(1, 4)
		if name.contains("axe") or name.contains("mace") or name.contains("great"):
			return Vector2i(2, 3)
		return Vector2i(1, 3)
	if slot == "offhand":
		return Vector2i(2, 2)
	if slot == "chest":
		return Vector2i(2, 3)
	if slot == "head" or slot == "gloves" or slot == "boots" or slot == "relic":
		return Vector2i(2, 2)
	if slot == "amulet" or slot == "ring" or slot == "ring1" or slot == "ring2":
		return Vector2i(1, 1)
	return Vector2i(1, 1)

func _update_equipment_slots(state: RVGameState) -> void:
	for slot_key_variant: Variant in equipment_buttons.keys():
		var slot_key: String = str(slot_key_variant)
		var button: Button = equipment_buttons[slot_key]
		var item_value: Variant = state.equipped.get(slot_key, {})
		var label: String = _slot_label(slot_key)
		button.disabled = false
		if typeof(item_value) == TYPE_DICTIONARY and not item_value.is_empty():
			var item: Dictionary = item_value
			button.text = label + "\n" + _short_name(item, 12)
			button.tooltip_text = label + ": " + str(item.get("name", "Item"))
			button.modulate = _rarity_color(str(item.get("rarity", "Normal")), selected_source == "equipment" and selected_equipment_slot == slot_key)
		else:
			button.text = label + "\nEmpty"
			button.tooltip_text = label + ": Empty"
			button.modulate = Color(0.72, 0.72, 0.72, 1.0)
		if not button.pressed.is_connected(_on_equipment_slot_pressed.bind(slot_key)):
			button.pressed.connect(_on_equipment_slot_pressed.bind(slot_key))

func _update_summary(state: RVGameState) -> void:
	if character_summary != null:
		character_summary.text = _equipped_summary(state)
	if materials_label != null:
		materials_label.text = "Gold %s  ·  Embers %s  ·  Shards %s  ·  Runes %s  ·  Echo Glass %s" % [
			state.gold,
			state.materials.get("embers", 0),
			state.materials.get("shards", 0),
			state.materials.get("runes", 0),
			state.materials.get("echo_glass", 0)
		]

func _update_details(state: RVGameState) -> void:
	var selected_item: Dictionary = _selected_item(state)
	if candidate_detail != null:
		candidate_detail.text = _candidate_text(state, selected_item)
	if equipped_detail != null:
		equipped_detail.text = _equipped_compare_text(state, selected_item)
	if action_hint_label != null:
		action_hint_label.text = _action_hint_text(state, selected_item)

func _candidate_text(state: RVGameState, item: Dictionary) -> String:
	if item.is_empty():
		return "No item selected.\n\nClick an item in the backpack grid or an equipped slot."

	if selected_source == "backpack":
		return RVInventorySystem.item_detail_text_with_compare(state, item)

	return RVInventorySystem.item_detail_text(item)

func _equipped_compare_text(state: RVGameState, item: Dictionary) -> String:
	if item.is_empty():
		return "Equipped comparison\n\nNothing selected."
	if selected_source == "equipment":
		return "Selected equipped item\n\n" + RVInventorySystem.item_detail_text(item)
	var target: Dictionary = RVInventorySystem.equipped_item_for_item(state, item)
	if target.is_empty():
		return "Equipped comparison\n\nNo item equipped in this slot."
	return "Currently equipped\n\n" + RVInventorySystem.item_detail_text(target)

func _action_hint_text(state: RVGameState, item: Dictionary) -> String:
	if item.is_empty():
		return "Click a backpack item to equip/stash/salvage. Click gear to inspect or unequip."
	if selected_source == "equipment":
		return "Selected gear slot: " + _slot_label(selected_equipment_slot) + ". Use Unequip Selected to move it back to backpack."
	var target_slot: String = _target_slot_for_item(state, item)
	if target_slot == "":
		return "This item cannot be equipped. You can stash or salvage it."
	return "Target slot: " + _slot_label(target_slot) + ". The right panel shows your current equipped comparison."

func _update_actions(state: RVGameState) -> void:
	var item: Dictionary = _selected_item(state)
	var backpack_selected: bool = selected_source == "backpack" and not item.is_empty()
	var equipment_selected: bool = selected_source == "equipment" and not item.is_empty()
	if equip_button != null:
		equip_button.disabled = not backpack_selected or _target_slot_for_item(state, item) == ""
	if stash_button != null:
		stash_button.disabled = not backpack_selected
	if salvage_button != null:
		salvage_button.disabled = not backpack_selected
	if unequip_button != null:
		unequip_button.disabled = not equipment_selected

func _selected_item(state: RVGameState) -> Dictionary:
	if selected_source == "equipment":
		var item_value: Variant = state.equipped.get(selected_equipment_slot, {})
		if typeof(item_value) == TYPE_DICTIONARY:
			return item_value
		return {}
	if state.backpack.is_empty():
		return {}
	RVInventorySystem.select_backpack_index(state, int(state.inventory_cursor))
	return RVInventorySystem.selected_backpack_item(state)

func _on_backpack_item_pressed(index: int) -> void:
	if current_state == null:
		return
	selected_source = "backpack"
	RVInventorySystem.select_backpack_index(current_state, index)
	update_from_state(current_state)

func _on_equipment_slot_pressed(slot_name: String) -> void:
	if current_state == null:
		return
	selected_source = "equipment"
	selected_equipment_slot = _normalize_slot(slot_name)
	RVInventorySystem.select_equipment_slot(current_state, selected_equipment_slot)
	update_from_state(current_state)

func _on_equip_pressed() -> void:
	if current_state == null:
		return
	if selected_source != "backpack":
		current_state.add_notice("Select a backpack item first")
		return
	RVInventorySystem.equip_selected_backpack_item(current_state)
	selected_source = "backpack"
	update_from_state(current_state)

func _on_unequip_pressed() -> void:
	if current_state == null:
		return
	if selected_source != "equipment":
		current_state.add_notice("Select equipped gear first")
		return
	RVInventorySystem.unequip_slot(current_state, selected_equipment_slot)
	selected_source = "backpack"
	update_from_state(current_state)

func _on_stash_pressed() -> void:
	if current_state == null:
		return
	if selected_source != "backpack":
		current_state.add_notice("Only backpack items can be stashed")
		return
	RVInventorySystem.stash_selected_backpack_item(current_state)
	update_from_state(current_state)

func _on_salvage_pressed() -> void:
	if current_state == null:
		return
	if selected_source != "backpack":
		current_state.add_notice("Only backpack items can be salvaged")
		return
	RVInventorySystem.salvage_selected_backpack_item(current_state)
	update_from_state(current_state)

func _on_close_pressed() -> void:
	if current_state != null:
		current_state.panel_mode = ""

func _target_slot_for_item(state: RVGameState, item: Dictionary) -> String:
	var slot: String = _normalize_slot(str(item.get("slot", "")))
	if slot == "ring":
		var ring1_value: Variant = state.equipped.get("ring1", {})
		if typeof(ring1_value) != TYPE_DICTIONARY or ring1_value.is_empty():
			return "ring1"
		return "ring2"
	if state.equipped.has(slot):
		return slot
	return ""

func _normalize_slot(raw_slot: String) -> String:
	var slot: String = raw_slot.strip_edges().to_lower()
	slot = slot.replace(" ", "")
	slot = slot.replace("_", "")
	slot = slot.replace("-", "")
	slot = slot.replace("equipment", "")
	slot = slot.replace("equipped", "")
	slot = slot.replace("button", "")
	slot = slot.replace("slot", "")
	match slot:
		"helmet", "helm", "head":
			return "head"
		"mainhand", "main", "weapon", "sword", "axe", "mace", "staff", "wand":
			return "weapon"
		"offhand", "shield", "focus":
			return "offhand"
		"body", "bodyarmor", "armor", "chest", "chestarmor":
			return "chest"
		"glove", "gloves", "hands", "hand":
			return "gloves"
		"boot", "boots", "feet", "foot":
			return "boots"
		"neck", "necklace", "amulet":
			return "amulet"
		"ring1", "leftring":
			return "ring1"
		"ring2", "rightring":
			return "ring2"
		"ring":
			return "ring"
		"relic", "charm", "trinket":
			return "relic"
	return slot

func _slot_label(slot: String) -> String:
	match _normalize_slot(slot):
		"weapon":
			return "Weapon"
		"offhand":
			return "Offhand"
		"head":
			return "Helmet"
		"chest":
			return "Chest"
		"gloves":
			return "Gloves"
		"boots":
			return "Boots"
		"amulet":
			return "Amulet"
		"ring1":
			return "Ring 1"
		"ring2":
			return "Ring 2"
		"relic":
			return "Relic"
	return slot.capitalize()

func _item_button_text(item: Dictionary) -> String:
	var rarity: String = str(item.get("rarity", "Normal"))
	var base: String = str(item.get("base_type", item.get("slot", "Item")))
	if base == "":
		base = str(item.get("slot", "Item"))
	return rarity.substr(0, 1) + "\n" + _short_text(base, 10)

func _short_name(item: Dictionary, max_len: int) -> String:
	return _short_text(str(item.get("name", "Item")), max_len)

func _short_text(text: String, max_len: int) -> String:
	if text.length() <= max_len:
		return text
	return text.substr(0, max(1, max_len - 1)) + "…"

func _rarity_color(rarity: String, selected: bool) -> Color:
	var color: Color = Color.WHITE
	match rarity:
		"Normal":
			color = Color(0.78, 0.78, 0.72, 1.0)
		"Magic":
			color = Color(0.55, 0.72, 1.0, 1.0)
		"Rare":
			color = Color(1.0, 0.83, 0.38, 1.0)
		"Unique":
			color = Color(1.0, 0.48, 0.18, 1.0)
		"Crafted":
			color = Color(0.48, 1.0, 0.78, 1.0)
	if selected:
		color = color.lightened(0.35)
	return color

func _equipped_summary(state: RVGameState) -> String:
	var lines: Array[String] = []
	lines.append("EQUIPPED GEAR")
	lines.append("Level %s  ·  Life %s/%s  ·  Mana %s/%s" % [state.level, int(state.player_hp), int(state.max_hp), int(state.player_mana), int(state.max_mana)])
	for slot: String in RVInventorySystem.EQUIPMENT_ORDER:
		var item_value: Variant = state.equipped.get(slot, {})
		var item_name: String = "Empty"
		if typeof(item_value) == TYPE_DICTIONARY and not item_value.is_empty():
			item_name = _short_name(item_value, 24)
		lines.append(_slot_label(slot) + ": " + item_name)
	return "\n".join(lines)
