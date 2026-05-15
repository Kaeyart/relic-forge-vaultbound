class_name RVDevToolSystem
extends RefCounted

static func heal_and_refill(state: RVGameState) -> void:
	if state == null: return
	state.player_hp = state.max_hp
	state.player_mana = state.max_mana
	state.add_notice("Dev: healed")

static func grant_level(state: RVGameState, amount: int = 1) -> void:
	if state == null: return
	state.level += amount
	state.mastery_points += amount
	state.add_notice("Dev: level +" + str(amount))

static func grant_xp(state: RVGameState, amount: float = 1500.0) -> void:
	if state == null: return
	state.xp += amount
	state.add_notice("Dev: XP +" + str(int(amount)))

static func grant_materials(state: RVGameState, amount: int = 50) -> void:
	if state == null: return
	var materials: Dictionary = state.materials
	for key in ["embers", "shards", "runes", "echo_glass", "socket_prisms", "salvage_parts"]:
		materials[key] = int(materials.get(key, 0)) + amount
	state.materials = materials
	state.add_notice("Dev: materials +" + str(amount))

static func grant_gold(state: RVGameState, amount: int = 25000) -> void:
	if state == null: return
	state.gold += amount
	state.add_notice("Dev: gold +" + str(amount))

static func grant_socket_prisms(state: RVGameState, amount: int = 5) -> void:
	if state == null: return
	state.materials["socket_prisms"] = int(state.materials.get("socket_prisms", 0)) + amount
	state.add_notice("Dev: socket prisms +" + str(amount))

static func grant_test_item(state: RVGameState, rarity: String = "Rare", slot_name: String = "weapon") -> void:
	if state == null: return
	var item: Dictionary = RVItemDB.generate_drop(state, max(1, state.level))
	item["rarity"] = rarity
	item["slot"] = _normalize_slot(slot_name)
	item["name"] = rarity + " Test " + str(item["slot"]).capitalize()
	if rarity == "Unique" or rarity == "Legendary":
		item["rarity"] = "Unique"
		item["name"] = "Dev Unique " + str(item["slot"]).capitalize()
		item["build_flags"] = ["Unique", "Proc", "Conversion"]
		item["unique_effects"] = ["Dev unique: modifies a skill behavior for testing."]
	state.backpack.append(item)
	state.add_notice("Dev: item added")
	RVTelemetryLogger.log_event("DevItemGranted", {"rarity": rarity, "slot": slot_name})

static func grant_item_bundle(state: RVGameState) -> void:
	if state == null: return
	for slot_name in ["weapon", "offhand", "head", "chest", "gloves", "boots", "amulet", "ring", "relic"]:
		grant_test_item(state, "Rare", slot_name)
	grant_test_item(state, "Unique", "relic")
	state.add_notice("Dev: item bundle added")

static func clear_backpack(state: RVGameState) -> void:
	if state == null: return
	state.backpack.clear()
	state.add_notice("Dev: backpack cleared")

static func grant_all_gems(state: RVGameState) -> void:
	if state == null: return
	var active_names: Array = ["Fireball", "Cleave", "Frost Nova", "Storm Lance", "Void Rift", "Blade Trap"]
	for skill_name in active_names:
		state.skill_gem_inventory.append({"id": skill_name.to_snake_case(), "name": skill_name, "skill": skill_name, "level": max(1, state.level), "socket_cap": 2, "supports": [], "tags": [skill_name, "Skill"]})
	for support_name in ["More Damage", "Faster Cast", "Area Increase", "Chain", "Burn", "Cooldown Reduction", "Mana Efficiency"]:
		state.support_gem_inventory.append({"id": support_name.to_snake_case(), "name": support_name, "level": 1, "tags": ["Support"]})
	for spirit_name in ["Flame Aura", "Storm Reserve", "Void Pact"]:
		state.spirit_gem_inventory.append({"id": spirit_name.to_snake_case(), "name": spirit_name, "level": 1, "socket_cap": 2, "supports": [], "reservation": 20, "tags": ["Spirit"]})
	state.add_notice("Dev: gem bundle added")

static func improve_all_socket_caps(state: RVGameState) -> void:
	if state == null: return
	for gem in state.skill_gem_inventory:
		if typeof(gem) == TYPE_DICTIONARY:
			gem["socket_cap"] = min(6, int(gem.get("socket_cap", 2)) + 1)
	for gem in state.spirit_gem_inventory:
		if typeof(gem) == TYPE_DICTIONARY:
			gem["socket_cap"] = min(6, int(gem.get("socket_cap", 2)) + 1)
	state.add_notice("Dev: socket caps improved")

static func reset_gem_setup(state: RVGameState) -> void:
	if state == null: return
	state.skill_gem_inventory.clear()
	state.support_gem_inventory.clear()
	state.spirit_gem_inventory.clear()
	state.active_skills = ["Fireball", "Cleave"]
	grant_all_gems(state)
	state.add_notice("Dev: gems reset")

static func make_dev_activity() -> Dictionary:
	return {"id": "dev_test_room", "name": "Dev Test Room", "type": "dev", "rooms": 1, "threat": 1.0, "reward": "mixed"}

static func make_stress_activity() -> Dictionary:
	return {"id": "dev_stress_room", "name": "Dev Stress Room", "type": "dev", "rooms": 1, "threat": 4.0, "reward": "stress"}

static func _normalize_slot(slot_name: String) -> String:
	var s: String = slot_name.to_lower()
	if s == "ring1" or s == "ring2": return "ring"
	if s == "helmet": return "head"
	return s
