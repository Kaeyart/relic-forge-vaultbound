class_name RVEnemyActor
extends Node2D

# Patch 068-071D: combat role/AI compatibility fields.
var windup: float = 0.35
var ai_timer: float = 0.0

signal died(enemy: RVEnemyActor)
signal damaged(enemy: RVEnemyActor, amount: float, tags: Array)
signal phase_changed(enemy: RVEnemyActor, phase: int)
signal hit_player(amount: float)
signal enemy_projectile_requested(pos: Vector2, velocity: Vector2, damage: float, radius: float, tags: Array)
signal enemy_zone_requested(pos: Vector2, radius: float, delay: float, duration: float, damage: float, tags: Array)
signal projectile_requested(payload: Dictionary)
signal zone_requested(payload: Dictionary)
signal spawn_requested(payload: Dictionary)

# Encounter metadata injected by map pack spawning / objective tracking.
var pack_id: String = ""
var encounter_role: String = ""
var encounter_pack_type: String = ""


# Patch 061-063: keeps the old EnemyActor API, but replaces debug-circle visuals
# with an animated visual proxy rig and clearer combat state timing.

var enemy_id: String = ""
var enemy_type: String = "Grunt"
var role: String = "chaser"
var hp: float = 50.0
var max_hp: float = 50.0
var speed: float = 80.0
var damage: float = 8.0
var radius: float = 15.0
var cooldown: float = 0.0
var enemy_color: Color = Color(0.75, 0.22, 0.14)
var max_poise: float = 40.0
var poise: float = 40.0
var stagger_timer: float = 0.0
var hit_flash_timer: float = 0.0
var last_damage_tags: Array = []
var statuses: Dictionary = {}
var dot_tick: float = 0.0

var ai_state: String = "idle"
var state_time: float = 0.0
var windup_time: float = 0.0
var recover_time: float = 0.0
var attack_direction: Vector2 = Vector2.RIGHT
var last_velocity: Vector2 = Vector2.ZERO
var dead_emitted: bool = false
var is_map_boss: bool = false
var is_elite: bool = false

var visual_rig: RVEnemyVisualRig = null


var aggro_range: float = 360.0
var attack_range: float = 72.0
var recovery: float = 0.75

func _ready() -> void:
	_ensure_visual_rig()
	set_process(true)

func setup(data: Dictionary) -> void:
	pack_id = str(data.get("pack_id", ""))
	encounter_role = str(data.get("encounter_role", data.get("role", "")))
	encounter_pack_type = str(data.get("pack_type", data.get("encounter_pack_type", "")))
	enemy_id = str(data.get("id", "enemy"))
	enemy_type = str(data.get("type", "Grunt"))
	role = str(data.get("role", "chaser"))
	global_position = data.get("pos", global_position)
	hp = float(data.get("hp", hp))
	max_hp = float(data.get("max_hp", hp))
	speed = float(data.get("speed", speed))
	damage = float(data.get("damage", damage))
	radius = float(data.get("radius", radius))
	enemy_color = data.get("color", enemy_color)
	is_map_boss = bool(data.get("is_map_boss", false)) or str(role).to_lower() == "boss"
	is_elite = bool(data.get("elite", false)) or str(enemy_type).to_lower().find("elite") >= 0
	statuses.clear()
	_apply_combat_role_tuning()
	cooldown = randf_range(0.10, 0.45)
	ai_state = "idle"
	state_time = 0.0
	dead_emitted = false
	_ensure_visual_rig()
	visual_rig.configure(enemy_type, role if not is_map_boss else "boss", radius, enemy_color)
	visual_rig.elite = is_elite
	visual_rig.boss = is_map_boss
	visual_rig.set_hp_ratio(hp / max(1.0, max_hp))
	queue_redraw()


