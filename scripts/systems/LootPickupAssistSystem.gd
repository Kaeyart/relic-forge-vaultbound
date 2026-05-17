class_name RVLootPickupAssistSystem
extends RefCounted

const DEFAULT_ATTRACT_RADIUS: float = 310.0
const DEFAULT_COLLECT_RADIUS: float = 54.0
const DEFAULT_PET_RADIUS: float = 210.0

static func ensure_defaults(state: Object) -> void:
	if state == null:
		return
	if _is_null_or_missing(state, "loot_pet_enabled"):
		state.set("loot_pet_enabled", true)
	if float(state.get("loot_pet_radius")) <= 0.0:
		state.set("loot_pet_radius", DEFAULT_PET_RADIUS)
	if float(state.get("loot_pet_collect_radius")) <= 0.0:
		state.set("loot_pet_collect_radius", DEFAULT_COLLECT_RADIUS)
	if float(state.get("loot_pet_attract_radius")) <= 0.0:
		state.set("loot_pet_attract_radius", DEFAULT_ATTRACT_RADIUS)
	if str(state.get("loot_filter_preset")) == "":
		state.set("loot_filter_preset", "Starter")
	var settings: Dictionary = {}
	var raw_settings: Variant = state.get("loot_filter_settings")
	if typeof(raw_settings) == TYPE_DICTIONARY:
		settings = Dictionary(raw_settings)
	var defaults: Dictionary = default_filter_settings()
	for key in defaults.keys():
		if not settings.has(key):
			settings[key] = defaults[key]
	state.set("loot_filter_settings", settings)
	if _is_null_or_missing(state, "loot_pickup_stats") or typeof(state.get("loot_pickup_stats")) != TYPE_DICTIONARY:
		state.set("loot_pickup_stats", {})

static func default_filter_settings() -> Dictionary:
	return {
		"auto_pickup_gold": true,
		"auto_pickup_shards": true,
		"auto_pickup_embers": true,
		"auto_pickup_materials": true,
		"auto_pickup_currency": true,
		"auto_pickup_maps": false,
		"auto_pickup_gems": false,
		"manual_pickup_gear": true,
		"manual_pickup_uniques": true,
		"show_hidden_auto_pickup_notice": false,
	}

# Flexible signature on purpose: older/newer GameRoot patches may pass either
# (state, combat, player, delta) or add a pet visual node.
static func update(state: Object, combat_root: Node = null, player: Node = null, arg3: Variant = 0.0, arg4: Variant = null) -> void:
	if state == null or combat_root == null or player == null:
		return
	ensure_defaults(state)
	if not bool(state.get("loot_pet_enabled")):
		return
	if str(state.get("mode")) != "combat":
		return
	var delta: float = 0.0
	if typeof(arg3) == TYPE_FLOAT or typeof(arg3) == TYPE_INT:
		delta = float(arg3)
	elif typeof(arg4) == TYPE_FLOAT or typeof(arg4) == TYPE_INT:
		delta = float(arg4)
	var player_pos: Vector2 = _player_position(state, player)
	var collect_radius: float = max(16.0, float(state.get("loot_pet_collect_radius")))
	var attract_radius: float = max(collect_radius, float(state.get("loot_pet_attract_radius")))
	var nodes: Array[Node] = []
	_collect_loot_nodes(combat_root, nodes)
	for node in nodes:
		if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var data: Dictionary = _drop_data_for_node(node)
		if data.is_empty():
			continue
		if not should_auto_pickup(state, data):
			continue
		var node_pos: Vector2 = _node_position(node)
		var distance: float = node_pos.distance_to(player_pos)
		if distance <= collect_radius:
			_collect_drop_node(state, node, data)
		elif distance <= attract_radius and delta > 0.0:
			_attract_node_toward(node, player_pos, delta, distance, attract_radius)

static func should_auto_pickup(state: Object, drop_data: Dictionary) -> bool:
	ensure_defaults(state)
	var settings: Dictionary = Dictionary(state.get("loot_filter_settings"))
	var kind: String = _drop_kind(drop_data)
	match kind:
		"gold":
			return bool(settings.get("auto_pickup_gold", true))
		"shards":
			return bool(settings.get("auto_pickup_shards", true))
		"embers":
			return bool(settings.get("auto_pickup_embers", true))
		"material":
			return bool(settings.get("auto_pickup_materials", true))
		"currency":
			return bool(settings.get("auto_pickup_currency", true))
		"map":
			return bool(settings.get("auto_pickup_maps", false))
		"gem":
			return bool(settings.get("auto_pickup_gems", false))
		_:
			return false

