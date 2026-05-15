class_name RVHubRoot
extends Node2D

# Scene-authored hub root.
#
# Hub stations are manually placed as children of Stations, usually with
# RVHubStation attached. This script never creates stations and does not own
# station layout.

@onready var stations_root: Node2D = $Stations

var focused_station: RVHubStation = null

func _ready() -> void:
	refresh_station_visuals()


func refresh_station_visuals() -> void:
	for station: RVHubStation in get_stations():
		station.apply_scene_values()
		station.set_focused(false)


func get_stations() -> Array[RVHubStation]:
	var result: Array[RVHubStation] = []
	_collect_stations(stations_root, result)
	return result


func _collect_stations(node: Node, result: Array[RVHubStation]) -> void:
	for child: Node in node.get_children():
		if child is RVHubStation:
			result.append(child)
		_collect_stations(child, result)


func get_nearest_station(player_pos: Vector2) -> RVHubStation:
	var best: RVHubStation = null
	var best_distance: float = 999999.0

	for station: RVHubStation in get_stations():
		var distance: float = station.distance_to_player(player_pos)
		if distance < best_distance:
			best_distance = distance
			best = station

	if best != null and best_distance <= best.interaction_radius:
		return best

	return null


func update_focus(state: RVGameState) -> void:
	var station: RVHubStation = get_nearest_station(state.player_pos)

	if focused_station != null and focused_station != station:
		focused_station.set_focused(false)

	focused_station = station
	state.clear_prompt()

	if focused_station == null:
		return

	focused_station.set_focused(true)
	state.focused_hub_station_id = focused_station.station_id
	state.focused_hub_station_name = focused_station.display_name
	state.prompt_text = focused_station.get_prompt()


func interact_primary(state: RVGameState) -> Dictionary:
	var station: RVHubStation = get_nearest_station(state.player_pos)
	if station == null:
		return {}

	match station.station_type:
		"activity":
			return RVContractDB.by_id(station.activity_id)
		"inventory":
			state.toggle_panel("inventory")
		"crafting":
			state.toggle_panel("crafting")
		"passive":
			state.toggle_panel("passive_atlas")
		"skills":
			state.toggle_panel("skill_gems")
		"stash":
			state.toggle_panel("stash")
		"character":
			state.toggle_panel("character")
		"training":
			state.add_notice("Training dummy not wired yet")
		_:
			state.add_notice("Station not wired yet")

	return {}


func interact_secondary(state: RVGameState) -> void:
	var station: RVHubStation = get_nearest_station(state.player_pos)
	if station == null:
		return

	match station.station_type:
		"inventory":
			state.toggle_panel("character")
		"crafting":
			state.add_notice("Secondary crafting action not wired yet")
		"stash":
			state.toggle_panel("inventory")
		"skills":
			state.toggle_panel("passive_atlas")
		"passive":
			state.toggle_panel("skill_gems")
		_:
			state.add_notice(station.display_name)
