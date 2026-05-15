class_name RVForgecraftSystem
extends RefCounted

# Patch 037-041: deterministic-leaning forgecraft MVP.
# Items are projects: finite forge potential, visible prefixes/suffixes, shard-driven edits.

const COST_ADD_AFFIX: int = 4
const COST_UPGRADE: int = 3
const COST_REROLL: int = 5
const COST_REMOVE: int = 6
const COST_SEAL: int = 8

static func selected_crafting_item(state: RVGameState) -> Dictionary:
	if state.backpack.is_empty():
		return {}
	state.inventory_cursor = clamp(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
	return RVItemDB.normalize_item(state.backpack[int(state.inventory_cursor)])

static func add_prefix(state: RVGameState) -> bool:
	return _add_affix(state, "prefix")

static func add_suffix(state: RVGameState) -> bool:
	return _add_affix(state, "suffix")

static func upgrade_affix(state: RVGameState) -> bool:
	var pack: Dictionary = _get_selected_mutable_item(state)
	if pack.is_empty():
		return false
	var item: Dictionary = pack["item"]
	if not _spend_potential(state, item, COST_UPGRADE):
		return false
	var item_level: int = int(item.get("item_level", 1))
	for group_name: String in ["prefixes", "suffixes"]:
		var group: Array = Array(item.get(group_name, []))
		for i: int in range(group.size()):
			if typeof(group[i]) != TYPE_DICTIONARY:
				continue
			var affix: Dictionary = Dictionary(group[i])
			if bool(affix.get("sealed", false)):
				continue
			var def: Dictionary = RVItemAffixDB.affix_def_by_id(str(affix.get("id", "")))
			if def.is_empty():
				continue
			var max_tier: int = RVItemAffixDB.max_tier_for_affix(def, item_level)
			if int(affix.get("tier", 1)) >= max_tier:
				continue
			group[i] = RVItemAffixDB.next_tier_affix(affix, state.rng, item_level)
			item[group_name] = group
			_commit_item(state, int(pack["index"]), item, "Upgraded " + str(affix.get("name", "affix")))
			return true
	state.add_notice("No upgradeable affix")
	return false

static func reroll_affix(state: RVGameState) -> bool:
	var pack: Dictionary = _get_selected_mutable_item(state)
	if pack.is_empty():
		return false
	var item: Dictionary = pack["item"]
	if not _spend_potential(state, item, COST_REROLL):
		return false
	var base: Dictionary = RVItemBaseDB.get_base(str(item.get("base_id", "")))
	var item_level: int = int(item.get("item_level", 1))
	for group_name: String in ["suffixes", "prefixes"]:
		var group: Array = Array(item.get(group_name, []))
		for i: int in range(group.size()):
			if typeof(group[i]) != TYPE_DICTIONARY:
				continue
			var old_affix: Dictionary = Dictionary(group[i])
			if bool(old_affix.get("sealed", false)):
				continue
			var blocked: Array[String] = _families_except(item, group_name, i)
			var replacement: Dictionary = RVItemAffixDB.roll_affix(state.rng, str(old_affix.get("type", "suffix")), base, item_level, blocked, Array(item.get("tags", [])))
			if replacement.is_empty():
				continue
			group[i] = replacement
			item[group_name] = group
			_commit_item(state, int(pack["index"]), item, "Rerolled affix")
			return true
	state.add_notice("No rerollable affix")
	return false

static func remove_affix(state: RVGameState) -> bool:
	var pack: Dictionary = _get_selected_mutable_item(state)
	if pack.is_empty():
		return false
	var item: Dictionary = pack["item"]
	if not _spend_potential(state, item, COST_REMOVE):
		return false
	for group_name: String in ["suffixes", "prefixes"]:
		var group: Array = Array(item.get(group_name, []))
		for i: int in range(group.size()):
			if typeof(group[i]) == TYPE_DICTIONARY and not bool(Dictionary(group[i]).get("sealed", false)):
				var affix_name: String = str(Dictionary(group[i]).get("name", "affix"))
				group.remove_at(i)
				item[group_name] = group
				_commit_item(state, int(pack["index"]), item, "Removed " + affix_name)
				return true
	state.add_notice("No removable affix")
	return false

static func seal_affix(state: RVGameState) -> bool:
	var pack: Dictionary = _get_selected_mutable_item(state)
	if pack.is_empty():
		return false
	var item: Dictionary = pack["item"]
	if not _spend_potential(state, item, COST_SEAL):
		return false
	for group_name: String in ["prefixes", "suffixes"]:
		var group: Array = Array(item.get(group_name, []))
		for i: int in range(group.size()):
			if typeof(group[i]) == TYPE_DICTIONARY and not bool(Dictionary(group[i]).get("sealed", false)):
				var affix: Dictionary = Dictionary(group[i])
				affix["sealed"] = true
				group[i] = affix
				item[group_name] = group
				_commit_item(state, int(pack["index"]), item, "Sealed " + str(affix.get("name", "affix")))
				return true
	state.add_notice("No sealable affix")
	return false

static func shatter_selected_item(state: RVGameState) -> bool:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return false
	state.inventory_cursor = clamp(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
	var item: Dictionary = RVItemDB.normalize_item(state.backpack[int(state.inventory_cursor)])
	var rewards: Dictionary = RVInventorySystem.salvage_rewards(item)
	for key_value: Variant in rewards.keys():
		var key: String = str(key_value)
		state.materials[key] = int(state.materials.get(key, 0)) + int(rewards[key_value])
	for affix_value: Variant in Array(item.get("prefixes", [])) + Array(item.get("suffixes", [])):
		if typeof(affix_value) == TYPE_DICTIONARY:
			var affix: Dictionary = Dictionary(affix_value)
			for tag_value: Variant in affix.get("tags", []):
				var shard_key: String = _tag_to_shard(str(tag_value))
				if shard_key != "":
					state.materials[shard_key] = int(state.materials.get(shard_key, 0)) + max(1, int(affix.get("tier", 1)))
	state.backpack.remove_at(int(state.inventory_cursor))
	state.inventory_cursor = clamp(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
	state.add_notice("Shattered " + str(item.get("name", "item")))
	return true

static func _add_affix(state: RVGameState, affix_type: String) -> bool:
	var pack: Dictionary = _get_selected_mutable_item(state)
	if pack.is_empty():
		return false
	var item: Dictionary = pack["item"]
	var group_name: String = "prefixes" if affix_type == "prefix" else "suffixes"
	var group: Array = Array(item.get(group_name, []))
	if group.size() >= 3:
		state.add_notice("No open " + affix_type + " slot")
		return false
	if not _spend_potential(state, item, COST_ADD_AFFIX):
		return false
	var base: Dictionary = RVItemBaseDB.get_base(str(item.get("base_id", "")))
	var blocked: Array[String] = _families_except(item, "", -1)
	var affix: Dictionary = RVItemAffixDB.roll_affix(state.rng, affix_type, base, int(item.get("item_level", 1)), blocked, Array(item.get("tags", [])))
	if affix.is_empty():
		state.add_notice("No legal affix")
		return false
	group.append(affix)
	item[group_name] = group
	if str(item.get("rarity", "Normal")) == "Normal":
		item["rarity"] = "Magic"
	elif str(item.get("rarity", "Normal")) == "Magic" and Array(item.get("prefixes", [])).size() + Array(item.get("suffixes", [])).size() >= 3:
		item["rarity"] = "Rare"
	_commit_item(state, int(pack["index"]), item, "Added " + str(affix.get("name", "affix")))
	return true

static func _get_selected_mutable_item(state: RVGameState) -> Dictionary:
	if state.backpack.is_empty():
		state.add_notice("Backpack is empty")
		return {}
	state.inventory_cursor = clamp(int(state.inventory_cursor), 0, max(0, state.backpack.size() - 1))
	var item: Dictionary = RVItemDB.normalize_item(state.backpack[int(state.inventory_cursor)])
	if str(item.get("rarity", "Normal")) == "Unique":
		state.add_notice("Uniques cannot be forged yet")
		return {}
	return {"item": item, "index": int(state.inventory_cursor)}

static func _spend_potential(state: RVGameState, item: Dictionary, cost: int) -> bool:
	var fp: int = int(item.get("forge_potential", 0))
	if fp < cost:
		state.add_notice("Not enough forge potential")
		return false
	item["forge_potential"] = fp - cost
	return true

static func _commit_item(state: RVGameState, index: int, item: Dictionary, notice: String) -> void:
	state.backpack[index] = RVItemDB.rebuild_item(item)
	state.recompute_stats()
	state.add_notice(notice)

static func _families_except(item: Dictionary, group_name: String, skip_index: int) -> Array[String]:
	var out: Array[String] = []
	for name: String in ["prefixes", "suffixes"]:
		var group: Array = Array(item.get(name, []))
		for i: int in range(group.size()):
			if name == group_name and i == skip_index:
				continue
			if typeof(group[i]) == TYPE_DICTIONARY:
				var family: String = str(Dictionary(group[i]).get("family", ""))
				if family != "" and not out.has(family):
					out.append(family)
	return out

static func _tag_to_shard(tag: String) -> String:
	match tag:
		"Fire", "Burn": return "fire_shards"
		"Cold", "Freeze": return "cold_shards"
		"Lightning", "Shock", "Chain": return "lightning_shards"
		"Void", "Curse": return "void_shards"
		"Melee", "Physical", "Bleed": return "melee_shards"
		"Trap": return "trap_shards"
		"Life", "Defense", "Armor", "Resistance", "Ward": return "defense_shards"
		"Mana", "Spirit", "Resource", "Cooldown", "Utility": return "utility_shards"
	return ""
