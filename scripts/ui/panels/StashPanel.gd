extends RVUIPanelBase

@onready var stash_grid: GridContainer = get_node_or_null("%StashGrid") as GridContainer
@onready var detail_label: Label = get_node_or_null("%DetailLabel") as Label
@onready var withdraw_button: Button = get_node_or_null("%WithdrawButton") as Button
@onready var deposit_all_button: Button = get_node_or_null("%DepositAllButton") as Button
@onready var close_button: Button = get_node_or_null("%CloseButton") as Button
@onready var general_tab_button: Button = get_node_or_null("%GeneralTabButton") as Button
@onready var maps_tab_button: Button = get_node_or_null("%MapsTabButton") as Button
@onready var currency_tab_button: Button = get_node_or_null("%CurrencyTabButton") as Button
@onready var materials_tab_button: Button = get_node_or_null("%MaterialsTabButton") as Button
@onready var gems_tab_button: Button = get_node_or_null("%GemsTabButton") as Button
@onready var uniques_tab_button: Button = get_node_or_null("%UniquesTabButton") as Button
@onready var dump_tab_button: Button = get_node_or_null("%DumpTabButton") as Button
@onready var buy_tab_button: Button = get_node_or_null("%BuyTabButton") as Button
@onready var affinity_toggle_button: Button = get_node_or_null("%AffinityToggleButton") as Button
@onready var tier_prev_button: Button = get_node_or_null("%TierPrevButton") as Button
@onready var tier_next_button: Button = get_node_or_null("%TierNextButton") as Button
@onready var map_tier_filter_label: Label = get_node_or_null("%MapTierFilterLabel") as Label
@onready var economy_label: Label = get_node_or_null("%StashEconomyLabel") as Label
@onready var local_title_label: Label = get_node_or_null("%TitleLabel") as Label

var current_state: RVGameState = null
var stash_buttons: Array[Button] = []
var active_tab: String = RVStashSystem.TAB_GENERAL
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
	RVStashSystem.ensure_defaults(state)
	RVMapSystem.ensure_defaults(state)
	if str(state.stash_tab_mode) != "" and RVStashSystem.tab_order().has(str(state.stash_tab_mode)):
		active_tab = str(state.stash_tab_mode)
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
	_bind(general_tab_button, _on_tab_pressed.bind(RVStashSystem.TAB_GENERAL))
	_bind(maps_tab_button, _on_tab_pressed.bind(RVStashSystem.TAB_MAPS))
	_bind(currency_tab_button, _on_tab_pressed.bind(RVStashSystem.TAB_CURRENCY))
	_bind(materials_tab_button, _on_tab_pressed.bind(RVStashSystem.TAB_MATERIALS))
	_bind(gems_tab_button, _on_tab_pressed.bind(RVStashSystem.TAB_GEMS))
	_bind(uniques_tab_button, _on_tab_pressed.bind(RVStashSystem.TAB_UNIQUES))
	_bind(dump_tab_button, _on_tab_pressed.bind(RVStashSystem.TAB_DUMP))
	_bind(buy_tab_button, _on_buy_tab_pressed)
	_bind(affinity_toggle_button, _on_affinity_toggle_pressed)
	_bind(tier_prev_button, _on_tier_prev_pressed)
	_bind(tier_next_button, _on_tier_next_pressed)

func _bind(button: Button, callback: Callable) -> void:
	if button != null and not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _input(event: InputEvent) -> void:
	if not visible or current_state == null:
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
				_cycle_visible_tab(1)
				accept_event()
			KEY_A, KEY_LEFT:
				if active_tab == RVStashSystem.TAB_MAPS:
					RVMapItemSystem.cycle_tier_filter(current_state, -1)
					update_from_state(current_state)
					accept_event()
			KEY_D, KEY_RIGHT:
				if active_tab == RVStashSystem.TAB_MAPS:
					RVMapItemSystem.cycle_tier_filter(current_state, 1)
					update_from_state(current_state)
					accept_event()
			KEY_B:
				_on_buy_tab_pressed()
				accept_event()
			KEY_F:
				_on_affinity_toggle_pressed()
				accept_event()

