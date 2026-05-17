class_name RVPassiveAtlasDB
extends RefCounted

# Patch 076: 900-node passive atlas power / identity rewrite.
# Original ARPG passive atlas baseline. Data-generated for scale, but nodes now use
# stronger values, named archetype clusters, keystone downsides, and build flags.

const CLASS_REGIONS: Dictionary = {
	"sorceress": {
		"prefix": "sor",
		"label": "Sorceress",
		"origin": Vector2(520.0, -420.0),
		"angle_offset": -1.570796,
		"themes": ["fire", "cold", "lightning", "void", "mana", "spirit", "spell", "area", "projectile", "cooldown", "gem", "map"]
	},
	"huntress": {
		"prefix": "hun",
		"label": "Huntress",
		"origin": Vector2(720.0, 420.0),
		"angle_offset": 0.523599,
		"themes": ["trap", "crit", "bleed", "evasion", "mobility", "projectile", "mark", "void", "attack", "ailment", "map", "forge"]
	},
	"warrior": {
		"prefix": "war",
		"label": "Warrior",
		"origin": Vector2(-680.0, 120.0),
		"angle_offset": 2.617994,
		"themes": ["melee", "physical", "armor", "life", "stagger", "bleed", "fire", "leech", "spirit", "fortify", "forge", "map"]
	}
}

const REGION_ORDER: Array[String] = ["sorceress", "huntress", "warrior"]
const NODES_PER_REGION: int = 300
const RINGS_PER_REGION: int = 10
const NODES_PER_RING: int = 30

const NODE_POWER: Dictionary = {
	"class_start": 2.4,
	"travel": 1.05,
	"small": 1.35,
	"notable": 4.6,
	"mastery": 6.2,
	"keystone": 8.0,
	"bridge": 3.1
}

const SPECIAL_NAMES: Dictionary = {
	"sorceress": {
		"notable": ["Combustion Diagram", "Frozen Equation", "Forked Omen", "Rift Memorandum", "Mana Engine", "Spirit Geometry", "Projectile Grammar", "Cathedral Flame", "Stormline Thesis", "Void Sentence", "Cold Archive", "Arcane Relay"],
		"mastery": ["Elemental Mastery", "Spell Engine Mastery", "Spirit Circuit Mastery", "Projectile Equation", "Rift Archive", "Mana Reservoir"],
		"keystone": ["Glass Conduit", "Perfect Combustion", "Absolute Zero Writ", "Final Notice", "The Third Voice", "Hollow Reservoir"],
		"bridge": ["Forbidden Lesson", "Crossed Theorem", "Borrowed Weapon Logic"]
	},
	"huntress": {
		"notable": ["Linked Mechanism", "Blood Scent", "Veil Cut", "Marked Prey", "Pressure Plate", "Running Wound", "Dead Angle", "Rift Snare", "Kill Trail", "Needle Geometry", "Ambush Proof", "Evasive Rhythm"],
		"mastery": ["Trap Circuit Mastery", "Prey Mastery", "Ambush Mastery", "Blood Trail Mastery", "Evasion Mastery", "Projectile Instinct"],
		"keystone": ["Perfect Setup", "No Clean Wounds", "Ghost Dividend", "Kill Switch", "Stolen Opening", "Predator's Debt"],
		"bridge": ["Smuggled Route", "Shadow Crossing", "Hidden Bridge Seal"]
	},
	"warrior": {
		"notable": ["Break Rhythm", "Iron Blood", "Furnace Edge", "Red Engine", "Crack the Gate", "Unmoving Frame", "Weapon Oath", "Thirsting Edge", "Guard Flame", "Bossbreaker", "Heated Plate", "War Banner"],
		"mastery": ["Stagger Mastery", "Blood Oath Mastery", "Furnace Mastery", "Armor Mastery", "Melee Doctrine", "Forgeguard Practice"],
		"keystone": ["Blood Price", "The Anvil Remembers", "No Step Back", "Furnace Vow", "Crimson Dividend", "Iron Verdict"],
		"bridge": ["War Gate", "Anvil Bridge", "Furnace Crossing"]
	}
}

