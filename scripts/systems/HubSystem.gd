class_name RVHubSystem
extends RefCounted

static func rebuild_objects(state: RVGameState) -> void:
	state.hub_objects.clear()

	for contract in RVContractDB.all():
		state.hub_objects.append({
			"type": "contract",
			"name": str(contract["name"]),
			"pos": contract["pos"],
			"color": contract["color"],
			"data": contract,
			"prompt": "E enter " + str(contract["name"])
		})

	for recipe in RVItemDB.recipes():
		state.hub_objects.append({
			"type": "forge",
			"name": str(recipe["name"]),
			"pos": recipe["pos"],
			"color": recipe["color"],
			"data": recipe,
			"prompt": "E craft " + str(recipe["name"])
		})

	var passive_positions: Dictionary = {
		"ash": Vector2(250.0, 250.0),
		"frost": Vector2(330.0, 210.0),
		"storm": Vector2(410.0, 250.0),
		"void": Vector2(250.0, 365.0),
		"steel": Vector2(410.0, 365.0),
		"trap": Vector2(250.0, 480.0),
		"blood": Vector2(330.0, 520.0),
		"relic": Vector2(410.0, 480.0)
	}

	for branch in passive_positions.keys():
		state.hub_objects.append({
			"type": "passive",
			"name": branch.capitalize() + " Shrine",
			"pos": passive_positions[branch],
			"color": passive_color(branch),
			"data": branch,
			"prompt": "E spend mastery in " + branch.capitalize()
		})

	var skill_positions: Dictionary = {
		"Fireball": Vector2(535.0, 530.0),
		"Cleave": Vector2(610.0, 560.0),
		"Frost Nova": Vector2(685.0, 560.0),
		"Storm Lance": Vector2(760.0, 530.0),
		"Void Rift": Vector2(575.0, 610.0),
		"Blade Trap": Vector2(725.0, 610.0)
	}

	for skill in skill_positions.keys():
		state.hub_objects.append({
			"type": "skill",
			"name": skill + " Altar",
			"pos": skill_positions[skill],
			"color": RVSkillDB.color(skill),
			"data": skill,
			"prompt": "E upgrade " + skill + " · X toggle loadout"
		})

	state.hub_objects.append({"type": "stash", "name": "Stash Chest", "pos": Vector2(640.0, 355.0), "color": Color(0.95, 0.78, 0.34), "data": {}, "prompt": "E deposit backpack · X withdraw first stash item"})
	state.hub_objects.append({"type": "armory", "name": "Armory Rack", "pos": Vector2(700.0, 355.0), "color": Color(0.86, 0.78, 0.62), "data": {}, "prompt": "E equip first backpack item · X salvage first backpack item"})


static func update_focus(state: RVGameState) -> void:
	state.focus_clear()
	var best_distance: float = 999999.0
	var best: Dictionary = {}

	for obj in state.hub_objects:
		var pos: Vector2 = obj["pos"]
		var dist: float = state.player_pos.distance_to(pos)
		if dist < best_distance:
			best_distance = dist
			best = obj

	if best_distance <= 56.0:
		state.focused_object = best
		state.prompt = str(best.get("prompt", ""))


static func interact_primary(state: RVGameState) -> void:
	if state.focused_object.is_empty(): return
	var obj: Dictionary = state.focused_object
	match str(obj["type"]):
		"contract": RVCombatSystem.start_contract(state, obj["data"])
		"forge": craft_recipe(state, obj["data"])
		"passive": spend_passive(state, str(obj["data"]))
		"skill": upgrade_skill(state, str(obj["data"]))
		"stash": deposit_backpack(state)
		"armory": equip_first_backpack_item(state)


static func interact_secondary(state: RVGameState) -> void:
	if state.focused_object.is_empty(): return
	var obj: Dictionary = state.focused_object
	match str(obj["type"]):
		"skill": toggle_loadout(state, str(obj["data"]))
		"stash": withdraw_first_stash_item(state)
		"armory": salvage_first_backpack_item(state)


static func craft_recipe(state: RVGameState, recipe: Dictionary) -> void:
	var cost: Dictionary = recipe.get("cost", {})
	if not RVItemDB.can_pay(state, cost):
		state.add_notice("Not enough materials")
		return
	RVItemDB.pay(state, cost)
	var item: Dictionary = RVItemDB.craft(state, recipe)
	state.backpack.append(item)
	state.add_notice("Crafted " + str(item["name"]))