func _apply_combat_role_tuning() -> void:
	# Patch 065: role-specific timings. Data can still override these later.
	match role:
		"shooter":
			aggro_range = max(aggro_range, 420.0)
			attack_range = max(attack_range, 330.0)
			windup = max(windup, 0.36)
			recovery = max(recovery, 0.88)
		"caster", "binder":
			aggro_range = max(aggro_range, 455.0)
			attack_range = max(attack_range, 360.0)
			windup = max(windup, 0.52)
			recovery = max(recovery, 1.02)
		"lunger", "hound":
			aggro_range = max(aggro_range, 355.0)
			attack_range = max(attack_range, 112.0)
			windup = clamp(windup, 0.24, 0.42)
			recovery = max(recovery, 0.74)
		"brute":
			attack_range = max(attack_range, 86.0)
			windup = max(windup, 0.66)
			recovery = max(recovery, 1.20)
		"knight":
			attack_range = max(attack_range, 72.0)
			windup = max(windup, 0.44)
			recovery = max(recovery, 0.92)
		"caller":
			aggro_range = max(aggro_range, 500.0)
			attack_range = max(attack_range, 390.0)
			windup = max(windup, 0.72)
			recovery = max(recovery, 1.45)
		"boss":
			aggro_range = max(aggro_range, 560.0)
			attack_range = max(attack_range, 118.0)
			windup = max(windup, 0.48)
			recovery = max(recovery, 0.92)
	if is_elite:
		max_hp *= 1.35
		hp = max(hp, max_hp)
		damage *= 1.18
		radius *= 1.08
	if is_map_boss:
		max_hp *= 1.65
		hp = max(hp, max_hp)
		damage *= 1.25
		radius *= 1.18

func _process(delta: float) -> void:
	_update_statuses(delta)
	_rf_update_combat_juice_timers(delta)
	state_time += delta
	if visual_rig != null:
		visual_rig.set_hp_ratio(hp / max(1.0, max_hp))
		visual_rig.set_visual_state(ai_state, last_velocity)
	queue_redraw()

func update_ai(player_pos: Vector2, delta: float) -> void:
	if hp <= 0.0:
		return
	if is_staggered():
		queue_redraw()
		return
	cooldown = max(0.0, cooldown - delta)
	windup_time = max(0.0, windup_time - delta)
	recover_time = max(0.0, recover_time - delta)

	var to_player: Vector2 = player_pos - global_position
	var distance: float = to_player.length()
	var direction: Vector2 = to_player / distance if distance > 0.01 else Vector2.ZERO
	if direction.length() > 0.01:
		attack_direction = direction
	var actual_speed: float = speed * _status_speed_multiplier()
	last_velocity = Vector2.ZERO

	if windup_time > 0.0:
		ai_state = "windup"
		return
	if recover_time > 0.0:
		ai_state = "recover"
		return

	var role_key: String = role.to_lower()
	if is_map_boss or role_key == "boss":
		_update_boss_ai(direction, distance, actual_speed, delta)
	elif role_key == "shooter" or role_key == "spitter" or enemy_type.to_lower().find("spitter") >= 0:
		_update_ranged_ai(direction, distance, actual_speed, delta)
	elif role_key == "acolyte" or role_key == "caster" or role_key == "binder" or enemy_type.to_lower().find("binder") >= 0:
		_update_caster_ai(direction, distance, actual_speed, delta)
	elif role_key == "brute" or enemy_type.to_lower().find("brute") >= 0:
		_update_brute_ai(direction, distance, actual_speed, delta)
	elif role_key == "hound" or enemy_type.to_lower().find("lunger") >= 0 or enemy_type.to_lower().find("hound") >= 0:
		_update_lunger_ai(direction, distance, actual_speed, delta)
	else:
		_update_melee_ai(direction, distance, actual_speed, delta)

func _update_melee_ai(direction: Vector2, distance: float, actual_speed: float, delta: float) -> void:
	if distance > radius + 26.0:
		_move(direction * actual_speed * delta)
	else:
		ai_state = "idle"
		if cooldown <= 0.0:
			_start_attack(0.22, 0.36, 0.70)

