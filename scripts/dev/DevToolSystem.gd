class_name RVDevToolSystem
extends RefCounted

# Relic Forge: Vaultbound
# Patch 032: developer/creative-mode helpers.
# These methods intentionally create test data directly so content can be verified quickly.

const ACTIVE_GEM_IDS: Array[String] = ["fireball", "cleave", "frost_nova", "storm_lance", "void_rift", "blade_trap"]
const SUPPORT_GEM_IDS: Array[String] = ["controlled_power", "efficient_casting", "area_expansion", "chain_reaction", "critical_focus", "mana_efficiency"]
const SPIRIT_GEM_IDS: Array[String] = ["clarity", "vitality", "emberskin", "storm_focus"]

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
	for gem_id: String in ACTIVE_GEM_IDS:
		if _state_has_method(state, "_make_active_gem"):
			state.skill_gem_inventory.append(state.call("_make_active_gem", gem_id, max(1, state.level), false))
	for support_id: String in SUPPORT_GEM_IDS:
		if _state_has_method(state, "_make_support_gem"):
			state.support_gem_inventory.append(state.call("_make_support_gem", support_id, max(1, state.level)))
	for spirit_id: String in SPIRIT_GEM_IDS:
		if _state_has_method(state, "_make_spirit_gem"):
			state.spirit_gem_inventory.append(state.call("_make_spirit_gem", spirit_id, max(1, state.level), false))
	if _state_has_method(state, "ensure_defaults"):
		state.ensure_defaults()
	state.add_notice("Dev: gem bundle added")


static func improve_all_socket_caps(state: RVGameState) -> void:
	for gem: Dictionary in state.skill_gem_inventory:
		gem["max_support_sockets"] = min(6, int(gem.get("max_support_sockets", 2)) + 1)
	for spirit: Dictionary in state.spirit_gem_inventory:
		spirit["max_support_sockets"] = min(6, int(spirit.get("max_support_sockets", 2)) + 1)
	state.add_notice("Dev: socket caps improved")


static func reset_gem_setup(state: RVGameState) -> void:
	state.skill_gem_inventory.clear()
	state.support_gem_inventory.clear()
	state.spirit_gem_inventory.clear()
	if _state_has_method(state, "ensure_defaults"):
		state.ensure_defaults()
	state.add_notice("Dev: gem setup reset")


static func make_dev_activity() -> Dictionary:
	return {
		"id": "dev_test_room",
		"name": "Dev Test Room",
		"summary": "Low-risk room for testing combat, drops, skills, and enemies.",
		"threat": 0.35,
		"rooms": 1,
		"reward": "Developer test loot"
	}


static func make_stress_activity() -> Dictionary:
	return {
		"id": "dev_stress_room",
		"name": "Dev Stress Room",
		"summary": "Higher pressure test room for skill and loot validation.",
		"threat": 1.75,
		"rooms": 3,
		"reward": "Stress-test rewards"
	}


static func make_test_item(state: RVGameState, rarity: String, slot: String) -> Dictionary:
	var normalized_slot: String = _normalize_slot(slot)
	var item_level: int = max(1, state.level)
	var base_type: String = _base_type_for_slot(normalized_slot)
	var affix_count: int = _affix_count_for_rarity(rarity)
	var prefixes: Array[Dictionary] = []
	var suffixes: Array[Dictionary] = []
	var stats: Dictionary = {}
	var implicit_stats: Dictionary = _implicit_for_slot(normalized_slot, item_level)
	_merge_stats(stats, implicit_stats)

	for i in range(affix_count):
		var affix: Dictionary = _make_affix(normalized_slot, item_level, i)
		if str(affix.get("kind", "prefix")) == "prefix" and prefixes.size() < 3:
			prefixes.append(affix)
		elif suffixes.size() < 3:
			suffixes.append(affix)
		else:
			prefixes.append(affix)
		_merge_stats(stats, affix.get("stats", {}))

	var item_name: String = rarity + " Dev " + base_type
	var unique_effects: Array[String] = []
	var unique_flags: Array[String] = []

	if rarity == "Unique":
		item_name = _unique_name_for_slot(normalized_slot)
		unique_effects = _unique_effects_for_slot(normalized_slot)
		unique_flags = _unique_flags_for_slot(normalized_slot)
		_merge_stats(stats, {"Global Damage": 0.12, "Maximum Spirit": 10.0})

	return {
		"name": item_name,
		"slot": normalized_slot,
		"base_type": base_type,
		"armor_class": _armor_class_for_slot(normalized_slot),
		"item_level": item_level,
		"rarity": rarity,
		"implicit": [{"name": "Base " + base_type, "stats": implicit_stats, "tags": [normalized_slot]}],
		"prefixes": prefixes,
		"suffixes": suffixes,
		"stats": stats,
		"forge_potential": _forge_potential_for_rarity(rarity, item_level),
		"unique_effects": unique_effects,
		"unique_flags": unique_flags,
		"flags": unique_flags,
		"desc": "Developer test item generated for rapid build validation."
	}