static func spend_passive(state: RVGameState, branch: String) -> void:
	if state.mastery_points <= 0:
		state.add_notice("No mastery points")
		return
	state.passives[branch] = int(state.passives.get(branch, 0)) + 1
	state.mastery_points -= 1
	state.recompute_stats()
	state.add_notice(branch.capitalize() + " mastery gained")


static func upgrade_skill(state: RVGameState, skill: String) -> void:
	var rank: int = int(state.skill_ranks.get(skill, 0))
	var gold_cost: int = 60 + rank * 45
	var shard_cost: int = 2 + rank
	if state.gold < gold_cost:
		state.add_notice("Need " + str(gold_cost) + " gold")
		return
	if int(state.materials.get("shards", 0)) < shard_cost:
		state.add_notice("Need " + str(shard_cost) + " shards")
		return
	state.gold -= gold_cost
	state.materials["shards"] = int(state.materials.get("shards", 0)) - shard_cost
	state.skill_ranks[skill] = rank + 1
	state.add_notice(skill + " upgraded")


static func toggle_loadout(state: RVGameState, skill: String) -> void:
	if state.active_skills.has(skill):
		state.active_skills.erase(skill)
		state.add_notice(skill + " removed")
	else:
		if state.active_skills.size() >= 4:
			state.add_notice("Loadout limit: 4")
			return
		state.active_skills.append(skill)
		state.add_notice(skill + " added")
	if state.active_skills.size() == 0: state.active_skills.append("Fireball")
	state.selected_skill = clamp(state.selected_skill, 0, state.active_skills.size() - 1)


static func deposit_backpack(state: RVGameState) -> void:
	for item in state.backpack: state.stash.append(item)
	state.backpack.clear()
	state.add_notice("Backpack deposited")


static func withdraw_first_stash_item(state: RVGameState) -> void:
	if state.stash.size() == 0:
		state.add_notice("Stash empty")
		return
	var item: Dictionary = state.stash[0]
	state.stash.remove_at(0)
	state.backpack.append(item)
	state.add_notice("Withdrew " + str(item.get("name", "item")))


static func equip_first_backpack_item(state: RVGameState) -> void:
	if state.backpack.size() == 0:
		state.add_notice("Backpack empty")
		return
	var item: Dictionary = state.backpack[0]
	state.backpack.remove_at(0)
	var slot: String = str(item.get("slot", "relic"))
	if slot == "ring": slot = "ring1" if state.equipped["ring1"].is_empty() else "ring2"
	if not state.equipped.has(slot): slot = "relic"
	var old: Variant = state.equipped[slot]
	state.equipped[slot] = item
	if typeof(old) == TYPE_DICTIONARY and not old.is_empty(): state.backpack.append(old)
	state.recompute_stats()
	state.add_notice("Equipped " + str(item.get("name", "item")))


static func salvage_first_backpack_item(state: RVGameState) -> void:
	if state.backpack.size() == 0:
		state.add_notice("Backpack empty")
		return
	var item: Dictionary = state.backpack[0]
	state.backpack.remove_at(0)
	state.materials["embers"] = int(state.materials.get("embers", 0)) + 3
	state.materials["shards"] = int(state.materials.get("shards", 0)) + 1
	var rarity: String = str(item.get("rarity", "Magic"))
	if rarity == "Rare": state.materials["shards"] = int(state.materials.get("shards", 0)) + 3
	elif rarity == "Legendary" or rarity == "Crafted":
		state.materials["runes"] = int(state.materials.get("runes", 0)) + 1
		state.materials["echo_glass"] = int(state.materials.get("echo_glass", 0)) + 1
	state.add_notice("Salvaged " + str(item.get("name", "item")))


static func passive_color(branch: String) -> Color:
	match branch:
		"ash": return Color(1.0, 0.34, 0.12)
		"frost": return Color(0.42, 0.82, 1.0)
		"storm": return Color(0.72, 0.92, 1.0)
		"void": return Color(0.70, 0.36, 1.0)
		"steel": return Color(0.88, 0.80, 0.62)
		"trap": return Color(0.95, 0.72, 0.30)
		"blood": return Color(1.0, 0.22, 0.18)
		"relic": return Color(0.90, 0.70, 0.36)
	return Color(0.90, 0.84, 0.70)
