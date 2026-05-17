class_name RVSpellVFXSystem
extends RefCounted

# Patch 061-063B: reusable Godot-native spell VFX recipes.
# Adds emit_skill() compatibility for CombatArena integration.

static func emit_skill(caller: Node, parent: Node, skill_name: String, origin: Vector2, aim: Vector2, direction: Vector2, skill_data: Dictionary = {}, tags: Array = []) -> void:
	if parent == null:
		return

	var dir: Vector2 = direction
	if dir.length() <= 0.01:
		dir = aim - origin
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	dir = dir.normalized()

	# Cast/body visual.
	spawn_skill_cast(parent, skill_name, origin, aim, tags)

	# Extra readable accents for skills that are effectively instant or area-based.
	match skill_name:
		"Frost Nova":
			spawn_skill_impact(parent, skill_name, origin, tags)
		"Void Rift":
			spawn_skill_impact(parent, skill_name, aim, tags)
		"Cleave":
			_spawn(parent, {
				"kind": "hit_spark",
				"pos": origin + dir * 76.0,
				"radius": float(skill_data.get("radius", 54.0)),
				"lifetime": 0.22,
				"direction": dir,
				"tags": tags
			})
		"Blade Trap":
			_spawn(parent, {
				"kind": "blade_trap",
				"pos": aim,
				"radius": float(skill_data.get("radius", 74.0)),
				"lifetime": 0.80,
				"direction": dir,
				"tags": tags
			})
		_:
			pass

static func spawn_skill_cast(parent: Node, skill_name: String, from_pos: Vector2, aim_pos: Vector2, tags: Array = []) -> void:
	if parent == null:
		return
	var dir: Vector2 = aim_pos - from_pos
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	match skill_name:
		"Fireball":
			_spawn(parent, {"kind": "fireball_cast", "pos": from_pos + dir * 28.0, "radius": 48.0, "lifetime": 0.34, "direction": dir, "tags": tags})
		"Storm Lance":
			_spawn(parent, {"kind": "storm_lance", "pos": from_pos + dir * 20.0, "start": from_pos + dir * 20.0, "end": from_pos + dir * 360.0, "radius": 120.0, "lifetime": 0.22, "direction": dir, "tags": tags})
		"Frost Nova":
			_spawn(parent, {"kind": "frost_nova", "pos": from_pos, "radius": 160.0, "lifetime": 0.52, "direction": dir, "tags": tags})
		"Void Rift":
			_spawn(parent, {"kind": "void_rift", "pos": aim_pos, "radius": 118.0, "lifetime": 0.74, "direction": dir, "tags": tags})
		"Cleave":
			var n: RVVisualProxyVFXNode = _spawn(parent, {"kind": "cleave_arc", "pos": from_pos + dir * 50.0, "radius": 96.0, "lifetime": 0.24, "direction": dir, "tags": tags})
			if n != null:
				n.rotation = dir.angle()
		"Blade Trap":
			_spawn(parent, {"kind": "blade_trap", "pos": aim_pos, "radius": 74.0, "lifetime": 0.76, "direction": dir, "tags": tags})
		_:
			_spawn(parent, {"kind": "impact", "pos": from_pos + dir * 42.0, "radius": 46.0, "lifetime": 0.32, "direction": dir, "tags": tags})

static func spawn_skill_impact(parent: Node, skill_name: String, pos: Vector2, tags: Array = []) -> void:
	if parent == null:
		return
	if tags.has("Fire") or tags.has("inflicts_burn") or skill_name == "Fireball":
		_spawn(parent, {"kind": "fireball_impact", "pos": pos, "radius": 58.0, "lifetime": 0.42, "tags": tags})
	elif tags.has("Lightning") or skill_name == "Storm Lance":
		_spawn(parent, {"kind": "storm_impact", "pos": pos, "radius": 48.0, "lifetime": 0.30, "tags": tags})
	elif tags.has("Cold") or skill_name == "Frost Nova":
		_spawn(parent, {"kind": "frost_nova", "pos": pos, "radius": 56.0, "lifetime": 0.34, "tags": tags})
	elif tags.has("Void") or skill_name == "Void Rift":
		_spawn(parent, {"kind": "void_rift", "pos": pos, "radius": 62.0, "lifetime": 0.44, "tags": tags})
	else:
		_spawn(parent, {"kind": "hit_spark", "pos": pos, "radius": 42.0, "lifetime": 0.28, "tags": tags})

static func spawn_enemy_hit(parent: Node, pos: Vector2, tags: Array = []) -> void:
	_spawn(parent, {"kind": "hit_spark", "pos": pos, "radius": 34.0, "lifetime": 0.22, "tags": tags})

static func _spawn(parent: Node, data: Dictionary) -> RVVisualProxyVFXNode:
	if parent == null:
		return null
	var node: RVVisualProxyVFXNode = RVVisualProxyVFXNode.new()
	parent.add_child(node)
	node.configure(data)
	return node