static var _cache: Dictionary = {}
static var _ids: Array[String] = []

static func all_nodes() -> Dictionary:
	_build_cache()
	return _cache

static func nodes() -> Dictionary:
	return all_nodes()

static func node_ids() -> Array[String]:
	_build_cache()
	return _ids.duplicate()

static func all_node_ids() -> Array[String]:
	return node_ids()

static func get_node(node_id: String) -> Dictionary:
	_build_cache()
	return Dictionary(_cache.get(node_id, {})).duplicate(true)

static func node(node_id: String) -> Dictionary:
	return get_node(node_id)

static func node_data(node_id: String) -> Dictionary:
	return get_node(node_id)

static func has_node(node_id: String) -> bool:
	_build_cache()
	return _cache.has(node_id)

static func start_node_for_class(class_id: String) -> String:
	var normalized: String = _normalize_class(class_id)
	var region: Dictionary = CLASS_REGIONS.get(normalized, CLASS_REGIONS["warrior"])
	return str(region.get("prefix", "war")) + "_000"

static func class_start_node(class_id: String) -> String:
	return start_node_for_class(class_id)

static func default_cursor_for_class(class_id: String) -> int:
	_build_cache()
	var start_id: String = start_node_for_class(class_id)
	var index: int = _ids.find(start_id)
	return max(0, index)

static func ids_for_region(region_id: String) -> Array[String]:
	_build_cache()
	var result: Array[String] = []
	for node_id: String in _ids:
		var data: Dictionary = _cache[node_id]
		if str(data.get("region", "")) == region_id:
			result.append(node_id)
	return result

static func node_ids_for_class(class_id: String) -> Array[String]:
	return ordered_ids_for_class(class_id)

static func ordered_ids_for_class(class_id: String) -> Array[String]:
	_build_cache()
	var normalized: String = _normalize_class(class_id)
	var result: Array[String] = []
	result.append("center")
	for node_id: String in _ids:
		var region_id: String = str(_cache[node_id].get("region", ""))
		if region_id == normalized:
			result.append(node_id)
	for node_id2: String in _ids:
		var region_id2: String = str(_cache[node_id2].get("region", ""))
		if region_id2 != normalized and node_id2 != "center":
			result.append(node_id2)
	return result

static func visible_ids_for_state(state: Variant) -> Array[String]:
	if state != null and state.has_method("get"):
		return ordered_ids_for_class(str(state.get("character_class_id")))
	return node_ids()

static func selected_node_id(state: Variant) -> String:
	if state == null:
		return "center"
	var class_id: String = "warrior"
	if state.has_method("get"):
		class_id = str(state.get("character_class_id"))
	var ids: Array[String] = ordered_ids_for_class(class_id)
	if ids.is_empty():
		return "center"
	var cursor: int = 0
	if state.has_method("get"):
		cursor = int(state.get("passive_atlas_cursor"))
	cursor = clamp(cursor, 0, ids.size() - 1)
	if state.has_method("set"):
		state.set("passive_atlas_cursor", cursor)
	return ids[cursor]

static func connected_ids(node_id: String) -> Array[String]:
	var data: Dictionary = get_node(node_id)
	var result: Array[String] = []
	for value: Variant in Array(data.get("links", [])):
		result.append(str(value))
	return result