func _cycle_visible_tab(delta: int) -> void:
	var order: Array[String] = RVStashSystem.tab_order()
	var index: int = max(0, order.find(active_tab))
	index = wrapi(index + delta, 0, order.size())
	_select_tab(order[index])

func _update_title_and_tabs(state: RVGameState) -> void:
	if local_title_label != null:
		local_title_label.text = "Stash — " + RVStashSystem.tab_display_name(active_tab)
	_update_tab_button(general_tab_button, RVStashSystem.TAB_GENERAL)
	_update_tab_button(maps_tab_button, RVStashSystem.TAB_MAPS)
	_update_tab_button(currency_tab_button, RVStashSystem.TAB_CURRENCY)
	_update_tab_button(materials_tab_button, RVStashSystem.TAB_MATERIALS)
	_update_tab_button(gems_tab_button, RVStashSystem.TAB_GEMS)
	_update_tab_button(uniques_tab_button, RVStashSystem.TAB_UNIQUES)
	_update_tab_button(dump_tab_button, RVStashSystem.TAB_DUMP)
	var is_maps: bool = active_tab == RVStashSystem.TAB_MAPS
	if map_tier_filter_label != null:
		map_tier_filter_label.visible = is_maps
		map_tier_filter_label.text = RVMapItemSystem.tier_filter_text(state)
	if tier_prev_button != null:
		tier_prev_button.visible = is_maps
	if tier_next_button != null:
		tier_next_button.visible = is_maps
	if buy_tab_button != null:
		var unlocked: bool = RVStashSystem.is_tab_unlocked(state, active_tab)
		var cost: int = RVStashSystem.tab_cost(active_tab)
		buy_tab_button.visible = cost > 0
		buy_tab_button.disabled = unlocked or int(state.gold) < cost
		buy_tab_button.text = "Owned" if unlocked else "Buy " + str(cost) + "g"
	if affinity_toggle_button != null:
		affinity_toggle_button.text = "Affinity ON" if state.stash_affinities_enabled else "Affinity OFF"
	if economy_label != null:
		economy_label.text = _economy_text(state)

func _update_tab_button(button: Button, tab_id: String) -> void:
	if button == null or current_state == null:
		return
	var unlocked: bool = RVStashSystem.is_tab_unlocked(current_state, tab_id)
	var count: int = _tab_count_for_display(current_state, tab_id)
	var label: String = RVStashSystem.tab_display_name(tab_id)
	if not unlocked:
		label += " " + str(RVStashSystem.tab_cost(tab_id)) + "g"
	else:
		label += " (" + str(count) + ")"
	button.text = label
	button.disabled = false
	if tab_id == active_tab:
		button.modulate = Color(1.0, 0.88, 0.58, 1.0)
	elif not unlocked:
		button.modulate = Color(0.55, 0.55, 0.55, 1.0)
	else:
		button.modulate = Color.WHITE

func _economy_text(state: RVGameState) -> String:
	var affinity: String = "ON" if state.stash_affinities_enabled else "OFF"
	if RVStashSystem.is_tab_unlocked(state, active_tab):
		return "Gold: " + str(state.gold) + " · Affinity " + affinity + " · Deposit routes maps/currency/materials/gems/uniques to owned tabs. Press F to toggle."
	return "Gold: " + str(state.gold) + " · " + RVStashSystem.tab_display_name(active_tab) + " tab locked. Press B or Buy Tab to unlock."

func _update_stash_slots(state: RVGameState) -> void:
	if active_tab == RVStashSystem.TAB_MAPS:
		_update_map_slots(state)
	elif active_tab == RVStashSystem.TAB_GENERAL:
		_update_item_slots(state, state.stash, state.stash_cursor)
	else:
		_update_special_slots(state)

