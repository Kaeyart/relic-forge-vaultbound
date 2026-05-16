class_name RVEnemyActor
extends Node2D
const EnemyVisualRigScript := preload("res://scripts/visuals/EnemyVisualRig.gd")

signal died(enemy: RVEnemyActor)
signal hit_player(amount: float)
signal projectile_requested(pos: Vector2, vel: Vector2, damage: float, radius: float, tags: Array)
signal zone_requested(pos: Vector2, radius: float, delay: float, duration: float, damage: float, tags: Array, color: Color)
signal spawn_requested(enemy_type: String, pos: Vector2, count: int)

var enemy_id: String = ""
var enemy_type: String = "Grunt"
var role: String = "chaser"
var hp: float = 50.0
var max_hp: float = 50.0
var speed: float = 80.0
var damage: float = 8.0
var radius: float = 15.0
var enemy_color: Color = Color(0.75, 0.22, 0.14)

var statuses: Dictionary = {}
var dot_tick: float = 0.0
var visual_rig: Node2D = null

var ai_state: String = "idle"
var ai_timer: float = 0.0
var cooldown: float = 0.0
var attack_dir: Vector2 = Vector2.RIGHT
var attack_target: Vector2 = Vector2.ZERO
var attack_kind: String = ""
var aggro_range: float = 300.0
var attack_range: float = 48.0
var windup: float = 0.35
var recovery: float = 0.70
var wake_radius: float = 300.0
var leash_center: Vector2 = Vector2.ZERO
var leash_radius: float = 260.0
var pack_id: String = ""
var is_elite: bool = false
var is_map_boss: bool = false
var boss_phase: int = 1
var summon_count: int = 0
var xp_value: float = 10.0

func setup(data: Dictionary) -> void:
	enemy_id = str(data.get("id", "enemy"))
	enemy_type = str(data.get("type", "Grunt"))
	role = str(data.get("role", "chaser"))
	global_position = Vector2(data.get("pos", global_position))
	hp = float(data.get("hp", hp))
	max_hp = float(data.get("max_hp", hp))
	speed = float(data.get("speed", speed))
	damage = float(data.get("damage", damage))
	radius = float(data.get("radius", radius))
	aggro_range = float(data.get("aggro_range", aggro_range))
	attack_range = float(data.get("attack_range", attack_range))
	windup = float(data.get("windup", windup))
	recovery = float(data.get("recovery", recovery))
	wake_radius = float(data.get("wake_radius", aggro_range))
	leash_center = Vector2(data.get("leash_center", global_position))
	leash_radius = float(data.get("leash_radius", leash_radius))
	pack_id = str(data.get("pack_id", ""))
	is_elite = bool(data.get("is_elite", false))
	is_map_boss = bool(data.get("is_map_boss", false))
	xp_value = float(data.get("xp", 10.0))
	enemy_color = data.get("color", enemy_color)
	statuses.clear()
	_sync_visual_proxy(data)
	ai_state = "idle"
	ai_timer = 0.0
	cooldown = randf_range(0.05, 0.40)
	boss_phase = 1
	summon_count = 0
	queue_redraw()

func _process(delta: float) -> void:
	_update_statuses(delta)
	_sync_visual_statuses()

func update_ai(player_pos: Vector2, delta: float) -> void:
	if hp <= 0.0:
		return
	cooldown = max(0.0, cooldown - delta)
	var to_player: Vector2 = player_pos - global_position
	var distance: float = to_player.length()
	var dir: Vector2 = to_player.normalized() if distance > 0.01 else Vector2.RIGHT
	_update_boss_phase()
	if ai_state == "idle":
		if distance <= wake_radius:
			ai_state = "aggro"
		else:
			queue_redraw()
			return
	if ai_state == "windup":
		ai_timer -= delta
		if ai_timer <= 0.0:
			_execute_attack(player_pos)
			ai_state = "recover"
			ai_timer = recovery * _phase_speed_mult()
		queue_redraw()
		return
	if ai_state == "recover":
		ai_timer -= delta
		if ai_timer <= 0.0:
			ai_state = "aggro"
		queue_redraw()
		return
	if ai_state == "special":
		ai_timer -= delta
		if ai_timer <= 0.0:
			ai_state = "aggro"
		queue_redraw()
		return
	var actual_speed: float = speed * _status_speed_mult() * _phase_move_mult()
	if global_position.distance_to(leash_center) > leash_radius:
		var home_dir: Vector2 = (leash_center - global_position).normalized()
		global_position += home_dir * actual_speed * 1.25 * delta
		queue_redraw()
		return
	match role:
		"shooter":
			_ranged_move_and_attack(dir, distance, actual_speed, delta, "shot")
		"caster", "binder":
			_ranged_move_and_attack(dir, distance, actual_speed, delta, "zone")
		"lunger", "hound":
			_lunger_move_and_attack(dir, distance, actual_speed, delta)
		"brute", "knight":
			_brute_move_and_attack(dir, distance, actual_speed, delta)
		"caller":
			_caller_ai(dir, distance, actual_speed, delta)
		"boss":
			_boss_ai(dir, distance, actual_speed, delta)
		_:
			_chaser_move_and_attack(dir, distance, actual_speed, delta)
	queue_redraw()

