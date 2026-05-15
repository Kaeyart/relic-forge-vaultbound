class_name RVHubRoot
extends Node2D

@onready var stations_root: Node2D = $Stations

func get_nearest_station(player_pos: Vector2) -> RVHubStation:
	var best: RVHubStation = null
	var best_distance: float = 999999.0

	for child: Node in stations_root.get_children():
		if child is RVHubStation:
			var station: RVHubStation = child
			var distance: float = player_pos.distance_to(station.global_position)
			if distance < best_distance:
				best_distance = distance
				best = station

	if best != null and best_distance <= best.radius:
		return best

	return null


func update_focus(state: RVGameState) -> void:
	var station: RVHubStation = get_nearest_station(state.player_pos)
	state.clear_prompt()

	if station == null:
		return

	state.focused_hub_station_id = station.station_id
	state.focused_hub_station_name = station.display_name
	state.prompt_text = station.prompt_text


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

	return {}
