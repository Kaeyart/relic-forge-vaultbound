class_name RVBossPhaseDirector
extends RefCounted

# Patch 071: simple boss phase production layer.
# Bosses now announce phases and spawn distinct pressure when phase changes.

static func on_phase_changed(arena: Node, state: RVGameState, enemy: Node, phase: int) -> void:
	if enemy == null:
		return
	var pos: Vector2 = Vector2.ZERO
	if enemy is Node2D:
		pos = (enemy as Node2D).global_position
	var root: Node2D = arena as Node2D
	if arena != null and arena.has_method("_ensure_vfx_root"):
		var value: Variant = arena.call("_ensure_vfx_root")
		if value is Node2D:
			root = value as Node2D
	RVCombatJuiceSystem.boss_phase_feedback(arena as Node2D, root, pos, phase)
	if state != null:
		state.add_notice("Boss phase " + str(phase))
	if enemy.has_signal("spawn_requested"):
		if phase == 2:
			enemy.emit_signal("spawn_requested", "Spitter", pos + Vector2(70.0, 0.0), 2)
		elif phase >= 3:
			enemy.emit_signal("spawn_requested", "Hound", pos + Vector2(70.0, 0.0), 3)
	if enemy.has_signal("zone_requested"):
		if phase >= 2:
			enemy.emit_signal("zone_requested", pos, 104.0, 0.32, 0.28, float(enemy.get("damage")) * 0.65, ["Enemy", "Boss", "Phase"], Color(1.0, 0.18, 0.05, 0.25))
		if phase >= 3:
			enemy.emit_signal("zone_requested", pos + Vector2(88.0, 0.0), 62.0, 0.55, 0.32, float(enemy.get("damage")) * 0.80, ["Enemy", "Boss", "Fire"], Color(1.0, 0.32, 0.05, 0.25))
			enemy.emit_signal("zone_requested", pos + Vector2(-88.0, 0.0), 62.0, 0.55, 0.32, float(enemy.get("damage")) * 0.80, ["Enemy", "Boss", "Fire"], Color(1.0, 0.32, 0.05, 0.25))
