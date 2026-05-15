class_name RVHubSystem
extends RefCounted

static func rebuild_objects(state: RVGameState) -> void:
	state.hub_objects.clear()

	for contract in RVContractDB.all():
		state.hub_objects.append({"type": "contract", "name": str(contract["name"]), "pos": contract["pos"], "color": contract["color"], "data": contract, "prompt": "E start " + str(contract["name"]) + " · " + str(contract["goal"])})

	for recipe in RVItemDB.recipes():
		state.hub_objects.append({"type": "recipe", "name": str(recipe["name"]), "pos": recipe["pos"], "color": recipe["color"], "data": recipe, "prompt": "E craft " + str(recipe["name"])})

	var skill_positions: Dictionary = {"Fireball": Vector2(535.0, 530.0), "Cleave": Vector2(610.0, 560.0), "Frost Nova": Vector2(685.0, 560.0), "Storm Lance": Vector2(760.0, 530.0), "Void Rift": Vector2(575.0, 610.0), "Blade Trap": Vector2(725.0, 610.0)}
	for skill in skill_positions.keys():
		state.hub_objects.append({"type": "skill_toggle", "name": skill, "pos": skill_positions[skill], "color": RVSkillDB.color(skill), "data": skill, "prompt": "E toggle " + skill + " · 1-6 also toggles skills"})

	state.hub_objects.append({"type": "stash", "name": "Stash", "pos": Vector2(640.0, 355.0), "color": Color(0.95, 0.78, 0.34), "data": {}, "prompt": "E deposit backpack · X withdraw first item"})
	state.hub_objects.append({"type": "armory", "name": "Armory", "pos": Vector2(700.0, 355.0), "color": Color(0.86, 0.78, 0.62), "data": {}, "prompt": "E equip first backpack item · X salvage first item"})

static func update_focus(state: RVGameState) -> void:
	state.focus_clear()
	var best_distance: float = 999999.0
	var best: Dictionary = {}
	for obj in state.hub_objects:
		var pos: Vector2 = obj.get("pos", Vector2.ZERO)
		var dist: float = state.player_pos.distance_to(pos)
		if dist < best_distance:
			best_distance = dist
			best = obj
	if best_distance <= 58.0:
		state.focused_object = best
		state.prompt = str(best.get("prompt", ""))

static func interact_primary(state: RVGameState) -> void:
	if state.focused_object.is_empty(): return
	var obj: Dictionary = state.focused_object
	match str(obj.get("type", "")):
		"contract": RVCombatSystem.start_contract(state, obj.get("data", {}))
		"recipe": craft_recipe(state, obj.get("data", {}))
		"skill_toggle": RVBuildcraftSystem.toggle_skill_loadout(state, RVSkillDB.names().find(str(obj.get("data", ""))))
		"stash": deposit_backpack(state)
		"armory": equip_first_backpack_item(state)
		"passive_atlas": RVBuildcraftSystem.open_panel(state, "passive_tree")
		"skill_gems": RVBuildcraftSystem.open_panel(state, "skill_gems")
		"forgecraft": RVBuildcraftSystem.open_panel(state, "crafting")

static func interact_secondary(state: RVGameState) -> void:
	if state.focused_object.is_empty(): return
	var obj: Dictionary = state.focused_object
	match str(obj.get("type", "")):
		"stash": withdraw_first_stash_item(state)
		"armory": salvage_first_backpack_item(state)
		"skill_toggle": RVBuildcraftSystem.toggle_skill_loadout(state, RVSkillDB.names().find(str(obj.get("data", ""))))

static func craft_recipe(state: RVGameState, recipe: Dictionary) -> void:
	var cost: Dictionary = recipe.get("cost", {})
	if not RVItemDB.can_pay(state, cost): state.add_notice("Not enough materials"); return
	RVItemDB.pay(state, cost)
	var item: Dictionary = RVItemDB.craft(state, recipe)
	state.backpack.append(item)
	state.add_notice("Crafted " + str(item.get("name", "item")))

static func deposit_backpack(state: RVGameState) -> void:
	for item in state.backpack:
		state.stash.append(item)
	state.backpack.clear()
	state.add_notice("Backpack deposited")

static func withdraw_first_stash_item(state: RVGameState) -> void:
	if state.stash.size() == 0: state.add_notice("Stash empty"); return
	var item: Dictionary = state.stash[0]
	state.stash.remove_at(0)
	state.backpack.append(item)
	state.add_notice("Withdrew " + str(item.get("name", "item")))

static func equip_first_backpack_item(state: RVGameState) -> void:
	if state.backpack.size() == 0: state.add_notice("Backpack empty"); return
	var item: Dictionary = state.backpack[0]
	state.backpack.remove_at(0)
	var slot: String = str(item.get("slot", "relic"))
	if slot == "ring": slot = "ring1" if state.equipped.get("ring1", {}).is_empty() else "ring2"
	if not state.equipped.has(slot): slot = "relic"
	var old: Variant = state.equipped.get(slot, {})
	state.equipped[slot] = item
	if typeof(old) == TYPE_DICTIONARY and not old.is_empty(): state.backpack.append(old)
	state.recompute_stats()
	state.add_notice("Equipped " + str(item.get("name", "item")))

static func salvage_first_backpack_item(state: RVGameState) -> void:
	if state.backpack.size() == 0: state.add_notice("Backpack empty"); return
	var item: Dictionary = state.backpack[0]
	state.backpack.remove_at(0)
	state.materials["embers"] = int(state.materials.get("embers", 0)) + 3
	state.materials["shards"] = int(state.materials.get("shards", 0)) + 1
	if str(item.get("rarity", "Magic")) == "Legendary": state.materials["runes"] = int(state.materials.get("runes", 0)) + 1
	state.add_notice("Salvaged " + str(item.get("name", "item")))
