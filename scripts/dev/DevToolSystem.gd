class_name RVDevToolSystem
extends RefCounted

# Developer / creative-mode helpers. Patch 043 gem bundle grants uncut gems.

const ACTIVE_GEM_IDS: Array[String] = ["fireball", "cleave", "frost_nova", "storm_lance", "void_rift", "blade_trap"]
const SUPPORT_GEM_IDS: Array[String] = ["controlled_power", "swift_cast", "area_expansion", "chain", "burning", "frostbite", "overcharge", "void_echo", "trap_mechanism", "bloodletting", "critical_focus", "mana_efficiency", "multi_projectile"]
const SPIRIT_GEM_IDS: Array[String] = ["clarity", "vitality", "emberskin", "storm_focus", "void_whisper", "war_banner"]

static func heal_and_refill(state: RVGameState) -> void:
	if state == null:
		return
	state.full_restore()
	state.add_notice("Dev: restored life and mana")

static func grant_level(state: RVGameState, amount: int = 1) -> void:
	if state == null:
		return
	for i in range(max(1, amount)):
		state.level += 1
		state.mastery_points += 1
		state.refund_points += 1
	state.recompute_stats()
	state.full_restore()
	state.add_notice("Dev: +" + str(max(1, amount)) + " level")

static func grant_xp(state: RVGameState, amount: float = 500.0) -> void:
	if state == null:
		return
	if state.has_method("add_xp"):
		state.call("add_xp", amount)
	else:
		state.xp += amount
	state.add_notice("Dev: +" + str(int(amount)) + " XP")

static func grant_materials(state: RVGameState, amount: int = 50) -> void:
	if state == null:
		return
	var keys: Array[String] = ["embers", "shards", "runes", "echo_glass", "socket_prisms"]
	for key: String in keys:
		state.materials[key] = int(state.materials.get(key, 0)) + amount
	state.gold += amount * 100
	state.add_notice("Dev: materials granted")

static func grant_gold(state: RVGameState, amount: int = 25000) -> void:
	state.gold += amount
	state.add_notice("Dev: +" + str(amount) + " gold")

static func grant_socket_prisms(state: RVGameState, amount: int = 5) -> void:
	state.materials["socket_prisms"] = int(state.materials.get("socket_prisms", 0)) + amount
	state.add_notice("Dev: socket prisms granted")

static func grant_test_item(state: RVGameState, rarity: String = "Rare", slot: String = "weapon") -> Dictionary:
	var item: Dictionary = make_test_item(state, rarity, slot)
	state.backpack.append(item)
	state.inventory_cursor = max(0, state.backpack.size() - 1)
	state.add_notice("Dev item: " + str(item.get("name", "item")))
	return item

static func grant_item_bundle(state: RVGameState) -> void:
	grant_test_item(state, "Magic", "weapon")
	grant_test_item(state, "Rare", "chest")
	grant_test_item(state, "Rare", "ring1")
	grant_test_item(state, "Unique", "relic")
	grant_test_item(state, "Normal", "boots")
	state.add_notice("Dev: item bundle added")

static func clear_backpack(state: RVGameState) -> void:
	state.backpack.clear()
	state.inventory_cursor = 0
	state.add_notice("Dev: backpack cleared")

static func grant_all_gems(state: RVGameState) -> void:
	if state == null:
		return
	RVSkillGemSystem.grant_uncut_bundle(state)
	RVSkillGemSystem.grant_uncut_bundle(state)
	state.materials["socket_prisms"] = int(state.materials.get("socket_prisms", 0)) + 3
	state.ensure_defaults()
	state.add_notice("Dev: uncut gem bundle added")

static func improve_all_socket_caps(state: RVGameState) -> void:
	for i: int in range(state.skill_gem_inventory.size()):
		var gem: Dictionary = state.skill_gem_inventory[i]
		if str(gem.get("type", "active")) == "active":
			gem["max_support_sockets"] = min(6, int(gem.get("max_support_sockets", 2)) + 1)
			state.skill_gem_inventory[i] = gem
	for j: int in range(state.spirit_gem_inventory.size()):
		var spirit: Dictionary = state.spirit_gem_inventory[j]
		if str(spirit.get("type", "spirit")) == "spirit":
			spirit["max_support_sockets"] = min(6, int(spirit.get("max_support_sockets", 2)) + 1)
			state.spirit_gem_inventory[j] = spirit
	state.add_notice("Dev: socket caps improved")

static func reset_gem_setup(state: RVGameState) -> void:
	state.skill_gem_inventory.clear()
	state.support_gem_inventory.clear()
	state.spirit_gem_inventory.clear()
	if state.has_method("ensure_defaults"):
		state.ensure_defaults()
	RVSkillGemSystem.grant_uncut_bundle(state)
	state.add_notice("Dev: gem setup reset")

static func make_dev_activity() -> Dictionary:
	return {"id": "dev_test_room", "name": "Dev Test Room", "summary": "Low-risk room for testing combat, drops, skills, and enemies.", "threat": 0.35, "rooms": 1, "reward": "Developer test loot"}

static func make_stress_activity() -> Dictionary:
	return {"id": "dev_stress_room", "name": "Dev Stress Room", "summary": "Higher pressure test room for skill and loot validation.", "threat": 1.75, "rooms": 3, "reward": "Stress-test rewards"}

static func make_test_item(state: RVGameState, rarity: String, slot: String) -> Dictionary:
	# Prefer the real item roller so dev items exercise the same data model.
	var item: Dictionary = RVItemDB.generate_drop(state, max(1, state.room_index))
	if rarity != "":
		item["rarity"] = rarity
	if slot != "":
		item["slot"] = _normalize_slot(slot)
	item["name"] = rarity + " Dev " + str(item.get("base_type", "Item"))
	return RVItemDB.normalize_item(item)

static func _normalize_slot(slot: String) -> String:
	var s: String = slot.to_lower()
	match s:
		"mainhand", "main_hand", "weapon", "sword", "axe", "mace", "staff": return "weapon"
		"offhand", "off_hand", "shield", "focus": return "offhand"
		"helmet", "helm", "head": return "head"
		"body", "body_armor", "armor", "chest": return "chest"
		"glove", "gloves": return "gloves"
		"boot", "boots": return "boots"
		"ring", "ring_left", "ring_right", "ring1", "ring2": return "ring1"
		"amulet", "necklace": return "amulet"
		"relic", "charm": return "relic"
	return s
