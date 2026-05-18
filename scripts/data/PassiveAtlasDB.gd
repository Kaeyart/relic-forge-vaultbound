class_name RVPassiveAtlasDB
extends RefCounted

# Patch 085F: hardened passive database compatibility layer.
# The tree intentionally supports both old APIs used by RVClassAscendancySystem
# and newer APIs used by RVPassiveTreeSystem / panel rendering.

const START_NODE_ID: String = "center"
const CENTER_NODE_ID: String = "center"

static var _nodes_cache: Array[Dictionary] = []
static var _by_id_cache: Dictionary = {}

static func start_node_id() -> String:
	return START_NODE_ID

static func get_start_node_id() -> String:
	return START_NODE_ID

static func nodes() -> Array[Dictionary]:
	_ensure_cache()
	var out: Array[Dictionary] = []
	for node_data: Dictionary in _nodes_cache:
		out.append(node_data.duplicate(true))
	return out

static func all_nodes() -> Array[Dictionary]:
	return nodes()

static func node_count() -> int:
	_ensure_cache()
	return _nodes_cache.size()

static func ordered_ids() -> Array[String]:
	_ensure_cache()
	var out: Array[String] = []
	for node_data: Dictionary in _nodes_cache:
		out.append(str(node_data.get("id", "")))
	return out

static func ordered_ids_for_class(_class_id: String = "") -> Array[String]:
	# V1 is class-aware only by start-node position. All classes can inspect the whole tree.
	return ordered_ids()

static func node_by_id(node_id: String) -> Dictionary:
	_ensure_cache()
	if _by_id_cache.has(node_id):
		return Dictionary(_by_id_cache[node_id]).duplicate(true)
	return {}

static func node(node_id: String) -> Dictionary:
	return node_by_id(node_id)

static func get_node(node_id: String) -> Dictionary:
	return node_by_id(node_id)

static func has_node(node_id: String) -> bool:
	_ensure_cache()
	return _by_id_cache.has(node_id)

static func connected_ids(node_id: String) -> Array[String]:
	_ensure_cache()
	var out: Array[String] = []
	var data: Dictionary = node_by_id(node_id)
	for value: Variant in Array(data.get("connections", [])):
		var id: String = str(value)
		if id != "" and not out.has(id):
			out.append(id)
	# Reverse lookup allows one-way authored connections to still behave like an undirected tree.
	for other: Dictionary in _nodes_cache:
		var other_id: String = str(other.get("id", ""))
		if other_id == "" or other_id == node_id:
			continue
		if Array(other.get("connections", [])).has(node_id) and not out.has(other_id):
			out.append(other_id)
	return out

static func can_allocate(node_id: String, allocated: Array, _class_id: String = "") -> bool:
	if node_id == "" or not has_node(node_id):
		return false
	var allocated_ids: Array[String] = _string_array(allocated)
	if allocated_ids.has(node_id):
		return false
	if node_id == START_NODE_ID:
		return true
	for other_id: String in connected_ids(node_id):
		if allocated_ids.has(other_id):
			return true
	return false

static func class_start_node(class_id: String) -> String:
	match class_id:
		"sorceress", "arcanist", "mage": return "start_sorceress"
		"warden", "sentinel", "knight", "warrior": return "start_warden"
		"duelist", "rogue", "ranger": return "start_duelist"
		"trapwright", "engineer": return "start_trapwright"
	return START_NODE_ID

static func nodes_for_cluster(cluster_id: String) -> Array[Dictionary]:
	_ensure_cache()
	var out: Array[Dictionary] = []
	for node_data: Dictionary in _nodes_cache:
		if str(node_data.get("cluster", "")) == cluster_id:
			out.append(node_data.duplicate(true))
	return out

static func _ensure_cache() -> void:
	if not _nodes_cache.is_empty() and not _by_id_cache.is_empty():
		return
	_nodes_cache = _build_nodes()
	_by_id_cache.clear()
	for node_data: Dictionary in _nodes_cache:
		var id: String = str(node_data.get("id", ""))
		if id != "":
			_by_id_cache[id] = node_data.duplicate(true)