func _update_lunger_ai(direction: Vector2, distance: float, actual_speed: float, delta: float) -> void:
	if distance > 78.0:
		_move(direction * actual_speed * 1.18 * delta)
	else:
		ai_state = "idle"
	if distance < 190.0 and cooldown <= 0.0:
		_start_attack(0.42, 0.46, 1.30)

func _update_brute_ai(direction: Vector2, distance: float, actual_speed: float, delta: float) -> void:
	if distance > 74.0:
		_move(direction * actual_speed * 0.72 * delta)
	else:
		ai_state = "idle"
	if distance < 138.0 and cooldown <= 0.0:
		_start_attack(0.58, 0.64, 1.55)

func _update_ranged_ai(direction: Vector2, distance: float, actual_speed: float, delta: float) -> void:
	if distance < 210.0:
		_move(-direction * actual_speed * 0.72 * delta)
	elif distance > 330.0:
		_move(direction * actual_speed * 0.78 * delta)
	else:
		ai_state = "idle"
	if distance < 430.0 and cooldown <= 0.0:
		_start_attack(0.38, 0.34, 1.18)

func _update_caster_ai(direction: Vector2, distance: float, actual_speed: float, delta: float) -> void:
	if distance < 230.0:
		_move(-direction.rotated(0.35) * actual_speed * 0.55 * delta)
	elif distance > 410.0:
		_move(direction * actual_speed * 0.62 * delta)
	else:
		ai_state = "idle"
	if distance < 480.0 and cooldown <= 0.0:
		_start_attack(0.52, 0.46, 1.38)

func _update_boss_ai(direction: Vector2, distance: float, actual_speed: float, delta: float) -> void:
	var phase_speed: float = 1.0
	if hp / max(1.0, max_hp) < 0.35:
		phase_speed = 1.20
	if distance > 104.0:
		_move(direction * actual_speed * 0.62 * phase_speed * delta)
	else:
		ai_state = "idle"
	if distance < 175.0 and cooldown <= 0.0:
		_start_attack(0.62, 0.58, 1.35 / phase_speed)

func _move(delta_pos: Vector2) -> void:
	global_position += delta_pos
	last_velocity = delta_pos
	ai_state = "move" if delta_pos.length() > 0.001 else "idle"

func _start_attack(windup: float, recover: float, cd: float) -> void:
	ai_state = "windup"
	windup_time = windup
	recover_time = windup + recover
	cooldown = cd
	call_deferred("_resolve_attack_after_windup", windup)

func _resolve_attack_after_windup(_delay: float) -> void:
	if hp <= 0.0:
		return
	await get_tree().create_timer(max(0.02, windup_time)).timeout
	if hp <= 0.0:
		return
	ai_state = "attack"
	# Existing combat API only requires hit_player. Ranged/caster roles still apply readable pressure.
	var damage_mult: float = 1.0
	if role.to_lower() == "brute" or is_map_boss:
		damage_mult = 1.45
	hit_player.emit(damage * damage_mult)
	if visual_rig != null:
		visual_rig.set_visual_state("attack", attack_direction)

func take_damage(amount: float, tags: Array = [], source_skill: String = "") -> void:
	if hp <= 0.0:
		return
	var final_amount: float = amount
	if has_status("curse"):
		final_amount *= 1.16
	if has_status("shock"):
		final_amount *= 1.08
	hp -= final_amount
	last_damage_tags = tags.duplicate(true)
	flash_hit()
	apply_stagger(final_amount, tags)
	if has_signal("damaged"):
		damaged.emit(self, final_amount, tags)
		if visual_rig != null:
			pass # PATCH_068_071A: parser guard for previously empty generated block
		visual_rig.pulse_hit()
	if hp <= 0.0:
		_die_once()
	queue_redraw()

