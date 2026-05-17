class_name RVLootDropSystem
extends RefCounted

static func enemy_drop_payloads(state: RVGameState, enemy: Node, activity: Dictionary) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if state != null:
		rng = state.rng

	var is_boss: bool = false
	var is_elite_enemy: bool = false
	if enemy != null:
		is_boss = bool(enemy.get("is_map_boss"))
		is_elite_enemy = bool(enemy.get("is_elite"))

	var kind: String = str(activity.get("kind", ""))
	var level_fallback: int = 1
	if state != null:
		level_fallback = max(1, int(state.level))
	var map_data: Dictionary = Dictionary(activity.get("map", {}))
	var depth: int = max(1, int(map_data.get("map_level", level_fallback)))
	var reward_bonus: float = max(0.25, float(map_data.get("reward_bonus", 1.0)))

	if is_boss:
		var boss_item_count: int = 3 + int(map_data.get("boss_bonus_drops", 0))
		for i: int in range(boss_item_count):
			drops.append(_make_item_drop(state, depth, rng))
		drops.append(_make_gold_drop(rng.randi_range(25, 65)))
		drops.append(_make_material_drop(rng, depth, true))
		if kind == "map" and rng.randf() < 0.55 * reward_bonus:
			drops.append(_make_map_drop(state, rng, depth))
		if rng.randf() < 0.25 * reward_bonus:
			drops.append(_make_gem_drop(state, rng, depth))
		return _valid_drops(drops)

	if is_elite_enemy:
		drops.append(_make_gold_drop(rng.randi_range(8, 22)))
		if rng.randf() < 0.65 * reward_bonus:
			drops.append(_make_item_drop(state, depth, rng))
		if rng.randf() < 0.32 * reward_bonus:
			drops.append(_make_material_drop(rng, depth, false))
		if kind == "map" and rng.randf() < 0.10 * reward_bonus:
			drops.append(_make_map_drop(state, rng, depth))
		return _valid_drops(drops)

	if rng.randf() < 0.18:
		drops.append(_make_gold_drop(rng.randi_range(2, 9)))
	if rng.randf() < 0.12 * reward_bonus:
		drops.append(_make_material_drop(rng, depth, false))
	if rng.randf() < 0.085 * reward_bonus:
		drops.append(_make_item_drop(state, depth, rng))
	if kind == "map" and rng.randf() < 0.025 * reward_bonus:
		drops.append(_make_map_drop(state, rng, depth))
	return _valid_drops(drops)

static func pickup_payload(state: RVGameState, payload: Dictionary) -> String:
	if state == null:
		return ""
	var kind: String = str(payload.get("kind", "item"))
	match kind:
		"gold":
			var amount: int = int(payload.get("amount", 0))
			state.gold += amount
			return "+" + str(amount) + " Gold"
		"material":
			var mat: String = str(payload.get("material", "shards"))
			var count: int = int(payload.get("amount", 1))
			if not state.materials.has(mat):
				state.materials[mat] = 0
			state.materials[mat] = int(state.materials[mat]) + count
			return "+" + str(count) + " " + str(payload.get("name", mat))
		"map":
			var map_pickup: Dictionary = Dictionary(payload.get("map", payload))
			# Current map system uses map_stash on GameState. If a future save lacks it, fall back to backpack.
			if state.get("map_stash") != null:
				state.map_stash.append(map_pickup)
			else:
				state.backpack.append(map_pickup)
			return "Picked up " + str(map_pickup.get("name", "Map"))
		"gem":
			var gem: Dictionary = Dictionary(payload.get("gem", payload))
			var gem_type: String = str(gem.get("type", "support"))
			if gem_type == "active" or gem_type == "uncut_skill":
				state.skill_gem_inventory.append(gem)
			elif gem_type == "spirit" or gem_type == "uncut_spirit":
				state.spirit_gem_inventory.append(gem)
			else:
				state.support_gem_inventory.append(gem)
			return "Picked up " + str(gem.get("name", "Gem"))
		_:
			var item: Dictionary = Dictionary(payload.get("item", payload))
			state.backpack.append(item)
			return "Picked up " + str(item.get("name", "Item"))

static func _make_item_drop(state: RVGameState, depth: int, _rng: RandomNumberGenerator) -> Dictionary:
	var item: Dictionary = RVItemDB.generate_drop(state, depth)
	item = RVItemDB.normalize_item(item)
	return {
		"kind": "item",
		"item": item,
		"rarity": str(item.get("rarity", "Normal")),
		"name": str(item.get("name", "Item"))
	}

static func _make_gold_drop(amount: int) -> Dictionary:
	return {"kind": "gold", "rarity": "gold", "amount": amount, "name": str(amount) + " Gold"}

static func _make_material_drop(rng: RandomNumberGenerator, _depth: int, boss: bool) -> Dictionary:
	var names: Array[String] = ["shards", "embers", "runes", "echo_glass"]
	var mat: String = names[rng.randi_range(0, names.size() - 1)]
	var count: int = rng.randi_range(2, 5) if boss else rng.randi_range(1, 2)
	return {"kind": "material", "rarity": "material", "material": mat, "amount": count, "name": mat.capitalize()}

static func _make_map_drop(state: RVGameState, rng: RandomNumberGenerator, depth: int) -> Dictionary:
	var map_data: Dictionary = RVMapDB.make_map(rng, depth)
	return {"kind": "map", "rarity": "map", "map": map_data, "name": str(map_data.get("name", "Map"))}

static func _make_gem_drop(state: RVGameState, rng: RandomNumberGenerator, depth: int) -> Dictionary:
	var level: int = max(1, min(20, int(depth / 2) + 1))
	var gem: Dictionary = {}
	var roll: float = rng.randf()
	if roll < 0.34:
		gem = RVSkillGemSystem._make_uncut_skill_drop(state, level)
	elif roll < 0.72:
		gem = RVSkillGemSystem._make_uncut_support_drop(state, level)
	else:
		gem = RVSkillGemSystem._make_uncut_spirit_drop(state, level)
	return {"kind": "gem", "rarity": "gem", "gem": gem, "name": str(gem.get("name", "Gem"))}

static func _valid_drops(drops: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for drop: Dictionary in drops:
		if not drop.is_empty():
			result.append(drop)
	return result
