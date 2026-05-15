class_name RVPlayerController
extends CharacterBody2D

@export var move_speed: float = 235.0
var state: RVGameState

func setup(p_state: RVGameState) -> void:
	state = p_state
	if state != null:
		global_position = state.player_pos

func _physics_process(_delta: float) -> void:
	var move: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): move.y -= 1.0
	if Input.is_key_pressed(KEY_S): move.y += 1.0
	if Input.is_key_pressed(KEY_A): move.x -= 1.0
	if Input.is_key_pressed(KEY_D): move.x += 1.0
	if move.length() > 0.01:
		move = move.normalized()
	velocity = move * move_speed
	move_and_slide()
	if state != null:
		state.player_pos = global_position