static func can_allocate(arg1: Variant, arg2: Variant = null, arg3: Variant = null) -> bool:
	_build_cache()
	var node_id: String = ""
	var allocated: Array = []
	var class_id: String = "warrior"
	if typeof(arg1) == TYPE_STRING:
		node_id = str(arg1)
		if typeof(arg2) == TYPE_ARRAY:
			allocated = Array(arg2)
		if arg3 != null:
			class_id = str(arg3)
	else:
		var state: Variant = arg1
		node_id = str(arg2)
		if state != null and state.has_method("get"):
			allocated = Array(state.get("passive_atlas_allocated"))
			class_id = str(state.get("character_class_id"))
	if not _cache.has(node_id):
		return false
	if allocated.has(node_id):
		return false
	if node_id == "center":
		return true
	var node_info: Dictionary = _cache[node_id]
	if str(node_info.get("type", "")) == "class_start":
		return allocated.has("center") or allocated.has(start_node_for_class(class_id))
	for link_value: Variant in Array(node_info.get("links", [])):
		if allocated.has(str(link_value)):
			return true
	for req_value: Variant in Array(node_info.get("requires", [])):
		if allocated.has(str(req_value)):
			return true
	return false

static func node_summary(node_id: String) -> String:
	var data: Dictionary = get_node(node_id)
	if data.is_empty():
		return "Unknown passive node."
	var lines: Array[String] = []
	lines.append(str(data.get("name", node_id)))
	lines.append(str(data.get("type", "passive")).capitalize() + " · " + str(data.get("region_label", data.get("region", ""))))
	var tags: Array = Array(data.get("tags", []))
	if not tags.is_empty():
		lines.append("Tags: " + ", ".join(PackedStringArray(_string_array(tags))))
	var stats: Dictionary = Dictionary(data.get("stats", {}))
	for key: Variant in stats.keys():
		var stat_key: String = str(key)
		if stat_key.find("_") >= 0:
			continue
		lines.append(_format_stat(stat_key, float(stats[key])))
	var effects: Array = Array(data.get("effects", []))
	for effect_value: Variant in effects:
		lines.append("• " + str(effect_value))
	var text: String = str(data.get("description", ""))
	if text != "":
		lines.append(text)
	return "\n".join(PackedStringArray(lines))

static func _build_cache() -> void:
	if not _cache.is_empty():
		return
	_cache = {}
	_ids = []
	_add_center()
	for region_id: String in REGION_ORDER:
		_build_region(region_id)
	_add_cross_region_links()

static func _add_center() -> void:
	_cache["center"] = {
		"id": "center",
		"name": "Vaultbound Core",
		"type": "center",
		"kind": "center",
		"region": "shared",
		"region_label": "Shared Core",
		"ring": -1,
		"slot": 0,
		"position": Vector2.ZERO,
		"x": 0.0,
		"y": 0.0,
		"tags": ["core"],
		"stats": {},
		"flags": ["atlas_core"],
		"effects": ["The central relic mechanism. All class paths begin here."],
		"links": ["sor_000", "hun_000", "war_000"],
		"requires": [],
		"description": "Central passive atlas memory. Already allocated."
	}
	_ids.append("center")

static func _build_region(region_id: String) -> void:
	var region: Dictionary = CLASS_REGIONS[region_id]
	var prefix: String = str(region.get("prefix", region_id.substr(0, 3)))
	var origin: Vector2 = region.get("origin", Vector2.ZERO)
	var angle_offset: float = float(region.get("angle_offset", 0.0))
	var themes: Array = Array(region.get("themes", []))
	for ring: int in range(RINGS_PER_REGION):
		for slot: int in range(NODES_PER_RING):
			var local_index: int = ring * NODES_PER_RING + slot
			var node_id: String = prefix + "_" + str(local_index).pad_zeros(3)
			var node_type: String = _node_type_for(local_index, ring, slot)
			var theme: String = str(themes[(slot + ring * 3) % themes.size()])
			var secondary: String = str(themes[(slot + ring * 5 + 4) % themes.size()])
			var pos: Vector2 = _node_position(origin, ring, slot, angle_offset)
			var links: Array[String] = _local_links(prefix, ring, slot)
			if local_index == 0:
				links.append("center")
			var stats: Dictionary = _stats_for_node(region_id, node_type, theme, secondary, ring, slot)
			var node: Dictionary = {
				"id": node_id,
				"name": _node_name(region_id, node_type, theme, secondary, local_index, ring, slot),
				"type": node_type,
				"kind": node_type,
				"region": region_id,
				"region_label": str(region.get("label", region_id.capitalize())),
				"ring": ring,
				"slot": slot,
				"local_index": local_index,
				"position": pos,
				"x": pos.x,
				"y": pos.y,
				"tags": _tags_for_node(region_id, node_type, theme, secondary),
				"stats": stats,
				"flags": _flags_for_node(region_id, node_type, theme, secondary, ring, slot),
				"effects": _effects_for_node(region_id, node_type, theme, secondary),
				"links": links,
				"requires": links.duplicate(),
				"description": _description_for_node(region_id, node_type, theme, secondary)
			}
			_cache[node_id] = node
			_ids.append(node_id)

