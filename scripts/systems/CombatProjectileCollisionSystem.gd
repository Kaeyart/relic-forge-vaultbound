class_name RVCombatProjectileCollisionSystem
extends RefCounted

# Patch 083C: projectile collision façade. CombatArena still owns the gameplay
# call sites for now; this system centralizes the geometry dependency for the
# next decomposition pass.

static func resolve(layout: Dictionary, previous_pos: Vector2, current_pos: Vector2, velocity: Vector2, radius: float = 5.0, bounces_remaining: int = 0) -> Dictionary:
	if layout.is_empty():
		return {"hit": false, "position": current_pos, "velocity": velocity, "bounces_remaining": bounces_remaining}
	return RVCombatGeometrySystem.resolve_projectile_segment(layout, previous_pos, current_pos, velocity, radius, bounces_remaining)

static func has_line_of_sight(layout: Dictionary, from_pos: Vector2, to_pos: Vector2, padding: float = 10.0) -> bool:
	if layout.is_empty():
		return true
	return RVCombatGeometrySystem.has_line_of_sight(layout, from_pos, to_pos, padding)
