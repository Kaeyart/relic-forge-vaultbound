class_name RVBuildcraftSystem
extends RefCounted

static func update(state: RVGameState, delta: float) -> void:
	state.spirit_reserved = compute_spirit_reserved(state)
	recompute_build_stats(state)

static func append_hub_objects(state: RVGameState) -> void:
	state.hub_objects.append({"type": "passive_atlas", "name": "Passive Atlas", "pos": Vector2(330.0, 330.0), "color": Color(0.82, 0.70, 1.0), "data": {}, "prompt": "E open Passive Atlas"})
	state.hub_objects.append({"type": "skill_gems", "name": "Skill Gem Bench", "pos": Vector2(650.0, 500.0), "color": Color(0.50, 0.82, 1.0), "data": {}, "prompt": "E open Skill Gems"})
	state.hub_objects.append({"type": "forgecraft", "name": "Forge", "pos": Vector2(990.0, 325.0), "color": Color(1.0, 0.55, 0.22), "data": {}, "prompt": "E open Crafting"})

static func open_panel(state: RVGameState, panel: String) -> void:
	state.panel_mode = panel
	state.add_notice(panel_title(panel))

static func panel_title(panel: String) -> String:
	match panel:
		"passive_tree": return "Passive Atlas"
		"skill_gems": return "Skill Gems"
		"crafting": return "Crafting"
	return ""

static func handle_key(state: RVGameState, keycode: int) -> bool:
	if state.panel_mode == "":
		if keycode == KEY_P:
			open_panel(state, "passive_tree"); return true
		if keycode == KEY_K:
			open_panel(state, "skill_gems"); return true
		if keycode == KEY_C:
			open_panel(state, "crafting"); return true
		return false

	if keycode == KEY_ESCAPE:
		state.panel_mode = ""; return true

	if state.panel_mode == "passive_tree":
		if keycode == KEY_Q: cycle_passive(state, -1); return true
		if keycode == KEY_E: cycle_passive(state, 1); return true
		if keycode == KEY_ENTER: allocate_passive(state); return true
		if keycode == KEY_BACKSPACE: refund_last_passive(state); return true

	if state.panel_mode == "skill_gems":
		if keycode == KEY_Q: cycle_skill_cursor(state, -1); return true
		if keycode == KEY_E: cycle_skill_cursor(state, 1); return true
		if keycode == KEY_W: cycle_support_cursor(state, -1); return true
		if keycode == KEY_S: cycle_support_cursor(state, 1); return true
		if keycode == KEY_ENTER: socket_support(state); return true
		if keycode == KEY_X or keycode == KEY_BACKSPACE: remove_support(state); return true
		if keycode == KEY_R: toggle_spirit(state); return true

	if state.panel_mode == "crafting":
		if keycode == KEY_F: craft_base(state); return true
		if keycode == KEY_E: add_or_upgrade_affix(state); return true
		if keycode == KEY_X: reroll_affix(state); return true
		if keycode == KEY_R: shatter_item(state); return true
		if keycode == KEY_W: focus_item(state, -1); return true
		if keycode == KEY_S: focus_item(state, 1); return true

	return false

static func toggle_skill_loadout(state: RVGameState, index: int) -> void:
	var skills: Array = RVSkillDB.names()
	if index < 0 or index >= skills.size(): return
	var skill: String = skills[index]
	if state.active_skills.has(skill):
		if state.active_skills.size() <= 1:
			state.add_notice("You need at least one skill")
			return
		state.active_skills.erase(skill)
		state.add_notice(skill + " removed from loadout")
	else:
		if state.active_skills.size() >= 4:
			state.add_notice("Loadout limit: 4 skills")
			return
		state.active_skills.append(skill)
		state.add_notice(skill + " added to loadout")
	state.selected_skill = clamp(state.selected_skill, 0, state.active_skills.size() - 1)

static func passive_nodes() -> Dictionary:
	return RVPassiveAtlasDB.nodes()

static func passive_ids() -> Array:
	return passive_nodes().keys()

static func cycle_passive(state: RVGameState, dir: int) -> void:
	var ids: Array = passive_ids()
	if ids.size() == 0: return
	state.passive_atlas_cursor = posmod(int(state.passive_atlas_cursor) + dir, ids.size())

static func selected_passive_id(state: RVGameState) -> String:
	var ids: Array = passive_ids()
	if ids.size() == 0: return "center"
	state.passive_atlas_cursor = clamp(state.passive_atlas_cursor, 0, ids.size() - 1)
	return str(ids[state.passive_atlas_cursor])