static func _node_position(origin: Vector2, ring: int, slot: int, angle_offset: float) -> Vector2:
	var radius: float = 72.0 + float(ring) * 52.0
	var angle: float = angle_offset + TAU * float(slot) / float(NODES_PER_RING)
	var wobble: float = 9.0 * sin(float(slot * 7 + ring * 11))
	return origin + Vector2(cos(angle), sin(angle)) * (radius + wobble)

static func _local_links(prefix: String, ring: int, slot: int) -> Array[String]:
	var links: Array[String] = []
	var left_slot: int = wrapi(slot - 1, 0, NODES_PER_RING)
	var right_slot: int = wrapi(slot + 1, 0, NODES_PER_RING)
	links.append(prefix + "_" + str(ring * NODES_PER_RING + left_slot).pad_zeros(3))
	links.append(prefix + "_" + str(ring * NODES_PER_RING + right_slot).pad_zeros(3))
	if ring > 0:
		links.append(prefix + "_" + str((ring - 1) * NODES_PER_RING + slot).pad_zeros(3))
		if slot % 3 == 0:
			links.append(prefix + "_" + str((ring - 1) * NODES_PER_RING + wrapi(slot + 1, 0, NODES_PER_RING)).pad_zeros(3))
	if ring < RINGS_PER_REGION - 1:
		links.append(prefix + "_" + str((ring + 1) * NODES_PER_RING + slot).pad_zeros(3))
		if slot % 5 == 0:
			links.append(prefix + "_" + str((ring + 1) * NODES_PER_RING + wrapi(slot - 1, 0, NODES_PER_RING)).pad_zeros(3))
	return links

static func _add_cross_region_links() -> void:
	var bridge_pairs: Array = [
		["sor_145", "hun_145"], ["hun_155", "war_155"], ["war_165", "sor_165"],
		["sor_238", "war_238"], ["hun_242", "sor_242"], ["war_246", "hun_246"],
		["sor_295", "hun_295"], ["hun_296", "war_296"], ["war_297", "sor_297"]
	]
	for pair: Array in bridge_pairs:
		_link_bidirectional(str(pair[0]), str(pair[1]))

static func _link_bidirectional(a: String, b: String) -> void:
	if not _cache.has(a) or not _cache.has(b):
		return
	var links_a: Array = Array(_cache[a].get("links", []))
	if not links_a.has(b):
		links_a.append(b)
	_cache[a]["links"] = links_a
	var links_b: Array = Array(_cache[b].get("links", []))
	if not links_b.has(a):
		links_b.append(a)
	_cache[b]["links"] = links_b

static func _node_type_for(local_index: int, ring: int, slot: int) -> String:
	if local_index == 0:
		return "class_start"
	if ring >= 7 and slot % 10 == 0:
		return "keystone"
	if ring >= 4 and slot % 7 == 0:
		return "mastery"
	if slot % 11 == 0:
		return "notable"
	if slot % 17 == 0:
		return "bridge"
	if slot % 5 == 0:
		return "travel"
	return "small"

