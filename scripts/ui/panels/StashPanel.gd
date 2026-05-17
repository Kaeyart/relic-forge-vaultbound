extends RVUIPanelBase

@onready var stash_grid: GridContainer = get_node_or_null("%StashGrid") as GridContainer
@onready var detail_label: Label = get_node_or_null("%DetailLabel") as Label
@onready var withdraw_button: Button = get_node_or_null("%WithdrawButton") as Button
@onready var deposit_all_button: Button = get_node_or_null("%DepositAllButton") as Button
@onready var close_button: Button = get_node_or_null("%CloseButton") as Button
@onready var general_tab_button: Button = get_node_or_null("%GeneralTabButton") as Button
@onready var maps_tab_button: Button = get_node_or_null("%MapsTabButton") as Button
@onready var tier_prev_button: Button = get_node_or_null("%TierPrevButton") as Button
@onready var tier_next_button: Button = get_node_or_null("%TierNextButton") as Button
@onready var map_tier_filter_label: Label = get_node_or_null("%MapTierFilterLabel") as Label
@onready var local_title_label: Label = get_node_or_null("%TitleLabel") as Label

var current_state: RVGameState = null
var stash_buttons: Array[Button] = []
var active_tab: String = "items"
var drag_tab: String = ""
var drag_index: int = -1
var drag_preview: Button = null

func _ready() -> void:
	super._ready()
	_collect_buttons()
	_connect_buttons()
	set_process_input(true)

func update_from_state(state: RVGameState) -> void:
	current_state = state
	RVMapSystem.ensure_defaults(state)
	_collect_buttons()
	_update_title_and_tabs(state)
	_update_stash_slots(state)
	_update_detail(state)
	_update_actions(state)

func _collect_buttons() -> void:
	stash_buttons.clear()
	if stash_grid != null:
		for child: Node in stash_grid.get_children():
			if child is Button:
				stash_buttons.append(child as Button)

func _connect_buttons() -> void:
	for i: int in range(stash_buttons.size()):
		var button: Button = stash_buttons[i]
		if not button.pressed.is_connected(_on_stash_slot_pressed.bind(i)):
			button.pressed.connect(_on_stash_slot_pressed.bind(i))
		if not button.gui_input.is_connected(_on_stash_slot_gui_input.bind(i)):
			button.gui_input.connect(_on_stash_slot_gui_input.bind(i))
	_bind(withdraw_button, _on_withdraw_pressed)
	_bind(deposit_all_button, _on_deposit_all_pressed)
	_bind(close_button, _on_close_pressed)
	_bind(general_tab_button, _on_general_tab_pressed)
	_bind(maps_tab_button, _on_maps_tab_pressed)
	_bind(tier_prev_button, _on_tier_prev_pressed)
	_bind(tier_next_button, _on_tier_next_pressed)

func _bind(button: Button, callback: Callable) -> void:
	if button != null and not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if drag_preview != null and is_instance_valid(drag_preview):
		if event is InputEventMouseMotion:
			drag_preview.global_position = (event as InputEventMouseMotion).global_position + Vector2(18.0, 18.0)
		elif event is InputEventMouseButton:
			var mouse_event: InputEventMouseButton = event as InputEventMouseButton
			if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
				_finish_drag(mouse_event.global_position)
				accept_event()
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed:
			return
		match key_event.keycode:
			KEY_TAB:
				active_tab = "maps" if active_tab == "items" else "items"
				update_from_state(current_state)
				accept_event()
			KEY_A, KEY_LEFT:
				if active_tab == "maps" and current_state != null:
					RVMapItemSystem.cycle_tier_filter(current_state, -1)
					update_from_state(current_state)
					accept_event()
			KEY_D, KEY_RIGHT:
				if active_tab == "maps" and current_state != null:
					RVMapItemSystem.cycle_tier_filter(current_state, 1)
					update_from_state(current_state)
					accept_event()

func _update_title_and_tabs(state: RVGameState) -> void:
	if local_title_label != null:
		local_title_label.text = "Stash — " + ("Map Tab" if active_tab == "maps" else "Items")
	if general_tab_button != null:
		general_tab_button.text = "Items"
		general_tab_button.modulate = Color(1.0, 0.88, 0.58, 1.0) if active_tab == "items" else Color.WHITE
	if maps_tab_button != null:
		maps_tab_button.text = "Maps (" + str(state.map_stash.size()) + ")"
		maps_tab_button.modulate = Color(1.0, 0.88, 0.58, 1.0) if active_tab == "maps" else Color.WHITE
	if map_tier_filter_label != null:
		map_tier_filter_label.visible = active_tab == "maps"
		map_tier_filter_label.text = RVMapItemSystem.tier_filter_text(state)
	if tier_prev_button != null:
		tier_prev_button.visible = active_tab == "maps"
	if tier_next_button != null:
		tier_next_button.visible = active_tab == "maps"