func _update_item_slots(state: RVGameState, items: Array, selected_index: int) -> void:
	for i: int in range(stash_buttons.size()):
		var button: Button = stash_buttons[i]
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		if i < items.size():
			var item: Dictionary = RVMapItemSystem.normalize_inventory_value(items[i], "stash", state)
			items[i] = item
			button.text = _slot_label_for_item(item)
			button.tooltip_text = RVMapItemSystem.map_plain_text(item, state) if RVMapItemSystem.is_map_item(item) else str(item.get("name", "Item"))
			button.disabled = false
			button.modulate = _item_color(item, i == selected_index)
		else:
			button.text = "Empty"
			button.tooltip_text = "Empty stash slot"
			button.disabled = true
			button.modulate = Color.WHITE

func _update_special_slots(state: RVGameState) -> void:
	if not RVStashSystem.is_tab_unlocked(state, active_tab):
		for button: Button in stash_buttons:
			button.text = "Locked"
			button.tooltip_text = "Buy this tab to store matching items."
			button.disabled = true
			button.modulate = Color(0.55, 0.55, 0.55, 1.0)
		return
	var items: Array = RVStashSystem.tab_items(state, active_tab)
	_update_item_slots(state, items, int(state.stash_tab_cursor))
	RVStashSystem.set_tab_items(state, active_tab, items)

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
	if active_tab == RVStashSystem.TAB_GENERAL:
		detail_label.text = RVInventorySystem.stash_panel_text(state)
		return
	if active_tab == RVStashSystem.TAB_MAPS:
		var map_index: int = RVMapItemSystem.selected_map_index(state)
		detail_label.text = RVStashSystem.selected_detail_text(state, active_tab, map_index)
		return
	detail_label.text = RVStashSystem.selected_detail_text(state, active_tab, int(state.stash_tab_cursor))

func _update_actions(state: RVGameState) -> void:
	var unlocked: bool = RVStashSystem.is_tab_unlocked(state, active_tab)
	if withdraw_button != null:
		withdraw_button.disabled = not unlocked or _active_count(state) <= 0
		withdraw_button.text = "Withdraw " + RVStashSystem.tab_display_name(active_tab)
	if deposit_all_button != null:
		deposit_all_button.disabled = state.backpack.is_empty()
		deposit_all_button.text = "Deposit by Affinity" if state.stash_affinities_enabled else "Deposit to Items"

func _active_count(state: RVGameState) -> int:
	return _tab_count_for_display(state, active_tab)

func _tab_count_for_display(state: RVGameState, tab_id: String) -> int:
	if tab_id == RVStashSystem.TAB_MAPS:
		return RVMapItemSystem.filtered_map_indices(state).size()
	return RVStashSystem.tab_count(state, tab_id)

func _on_stash_slot_pressed(index: int) -> void:
	if current_state == null:
		return
	if active_tab == RVStashSystem.TAB_MAPS:
		var indices: Array = RVMapItemSystem.filtered_map_indices(current_state)
		if index < indices.size():
			current_state.map_cursor = int(indices[index])
	elif active_tab == RVStashSystem.TAB_GENERAL:
		RVInventorySystem.select_stash_index(current_state, index)
	else:
		current_state.stash_tab_cursor = index
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
	if current_state == null or not RVStashSystem.is_tab_unlocked(current_state, active_tab):
		return
	if active_tab == RVStashSystem.TAB_MAPS:
		var indices: Array = RVMapItemSystem.filtered_map_indices(current_state)
		if slot_index >= indices.size():
			return
		current_state.map_cursor = int(indices[slot_index])
		drag_index = int(indices[slot_index])
	elif active_tab == RVStashSystem.TAB_GENERAL:
		if slot_index >= current_state.stash.size():
			return
		RVInventorySystem.select_stash_index(current_state, slot_index)
		drag_index = slot_index
	else:
		var items: Array = RVStashSystem.tab_items(current_state, active_tab)
		if slot_index >= items.size():
			return
		current_state.stash_tab_cursor = slot_index
		drag_index = slot_index
	drag_tab = active_tab
	if drag_preview != null and is_instance_valid(drag_preview):
		drag_preview.queue_free()
	drag_preview = Button.new()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.modulate = Color(1.0, 1.0, 1.0, 0.78)
	drag_preview.text = _drag_label()
	drag_preview.size = Vector2(118.0, 60.0)
	add_child(drag_preview)
	drag_preview.global_position = mouse_pos + Vector2(18.0, 18.0)
	drag_preview.z_index = 999
	update_from_state(current_state)

