class_name RVUIPanelRoot
extends CanvasLayer

@onready var inventory_panel: Control = %InventoryPanel
@onready var crafting_panel: Control = %CraftingPanel
@onready var passive_panel: Control = %PassiveAtlasPanel
@onready var skill_gems_panel: Control = %SkillGemsPanel
@onready var character_panel: Control = %CharacterPanel
@onready var stash_panel: Control = %StashPanel
@onready var activity_panel: Control = %ActivityPanel @onready var map_device_panel: Control = %MapDevicePanel

func update_from_state(state: RVGameState) -> void:
	_set_visible("inventory", inventory_panel, state)
	_set_visible("crafting", crafting_panel, state)
	_set_visible("passive_atlas", passive_panel, state)
	_set_visible("skill_gems", skill_gems_panel, state)
	_set_visible("character", character_panel, state)
	_set_visible("stash", stash_panel, state)
	_set_visible("activities", activity_panel, state) _set_visible("map_device", map_device_panel, state)

	for panel: Control in [inventory_panel, crafting_panel, passive_panel, skill_gems_panel, character_panel, stash_panel, activity_panel, map_device_panel]:
		if panel != null and panel.visible and panel.has_method("update_from_state"):
			panel.call("update_from_state", state)


func _set_visible(mode_name: String, panel: Control, state: RVGameState) -> void:
	if panel == null:
		return
	panel.visible = state.panel_mode == mode_name
