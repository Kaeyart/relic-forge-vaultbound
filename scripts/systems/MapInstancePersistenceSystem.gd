class_name RVMapInstancePersistenceSystem
extends RefCounted

const CombatRootSystemScript := preload("res://scripts/systems/CombatRootSystem.gd")

# Patch 083D: parse-safe map-instance snapshot helpers.
# This file intentionally avoids a custom _get() helper because Object already
# owns _get(StringName). It also uses a preload alias instead of referencing the
# RVCombatRootSystem global class directly, which avoids class-registration order
# failures during Godot's script parse pass.

static func capture_basic(arena: Object, state: Object = null) -> Dictionary:
	if arena == null:
		return {}
	var snapshot: Dictionary = {
		"version": 1,
		"activity": _dict_get(arena, "activity"),
		"map_layout": _dict_get(arena, "map_layout"),
		"encounter_plan": _dict_get(arena, "encounter_plan"),
		"room_clear": bool(_state_get(arena, "room_clear", false)),
		"reward_claimed": bool(_state_get(arena, "reward_claimed", false)),
		"map_pack_total": int(_state_get(arena, "map_pack_total", 0)),
		"map_pack_cleared": int(_state_get(arena, "map_pack_cleared", 0)),
		"map_boss_alive": bool(_state_get(arena, "map_boss_alive", false)),
		"player_pos": _state_get(state, "player_pos", Vector2.ZERO) if state != null else Vector2.ZERO,
		"enemy_snapshots": [],
		"loot_snapshots": [],
	}

	var enemies_root: Variant = _call_or_null(arena, "_rf_live_enemies_root")
	for enemy_node: Node in CombatRootSystemScript.safe_children(enemies_root):
		if enemy_node == null or not is_instance_valid(enemy_node) or enemy_node.is_queued_for_deletion():
			continue
		if enemy_node is Node2D:
			snapshot["enemy_snapshots"].append(_capture_enemy(enemy_node as Node2D))

	var loot_root: Variant = _call_or_null(arena, "_rf_loot_root")
	for loot_node: Node in CombatRootSystemScript.safe_children(loot_root):
		if loot_node == null or not is_instance_valid(loot_node) or loot_node.is_queued_for_deletion():
			continue
		if loot_node is Node2D:
			snapshot["loot_snapshots"].append(_capture_loot(loot_node as Node2D))
	return snapshot

static func _capture_enemy(enemy: Node2D) -> Dictionary:
	return {
		"pos": enemy.global_position,
		"hp": _state_get(enemy, "hp", 1.0),
		"max_hp": _state_get(enemy, "max_hp", 1.0),
		"type": str(_state_get(enemy, "enemy_type", "Grunt")),
		"role": str(_state_get(enemy, "role", "chaser")),
		"pack_id": str(_state_get(enemy, "pack_id", "")),
		"is_map_boss": bool(_state_get(enemy, "is_map_boss", false)),
		"elite": bool(_state_get(enemy, "is_elite", false)),
		"radius": float(_state_get(enemy, "radius", 15.0)),
		"damage": float(_state_get(enemy, "damage", 8.0)),
		"speed": float(_state_get(enemy, "speed", 80.0)),
	}

static func _capture_loot(loot: Node2D) -> Dictionary:
	return {"pos": loot.global_position, "payload": _dict_get(loot, "payload")}

static func _state_get(obj: Object, key: String, fallback: Variant = null) -> Variant:
	if obj == null:
		return fallback
	var value: Variant = obj.get(key)
	return fallback if value == null else value

static func _dict_get(obj: Object, key: String) -> Dictionary:
	var value: Variant = _state_get(obj, key, {})
	return Dictionary(value) if typeof(value) == TYPE_DICTIONARY else {}

static func _call_or_null(obj: Object, method_name: String) -> Variant:
	if obj != null and obj.has_method(method_name):
		return obj.call(method_name)
	return null