static func pickup_summary_text(state: Object) -> String:
	ensure_defaults(state)
	var settings: Dictionary = Dictionary(state.get("loot_filter_settings"))
	var stats: Dictionary = Dictionary(state.get("loot_pickup_stats"))
	var lines: Array[String] = []
	lines.append("LOOT PICKUP PET")
	lines.append("Pet: " + ("ON" if bool(state.get("loot_pet_enabled")) else "OFF") + " · Radius: " + str(int(state.get("loot_pet_radius"))))
	lines.append("Auto: gold " + _onoff(settings.get("auto_pickup_gold", true)) + " · shards " + _onoff(settings.get("auto_pickup_shards", true)) + " · embers " + _onoff(settings.get("auto_pickup_embers", true)) + " · materials " + _onoff(settings.get("auto_pickup_materials", true)) + " · maps " + _onoff(settings.get("auto_pickup_maps", false)))
	lines.append("Collected: gold " + str(int(stats.get("gold", 0))) + " · materials " + str(int(stats.get("material", 0))) + " · maps " + str(int(stats.get("map", 0))))
	return "\n".join(lines)

static func toggle_auto_pickup_maps(state: Object) -> bool:
	ensure_defaults(state)
	var settings: Dictionary = Dictionary(state.get("loot_filter_settings"))
	settings["auto_pickup_maps"] = not bool(settings.get("auto_pickup_maps", false))
	state.set("loot_filter_settings", settings)
	if state.has_method("add_notice"):
		state.call("add_notice", "Auto-pickup maps: " + ("ON" if bool(settings["auto_pickup_maps"]) else "OFF"))
	return true

static func toggle_pet_enabled(state: Object) -> bool:
	ensure_defaults(state)
	state.set("loot_pet_enabled", not bool(state.get("loot_pet_enabled")))
	if state.has_method("add_notice"):
		state.call("add_notice", "Loot pet: " + ("ON" if bool(state.get("loot_pet_enabled")) else "OFF"))
	return true

static func _collect_loot_nodes(root: Node, out_nodes: Array[Node]) -> void:
	if root == null:
		return
	for child in root.get_children():
		if _is_loot_node(child):
			out_nodes.append(child)
		_collect_loot_nodes(child, out_nodes)

static func _is_loot_node(node: Node) -> bool:
	if node == null:
		return false
	if node.has_method("get_auto_pickup_data") or node.has_method("collect_auto_pickup") or node.has_method("collect_into_state"):
		return true
	if node.has_meta("loot_data") or node.has_meta("drop_data") or node.has_meta("item_data"):
		return true
	var lower_name: String = str(node.name).to_lower()
	return lower_name.find("loot") >= 0 or lower_name.find("drop") >= 0

static func _drop_data_for_node(node: Node) -> Dictionary:
	if node == null:
		return {}
	if node.has_method("get_auto_pickup_data"):
		var result: Variant = node.call("get_auto_pickup_data")
		if typeof(result) == TYPE_DICTIONARY:
			return Dictionary(result)
	for meta_key in ["loot_data", "drop_data", "item_data", "payload"]:
		if node.has_meta(meta_key):
			var meta_value: Variant = node.get_meta(meta_key)
			if typeof(meta_value) == TYPE_DICTIONARY:
				return Dictionary(meta_value)
	var guessed: Dictionary = {}
	for key in ["kind", "loot_kind", "item_type", "category", "currency", "material", "amount", "quantity", "gold", "shards", "embers", "tier", "map_level", "boss_name"]:
		var value: Variant = node.get(StringName(key))
		if value != null:
			guessed[key] = value
	return guessed

static func _collect_drop_node(state: Object, node: Node, drop_data: Dictionary) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.has_method("collect_auto_pickup"):
		if bool(node.call("collect_auto_pickup", state)):
			_record_pickup(state, _drop_kind(drop_data), int(drop_data.get("amount", drop_data.get("quantity", 1))))
			return
	if node.has_method("collect_into_state"):
		if bool(node.call("collect_into_state", state)):
			_record_pickup(state, _drop_kind(drop_data), int(drop_data.get("amount", drop_data.get("quantity", 1))))
			return
	_apply_drop_to_state(state, drop_data)
	if is_instance_valid(node):
		node.queue_free()

