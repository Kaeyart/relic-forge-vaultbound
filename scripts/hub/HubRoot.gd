class_name RVHubRoot
extends Node2D

var state: RVGameState
var main: Node
var stations: Array = []
@onready var player_spawn: Marker2D = $PlayerSpawn

func setup(p_state: RVGameState, p_main: Node) -> void:
	state = p_state
	main = p_main
	stations = get_tree().get_nodes_in_group("hub_station")

func get_spawn_position() -> Vector2:
	return player_spawn.global_position

func update_focus(player_pos: Vector2) -> void:
	state.prompt = ""
	var best_distance: float = 999999.0
	var best: RVHubStation = null
	for node in stations:
		if node is RVHubStation:
			var d: float = player_pos.distance_to(node.global_position)
			if d < best_distance:
				best_distance = d
				best = node
	if best != null and best_distance <= 72.0:
		state.prompt = best.prompt_text
		state.current_activity = best.get_payload()
	else:
		state.current_activity = {}

func interact_primary() -> void:
	if state.current_activity.is_empty():
		return
	var station_type: String = str(state.current_activity.get("type", ""))
	if station_type == "activity":
		main.call("start_activity", state.current_activity)
	elif station_type == "passive":
		var name: String = str(state.current_activity.get("name", "Passive"))
		if state.mastery_points <= 0:
			state.add_notice("No Passive Points")
			return
		state.mastery_points -= 1
		state.passives[name] = int(state.passives.get(name, 0)) + 1
		state.recompute_stats()
		state.add_notice(name + " +1")
	elif station_type == "skill":
		var skill: String = str(state.current_activity.get("id", "Fireball"))
		state.skill_ranks[skill] = int(state.skill_ranks.get(skill, 0)) + 1
		state.add_notice(skill + " upgraded")
	elif station_type == "stash":
		for item in state.backpack:
			state.stash.append(item)
		state.backpack.clear()
		state.add_notice("Backpack moved to Stash")
	elif station_type == "forge":
		state.add_notice("Forge station ready")

func interact_secondary() -> void:
	if state.current_activity.is_empty():
		return
	if str(state.current_activity.get("type", "")) == "skill":
		var skill: String = str(state.current_activity.get("id", "Fireball"))
		if state.active_skills.has(skill):
			state.active_skills.erase(skill)
			state.add_notice(skill + " removed from Loadout")
		else:
			if state.active_skills.size() >= 4:
				state.add_notice("Loadout limit: 4")
				return
			state.active_skills.append(skill)
			state.add_notice(skill + " added to Loadout")
		if state.active_skills.size() == 0:
			state.active_skills.append("Fireball")
		state.selected_skill = clamp(state.selected_skill, 0, max(0, state.active_skills.size() - 1))
