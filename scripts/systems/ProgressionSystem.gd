class_name RVProgressionSystem
extends RefCounted

# Patch 043: gem drops are intentionally more visible while the gem system is being tested.

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
	var notice: String = "Room Complete - Item Added"
	# Higher chance until the skill gem loop is proven in real play.
	if state.rng.randf() < 0.78:
		var gem_notice: String = RVSkillGemSystem.award_random_gem_drop(state, max(1, state.room_index))
		notice += " · " + gem_notice
	if state.rng.randf() < 0.16:
		state.materials["socket_prisms"] = int(state.materials.get("socket_prisms", 0)) + 1
		notice += " · Socket Prism"
	state.add_notice(notice)