static func _make_affix(slot: String, item_level: int, index: int) -> Dictionary:
	var scale: float = 1.0 + float(item_level) * 0.025
	var templates: Array[Dictionary] = [
		{"name": "Burning", "kind": "prefix", "stats": {"Fire Damage": 0.08 * scale}, "tags": ["fire", "damage"]},
		{"name": "Glacial", "kind": "prefix", "stats": {"Cold Damage": 0.08 * scale}, "tags": ["cold", "damage"]},
		{"name": "Stormcharged", "kind": "prefix", "stats": {"Lightning Damage": 0.08 * scale}, "tags": ["lightning", "damage"]},
		{"name": "Void-Touched", "kind": "prefix", "stats": {"Void Damage": 0.08 * scale}, "tags": ["void", "damage"]},
		{"name": "of the Giant", "kind": "suffix", "stats": {"Maximum Life": 8.0 * scale}, "tags": ["life", "defense"]},
		{"name": "of Focus", "kind": "suffix", "stats": {"Maximum Mana": 6.0 * scale}, "tags": ["mana", "resource"]},
		{"name": "of Quickening", "kind": "suffix", "stats": {"Cooldown Recovery": 0.02 * scale}, "tags": ["speed", "utility"]},
		{"name": "of Precision", "kind": "suffix", "stats": {"Critical Chance": 0.015 * scale}, "tags": ["crit", "offense"]}
	]
	var selected: Dictionary = templates[index % templates.size()].duplicate(true)
	selected["tier"] = clamp(1 + int(item_level / 12), 1, 5)
	return selected


static func _merge_stats(target: Dictionary, source: Dictionary) -> void:
	for key: Variant in source.keys():
		target[key] = float(target.get(key, 0.0)) + float(source[key])


static func _normalize_slot(slot: String) -> String:
	var s: String = slot.to_lower()
	match s:
		"mainhand", "main_hand", "weapon", "sword", "axe", "mace", "staff":
			return "weapon"
		"offhand", "off_hand", "shield", "focus":
			return "offhand"
		"helmet", "helm", "head":
			return "head"
		"body", "body_armor", "armor", "chest":
			return "chest"
		"glove", "gloves":
			return "gloves"
		"boot", "boots":
			return "boots"
		"ring", "ring_left", "ring_right", "ring1", "ring2":
			return "ring1"
		"amulet", "necklace":
			return "amulet"
		"relic", "charm":
			return "relic"
	return s


static func _base_type_for_slot(slot: String) -> String:
	match slot:
		"weapon": return "Greatsword"
		"offhand": return "Focus"
		"head": return "Helmet"
		"chest": return "Chest Armor"
		"gloves": return "Gloves"
		"boots": return "Boots"
		"amulet": return "Amulet"
		"ring1", "ring2": return "Ring"
		"relic": return "Relic"
	return "Item"


static func _armor_class_for_slot(slot: String) -> String:
	match slot:
		"head", "chest", "gloves", "boots": return "Armor"
		"offhand": return "Focus"
		"weapon": return "Weapon"
		_: return "Accessory"


static func _implicit_for_slot(slot: String, item_level: int) -> Dictionary:
	var scale: float = 1.0 + float(item_level) * 0.035
	match slot:
		"weapon": return {"Physical Damage": 0.10 * scale, "Attack Power": 4.0 * scale}
		"offhand": return {"Spell Damage": 0.08 * scale, "Maximum Mana": 5.0 * scale}
		"head": return {"Maximum Life": 6.0 * scale}
		"chest": return {"Armor": 12.0 * scale, "Maximum Life": 10.0 * scale}
		"gloves": return {"Attack Speed": 0.03 * scale}
		"boots": return {"Movement Speed": 0.03 * scale}
		"amulet": return {"Global Damage": 0.04 * scale}
		"ring1", "ring2": return {"Critical Chance": 0.01 * scale}
		"relic": return {"Maximum Spirit": 5.0 * scale}
	return {"Maximum Life": 3.0 * scale}


static func _affix_count_for_rarity(rarity: String) -> int:
	match rarity:
		"Normal": return 0
		"Magic": return 2
		"Rare": return 5
		"Unique": return 4
		_: return 3


static func _forge_potential_for_rarity(rarity: String, item_level: int) -> int:
	match rarity:
		"Normal": return 18 + int(item_level / 4)
		"Magic": return 24 + int(item_level / 3)
		"Rare": return 32 + int(item_level / 2)
		"Unique": return 0
		_: return 20


static func _unique_name_for_slot(slot: String) -> String:
	match slot:
		"weapon": return "Dev Unique - Chainblade Prototype"
		"offhand": return "Dev Unique - Rift Focus Prototype"
		"chest": return "Dev Unique - Furnace Plate Prototype"
		"boots": return "Dev Unique - Riftwalker Prototype"
		"relic": return "Dev Unique - Choir Prism Prototype"
	return "Dev Unique - Build Enabler Prototype"


static func _unique_effects_for_slot(slot: String) -> Array[String]:
	match slot:
		"weapon": return ["Fireball and Storm Lance can chain into each other.", "Critical hits have a chance to cast a supported skill."]
		"offhand": return ["Void Rift counts as a Trap and pulls harder."]
		"chest": return ["Cleave gains Fire scaling and creates a burning shockwave."]
		"boots": return ["Dodging through enemies leaves a small Void Rift."]
		"relic": return ["Spirit skills reserve less Spirit and gain one support socket."]
	return ["Developer unique: build-changing behavior placeholder."]


static func _unique_flags_for_slot(slot: String) -> Array[String]:
	match slot:
		"weapon": return ["fire_lance_chain", "crit_cast_supported"]
		"offhand": return ["rift_counts_as_trap", "rift_pull_plus"]
		"chest": return ["cleave_fire_conversion", "cleave_burning_wave"]
		"boots": return ["dash_leaves_rift"]
		"relic": return ["spirit_efficiency", "spirit_socket_plus"]
	return ["dev_unique_effect"]


static func _state_has_method(state: RVGameState, method_name: String) -> bool:
	return state != null and state.has_method(method_name)
