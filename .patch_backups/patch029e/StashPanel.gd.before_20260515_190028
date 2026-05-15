extends RVUIPanelBase

@onready var stash_grid: GridContainer = %StashGrid
@onready var detail_label: Label = %DetailLabel
@onready var withdraw_button: Button = %WithdrawButton
@onready var deposit_all_button: Button = %DepositAllButton
@onready var close_button: Button = %CloseButton

var current_state: RVGameState = null
var stash_buttons: Array[Button] = []

func _ready() -> void:
	super._ready()
	_collect_buttons()
	_connect_buttons()


func update_from_state(state: RVGameState) -> void:
	current_state = state
	_collect_buttons()
	_update_stash_slots(state)
	_update_detail(state)
	_update_actions(state)


func _collect_buttons() -> void:
	if stash_buttons.is_empty() and stash_grid != null:
		for child: Node in stash_grid.get_children():
			if child is Button:
				stash_buttons.append(child)


func _connect_buttons() -> void:
	for i: int in range(stash_buttons.size()):
		var button: Button = stash_buttons[i]
		if not button.pressed.is_connected(_on_stash_slot_pressed.bind(i)):
			button.pressed.connect(_on_stash_slot_pressed.bind(i))
	if withdraw_button != null and not withdraw_button.pressed.is_connected(_on_withdraw_pressed):
		withdraw_button.pressed.connect(_on_withdraw_pressed)
	if deposit_all_button != null and not deposit_all_button.pressed.is_connected(_on_deposit_all_pressed):
		deposit_all_button.pressed.connect(_on_deposit_all_pressed)
	if close_button != null and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)


func _update_stash_slots(state: RVGameState) -> void:
	for i: int in range(stash_buttons.size()):
		var button: Button = stash_buttons[i]
		if i < state.stash.size():
			var item: Dictionary = state.stash[i]
			button.text = str(item.get("rarity", "Common")) + "\n" + str(item.get("name", "Item")).substr(0, 18)
			button.disabled = false
		else:
			button.text = "Empty"
			button.disabled = true
		button.modulate = Color(1.0, 0.88, 0.58, 1.0) if i == int(state.stash_cursor) and i < state.stash.size() else Color.WHITE


func _update_detail(state: RVGameState) -> void:
	if detail_label == null:
		return
	detail_label.text = RVInventorySystem.stash_panel_text(state)


func _update_actions(state: RVGameState) -> void:
	if withdraw_button != null:
		withdraw_button.disabled = state.stash.is_empty()
	if deposit_all_button != null:
		deposit_all_button.disabled = state.backpack.is_empty()


func _on_stash_slot_pressed(index: int) -> void:
	if current_state == null:
		return
	RVInventorySystem.select_stash_index(current_state, index)
	update_from_state(current_state)


func _on_withdraw_pressed() -> void:
	if current_state == null:
		return
	RVInventorySystem.withdraw_selected_stash_item(current_state)
	update_from_state(current_state)


func _on_deposit_all_pressed() -> void:
	if current_state == null:
		return
	RVInventorySystem.deposit_all_backpack(current_state)
	update_from_state(current_state)


func _on_close_pressed() -> void:
	if current_state != null:
		current_state.panel_mode = ""
