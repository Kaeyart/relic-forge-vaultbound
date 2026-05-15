extends RVUIPanelBase

# Inventory panel controller.
# Layout is scene-authored. This script may update data, selection states,
# tooltips, and button enabled/disabled states, but it must not position UI.
# Equipment slot labels should be separate Label nodes in the .tscn scene.

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


func _ready() -> void:
	super._ready()
	_collect_buttons()
	_connect_buttons()
	_clear_equipment_button_text()


func update_from_state(state: RVGameState) -> void:
	current_state = state
	_collect_buttons()
	_connect_buttons()
	_update_backpack_slots(state)
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
	backpack_buttons.clear()
	equipment_buttons.clear()

	if backpack_grid != null:
		for child: Node in backpack_grid.get_children():
			if child is Button:
				backpack_buttons.append(child)

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
		return str(meta_slot)

	var normalized_name: String = button.name.to_lower()
	if normalized_name.begins_with("slot"):
		normalized_name = normalized_name.trim_prefix("slot").to_lower()
	if normalized_name.begins_with("equipment"):
		normalized_name = normalized_name.trim_prefix("equipment").to_lower()

	for slot: String in RVInventorySystem.EQUIPMENT_ORDER:
		if normalized_name == slot or normalized_name.contains(slot):
			button.set_meta("slot", slot)
			return slot

	# Friendly aliases in case the scene uses display names.
	var aliases: Dictionary = {
		"mainhand": "weapon",
		"main_hand": "weapon",
		"mh": "weapon",
		"weapon": "weapon",
		"helm": "helmet",
		"head": "helmet",
		"helmet": "helmet",
		"body": "chest",
		"armor": "chest",
		"chest": "chest",
		"glove": "gloves",
		"gloves": "gloves",
		"boot": "boots",
		"boots": "boots",
		"neck": "amulet",
		"amulet": "amulet",
		"ring1": "ring1",
		"ringleft": "ring1",
		"ring_1": "ring1",
		"ring2": "ring2",
		"ringright": "ring2",
		"ring_2": "ring2",
		"relic": "relic",
		"offhand": "offhand",
		"off_hand": "offhand",
		"shield": "offhand"
	}
	for key: String in aliases.keys():
		if normalized_name.contains(key):
			var aliased_slot: String = str(aliases[key])
			button.set_meta("slot", aliased_slot)
			return aliased_slot

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


func _update_backpack_slots(state: RVGameState) -> void:
	for i: int in range(backpack_buttons.size()):
		var button: Button = backpack_buttons[i]
		if i < state.backpack.size():
			var item: Dictionary = state.backpack[i]
			button.text = _short_item_label(item)
			button.tooltip_text = str(item.get("name", "Item"))
			button.disabled = false
		else:
			button.text = ""
			button.tooltip_text = "Empty"
			button.disabled = true

		button.modulate = Color(1.0, 0.88, 0.58, 1.0) if i == int(state.inventory_cursor) and i < state.backpack.size() else Color.WHITE


func _update_equipment_slots(state: RVGameState) -> void:
	for slot_name: Variant in equipment_buttons.keys():
		var slot_key: String = str(slot_name)
		var button: Button = equipment_buttons[slot_key]
		var item_value: Variant = state.equipped.get(slot_key, {})

		# Critical scene-authored rule: never write Helmet / Empty / abbreviations into the button.
		# Labels belong to separate Label nodes placed by hand in the scene.
		button.text = ""
		button.disabled = false

		var display_slot: String = RVInventorySystem._slot_label(slot_key)
		if typeof(item_value) == TYPE_DICTIONARY and not item_value.is_empty():
			button.tooltip_text = "%s: %s" % [display_slot, str(item_value.get("name", "Item"))]
		else:
			button.tooltip_text = "%s: Empty" % display_slot

		button.modulate = Color(1.0, 0.88, 0.58, 1.0) if RVInventorySystem.EQUIPMENT_ORDER.find(slot_key) == int(state.equipment_cursor) else Color.WHITE


func _clear_equipment_button_text() -> void:
	for slot_name: Variant in equipment_buttons.keys():
		var button: Button = equipment_buttons[slot_name]
		button.text = ""


func _update_details(state: RVGameState) -> void:
	if character_summary != null:
		character_summary.text = "Level %s\nLife %s / %s\nMana %s / %s\nGold %s" % [
			state.level,
			int(state.player_hp),
			int(state.max_hp),
			int(state.player_mana),
			int(state.max_mana),
			state.gold
		]

	if materials_label != null:
		materials_label.text = "Embers %s Shards %s Runes %s Echo Glass %s" % [
			state.materials.get("embers", 0),
			state.materials.get("shards", 0),
			state.materials.get("runes", 0),
			state.materials.get("echo_glass", 0)
		]

	if detail_label == null:
		return

	var item: Dictionary = {}
	if not state.backpack.is_empty():
		item = RVInventorySystem.selected_backpack_item(state)
	else:
		item = RVInventorySystem.selected_equipped_item(state)
	detail_label.text = RVInventorySystem.item_detail_text(item)


func _update_actions(state: RVGameState) -> void:
	var has_backpack_item: bool = not state.backpack.is_empty()
	var has_equipped_item: bool = not RVInventorySystem.selected_equipped_item(state).is_empty()

	if equip_button != null:
		equip_button.disabled = not has_backpack_item
	if stash_button != null:
		stash_button.disabled = not has_backpack_item
	if salvage_button != null:
		salvage_button.disabled = not has_backpack_item
	if unequip_button != null:
		unequip_button.disabled = not has_equipped_item


func _on_backpack_slot_pressed(index: int) -> void:
	if current_state == null:
		return
	RVInventorySystem.select_backpack_index(current_state, index)
	_update_backpack_slots(current_state)
	_update_details(current_state)
	_update_actions(current_state)


func _on_equipment_slot_pressed(slot_name: String) -> void:
	if current_state == null:
		return
	RVInventorySystem.select_equipment_slot(current_state, slot_name)
	_update_equipment_slots(current_state)
	_update_details(current_state)
	_update_actions(current_state)


func _on_equip_pressed() -> void:
	if current_state == null:
		return
	RVInventorySystem.equip_selected_backpack_item(current_state)
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


func _short_item_label(item: Dictionary) -> String:
	var rarity: String = str(item.get("rarity", "Common"))
	var name: String = str(item.get("name", "Item"))
	return rarity.substr(0, 1) + "\n" + name.substr(0, 10)
