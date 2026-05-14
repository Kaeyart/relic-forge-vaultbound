class_name RVProgressionSystem
extends RefCounted

static func add_xp(state: RVGameState, amount: float) -> void:
	state.xp += amount

	while state.xp >= state.xp_to_next():
		state.xp -= state.xp_to_next()
		state.level += 1
		state.mastery_points += 1
		state.add_notice("LEVEL UP · Mastery point gained")

	state.recompute_stats()


static func award_kill(state: RVGameState) -> void:
	state.kills += 1
	add_xp(state, 10.0 + float(state.run_depth) * 2.0)

	state.gold += 2 + state.run_depth
	state.materials["embers"] = int(state.materials.get("embers", 0)) + 1

	if state.rng.randf() < 0.16:
		state.materials["shards"] = int(state.materials.get("shards", 0)) + 1

	if state.rng.randf() < 0.045:
		state.materials["runes"] = int(state.materials.get("runes", 0)) + 1

	if state.rng.randf() < 0.15:
		var item: Dictionary = RVItemDB.generate_drop(state, max(1, state.run_depth))
		state.backpack.append(item)
		state.add_notice("Loot added: " + str(item["name"]))


static func award_room(state: RVGameState) -> void:
	state.rooms_cleared += 1
	add_xp(state, 45.0 + float(state.run_depth) * 7.0)

	state.gold += 12 + state.run_depth * 3
	state.materials["shards"] = int(state.materials.get("shards", 0)) + 3

	if state.run_depth % 3 == 0:
		state.materials["runes"] = int(state.materials.get("runes", 0)) + 1

	if state.run_depth % 5 == 0:
		state.materials["echo_glass"] = int(state.materials.get("echo_glass", 0)) + 1

	var item: Dictionary = RVItemDB.generate_drop(state, max(1, state.run_depth))
	state.backpack.append(item)
	state.add_notice("Room reward: " + str(item["name"]))