static func allocate_passive(state: RVGameState) -> void:
	var nodes: Dictionary = passive_nodes()
	var id: String = selected_passive_id(state)
	if state.passive_atlas_allocated.has(id): state.add_notice("Node already allocated"); return
	var node: Dictionary = nodes[id]
	var cost: int = int(node.get("cost", 1))
	if state.mastery_points < cost: state.add_notice("Need " + str(cost) + " passive point"); return
	var linked: bool = false
	for link in node.get("links", []):
		if state.passive_atlas_allocated.has(str(link)): linked = true
	if not linked: state.add_notice("Node must connect to your tree"); return
	state.mastery_points -= cost
	state.passive_atlas_allocated.append(id)
	state.passive_atlas_refund_stack.append(id)
	state.add_notice(str(node.get("name", "Passive")) + " allocated")
	recompute_build_stats(state)

static func refund_last_passive(state: RVGameState) -> void:
	if state.passive_atlas_refund_stack.size() == 0: state.add_notice("Nothing to refund"); return
	var id: String = state.passive_atlas_refund_stack.pop_back()
	if id == "center": return
	state.passive_atlas_allocated.erase(id)
	state.mastery_points += int(passive_nodes().get(id, {}).get("cost", 1))
	state.add_notice("Passive refunded")
	recompute_build_stats(state)

static func recompute_build_stats(state: RVGameState) -> void:
	var stats: Dictionary = {}
	var flags: Array = []
	var nodes: Dictionary = passive_nodes()
	for id in state.passive_atlas_allocated:
		var node: Dictionary = nodes.get(str(id), {})
		for k in node.get("stats", {}).keys():
			stats[k] = float(stats.get(k, 0.0)) + float(node["stats"][k])
		for f in node.get("flags", []):
			if not flags.has(f):
				flags.append(f)
	for spirit in state.spirit_gems_enabled.keys():
		if bool(state.spirit_gems_enabled[spirit]):
			var sdata: Dictionary = RVSkillGemDB.spirit_data(str(spirit))
			for k2 in sdata.get("stats", {}).keys():
				stats[k2] = float(stats.get(k2, 0.0)) + float(sdata["stats"][k2])
	state.build_stats = stats
	state.build_flags = flags
	state.recompute_stats()

static func cycle_skill_cursor(state: RVGameState, dir: int) -> void:
	var skills: Array = RVSkillDB.names()
	state.gem_board_skill_cursor = posmod(int(state.gem_board_skill_cursor) + dir, skills.size())

static func cycle_support_cursor(state: RVGameState, dir: int) -> void:
	var supports: Array = RVSkillGemDB.support_names()
	state.gem_board_support_cursor = posmod(int(state.gem_board_support_cursor) + dir, supports.size())

static func selected_gem_skill(state: RVGameState) -> String:
	var skills: Array = RVSkillDB.names()
	return str(skills[clamp(state.gem_board_skill_cursor, 0, skills.size() - 1)])

static func selected_support(state: RVGameState) -> String:
	var supports: Array = RVSkillGemDB.support_names()
	return str(supports[clamp(state.gem_board_support_cursor, 0, supports.size() - 1)])

static func socket_support(state: RVGameState) -> void:
	var skill: String = selected_gem_skill(state)
	var support: String = selected_support(state)
	if not RVSkillGemDB.support_works_with_skill(support, skill): state.add_notice("Support does not match skill tags"); return
	if not state.skill_gem_sockets.has(skill): state.skill_gem_sockets[skill] = []
	var sockets: Array = state.skill_gem_sockets[skill]
	if sockets.size() >= 4: state.add_notice("Support socket limit: 4"); return
	if sockets.has(support): state.add_notice("Support already socketed"); return
	sockets.append(support)
	state.skill_gem_sockets[skill] = sockets
	state.add_notice(support + " linked to " + skill)

static func remove_support(state: RVGameState) -> void:
	var skill: String = selected_gem_skill(state)
	if not state.skill_gem_sockets.has(skill): return
	var sockets: Array = state.skill_gem_sockets[skill]
	if sockets.size() == 0: state.add_notice("No support to remove"); return
	var removed: String = str(sockets.pop_back())
	state.skill_gem_sockets[skill] = sockets
	state.add_notice(removed + " removed")

