class_name RVCombatRootSystem
extends RefCounted

# Patch 083D: parse-safe root/layer helpers for CombatArena.

static func node_alive(value: Variant) -> bool:
	return value != null and is_instance_valid(value) and value is Node and not (value as Node).is_queued_for_deletion()

static func safe_children(root: Variant) -> Array:
	if not node_alive(root):
		return []
	return (root as Node).get_children()

static func child_count(root: Variant) -> int:
	if not node_alive(root):
		return 0
	return (root as Node).get_child_count()

static func clear_children(root: Variant) -> void:
	for child: Node in safe_children(root):
		if child != null and is_instance_valid(child) and not child.is_queued_for_deletion():
			child.queue_free()

static func named_node2d(owner: Node, node_name: String, z: int = 0) -> Node2D:
	if owner == null or not is_instance_valid(owner) or owner.is_queued_for_deletion():
		return null
	var node: Node2D = owner.get_node_or_null(node_name) as Node2D
	if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
		node = Node2D.new()
		node.name = node_name
		owner.add_child(node)
	node.z_as_relative = false
	node.z_index = z
	return node

static func live_node2d(owner: Node, field_name: String, node_name: String, z: int = 0) -> Node2D:
	if owner == null or not is_instance_valid(owner) or owner.is_queued_for_deletion():
		return null
	var current_value: Variant = owner.get(field_name)
	if current_value != null and is_instance_valid(current_value) and current_value is Node2D and not (current_value as Node2D).is_queued_for_deletion():
		return current_value as Node2D
	var found: Node2D = owner.get_node_or_null(node_name) as Node2D
	if found == null or not is_instance_valid(found) or found.is_queued_for_deletion():
		found = Node2D.new()
		found.name = node_name
		owner.add_child(found)
	found.z_as_relative = false
	found.z_index = z
	owner.set(field_name, found)
	return found

static func ensure_standard_layers(arena: Node) -> Dictionary:
	var result: Dictionary = {}
	if arena == null or not is_instance_valid(arena) or arena.is_queued_for_deletion():
		return result
	result["enemies"] = live_node2d(arena, "enemies_root", "Enemies", 20)
	result["projectiles"] = live_node2d(arena, "projectiles_root", "Projectiles", 40)
	result["map_ground"] = named_node2d(arena, "MapGroundLayer", -100)
	result["map_dressing"] = named_node2d(arena, "MapDressingLayer", -50)
	result["telegraphs"] = named_node2d(arena, "GroundTelegraphLayer", -20)
	result["loot"] = named_node2d(arena, "GroundLootLayer", 8)
	result["floating_text"] = named_node2d(arena, "FloatingCombatTextLayer", 120)
	return result
