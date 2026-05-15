extends CanvasLayer

# Scene-authored system UI root.
# Owns panel visibility/key routing only. Layout belongs to scenes.

var game_state: Object = null
var active_panel: Control = null

@onready var inventory_panel: Control = $Panels/InventoryPanel
@onready var crafting_panel: Control = $Panels/CraftingPanel
@onready var passive_panel: Control = $Panels/PassiveAtlasPanel
@onready var skill_gems_panel: Control = $Panels/SkillGemsPanel
@onready var character_panel: Control = $Panels/CharacterPanel
@onready var stash_panel: Control = $Panels/StashPanel
@onready var activity_panel: Control = $Panels/ActivityPanel

func _ready() -> void:
	layer = 100
	game_state = _find_state()
	_close_all()
	set_process(true)
	set_process_input(true)


func _process(_delta: float) -> void:
	if game_state == null:
		game_state = _find_state()

	if active_panel != null and active_panel.visible and active_panel.has_method("refresh"):
		active_panel.call("refresh", game_state)

	# Keep older draw-code panels shut while scene-authored UI is installed.
	if game_state != null:
		if game_state.get("panel_mode") != null:
			game_state.set("panel_mode", "")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_I:
			_open(inventory_panel)
			get_viewport().set_input_as_handled()
		KEY_C:
			_open(crafting_panel)
			get_viewport().set_input_as_handled()
		KEY_P:
			_open(passive_panel)
			get_viewport().set_input_as_handled()
		KEY_K:
			_open(skill_gems_panel)
			get_viewport().set_input_as_handled()
		KEY_TAB:
			_open(character_panel)
			get_viewport().set_input_as_handled()
		KEY_B:
			_open(stash_panel)
			get_viewport().set_input_as_handled()
		KEY_M:
			_open(activity_panel)
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if active_panel != null:
				_close_all()
				get_viewport().set_input_as_handled()


func _open(panel: Control) -> void:
	if panel == null:
		return
	_close_all()
	active_panel = panel
	panel.visible = true
	if panel.has_method("open_panel"):
		panel.call("open_panel", game_state)
	elif panel.has_method("refresh"):
		panel.call("refresh", game_state)


func _close_all() -> void:
	var panels: Array = [inventory_panel, crafting_panel, passive_panel, skill_gems_panel, character_panel, stash_panel, activity_panel]
	for panel in panels:
		if panel != null:
			panel.visible = false
	active_panel = null


func _find_state() -> Object:
	var n: Node = get_parent()
	while n != null:
		var value: Variant = n.get("state")
		if value != null:
			return value
		n = n.get_parent()
	return null