func _update_stash_slots(state: RVGameState) -> void:
	if active_tab == "maps":
		_update_map_slots(state)
	else:
		_update_item_slots(state)

func _update_item_slots(state: RVGameState) -> void:
	for i: int in range(stash_buttons.size()):
		var button: Button = stash_buttons[i]
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		if i < state.stash.size():
			var item: Dictionary = RVMapItemSystem.normalize_inventory_value(state.stash[i], "stash", state)
			state.stash[i] = item
			button.text = _slot_label_for_item(item)
			button.tooltip_text = RVMapItemSystem.map_plain_text(item, state) if RVMapItemSystem.is_map_item(item) else str(item.get("name", "Item"))
			button.disabled = false
			button.modulate = _item_color(item, i == int(state.stash_cursor))
		else:
			button.text = "Empty"
			button.tooltip_text = "Empty stash slot"
			button.disabled = true
			button.modulate = Color.WHITE

func _update_map_slots(state: RVGameState) -> void:
	var indices: Array = RVMapItemSystem.filtered_map_indices(state)
	for i: int in range(stash_buttons.size()):
		var button: Button = stash_buttons[i]
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		if i < indices.size():
			var map_index: int = int(indices[i])
			var map_item: Dictionary = RVMapItemSystem.normalize_map_item(Dictionary(state.map_stash[map_index]), "map_tab", state)
			state.map_stash[map_index] = map_item
			button.text = _map_slot_label(map_item)
			button.tooltip_text = RVMapItemSystem.map_plain_text(map_item, state)
			button.disabled = false
			button.modulate = RVMapItemSystem.map_button_color(map_item, map_index == int(state.map_cursor))
		else:
			button.text = "Empty"
			button.tooltip_text = "Empty map slot"
			button.disabled = true
			button.modulate = Color.WHITE

func _update_detail(state: RVGameState) -> void:
	if detail_label == null:
		return
	if active_tab == "maps":
		var map_index: int = RVMapItemSystem.selected_map_index(state)
		if map_index >= 0 and map_index < state.map_stash.size():
			detail_label.text = RVMapItemSystem.map_plain_text(Dictionary(state.map_stash[map_index]), state)
		else:
			detail_label.text = "MAP TAB\n\nNo map selected.\nDeposit maps from backpack, then filter by tier."
	else:
		detail_label.text = RVInventorySystem.stash_panel_text(state)

func _update_actions(state: RVGameState) -> void:
	if withdraw_button != null:
		withdraw_button.disabled = _active_count(state) <= 0
		withdraw_button.text = "Withdraw Map" if active_tab == "maps" else "Withdraw Selected"
	if deposit_all_button != null:
		deposit_all_button.disabled = state.backpack.is_empty()
		deposit_all_button.text = "Deposit Maps" if active_tab == "maps" else "Deposit Items"

func _active_count(state: RVGameState) -> int:
	return RVMapItemSystem.filtered_map_indices(state).size() if active_tab == "maps" else state.stash.size()

func _on_stash_slot_pressed(index: int) -> void:
	if current_state == null:
		return
	if active_tab == "maps":
		var indices: Array = RVMapItemSystem.filtered_map_indices(current_state)
		if index < indices.size():
			current_state.map_cursor = int(indices[index])
	else:
		RVInventorySystem.select_stash_index(current_state, index)
	update_from_state(current_state)

func _on_stash_slot_gui_input(event: InputEvent, index: int) -> void:
	if current_state == null:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_start_drag(index, mouse_event.global_position)
			accept_event()

func _start_drag(slot_index: int, mouse_pos: Vector2) -> void:
	if current_state == null:
		return
	if active_tab == "maps":
		var indices: Array = RVMapItemSystem.filtered_map_indices(current_state)
		if slot_index >= indices.size():
			return
		current_state.map_cursor = int(indices[slot_index])
		drag_index = int(indices[slot_index])
	else:
		if slot_index >= current_state.stash.size():
			return
		RVInventorySystem.select_stash_index(current_state, slot_index)
		drag_index = slot_index
	drag_tab = active_tab
	if drag_preview != null and is_instance_valid(drag_preview):
		drag_preview.queue_free()
	drag_preview = Button.new()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.modulate = Color(1.0, 1.0, 1.0, 0.78)
	drag_preview.text = _drag_label()
	drag_preview.size = Vector2(112.0, 58.0)
	add_child(drag_preview)
	drag_preview.global_position = mouse_pos + Vector2(18.0, 18.0)
	drag_preview.z_index = 999
	update_from_state(current_state)

