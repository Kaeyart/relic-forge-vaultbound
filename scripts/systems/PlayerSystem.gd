class_name RVPlayerSystem
extends RefCounted

static func update(state: RVGameState, delta: float) -> void:
	var move: Vector2 = Vector2.ZERO

	if Input.is_key_pressed(KEY_W): move.y -= 1.0
	if Input.is_key_pressed(KEY_S): move.y += 1.0
	if Input.is_key_pressed(KEY_A): move.x -= 1.0
	if Input.is_key_pressed(KEY_D): move.x += 1.0

	if move.length() > 0.01:
		move = move.normalized()
		state.player_pos += move * state.player_speed * delta

	if state.mode == "hub":
		state.player_pos.x = clamp(state.player_pos.x, state.hub_bounds.position.x, state.hub_bounds.end.x)
		state.player_pos.y = clamp(state.player_pos.y, state.hub_bounds.position.y, state.hub_bounds.end.y)
	else:
		state.player_pos.x = clamp(state.player_pos.x, state.arena.position.x + state.player_radius, state.arena.end.x - state.player_radius)
		state.player_pos.y = clamp(state.player_pos.y, state.arena.position.y + state.player_radius, state.arena.end.y - state.player_radius)

	state.invuln = max(0.0, state.invuln - delta)
	state.player_mana = min(state.max_mana, state.player_mana + 12.0 * delta)
