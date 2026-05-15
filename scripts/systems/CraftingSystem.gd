class_name RVCraftingSystem
extends RefCounted

static func focused_item(state: RVGameState) -> Dictionary:
	if state.backpack.size() == 0:
		return {}
	state.craft_focus_index = clamp(state.craft_focus_index, 0, state.backpack.size() - 1)
	var item: Variant = state.backpack[state.craft_focus_index]
	if typeof(item) != TYPE_DICTIONARY:
		return {}
	item = RVItemDB.normalize_item(item)
	state.backpack[state.craft_focus_index] = item
	return item

static func focus_next(state: RVGameState, dir: int) -> void:
	if state.backpack.size() == 0:
		state.craft_focus_index = 0
		return
	state.craft_focus_index = posmod(state.craft_focus_index + dir, state.backpack.size())
	var item: Dictionary = focused_item(state)
	if not item.is_empty():
		state.add_notice("Focused " + str(item.get("name", "item")))

static func craft_base(state: RVGameState) -> void:
	var item: Dictionary = RVItemDB.make_base_item(state, "weapon")
	item["name"] = "Blank Forge Base"
	state.backpack.append(item)
	state.craft_focus_index = state.backpack.size() - 1
	state.add_notice("Created blank craft base")

static func add_or_upgrade_affix(state: RVGameState) -> void:
	var item: Dictionary = focused_item(state)
	if item.is_empty():
		craft_base(state)
		return
	if int(item.get("forge_integrity", 0)) <= 0:
		state.add_notice("Item has no forge integrity")
		return
	var affixes: Array = item.get("affixes", [])
	if affixes.size() < 4:
		_add_affix(state, item)
	else:
		_upgrade_lowest_affix(state, item)
	RVItemDB.normalize_item(item)
	state.backpack[state.craft_focus_index] = item
	state.recompute_stats()

static func _add_affix(state: RVGameState, item: Dictionary) -> void:
	var shard_bag: Dictionary = state.craft_bag.get("affix_shards", {})
	var candidates: Array = []
	for id in shard_bag.keys():
		if int(shard_bag[id]) > 0 and not _item_has_affix(item, str(id)):
			candidates.append(str(id))
	if candidates.size() == 0:
		state.add_notice("No usable affix shards")
		return
	var affix_id: String = candidates[state.rng.randi_range(0, candidates.size() - 1)]
	shard_bag[affix_id] = int(shard_bag[affix_id]) - 1
	state.craft_bag["affix_shards"] = shard_bag
	item["affixes"].append(RVItemDB.make_affix(state, affix_id, 1))
	_consume_integrity(state, item, 1, 7)
	state.add_notice("Added affix: " + str(RVItemDB.affix_data(affix_id).get("name", affix_id)))

static func _upgrade_lowest_affix(state: RVGameState, item: Dictionary) -> void:
	var affixes: Array = item.get("affixes", [])
	if affixes.size() == 0:
		_add_affix(state, item)
		return
	var best_index: int = -1
	var best_tier: int = 999
	for i in range(affixes.size()):
		var affix: Dictionary = affixes[i]
		var tier: int = int(affix.get("tier", 1))
		if tier < best_tier and tier < 5:
			best_tier = tier
			best_index = i
	if best_index == -1:
		state.add_notice("All affixes at max craft tier")
		return
	var target: Dictionary = affixes[best_index]
	var affix_id: String = str(target.get("id", ""))
	var shard_bag: Dictionary = state.craft_bag.get("affix_shards", {})
	var cost: int = 1 + int(target.get("tier", 1))
	if int(shard_bag.get(affix_id, 0)) < cost:
		state.add_notice("Need " + str(cost) + " shards")
		return
	shard_bag[affix_id] = int(shard_bag[affix_id]) - cost
	state.craft_bag["affix_shards"] = shard_bag
	target["tier"] = int(target.get("tier", 1)) + 1
	var data: Dictionary = RVItemDB.affix_data(affix_id)
	target["value"] = float(data.get("base", 0.01)) * float(target["tier"])
	affixes[best_index] = target
	item["affixes"] = affixes
	_consume_integrity(state, item, 2, 10)
	state.add_notice("Upgraded " + str(target.get("name", affix_id)) + " to T" + str(target["tier"]))