static func _tags_for_node(region_id: String, node_type: String, theme: String, secondary: String) -> Array[String]:
	var tags: Array[String] = [theme]
	if node_type in ["notable", "keystone", "mastery"] and secondary != theme:
		tags.append(secondary)
	if region_id == "sorceress":
		tags.append("spell")
	elif region_id == "huntress":
		tags.append("technique")
	elif region_id == "warrior":
		tags.append("martial")
	if node_type == "bridge":
		tags.append("bridge")
	if node_type == "keystone":
		tags.append("keystone")
	if node_type == "mastery":
		tags.append("mastery")
	return tags

static func _stats_for_node(region_id: String, node_type: String, theme: String, secondary: String, ring: int, slot: int) -> Dictionary:
	var ring_scale: float = 1.0 + float(ring) * 0.115
	var power: float = float(NODE_POWER.get(node_type, 1.0)) * ring_scale
	var stats: Dictionary = {}
	_add_theme_stats(stats, theme, power)
	if node_type in ["notable", "mastery", "keystone"]:
		_add_theme_stats(stats, secondary, power * 0.62)
	if node_type == "travel":
		_add_stat(stats, "Maximum Life", 5.0 + float(ring) * 1.5)
		_add_stat(stats, "Maximum Mana", 3.0 + float(ring) * 1.0)
		_add_stat(stats, "All Resistance", 0.7 + float(ring) * 0.12)
	elif node_type == "notable":
		_add_stat(stats, "Notable Power", 1.0)
	elif node_type == "mastery":
		_add_stat(stats, "Mastery Power", 1.0)
		_add_stat(stats, "Maximum Life", 8.0 + float(ring) * 2.0)
	elif node_type == "keystone":
		_add_stat(stats, "Keystone Power", 1.0)
		_apply_keystone_tradeoff(stats, theme)
	elif node_type == "bridge":
		_add_stat(stats, "Bridge Power", 1.0)
	return stats