static func _apply_drop_to_state(state: Object, drop_data: Dictionary) -> void:
	var kind: String = _drop_kind(drop_data)
	var amount: int = max(1, int(drop_data.get("amount", drop_data.get("quantity", 1))))
	match kind:
		"gold":
			state.set("gold", int(state.get("gold")) + amount)
			_notice(state, "Pet collected " + str(amount) + " gold")
		"shards", "embers", "material", "currency":
			var material_id: String = _material_id_for(drop_data, kind)
			var materials: Dictionary = Dictionary(state.get("materials"))
			materials[material_id] = int(materials.get(material_id, 0)) + amount
			state.set("materials", materials)
			_notice(state, "Pet collected " + str(amount) + " " + material_id)
		"map":
			if typeof(drop_data) == TYPE_DICTIONARY:
				var backpack: Array = Array(state.get("backpack"))
				if Engine.has_singleton("__never__"):
					pass
				if ClassDB.class_exists("RVMapItemSystem"):
					backpack.append(RVMapItemSystem.normalize_map_item(drop_data, "pet", state))
				else:
					backpack.append(drop_data)
				state.set("backpack", backpack)
			_notice(state, "Pet collected map")
		"gem", "item":
			var backpack_items: Array = Array(state.get("backpack"))
			backpack_items.append(drop_data)
			state.set("backpack", backpack_items)
			_notice(state, "Pet collected loot")
	_record_pickup(state, kind, amount)

static func _drop_kind(drop_data: Dictionary) -> String:
	var explicit: String = str(drop_data.get("kind", drop_data.get("loot_kind", drop_data.get("item_type", drop_data.get("category", ""))))).to_lower()
	if explicit == "skill_gem":
		return "gem"
	if explicit in ["gold", "currency", "material", "map", "gem", "item", "gear", "shards", "embers"]:
		return explicit
	if bool(drop_data.get("map_item", false)) or str(drop_data.get("slot", "")) == "map" or (drop_data.has("map_level") and drop_data.has("tier")):
		return "map"
	if drop_data.has("gold"):
		return "gold"
	if drop_data.has("shards"):
		return "shards"
	if drop_data.has("embers"):
		return "embers"
	if drop_data.has("material") or drop_data.has("material_id"):
		return "material"
	if str(drop_data.get("base_type", "")).to_lower().find("gem") >= 0:
		return "gem"
	return "item"

static func _material_id_for(drop_data: Dictionary, kind: String) -> String:
	if kind == "shards" or kind == "embers":
		return kind
	if str(drop_data.get("material_id", "")) != "":
		return str(drop_data.get("material_id"))
	if str(drop_data.get("material", "")) != "":
		return str(drop_data.get("material"))
	if str(drop_data.get("currency", "")) != "":
		return str(drop_data.get("currency"))
	return kind

static func _record_pickup(state: Object, kind: String, amount: int) -> void:
	var stats: Dictionary = Dictionary(state.get("loot_pickup_stats"))
	stats[kind] = int(stats.get(kind, 0)) + max(1, amount)
	state.set("loot_pickup_stats", stats)

static func _player_position(state: Object, player: Node) -> Vector2:
	if player != null and player is Node2D:
		return (player as Node2D).global_position
	var value: Variant = state.get("player_pos")
	return value if typeof(value) == TYPE_VECTOR2 else Vector2.ZERO

static func _node_position(node: Node) -> Vector2:
	if node is Node2D:
		return (node as Node2D).global_position
	if node is Control:
		return (node as Control).global_position
	return Vector2.ZERO

static func _attract_node_toward(node: Node, target_pos: Vector2, delta: float, distance: float, attract_radius: float) -> void:
	if not (node is Node2D):
		return
	var node2d: Node2D = node as Node2D
	var strength: float = clampf(1.0 - (distance / max(1.0, attract_radius)), 0.05, 1.0)
	var speed: float = lerpf(120.0, 520.0, strength)
	node2d.global_position = node2d.global_position.move_toward(target_pos, speed * delta)

static func _onoff(value: Variant) -> String:
	return "ON" if bool(value) else "OFF"

static func _notice(state: Object, text: String) -> void:
	if state != null and state.has_method("add_notice"):
		state.call("add_notice", text)

static func _is_null_or_missing(state: Object, key: String) -> bool:
	return state.get(key) == null