static func toggle_spirit(state: RVGameState) -> void:
	var names: Array = RVSkillGemDB.spirit_names()
	if names.size() == 0: return
	state.spirit_cursor = posmod(state.spirit_cursor + 1, names.size())
	var spirit: String = str(names[state.spirit_cursor])
	var enabled: bool = bool(state.spirit_gems_enabled.get(spirit, false))
	state.spirit_gems_enabled[spirit] = not enabled
	state.spirit_reserved = compute_spirit_reserved(state)
	if state.spirit_reserved > state.spirit_max:
		state.spirit_gems_enabled[spirit] = false
		state.spirit_reserved = compute_spirit_reserved(state)
		state.add_notice("Not enough spirit")
	else:
		state.add_notice(spirit + (" enabled" if not enabled else " disabled"))
	recompute_build_stats(state)

static func compute_spirit_reserved(state: RVGameState) -> int:
	var total: int = 0
	for spirit in state.spirit_gems_enabled.keys():
		if bool(state.spirit_gems_enabled[spirit]): total += int(RVSkillGemDB.spirit_data(str(spirit)).get("reservation", 0))
	return total

static func craft_base(state: RVGameState) -> void:
	var item: Dictionary = {"name": "Crafted Weapon", "slot": "weapon", "rarity": "Crafted", "stats": {}, "flags": [], "desc": "Blank crafted base.", "forge_potential": 20, "affixes": []}
	state.backpack.append(item)
	state.add_notice("Crafted blank weapon")

static func focused_item(state: RVGameState) -> Dictionary:
	if state.backpack.size() == 0: return {}
	state.forge_focus_index = clamp(state.forge_focus_index, 0, state.backpack.size() - 1)
	var item: Variant = state.backpack[state.forge_focus_index]
	if typeof(item) == TYPE_DICTIONARY: return item
	return {}

static func write_focused_item(state: RVGameState, item: Dictionary) -> void:
	if state.backpack.size() == 0: return
	state.forge_focus_index = clamp(state.forge_focus_index, 0, state.backpack.size() - 1)
	state.backpack[state.forge_focus_index] = item

static func focus_item(state: RVGameState, dir: int) -> void:
	if state.backpack.size() == 0: state.add_notice("Backpack empty"); return
	state.forge_focus_index = posmod(state.forge_focus_index + dir, state.backpack.size())
	state.add_notice(str(focused_item(state).get("name", "Item")))

static func add_or_upgrade_affix(state: RVGameState) -> void:
	var item: Dictionary = focused_item(state)
	if item.is_empty(): state.add_notice("No item to craft"); return
	var potential: int = int(item.get("forge_potential", 0))
	if potential <= 0: state.add_notice("No forge potential"); return
	var affix_keys: Array = RVItemDB.AFFIXES.keys()
	var key: String = str(affix_keys[posmod(state.forge_affix_cursor, affix_keys.size())])
	var stats: Dictionary = item.get("stats", {})
	stats[key] = float(stats.get(key, 0.0)) + RVItemDB.stat_roll(key, max(1, state.level), "Magic")
	item["stats"] = stats
	item["affixes"] = RVItemDB.stats_to_affixes(stats)
	item["forge_potential"] = potential - 2
	write_focused_item(state, item)
	state.add_notice(str(RVItemDB.AFFIXES[key]["name"]) + " crafted")

static func reroll_affix(state: RVGameState) -> void:
	var item: Dictionary = focused_item(state)
	if item.is_empty(): state.add_notice("No item to reroll"); return
	var potential: int = int(item.get("forge_potential", 0))
	if potential <= 0: state.add_notice("No forge potential"); return
	var stats: Dictionary = item.get("stats", {})
	if stats.size() == 0: state.add_notice("Item has no affixes"); return
	var keys: Array = stats.keys()
	var key: String = str(keys[state.rng.randi_range(0, keys.size() - 1)])
	stats[key] = RVItemDB.stat_roll(key, max(1, state.level), str(item.get("rarity", "Magic")))
	item["stats"] = stats
	item["affixes"] = RVItemDB.stats_to_affixes(stats)
	item["forge_potential"] = potential - 3
	write_focused_item(state, item)
	state.add_notice("Affix rerolled")

static func shatter_item(state: RVGameState) -> void:
	if state.backpack.size() == 0: state.add_notice("No item to shatter"); return
	var item: Dictionary = focused_item(state)
	for k in item.get("stats", {}).keys():
		state.crafting_shards[k] = int(state.crafting_shards.get(k, 0)) + 1
	state.backpack.remove_at(state.forge_focus_index)
	state.forge_focus_index = clamp(state.forge_focus_index, 0, max(0, state.backpack.size() - 1))
	state.add_notice("Item shattered into shards")