static func _add_theme_stats(stats: Dictionary, theme: String, amount: float) -> void:
	match theme:
		"fire":
			_add_stat(stats, "Fire Damage", 4.2 * amount)
			_add_stat(stats, "Burn Chance", 1.2 * amount)
			_add_stat(stats, "Burn Damage", 2.7 * amount)
		"cold":
			_add_stat(stats, "Cold Damage", 4.1 * amount)
			_add_stat(stats, "Freeze Chance", 1.0 * amount)
			_add_stat(stats, "Freeze Effect", 2.5 * amount)
		"lightning":
			_add_stat(stats, "Lightning Damage", 4.3 * amount)
			_add_stat(stats, "Shock Chance", 1.1 * amount)
			_add_stat(stats, "Chain Damage", 2.2 * amount)
		"void":
			_add_stat(stats, "Void Damage", 4.2 * amount)
			_add_stat(stats, "Curse Effect", 1.8 * amount)
			_add_stat(stats, "Pull Strength", 2.0 * amount)
		"spell":
			_add_stat(stats, "Spell Damage", 4.0 * amount)
			_add_stat(stats, "Cast Speed", 0.9 * amount)
		"area":
			_add_stat(stats, "Area Damage", 3.8 * amount)
			_add_stat(stats, "Area Size", 1.5 * amount)
		"projectile":
			_add_stat(stats, "Projectile Damage", 3.9 * amount)
			_add_stat(stats, "Projectile Speed", 1.4 * amount)
		"mana":
			_add_stat(stats, "Maximum Mana", 7.0 * amount)
			_add_stat(stats, "Mana Recovery", 2.1 * amount)
			_add_stat(stats, "Mana Cost Reduction", 0.55 * amount)
		"spirit":
			_add_stat(stats, "Maximum Spirit", 1.5 * amount)
			_add_stat(stats, "Spirit Efficiency", 0.9 * amount)
		"cooldown":
			_add_stat(stats, "Cooldown Recovery", 2.2 * amount)
			_add_stat(stats, "Skill Effect Duration", 1.4 * amount)
		"trap":
			_add_stat(stats, "Trap Damage", 4.4 * amount)
			_add_stat(stats, "Trap Arming Speed", 1.7 * amount)
		"crit":
			_add_stat(stats, "Critical Chance", 0.95 * amount)
			_add_stat(stats, "Critical Damage", 3.1 * amount)
		"bleed":
			_add_stat(stats, "Bleed Damage", 4.2 * amount)
			_add_stat(stats, "Bleed Chance", 1.1 * amount)
		"evasion":
			_add_stat(stats, "Evasion", 6.0 * amount)
			_add_stat(stats, "Dodge Chance", 0.45 * amount)
		"mobility":
			_add_stat(stats, "Movement Speed", 0.95 * amount)
			_add_stat(stats, "Damage After Moving", 2.4 * amount)
		"mark":
			_add_stat(stats, "Marked Damage", 4.0 * amount)
			_add_stat(stats, "Boss Damage", 1.6 * amount)
		"attack":
			_add_stat(stats, "Attack Damage", 4.0 * amount)
			_add_stat(stats, "Attack Speed", 0.9 * amount)
		"ailment":
			_add_stat(stats, "Ailment Effect", 2.6 * amount)
			_add_stat(stats, "Ailment Chance", 1.3 * amount)
		"melee":
			_add_stat(stats, "Melee Damage", 4.3 * amount)
			_add_stat(stats, "Cleave Area", 1.2 * amount)
		"physical":
			_add_stat(stats, "Physical Damage", 4.2 * amount)
			_add_stat(stats, "Stagger Power", 1.4 * amount)
		"armor":
			_add_stat(stats, "Armor", 8.0 * amount)
			_add_stat(stats, "Damage Reduction", 0.45 * amount)
		"life":
			_add_stat(stats, "Maximum Life", 9.0 * amount)
			_add_stat(stats, "Life Recovery", 1.0 * amount)
		"stagger":
			_add_stat(stats, "Stagger Power", 3.6 * amount)
			_add_stat(stats, "Stagger Damage", 2.7 * amount)
		"leech":
			_add_stat(stats, "Life Leech", 0.65 * amount)
			_add_stat(stats, "Damage While Leeching", 2.6 * amount)
		"fortify":
			_add_stat(stats, "Damage Reduction", 0.55 * amount)
			_add_stat(stats, "Poise", 2.5 * amount)
		"forge":
			_add_stat(stats, "Forge Potential Bonus", 1.4 * amount)
			_add_stat(stats, "Crafting Shard Gain", 2.2 * amount)
		"map":
			_add_stat(stats, "Map Drop Chance", 1.8 * amount)
			_add_stat(stats, "Map Reward Quantity", 2.0 * amount)
		"gem":
			_add_stat(stats, "Gem XP Gain", 2.8 * amount)
			_add_stat(stats, "Support Effect", 1.2 * amount)
		_:
			_add_stat(stats, "Generic Damage", 2.2 * amount)

static func _add_stat(stats: Dictionary, name: String, value: float) -> void:
	stats[name] = float(stats.get(name, 0.0)) + value
	var snake: String = _snake_key(name)
	stats[snake] = float(stats.get(snake, 0.0)) + value