static func _build_nodes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_add(out, START_NODE_ID, "Vaultbound Origin", "start", "core", Vector2(900, 650), ["start_sorceress", "start_warden", "start_duelist", "start_trapwright"], {}, [], "The center of the character passive tree.", ["core"])
	_add(out, "start_sorceress", "Sorceress Start", "start", "class", Vector2(900, 470), ["fire_small_01", "lightning_small_01", "mana_small_01"], {"Spell Damage": 0.04, "Maximum Mana": 8.0}, [], "A caster-oriented starting path.", ["spell", "mana"])
	_add(out, "start_warden", "Warden Start", "start", "class", Vector2(720, 650), ["armor_small_01", "life_small_01", "melee_small_01"], {"Armor": 10.0, "Maximum Life": 10.0}, [], "A durable melee-oriented starting path.", ["armor", "life", "melee"])
	_add(out, "start_duelist", "Duelist Start", "start", "class", Vector2(900, 830), ["melee_small_01", "bleed_small_01", "lightning_bridge_01"], {"Attack Speed": 0.03, "Melee Damage": 0.04}, [], "A fast attack and bleed starting path.", ["attack", "bleed"])
	_add(out, "start_trapwright", "Trapwright Start", "start", "class", Vector2(1080, 650), ["trap_small_01", "void_small_01", "spirit_small_01"], {"Trap Damage": 0.05, "Cooldown Reduction": 0.02}, [], "A trap and utility starting path.", ["trap", "cooldown"])

	_add_chain(out, "fire", "Fire", Vector2(700, 300), Vector2(-72, -24), 10, "Fire Damage", 0.035, ["fire", "spell", "damage"], "Scales burn and direct fire hits.")
	_add_notable(out, "fire_notable_01", "Cinder Discipline", "fire", Vector2(110, 150), ["fire_small_10", "fire_keystone_blood_ignition"], {"Fire Damage": 0.14, "Burn Damage": 0.12}, [], "Fire skills hit harder and burns become more relevant.", ["fire", "burn"])
	_add_keystone(out, "fire_keystone_blood_ignition", "Blood Ignition", "fire", Vector2(40, 260), ["bleed_bridge_01"], {}, ["bleed_can_ignite", "fire_scales_bleed"], "Bleeding enemies can be ignited. Fire bonuses also help bleed builds.", ["fire", "bleed", "keystone"])

	_add_chain(out, "lightning", "Lightning", Vector2(1120, 300), Vector2(76, -22), 10, "Lightning Damage", 0.035, ["lightning", "shock", "spell"], "Scales lightning hits and shock pressure.")
	_add_notable(out, "lightning_notable_01", "Static Geometry", "lightning", Vector2(1690, 150), ["lightning_small_10", "lightning_keystone_storm_conduit"], {"Lightning Damage": 0.12, "Critical Chance": 0.035}, [], "Lightning builds gain better critical and shock pressure.", ["lightning", "critical"])
	_add_keystone(out, "lightning_keystone_storm_conduit", "Storm Conduit", "lightning", Vector2(1765, 270), ["spirit_bridge_01"], {"Lightning Damage": -0.08}, ["lightning_extra_chain"], "Lightning skills chain one additional time, but lose first-hit damage.", ["lightning", "chain", "keystone"])

	_add_chain(out, "void", "Void", Vector2(1240, 610), Vector2(92, 18), 10, "Void Damage", 0.04, ["void", "curse", "spell"], "Scales rifts, curses, and void conversion.")
	_add_notable(out, "void_notable_01", "Abyssal Ledger", "void", Vector2(1880, 670), ["void_small_10", "void_keystone_debt"], {"Void Damage": 0.15, "Cooldown Reduction": 0.03}, [], "Void skills gain more uptime and damage.", ["void", "cooldown"])
	_add_keystone(out, "void_keystone_debt", "Void Debt", "void", Vector2(1960, 790), ["mana_bridge_01"], {"Void Damage": 0.18, "Maximum Mana": -20.0}, ["void_reserves_mana"], "Void skills deal more damage, but permanently pressure your mana pool.", ["void", "mana", "keystone"])

	_add_chain(out, "melee", "Melee", Vector2(590, 850), Vector2(-82, 34), 10, "Melee Damage", 0.035, ["melee", "attack", "physical"], "Scales close-range weapon and cleave builds.")
	_add_notable(out, "melee_notable_01", "Iron Follow-Through", "melee", Vector2(0, 1140), ["melee_small_10", "melee_keystone_forge_body"], {"Melee Damage": 0.14, "Attack Speed": 0.035}, [], "Melee attacks gain damage and tempo.", ["melee", "speed"])
	_add_keystone(out, "melee_keystone_forge_body", "Forge-Bound Body", "melee", Vector2(120, 1260), ["armor_bridge_01"], {"Armor": 0.18, "Maximum Life": 26.0, "Movement Speed": -0.05}, ["armor_grants_life"], "Armor grants extra durability, but movement becomes heavier.", ["armor", "life", "keystone"])

	_add_chain(out, "bleed", "Bleed", Vector2(740, 1010), Vector2(-44, 78), 9, "Bleed Damage", 0.04, ["bleed", "physical", "damage"], "Scales bleed and damage-over-time setups.")
	_add_notable(out, "bleed_notable_01", "Open Vein", "bleed", Vector2(390, 1660), ["bleed_small_09"], {"Bleed Damage": 0.16, "Critical Damage": 0.08}, [], "Bleed builds become better at finishing wounded enemies.", ["bleed", "critical"])

	_add_chain(out, "trap", "Trap", Vector2(1220, 850), Vector2(72, 58), 10, "Trap Damage", 0.04, ["trap", "cooldown", "damage"], "Scales traps, delayed hits, and setup skills.")
	_add_notable(out, "trap_notable_01", "Trigger Discipline", "trap", Vector2(1780, 1390), ["trap_small_10", "trap_keystone_echo"], {"Trap Damage": 0.14, "Cooldown Reduction": 0.04}, [], "Trap setups gain better tempo.", ["trap", "cooldown"])
	_add_keystone(out, "trap_keystone_echo", "Trap Echo", "trap", Vector2(1880, 1520), [], {"Cooldown Reduction": -0.04}, ["traps_repeat_once"], "Traps repeat once after triggering, but carry more cooldown pressure.", ["trap", "keystone"])

	_add_chain(out, "life", "Life", Vector2(520, 610), Vector2(-80, 0), 8, "Maximum Life", 8.0, ["life", "defense"], "Increases maximum life.")
	_add_notable(out, "life_notable_01", "Oath of Continuance", "life", Vector2(-200, 610), ["life_small_08"], {"Maximum Life": 36.0, "Life on Kill": 8.0}, [], "You gain a larger life pool and recover from kills.", ["life", "recovery"])

	_add_chain(out, "armor", "Armor", Vector2(640, 740), Vector2(-72, 42), 8, "Armor", 18.0, ["armor", "defense"], "Increases armor.")
	_add_notable(out, "armor_notable_01", "Plate Memory", "armor", Vector2(120, 1070), ["armor_small_08"], {"Armor": 82.0, "Fire Resistance": 0.08}, [], "A defensive armor notable with fire resistance.", ["armor", "resistance"])

	_add_chain(out, "mana", "Mana", Vector2(820, 270), Vector2(-10, -76), 8, "Maximum Mana", 7.0, ["mana", "resource"], "Increases maximum mana.")
	_add_notable(out, "mana_notable_01", "Well of Runes", "mana", Vector2(740, -370), ["mana_small_08"], {"Maximum Mana": 32.0, "Mana Regeneration": 0.12}, [], "Caster resource sustain notable.", ["mana", "recovery"])

	_add_chain(out, "spirit", "Spirit", Vector2(1080, 1020), Vector2(28, 86), 8, "Spirit", 4.0, ["spirit", "reservation"], "Increases spirit capacity for persistent effects.")
	_add_notable(out, "spirit_notable_01", "Bound Familiar", "spirit", Vector2(1320, 1700), ["spirit_small_08"], {"Spirit": 16.0, "Cooldown Reduction": 0.02}, [], "More room for persistent spirit effects.", ["spirit", "cooldown"])

	# Cross-cluster bridges.
	_add_bridge(out, "bleed_bridge_01", "Searing Wound", Vector2(245, 620), ["fire_keystone_blood_ignition", "bleed_small_01"], {"Fire Damage": 0.04, "Bleed Damage": 0.04}, ["fire", "bleed"])
	_add_bridge(out, "lightning_bridge_01", "Charged Footwork", Vector2(980, 920), ["start_duelist", "lightning_small_01"], {"Movement Speed": 0.03, "Lightning Damage": 0.04}, ["lightning", "speed"])
	_add_bridge(out, "spirit_bridge_01", "Conductive Spirit", Vector2(1500, 680), ["lightning_keystone_storm_conduit", "spirit_small_01"], {"Spirit": 5.0, "Lightning Damage": 0.04}, ["lightning", "spirit"])
	_add_bridge(out, "mana_bridge_01", "Hollow Reservoir", Vector2(1600, 520), ["void_keystone_debt", "mana_small_01"], {"Maximum Mana": 12.0, "Void Damage": 0.04}, ["void", "mana"])
	_add_bridge(out, "armor_bridge_01", "Tempered Frame", Vector2(330, 1120), ["melee_keystone_forge_body", "armor_small_01"], {"Armor": 28.0, "Melee Damage": 0.04}, ["armor", "melee"])

	return out