func _chaser_move_and_attack(dir: Vector2, distance: float, actual_speed: float, delta: float) -> void:
	if distance > attack_range:
		global_position += dir * actual_speed * delta
	elif cooldown <= 0.0:
		_start_attack("melee", dir, windup)

func _lunger_move_and_attack(dir: Vector2, distance: float, actual_speed: float, delta: float) -> void:
	if distance > attack_range:
		global_position += dir * actual_speed * delta
	elif cooldown <= 0.0:
		_start_attack("lunge", dir, windup)

func _brute_move_and_attack(dir: Vector2, distance: float, actual_speed: float, delta: float) -> void:
	if distance > attack_range:
		global_position += dir * actual_speed * 0.88 * delta
	elif cooldown <= 0.0:
		_start_attack("slam", dir, windup)

func _ranged_move_and_attack(dir: Vector2, distance: float, actual_speed: float, delta: float, kind: String) -> void:
	if distance < attack_range * 0.55:
		global_position -= dir * actual_speed * 0.78 * delta
	elif distance > attack_range:
		global_position += dir * actual_speed * 0.55 * delta
	if cooldown <= 0.0 and distance <= aggro_range:
		_start_attack(kind, dir, windup)

func _caller_ai(dir: Vector2, distance: float, actual_speed: float, delta: float) -> void:
	if distance < 210.0:
		global_position -= dir * actual_speed * 0.60 * delta
	if cooldown <= 0.0:
		_start_attack("summon", dir, windup)

func _boss_ai(dir: Vector2, distance: float, actual_speed: float, delta: float) -> void:
	if distance > attack_range:
		global_position += dir * actual_speed * delta
	if cooldown <= 0.0:
		var pattern: String = "boss_cleave"
		if boss_phase >= 2 and summon_count % 3 == 1:
			pattern = "boss_zone"
		elif boss_phase >= 3 and summon_count % 3 == 2:
			pattern = "boss_summon"
		elif distance > 150.0:
			pattern = "boss_charge"
		_start_attack(pattern, dir, max(0.28, windup - float(boss_phase - 1) * 0.08))
		summon_count += 1

func _start_attack(kind: String, dir: Vector2, time: float) -> void:
	attack_kind = kind
	attack_dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	attack_target = global_position + attack_dir * attack_range
	ai_state = "windup"
	ai_timer = time
	cooldown = recovery + time + 0.28

func _execute_attack(player_pos: Vector2) -> void:
	match attack_kind:
		"melee":
			if global_position.distance_to(player_pos) <= radius + 34.0:
				hit_player.emit(damage)
		"lunge":
			global_position += attack_dir * 102.0
			if global_position.distance_to(player_pos) <= radius + 34.0:
				hit_player.emit(damage * 1.20)
		"slam":
			zone_requested.emit(global_position + attack_dir * 38.0, 58.0, 0.08, 0.18, damage * 1.35, ["Enemy", "Area", "Slam"], Color(1.0, 0.62, 0.16, 0.28))
		"shot":
			projectile_requested.emit(global_position + attack_dir * (radius + 8.0), attack_dir * 330.0, damage, 8.0, ["Enemy", "Projectile"])
		"zone":
			var color: Color = Color(1.0, 0.25, 0.05, 0.30) if role == "caster" else Color(0.63, 0.25, 1.0, 0.28)
			var tags: Array = ["Enemy", "Area", "Fire"] if role == "caster" else ["Enemy", "Area", "Curse"]
			zone_requested.emit(attack_target, 52.0, 0.42, 0.24, damage * 1.08, tags, color)
		"summon":
			spawn_requested.emit("Grunt", global_position + attack_dir.rotated(0.9) * 52.0, 2)
		"boss_cleave":
			zone_requested.emit(global_position + attack_dir * 58.0, 72.0, 0.14, 0.22, damage * 1.20, ["Enemy", "Melee", "Boss"], Color(1.0, 0.40, 0.12, 0.32))
		"boss_zone":
			zone_requested.emit(player_pos, 74.0, 0.58, 0.35, damage * 1.10, ["Enemy", "Area", "Boss"], Color(0.92, 0.18, 0.06, 0.30))
		"boss_charge":
			global_position += attack_dir * 138.0
			zone_requested.emit(global_position, 62.0, 0.06, 0.18, damage * 1.05, ["Enemy", "Charge", "Boss"], Color(1.0, 0.70, 0.20, 0.26))
		"boss_summon":
			spawn_requested.emit("Grunt", global_position + attack_dir.rotated(1.25) * 70.0, 2)
			spawn_requested.emit("Spitter", global_position + attack_dir.rotated(-1.25) * 70.0, 1)