static func _apply_keystone_tradeoff(stats: Dictionary, theme: String) -> void:
	match theme:
		"fire":
			_add_stat(stats, "Hit Damage", -8.0)
			_add_stat(stats, "Burn Damage", 30.0)
		"cold":
			_add_stat(stats, "Cast Speed", -5.0)
			_add_stat(stats, "Freeze Effect", 28.0)
		"lightning":
			_add_stat(stats, "Damage Reduction", -3.0)
			_add_stat(stats, "Chain Count", 1.0)
		"void":
			_add_stat(stats, "Cooldown Recovery", -5.0)
			_add_stat(stats, "Curse Effect", 25.0)
		"trap":
			_add_stat(stats, "Direct Hit Damage", -8.0)
			_add_stat(stats, "Trap Count", 1.0)
		"bleed":
			_add_stat(stats, "Bleed Damage", 28.0)
			_add_stat(stats, "Maximum Mana", -12.0)
		"armor":
			_add_stat(stats, "Movement Speed", -3.0)
			_add_stat(stats, "Poise", 20.0)
		"life":
			_add_stat(stats, "Maximum Life", 45.0)
			_add_stat(stats, "Mana Cost Reduction", -6.0)
		_:
			_add_stat(stats, "Generic Damage", 12.0)

static func _flags_for_node(region_id: String, node_type: String, theme: String, secondary: String, ring: int, slot: int) -> Array[String]:
	var flags: Array[String] = []
	if node_type == "keystone":
		flags.append("keystone_" + region_id + "_" + theme + "_" + str(slot))
		flags.append(_keystone_flag(theme))
	elif node_type == "mastery":
		flags.append("mastery_" + region_id + "_" + theme)
		flags.append("mastery_unlock_" + theme)
	elif node_type == "notable":
		flags.append("notable_" + region_id + "_" + theme + "_" + secondary)
		flags.append(_notable_flag(theme, secondary))
	elif node_type == "bridge":
		flags.append("bridge_" + region_id)
	elif node_type == "class_start":
		flags.append("class_start_" + region_id)
	return flags

static func _keystone_flag(theme: String) -> String:
	match theme:
		"fire": return "keystone_perfect_combustion"
		"cold": return "keystone_absolute_zero"
		"lightning": return "keystone_glass_conduit"
		"void": return "keystone_final_notice"
		"trap": return "keystone_perfect_setup"
		"bleed": return "keystone_no_clean_wounds"
		"armor": return "keystone_no_step_back"
		"life": return "keystone_blood_price"
		"stagger": return "keystone_crack_the_gate"
		_:
			return "keystone_" + theme

static func _notable_flag(theme: String, secondary: String) -> String:
	return "node_" + theme + "_" + secondary + "_online"

static func _effects_for_node(region_id: String, node_type: String, theme: String, secondary: String) -> Array[String]:
	var effects: Array[String] = []
	if node_type == "notable":
		effects.append(_theme_effect_sentence(theme, secondary))
	elif node_type == "mastery":
		effects.append("Cluster mastery: committing here makes the " + _theme_label(theme) + " path noticeably stronger.")
	elif node_type == "keystone":
		effects.append(_keystone_sentence(theme))
	elif node_type == "bridge":
		effects.append("Bridge seal: opens expensive routes into cross-class power.")
	return effects

static func _node_name(region_id: String, node_type: String, theme: String, secondary: String, index: int, ring: int, slot: int) -> String:
	var region_label: String = str(CLASS_REGIONS[region_id].get("label", region_id.capitalize()))
	var theme_label: String = _theme_label(theme)
	var secondary_label: String = _theme_label(secondary)
	match node_type:
		"class_start": return region_label + " Origin"
		"travel": return _travel_name(theme, secondary, slot)
		"notable": return _special_name(region_id, "notable", index)
		"mastery": return _special_name(region_id, "mastery", index)
		"keystone": return _special_name(region_id, "keystone", index)
		"bridge": return _special_name(region_id, "bridge", index)
		_:
			if index % 6 == 0:
				return theme_label + " through " + secondary_label
			if index % 4 == 0:
				return secondary_label + "-Tuned " + theme_label
			return theme_label + " Practice"

static func _special_name(region_id: String, group: String, index: int) -> String:
	var region_data: Dictionary = SPECIAL_NAMES.get(region_id, {})
	var names: Array = Array(region_data.get(group, []))
	if names.is_empty():
		return group.capitalize()
	return str(names[index % names.size()])