static func chaos_reroll_affix(state: RVGameState) -> void:
	var item: Dictionary = focused_item(state)
	if item.is_empty():
		return
	if int(state.craft_bag.get("chaos_sigils", 0)) <= 0:
		state.add_notice("No chaos sigils")
		return
	var affixes: Array = item.get("affixes", [])
	if affixes.size() == 0:
		state.add_notice("No affix to reroll")
		return
	var index: int = state.rng.randi_range(0, affixes.size() - 1)
	var old: Dictionary = affixes[index]
	var ids: Array = RVItemDB.affix_ids()
	var new_id: String = ids[state.rng.randi_range(0, ids.size() - 1)]
	var tier: int = int(old.get("tier", 1))
	affixes[index] = RVItemDB.make_affix(state, new_id, tier)
	item["affixes"] = affixes
	state.craft_bag["chaos_sigils"] = int(state.craft_bag.get("chaos_sigils", 0)) - 1
	_consume_integrity(state, item, 3, 11)
	RVItemDB.normalize_item(item)
	state.backpack[state.craft_focus_index] = item
	state.add_notice("Chaos rerolled affix")

static func seal_affix(state: RVGameState) -> void:
	var item: Dictionary = focused_item(state)
	if item.is_empty():
		return
	if int(state.craft_bag.get("seal_sigils", 0)) <= 0:
		state.add_notice("No seal sigils")
		return
	if not item.get("sealed_affix", {}).is_empty():
		state.add_notice("Item already has sealed affix")
		return
	var affixes: Array = item.get("affixes", [])
	if affixes.size() == 0:
		state.add_notice("No affix to seal")
		return
	var index: int = state.rng.randi_range(0, affixes.size() - 1)
	item["sealed_affix"] = affixes[index]
	affixes.remove_at(index)
	item["affixes"] = affixes
	state.craft_bag["seal_sigils"] = int(state.craft_bag.get("seal_sigils", 0)) - 1
	_consume_integrity(state, item, 4, 14)
	RVItemDB.normalize_item(item)
	state.backpack[state.craft_focus_index] = item
	state.add_notice("Sealed an affix")

static func shatter_focused_item(state: RVGameState) -> void:
	if state.backpack.size() == 0:
		state.add_notice("Backpack empty")
		return
	if int(state.craft_bag.get("shatter_runes", 0)) <= 0:
		state.add_notice("No shatter runes")
		return
	var item: Dictionary = focused_item(state)
	if item.is_empty():
		return
	var shards: Dictionary = state.craft_bag.get("affix_shards", {})
	for affix in item.get("affixes", []):
		if typeof(affix) != TYPE_DICTIONARY:
			continue
		var id: String = str(affix.get("id", ""))
		var tier: int = int(affix.get("tier", 1))
		if id != "":
			shards[id] = int(shards.get(id, 0)) + max(1, tier)
	var sealed: Dictionary = item.get("sealed_affix", {})
	if not sealed.is_empty():
		var sid: String = str(sealed.get("id", ""))
		if sid != "":
			shards[sid] = int(shards.get(sid, 0)) + int(sealed.get("tier", 1))
	state.craft_bag["affix_shards"] = shards
	state.craft_bag["shatter_runes"] = int(state.craft_bag.get("shatter_runes", 0)) - 1
	state.backpack.remove_at(state.craft_focus_index)
	state.craft_focus_index = clamp(state.craft_focus_index, 0, max(0, state.backpack.size() - 1))
	state.add_notice("Item shattered into shards")

static func _consume_integrity(state: RVGameState, item: Dictionary, min_cost: int, max_cost: int) -> void:
	var preserve: bool = false
	if int(state.craft_bag.get("hope_sigils", 0)) > 0:
		state.craft_bag["hope_sigils"] = int(state.craft_bag.get("hope_sigils", 0)) - 1
		preserve = state.rng.randf() < 0.25
	if preserve:
		state.add_notice("Hope preserved forge integrity")
		return
	var cost: int = state.rng.randi_range(min_cost, max_cost)
	item["forge_integrity"] = max(0, int(item.get("forge_integrity", 0)) - cost)

static func _item_has_affix(item: Dictionary, affix_id: String) -> bool:
	for affix in item.get("affixes", []):
		if typeof(affix) == TYPE_DICTIONARY and str(affix.get("id", "")) == affix_id:
			return true
	return false