func _update_boss_phase() -> void:
	if not is_map_boss:
		return
	var pct: float = hp / max(1.0, max_hp)
	var new_phase: int = 1
	if pct <= 0.30:
		new_phase = 3
	elif pct <= 0.65:
		new_phase = 2
	if new_phase != boss_phase:
		boss_phase = new_phase
		ai_state = "recover"
		ai_timer = 0.35
		cooldown = 0.35

func take_damage(amount: float) -> void:
	var final_amount: float = amount
	if has_status("curse"):
		final_amount *= 1.16
	if has_status("shock"):
		final_amount *= 1.08
	hp -= final_amount
	_visual_hit_flash()
	if hp <= 0.0:
		died.emit(self)
	queue_redraw()

func apply_status(status_id: String, duration: float, power: float = 1.0) -> void:
	if status_id == "" or is_map_boss and status_id == "freeze":
		return
	var current: Dictionary = statuses.get(status_id, {})
	current["time"] = max(float(current.get("time", 0.0)), duration)
	current["power"] = max(float(current.get("power", 0.0)), power)
	statuses[status_id] = current
	queue_redraw()

func has_status(status_id: String) -> bool:
	if not statuses.has(status_id):
		return false
	return float(Dictionary(statuses[status_id]).get("time", 0.0)) > 0.0

func pull_toward(center: Vector2, amount: float) -> void:
	if is_map_boss:
		amount *= 0.25
	var direction: Vector2 = center - global_position
	if direction.length() <= 0.01:
		return
	global_position += direction.normalized() * amount

func _status_speed_mult() -> float:
	var mult: float = 1.0
	if has_status("freeze"):
		mult *= 0.30
	if has_status("shock"):
		mult *= 0.86
	if has_status("curse"):
		mult *= 0.92
	return mult

func _phase_move_mult() -> float:
	if not is_map_boss:
		return 1.0
	return 1.0 + float(boss_phase - 1) * 0.10

func _phase_speed_mult() -> float:
	if not is_map_boss:
		return 1.0
	return max(0.70, 1.0 - float(boss_phase - 1) * 0.12)

func _update_statuses(delta: float) -> void:
	if statuses.is_empty():
		return
	dot_tick -= delta
	var do_dot: bool = false
	if dot_tick <= 0.0:
		dot_tick = 0.35
		do_dot = true
	var to_remove: Array[String] = []
	for status_id: Variant in statuses.keys():
		var status: Dictionary = Dictionary(statuses[status_id])
		status["time"] = max(0.0, float(status.get("time", 0.0)) - delta)
		if do_dot:
			var power: float = float(status.get("power", 1.0))
			match str(status_id):
				"burn": hp -= 1.8 * power
				"bleed": hp -= 1.3 * power
		if float(status.get("time", 0.0)) <= 0.0:
			to_remove.append(str(status_id))
		else:
			statuses[status_id] = status
	for status_name: String in to_remove:
		statuses.erase(status_name)
	if hp <= 0.0:
		died.emit(self)
	queue_redraw()

func _draw() -> void:
	# Patch 059: enemy body is now drawn by EnemyVisualRig. This node only draws health.
	var pct: float = clamp(hp / max(1.0, max_hp), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-radius, -radius - 12.0), Vector2(radius * 2.0, 4.0)), Color(0.08, 0.03, 0.03, 0.80), true)
	draw_rect(Rect2(Vector2(-radius, -radius - 12.0), Vector2(radius * 2.0 * pct, 4.0)), Color(0.90, 0.18, 0.12), true)
func _draw_status_rings() -> void:
	var ring_radius: float = radius + 4.0
	if has_status("burn"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(1.0, 0.28, 0.05, 0.75), 2.0)
		ring_radius += 3.0
	if has_status("freeze"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(0.45, 0.85, 1.0, 0.72), 2.0)
		ring_radius += 3.0
	if has_status("curse"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(0.70, 0.26, 1.0, 0.72), 2.0)
		ring_radius += 3.0
	if has_status("bleed"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(0.72, 0.02, 0.02, 0.72), 2.0)
		ring_radius += 3.0
	if has_status("shock"):
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 24, Color(0.75, 0.95, 1.0, 0.72), 2.0)

func _sync_visual_proxy(data: Dictionary = {}) -> void:
	_ensure_visual_proxy()
	if visual_rig != null and visual_rig.has_method("apply_profile"):
		visual_rig.call("apply_profile", enemy_type, role, radius, enemy_color, data)
	_sync_visual_statuses()

func _ensure_visual_proxy() -> void:
	if visual_rig != null and is_instance_valid(visual_rig):
		return
	visual_rig = EnemyVisualRigScript.new()
	visual_rig.name = "EnemyVisualRig"
	visual_rig.z_index = -1
	add_child(visual_rig)
	move_child(visual_rig, 0)

func _sync_visual_statuses() -> void:
	if visual_rig != null and is_instance_valid(visual_rig) and visual_rig.has_method("update_statuses"):
		visual_rig.call("update_statuses", statuses)

func _visual_hit_flash() -> void:
	if visual_rig != null and is_instance_valid(visual_rig) and visual_rig.has_method("flash_hit"):
		visual_rig.call("flash_hit")