static func _travel_name(theme: String, secondary: String, slot: int) -> String:
	if slot % 2 == 0:
		return _theme_label(theme) + " Route"
	return _theme_label(theme) + " / " + _theme_label(secondary) + " Path"

static func _description_for_node(region_id: String, node_type: String, theme: String, secondary: String) -> String:
	match node_type:
		"class_start": return "Class origin. This starts the region's natural build language."
		"travel": return "Travel node with real power; not empty attribute filler."
		"notable": return "Build-direction node. Strong enough to shape skill, item, or status choices."
		"mastery": return "Cluster reward. This should be a commitment payoff, not a filler stat."
		"keystone": return "Rule-level passive with a large upside and a real cost."
		"bridge": return "Cross-region connector for strange builds and expensive class theft."
		_:
			return "Passive power for the " + _theme_label(theme) + " path."

static func _theme_effect_sentence(theme: String, secondary: String) -> String:
	match theme:
		"fire": return "Fire hits, burns, and explosions scale together."
		"cold": return "Cold skills gain more control and freeze payoff."
		"lightning": return "Lightning builds gain shock pressure and chain payoff."
		"void": return "Void skills lean harder into curse, pull, and delayed punishment."
		"trap": return "Trap builds gain arming speed, burst, and setup reward."
		"bleed": return "Bleed becomes a real kill condition instead of a minor damage rider."
		"stagger": return "Stagger pressure creates interrupt and boss-pressure builds."
		"forge": return "Crafting and item progression become part of the build plan."
		"map": return "Map sustain and reward pressure improve."
		_:
			return _theme_label(theme) + " is reinforced and cross-scales with " + _theme_label(secondary) + "."

static func _keystone_sentence(theme: String) -> String:
	match theme:
		"fire": return "Burn becomes the main payoff, but direct hit damage is reduced."
		"cold": return "Freeze control becomes oppressive, but casts become heavier."
		"lightning": return "Lightning chains harder, but defense while casting is worse."
		"void": return "Curses and delayed damage become stronger, but cooldown pressure rises."
		"trap": return "Traps can cover more space, but direct hit builds lose pressure."
		"armor": return "You become hard to stagger, but mobility suffers."
		"life": return "Life becomes a resource and a weapon."
		_:
			return "Large upside with a real build cost."

static func _theme_label(theme: String) -> String:
	match theme:
		"fire": return "Fire"
		"cold": return "Cold"
		"lightning": return "Lightning"
		"void": return "Void"
		"mana": return "Mana"
		"spirit": return "Spirit"
		"spell": return "Spell"
		"area": return "Area"
		"projectile": return "Projectile"
		"cooldown": return "Cooldown"
		"trap": return "Trap"
		"crit": return "Critical"
		"bleed": return "Bleed"
		"evasion": return "Evasion"
		"mobility": return "Mobility"
		"mark": return "Marked Prey"
		"attack": return "Attack"
		"ailment": return "Ailment"
		"melee": return "Melee"
		"physical": return "Physical"
		"armor": return "Armor"
		"life": return "Life"
		"stagger": return "Stagger"
		"leech": return "Leech"
		"fortify": return "Fortify"
		"forge": return "Forge"
		"map": return "Map"
		"gem": return "Gem"
		_:
			return theme.capitalize()

static func _format_stat(key: String, value: float) -> String:
	var sign: String = "+" if value >= 0.0 else ""
	var shown_value: float = round(value * 10.0) / 10.0
	return sign + str(shown_value) + " " + key

static func _string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values:
		result.append(str(value))
	return result

static func _snake_key(name: String) -> String:
	return name.to_lower().replace(" ", "_").replace("/", "_").replace("-", "_")

static func _normalize_class(class_id: String) -> String:
	var lower: String = class_id.to_lower()
	if lower in ["sorceress", "sor", "mage"]:
		return "sorceress"
	if lower in ["huntress", "hun", "hunter", "rogue"]:
		return "huntress"
	return "warrior"