static func _add_chain(out: Array[Dictionary], prefix: String, label: String, start: Vector2, step: Vector2, count: int, stat_name: String, stat_amount: float, tags: Array, description: String) -> void:
	var previous: String = "start_sorceress"
	match prefix:
		"fire": previous = "start_sorceress"
		"lightning": previous = "start_sorceress"
		"void": previous = "start_trapwright"
		"melee": previous = "start_warden"
		"bleed": previous = "start_duelist"
		"trap": previous = "start_trapwright"
		"life": previous = "start_warden"
		"armor": previous = "start_warden"
		"mana": previous = "start_sorceress"
		"spirit": previous = "start_trapwright"
	for i: int in range(1, count + 1):
		var id: String = prefix + "_small_" + str(i).pad_zeros(2)
		var next_id: String = prefix + "_small_" + str(i + 1).pad_zeros(2) if i < count else prefix + "_notable_01"
		_add(out, id, label + " Practice " + str(i), "small", prefix, start + step * float(i - 1), [previous, next_id], {stat_name: stat_amount}, [], description, tags)
		previous = id

static func _add_notable(out: Array[Dictionary], id: String, name: String, cluster: String, pos: Vector2, connections: Array, stats: Dictionary, rules: Array, description: String, tags: Array) -> void:
	_add(out, id, name, "notable", cluster, pos, connections, stats, rules, description, tags)

