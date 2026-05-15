class_name RVMapDevicePanel
extends Control

@onready var list_label: Label = %MapListLabel
@onready var detail_label: Label = %MapDetailLabel
@onready var hint_label: Label = %HintLabel

var current_state: RVGameState = null

func _ready() -> void:
	visible = false

func update_from_state(state: RVGameState) -> void:
	current_state = state
	RVMapSystem.ensure_defaults(state)
	if list_label != null:
		list_label.text = RVMapSystem.map_stash_text(state)
	if detail_label != null:
		detail_label.text = RVMapSystem.selected_map_detail(state)
	if hint_label != null:
		hint_label.text = "N opens Map Device · W/S select · Enter/R run · G add dev map · Esc close"
