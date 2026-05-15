class_name RVProgressionSystem
extends RefCounted

static func award_kill(state: RVGameState) -> void:
	state.kills += 1
	state.gold += 2 + state.room_index
	state.materials["embers"] = int(state.materials.get("embers", 0)) + 1
	state.add_xp(12.0 + float(state.room_index) * 2.0)


static func award_room(state: RVGameState) -> void:
	state.rooms_cleared += 1
	state.gold += 15 + state.room_index * 3
	state.materials["shards"] = int(state.materials.get("shards", 0)) + 2
	state.add_xp(55.0 + float(state.room_index) * 8.0)

	var drop: Dictionary = RVItemDB.generate_drop(state, max(1, state.room_index))
	state.backpack.append(drop)
	state.add_notice("Room Complete - Item Added")