static func _add_keystone(out: Array[Dictionary], id: String, name: String, cluster: String, pos: Vector2, connections: Array, stats: Dictionary, rules: Array, description: String, tags: Array) -> void:
	_add(out, id, name, "keystone", cluster, pos, connections, stats, rules, description, tags)

static func _add_bridge(out: Array[Dictionary], id: String, name: String, pos: Vector2, connections: Array, stats: Dictionary, tags: Array) -> void:
	_add(out, id, name, "notable", "bridge", pos, connections, stats, [], "A bridge node that links neighboring build families.", tags)

static func _add(out: Array[Dictionary], id: String, name: String, type: String, cluster: String, pos: Vector2, connections: Array, stats: Dictionary, rules: Array, description: String, tags: Array) -> void:
	out.append({
		"id": id,
		"name": name,
		"type": type,
		"kind": type,
		"cluster": cluster,
		"pos": pos,
		"connections": connections.duplicate(true),
		"cost": 0 if type == "start" else 1,
		"stats": stats.duplicate(true),
		"rules": rules.duplicate(true),
		"flags": rules.duplicate(true),
		"description": description,
		"tags": tags.duplicate(true),
	})

static func _string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value: Variant in values:
		var text: String = str(value)
		if text != "" and not out.has(text):
			out.append(text)
	return out
