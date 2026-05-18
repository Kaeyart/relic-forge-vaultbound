class_name RVUIPanelRoot
extends CanvasLayer

@onready var inventory_panel: Control = %InventoryPanel
@onready var crafting_panel: Control = %CraftingPanel
@onready var passive_panel: Control = %PassiveAtlasPanel
@onready var skill_gems_panel: Control = %SkillGemsPanel
@onready var character_panel: Control = %CharacterPanel
@onready var stash_panel: Control = %StashPanel
@onready var activity_panel: Control = %ActivityPanel

var map_device_panel: Control = null
var loot_filter_panel: Control = null

func _ready() -> void:
	_ensure_map_device_panel()
	_ensure_loot_filter_panel()

func update_from_state(state: RVGameState) -> void:
	_ensure_map_device_panel()
	_ensure_loot_filter_panel()
	_set_visible("inventory", inventory_panel, state)
	_set_visible("crafting", crafting_panel, state)
	_set_visible("passive_atlas", passive_panel, state)
	_set_visible("skill_gems", skill_gems_panel, state)
	_set_visible("character", character_panel, state)
	_set_visible("stash", stash_panel, state)
	_set_visible("activities", activity_panel, state)
	_set_visible("map_device", map_device_panel, state)
	_set_visible("loot_filter", loot_filter_panel, state)
	for panel: Control in [inventory_panel, crafting_panel, passive_panel, skill_gems_panel, character_panel, stash_panel, activity_panel, map_device_panel, loot_filter_panel]:
		if panel != null and panel.visible and panel.has_method("update_from_state"):
			panel.call("update_from_state", state)

func _set_visible(mode_name: String, panel: Control, state: RVGameState) -> void:
	if panel == null:
		return
	panel.visible = state.panel_mode == mode_name

func _ensure_map_device_panel() -> void:
	if map_device_panel != null:
		return
	var existing: Node = get_node_or_null("%MapDevicePanel")
	if existing is Control:
		map_device_panel = existing as Control
		return
	var scene_path: String = "res://scenes/ui/panels/MapDevicePanel.tscn"
	if not ResourceLoader.exists(scene_path):
		return
	var packed: PackedScene = load(scene_path)
	map_device_panel = packed.instantiate() as Control
	map_device_panel.name = "MapDevicePanel"
	map_device_panel.visible = false
	var root_node: Node = get_node_or_null("Root")
	if root_node != null:
		root_node.add_child(map_device_panel)
	else:
		add_child(map_device_panel)


func _ensure_loot_filter_panel() -> void:
	if loot_filter_panel != null and is_instance_valid(loot_filter_panel):
		return
	var existing: Node = get_node_or_null("%LootFilterPanel")
	if existing is Control:
		loot_filter_panel = existing as Control
		return
	var scene_path: String = "res://scenes/ui/panels/LootFilterPanel.tscn"
	if not ResourceLoader.exists(scene_path):
		return
	var packed: PackedScene = load(scene_path)
	loot_filter_panel = packed.instantiate() as Control
	loot_filter_panel.name = "LootFilterPanel"
	loot_filter_panel.visible = false
	var root_node: Node = get_node_or_null("Root")
	if root_node != null:
		root_node.add_child(loot_filter_panel)
	else:
		add_child(loot_filter_panel)
