class_name RVLootDropActor
extends Area2D

signal picked_up(drop: RVLootDropActor)

var payload: Dictionary = {}
var pickup_radius: float = 34.0
var life_time: float = 0.0
var label_node: Label = null
var beam: Polygon2D = null
var glow: Polygon2D = null
var sparkle_timer: float = 0.0

func _ready() -> void:
	z_as_relative = false
	z_index = 8
	monitoring = false
	monitorable = false
	_build_visuals()
	set_process(true)

func setup(drop_payload: Dictionary) -> void:
	payload = drop_payload.duplicate(true)
	if is_inside_tree():
		_refresh_visuals()

func _process(delta: float) -> void:
	life_time += delta
	sparkle_timer += delta
	var bob: float = sin(life_time * 4.2) * 2.0
	if label_node != null:
		label_node.position.y = -30.0 + bob
	if glow != null:
		glow.scale = Vector2.ONE * (1.0 + sin(life_time * 5.0) * 0.045)

func can_pickup(player_pos: Vector2) -> bool:
	return global_position.distance_to(player_pos) <= pickup_radius

func pick_up() -> void:
	picked_up.emit(self)
	queue_free()

func _build_visuals() -> void:
	beam = Polygon2D.new()
	beam.name = "LootBeam"
	beam.polygon = PackedVector2Array([Vector2(-5, -28), Vector2(5, -28), Vector2(2, 0), Vector2(-2, 0)])
	beam.color = Color(1.0, 0.76, 0.24, 0.34)
	beam.z_index = 7
	add_child(beam)

	glow = Polygon2D.new()
	glow.name = "LootMarker"
	glow.polygon = PackedVector2Array([Vector2(0,-8), Vector2(9,0), Vector2(0,8), Vector2(-9,0)])
	glow.color = Color(1.0, 0.76, 0.24, 0.82)
	glow.z_index = 8
	add_child(glow)

	label_node = Label.new()
	label_node.name = "LootLabel"
	label_node.position = Vector2(-62, -30)
	label_node.size = Vector2(124, 20)
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_node.add_theme_font_size_override("font_size", 12)
	label_node.add_theme_color_override("font_shadow_color", Color(0,0,0,0.9))
	label_node.add_theme_constant_override("shadow_offset_x", 1)
	label_node.add_theme_constant_override("shadow_offset_y", 1)
	label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_node.z_index = 9
	add_child(label_node)
	_refresh_visuals()

func _refresh_visuals() -> void:
	if label_node == null:
		return
	label_node.text = display_name()
	var col: Color = rarity_color()
	label_node.add_theme_color_override("font_color", col)
	if beam != null:
		beam.color = Color(col.r, col.g, col.b, 0.30)
	if glow != null:
		glow.color = Color(col.r, col.g, col.b, 0.88)

func display_name() -> String:
	var kind: String = str(payload.get("kind", "item"))
	if kind == "gold":
		return str(int(payload.get("amount", 0))) + " Gold"
	if kind == "material":
		return str(payload.get("name", payload.get("material", "Material")))
	if kind == "map":
		return str(payload.get("name", "Map"))
	if kind == "gem":
		return str(payload.get("name", "Gem"))
	var item: Dictionary = Dictionary(payload.get("item", payload))
	return str(item.get("name", "Item"))

func rarity_color() -> Color:
	var rarity: String = str(payload.get("rarity", "")).to_lower()
	if rarity == "":
		var item: Dictionary = Dictionary(payload.get("item", payload))
		rarity = str(item.get("rarity", "normal")).to_lower()
	match rarity:
		"unique", "legendary":
			return Color(1.0, 0.58, 0.18)
		"rare":
			return Color(1.0, 0.86, 0.28)
		"magic":
			return Color(0.42, 0.70, 1.0)
		"map":
			return Color(0.75, 0.55, 1.0)
		"gem":
			return Color(0.35, 1.0, 0.74)
		"material":
			return Color(0.82, 0.86, 0.72)
		"gold":
			return Color(1.0, 0.74, 0.22)
	return Color(0.88, 0.86, 0.78)


func get_auto_pickup_data() -> Dictionary:
	var data: Dictionary = {}
	for key: String in ["loot_data", "drop_data", "item_data", "payload", "item", "map_item"]:
		var value: Variant = get(key)
		if typeof(value) == TYPE_DICTIONARY:
			data = Dictionary(value).duplicate(true)
			break
	for key: String in ["kind", "loot_kind", "item_type", "category", "currency", "material", "material_id", "amount", "quantity", "gold", "shards", "embers", "tier", "map_level", "boss_name"]:
		var value: Variant = get(key)
		if value != null:
			data[key] = value
	return data

func collect_auto_pickup(state: RVGameState) -> bool:
	if has_method("collect_into_state"):
		return bool(call("collect_into_state", state))
	return false