func _die_once() -> void:
	if dead_emitted:
		return
	dead_emitted = true
	ai_state = "death"
	if visual_rig != null:
		visual_rig.play_death()
	died.emit(self)

func apply_status(status_id: String, duration: float, power: float = 1.0) -> void:
	if status_id == "":
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
	var direction: Vector2 = center - global_position
	if direction.length() <= 0.01:
		return
	global_position += direction.normalized() * amount
	last_velocity = direction.normalized() * amount

func _status_speed_multiplier() -> float:
	var speed_mult: float = 1.0
	if has_status("freeze"):
		speed_mult *= 0.30
	if has_status("shock"):
		speed_mult *= 0.86
	if has_status("curse"):
		speed_mult *= 0.92
	return speed_mult

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
		var status: Dictionary = statuses[status_id]
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
		_die_once()
	queue_redraw()

func _ensure_visual_rig() -> void:
	if visual_rig != null and is_instance_valid(visual_rig):
		return
	visual_rig = RVEnemyVisualRig.new()
	visual_rig.name = "VisualRig"
	visual_rig.z_index = -1
	add_child(visual_rig)


func _rf_apply_combat_juice_profile(data: Dictionary = {}) -> void:
	max_poise = float(data.get("poise", _rf_default_poise()))
	if is_elite:
		max_poise *= 1.45
	if is_map_boss or role == "boss":
		max_poise *= 3.00
	poise = max_poise
	stagger_timer = 0.0
	hit_flash_timer = 0.0

func _rf_default_poise() -> float:
	match role:
		"hound", "lunger": return 28.0
		"shooter", "caster", "binder", "caller": return 34.0
		"knight": return 56.0
		"brute": return 88.0
		"boss": return 160.0
	return 42.0

func _rf_update_combat_juice_timers(delta: float) -> void:
	if stagger_timer > 0.0:
		stagger_timer = max(0.0, stagger_timer - delta)
		if stagger_timer <= 0.0 and ai_state == "stagger":
			ai_state = "aggro"
	if hit_flash_timer > 0.0:
		hit_flash_timer = max(0.0, hit_flash_timer - delta)
	if poise < max_poise:
		poise = min(max_poise, poise + max_poise * 0.28 * delta)

func is_staggered() -> bool:
	return stagger_timer > 0.0 or ai_state == "stagger"

func apply_stagger(amount: float, tags: Array = []) -> void:
	var poise_damage: float = amount
	if tags.has("Heavy") or tags.has("Slam") or tags.has("Explosion"):
		poise_damage *= 1.35
	if tags.has("Storm") or tags.has("Lightning"):
		poise_damage *= 1.10
	if is_map_boss:
		poise_damage *= 0.22
	elif is_elite:
		poise_damage *= 0.58
	poise -= poise_damage
	if poise <= 0.0:
		poise = max_poise
		stagger_timer = 0.16
		if is_elite:
			stagger_timer = 0.12
		if is_map_boss:
			stagger_timer = 0.08
		ai_state = "stagger"
		ai_timer = stagger_timer
		queue_redraw()

func flash_hit() -> void:
	hit_flash_timer = 0.12
	modulate = Color(1.55, 1.35, 1.10, 1.0)
	if is_inside_tree():
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.12)

func _draw() -> void:
	_draw_status_rings()
	_draw_health_bar()

func _draw_health_bar() -> void:
	var pct: float = clamp(hp / max(1.0, max_hp), 0.0, 1.0)
	var bar_width: float = max(26.0, radius * 2.0)
	var y: float = -radius * float(RVEnemyShapeKitDB.profile(enemy_type, role).get("scale", 1.0)) - 15.0
	draw_rect(Rect2(Vector2(-bar_width * 0.5, y), Vector2(bar_width, 4.0)), Color(0.08, 0.03, 0.03, 0.80), true)
	draw_rect(Rect2(Vector2(-bar_width * 0.5, y), Vector2(bar_width * pct, 4.0)), Color(0.90, 0.18, 0.12), true)

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