func _finish_drag(mouse_pos: Vector2) -> void:
	if current_state == null or drag_index < 0:
		_cancel_drag()
		return
	if _button_contains(withdraw_button, mouse_pos):
		if drag_tab == "maps":
			RVMapItemSystem.move_map_tab_item_to_backpack(current_state, drag_index)
		else:
			RVInventorySystem.select_stash_index(current_state, drag_index)
			RVInventorySystem.withdraw_selected_stash_item(current_state)
		_cancel_drag()
		update_from_state(current_state)
		return
	if _button_contains(maps_tab_button, mouse_pos):
		if drag_tab == "items" and drag_index < current_state.stash.size() and RVMapItemSystem.is_map_item(current_state.stash[drag_index]):
			RVMapItemSystem.move_general_stash_map_to_map_tab(current_state, drag_index)
			active_tab = "maps"
		_cancel_drag()
		update_from_state(current_state)
		return
	_cancel_drag()
	update_from_state(current_state)

func _cancel_drag() -> void:
	drag_tab = ""
	drag_index = -1
	if drag_preview != null and is_instance_valid(drag_preview):
		drag_preview.queue_free()
	drag_preview = null

func _drag_label() -> String:
	if current_state == null:
		return "Item"
	if drag_tab == "maps" and drag_index >= 0 and drag_index < current_state.map_stash.size():
		return RVMapItemSystem.map_item_label(Dictionary(current_state.map_stash[drag_index]))
	if drag_tab == "items" and drag_index >= 0 and drag_index < current_state.stash.size():
		var item: Dictionary = RVMapItemSystem.normalize_inventory_value(current_state.stash[drag_index], "stash", current_state)
		return RVMapItemSystem.map_item_label(item) if RVMapItemSystem.is_map_item(item) else str(item.get("rarity", "Item")).substr(0, 1) + "\n" + str(item.get("base_type", "Item")).substr(0, 5)
	return "Item"

func _on_withdraw_pressed() -> void:
	if current_state == null:
		return
	if active_tab == "maps":
		RVMapItemSystem.move_selected_map_tab_item_to_backpack(current_state)
	else:
		RVInventorySystem.withdraw_selected_stash_item(current_state)
	update_from_state(current_state)

func _on_deposit_all_pressed() -> void:
	if current_state == null:
		return
	if active_tab == "maps":
		var moved_maps: int = RVMapItemSystem.deposit_all_backpack_maps_to_map_tab(current_state)
		if moved_maps == 0:
			current_state.add_notice("No backpack maps to deposit")
	else:
		var moved_items: int = RVMapItemSystem.deposit_all_non_map_backpack_items_to_stash(current_state)
		var moved_maps_from_backpack: int = RVMapItemSystem.deposit_all_backpack_maps_to_map_tab(current_state)
		if moved_items == 0 and moved_maps_from_backpack == 0:
			current_state.add_notice("Backpack is empty")
	update_from_state(current_state)

func _on_general_tab_pressed() -> void:
	active_tab = "items"
	update_from_state(current_state)

func _on_maps_tab_pressed() -> void:
	active_tab = "maps"
	update_from_state(current_state)

func _on_tier_prev_pressed() -> void:
	if current_state != null:
		RVMapItemSystem.cycle_tier_filter(current_state, -1)
		update_from_state(current_state)

func _on_tier_next_pressed() -> void:
	if current_state != null:
		RVMapItemSystem.cycle_tier_filter(current_state, 1)
		update_from_state(current_state)

func _on_close_pressed() -> void:
	_cancel_drag()
	if current_state != null:
		current_state.panel_mode = ""

func _slot_label_for_item(item: Dictionary) -> String:
	if RVMapItemSystem.is_map_item(item):
		return _map_slot_label(item)
	return str(item.get("rarity", "Common")) + "\n" + str(item.get("name", "Item")).substr(0, 18)

func _map_slot_label(map_item: Dictionary) -> String:
	var done: String = "✓" if bool(map_item.get("completed", false)) else "□"
	return done + " T" + str(int(map_item.get("tier", 1))) + "\n" + str(map_item.get("name", "Map")).substr(0, 18)

func _item_color(item: Dictionary, selected: bool = false) -> Color:
	if RVMapItemSystem.is_map_item(item):
		return RVMapItemSystem.map_button_color(item, selected)
	if selected:
		return Color(1.0, 0.88, 0.58, 1.0)
	match str(item.get("rarity", "Normal")):
		"Unique": return Color(0.95, 0.55, 0.18, 1.0)
		"Rare": return Color(0.92, 0.80, 0.26, 1.0)
		"Magic": return Color(0.55, 0.68, 1.0, 1.0)
		_: return Color.WHITE

func _button_contains(button: Button, mouse_pos: Vector2) -> bool:
	return button != null and button.visible and button.get_global_rect().has_point(mouse_pos)