func _finish_drag(mouse_pos: Vector2) -> void:
	if current_state == null or drag_index < 0:
		_cancel_drag()
		return
	if _button_contains(withdraw_button, mouse_pos):
		_withdraw_from_drag()
		_cancel_drag()
		update_from_state(current_state)
		return
	if _button_contains(maps_tab_button, mouse_pos) and drag_tab == RVStashSystem.TAB_GENERAL and drag_index < current_state.stash.size() and RVMapItemSystem.is_map_item(current_state.stash[drag_index]):
		RVMapItemSystem.move_general_stash_map_to_map_tab(current_state, drag_index)
		_select_tab(RVStashSystem.TAB_MAPS)
		_cancel_drag()
		update_from_state(current_state)
		return
	_cancel_drag()
	update_from_state(current_state)

func _withdraw_from_drag() -> void:
	if drag_tab == RVStashSystem.TAB_MAPS:
		RVMapItemSystem.move_map_tab_item_to_backpack(current_state, drag_index)
	elif drag_tab == RVStashSystem.TAB_GENERAL:
		RVInventorySystem.select_stash_index(current_state, drag_index)
		RVInventorySystem.withdraw_selected_stash_item(current_state)
	else:
		RVStashSystem.withdraw_from_tab(current_state, drag_tab, drag_index)

func _cancel_drag() -> void:
	drag_tab = ""
	drag_index = -1
	if drag_preview != null and is_instance_valid(drag_preview):
		drag_preview.queue_free()
	drag_preview = null

func _drag_label() -> String:
	if current_state == null:
		return "Item"
	if drag_tab == RVStashSystem.TAB_MAPS and drag_index >= 0 and drag_index < current_state.map_stash.size():
		return RVMapItemSystem.map_item_label(Dictionary(current_state.map_stash[drag_index]))
	var items: Array = current_state.stash if drag_tab == RVStashSystem.TAB_GENERAL else RVStashSystem.tab_items(current_state, drag_tab)
	if drag_index >= 0 and drag_index < items.size():
		var item: Dictionary = RVMapItemSystem.normalize_inventory_value(items[drag_index], "stash", current_state)
		return RVMapItemSystem.map_item_label(item) if RVMapItemSystem.is_map_item(item) else str(item.get("rarity", "Item")).substr(0, 1) + "\n" + str(item.get("base_type", "Item")).substr(0, 5)
	return "Item"

func _on_withdraw_pressed() -> void:
	if current_state == null:
		return
	if active_tab == RVStashSystem.TAB_MAPS:
		RVMapItemSystem.move_selected_map_tab_item_to_backpack(current_state)
	elif active_tab == RVStashSystem.TAB_GENERAL:
		RVInventorySystem.withdraw_selected_stash_item(current_state)
	else:
		RVStashSystem.withdraw_from_tab(current_state, active_tab, int(current_state.stash_tab_cursor))
	update_from_state(current_state)

func _on_deposit_all_pressed() -> void:
	if current_state == null:
		return
	RVStashSystem.deposit_all_backpack_by_affinity(current_state)
	update_from_state(current_state)

func _on_tab_pressed(tab_id: String) -> void:
	_select_tab(tab_id)

func _select_tab(tab_id: String) -> void:
	active_tab = tab_id
	if current_state != null:
		current_state.stash_tab_mode = active_tab
		update_from_state(current_state)

func _on_buy_tab_pressed() -> void:
	if current_state == null:
		return
	RVStashSystem.purchase_tab(current_state, active_tab)
	update_from_state(current_state)

func _on_affinity_toggle_pressed() -> void:
	if current_state == null:
		return
	RVStashSystem.toggle_affinities(current_state)
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
	return str(item.get("rarity", "Common")).substr(0, 6) + "\n" + str(item.get("name", "Item")).substr(0, 18)

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
