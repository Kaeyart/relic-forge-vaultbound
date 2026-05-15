extends RVUIPanelBase

@onready var backpack_grid: Control = %BackpackGrid
@onready var equipment_grid: Control = %EquipmentGrid
@onready var detail_label: Label = %DetailLabel
@onready var character_summary: Label = %CharacterSummary
@onready var materials_label: Label = %MaterialsLabel
@onready var equip_button: Button = %EquipButton
@onready var stash_button: Button = %StashButton
@onready var salvage_button: Button = %SalvageButton
@onready var unequip_button: Button = %UnequipButton
@onready var close_button: Button = %CloseButton

var current_state: RVGameState = null
var backpack_buttons: Array[Button] = []
var equipment_buttons: Dictionary = {}

func _ready() -> void:
	super._ready()
	_collect_buttons()
	_connect_buttons()

func update_from_state(state: RVGameState) -> void:
	current_state = state
	_collect_buttons()
	_connect_buttons()
	_update_backpack_slots(state)
	_update_equipment_slots(state)
	_update_details(state)
	_update_actions(state)

func _collect_buttons() -> void:
	if backpack_buttons.is_empty() and backpack_grid != null:
		for child: Node in backpack_grid.get_children():
			if child is Button:
				backpack_buttons.append(child)
	if equipment_buttons.is_empty() and equipment_grid != null:
		for child2: Node in equipment_grid.get_children():
			if child2 is Button:
				var slot_name: String = str(child2.get_meta("slot", child2.name.to_lower()))
				equipment_buttons[slot_name] = child2

func _connect_buttons() -> void:
	for i: int in range(backpack_buttons.size()):
		var button: Button = backpack_buttons[i]
		var cb := _on_backpack_slot_pressed.bind(i)
		if not button.pressed.is_connected(cb):
			button.pressed.connect(cb)
	for slot_name: Variant in equipment_buttons.keys():
		var gear_button: Button = equipment_buttons[slot_name]
		var gear_cb := _on_equipment_slot_pressed.bind(str(slot_name))
		if not gear_button.pressed.is_connected(gear_cb):
			gear_button.pressed.connect(gear_cb)
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
		button.text = ""
		button.tooltip_text = ""
		button.disabled = i >= state.backpack.size()
		button.modulate = Color.WHITE
		if i < state.backpack.size():
			var item: Dictionary = state.backpack[i]
			button.tooltip_text = _tooltip_item_label(item)
			button.disabled = false
			# Temporary compact item marker until proper item icons are integrated.
			button.text = _compact_item_marker(item)
			button.modulate = Color(1.0, 0.88, 0.58, 1.0) if i == int(state.inventory_cursor) else Color.WHITE

func _update_equipment_slots(state: RVGameState) -> void:
	for slot_name: Variant in equipment_buttons.keys():
		var button: Button = equipment_buttons[slot_name]
		var slot_text: String = RVInventorySystem._slot_label(str(slot_name))
		var item_value: Variant = state.equipped.get(str(slot_name), {})
		if typeof(item_value) == TYPE_DICTIONARY and not item_value.is_empty():
			button.text = slot_text + "
" + _compact_item_marker(item_value)
			button.tooltip_text = _tooltip_item_label(item_value)
		else:
			button.text = slot_text
			button.tooltip_text = slot_text
		button.modulate = Color(1.0, 0.88, 0.58, 1.0) if RVInventorySystem.EQUIPMENT_ORDER.find(str(slot_name)) == int(state.equipment_cursor) else Color.WHITE

func _update_details(state: RVGameState) -> void:
	if character_summary != null:
		character_summary.text = "Level %s
Life %s / %s
Mana %s / %s
Gold %s" % [state.level, int(state.player_hp), int(state.max_hp), int(state.player_mana), int(state.max_mana), state.gold]
	if materials_label != null:
		materials_label.text = "Embers %s  Shards %s  Runes %s  Echo Glass %s" % [state.materials.get("embers", 0), state.materials.get("shards", 0), state.materials.get("runes", 0), state.materials.get("echo_glass", 0)]
	if detail_label == null:
		return
	var item: Dictionary = {}
	if not state.backpack.is_empty():
		item = RVInventorySystem.selected_backpack_item(state)
	else:
		item = RVInventorySystem.selected_equipped_item(state)
	detail_label.text = RVInventorySystem.item_detail_text(item)

func _update_actions(state: RVGameState) -> void:
	var has_backpack_item: bool = not RVInventorySystem.selected_backpack_item(state).is_empty()
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
	if index >= current_state.backpack.size():
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

func _compact_item_marker(item: Dictionary) -> String:
	var name: String = str(item.get("name", "Item")).strip_edges()
	if name == "":
		return "•"
	var words: PackedStringArray = name.split(" ", false)
	if words.size() >= 2:
		return words[0].substr(0, 1).to_upper() + words[1].substr(0, 1).to_upper()
	return name.substr(0, min(2, name.length())).to_upper()

func _tooltip_item_label(item: Dictionary) -> String:
	return "%s
%s %s" % [str(item.get("name", "Item")), str(item.get("rarity", "Common")), RVInventorySystem._slot_label(str(item.get("slot", "item")))]
