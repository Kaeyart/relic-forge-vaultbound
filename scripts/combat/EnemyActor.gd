class_name RVEnemyActor
extends CharacterBody2D

signal died(enemy: RVEnemyActor)

@export var max_life: float = 60.0
@export var damage: float = 10.0
@export var move_speed: float = 82.0
@export var radius: float = 16.0

var life: float = 60.0
var state: RVGameState
var attack_cd: float = 0.0

func setup(p_state: RVGameState, threat: float) -> void:
	state = p_state
	life = max_life * threat
	damage *= threat

func _physics_process(delta: float) -> void:
	if state == null or state.mode != "combat":
		return
	attack_cd = max(0.0, attack_cd - delta)
	var to_player: Vector2 = state.player_pos - global_position
	var dist: float = to_player.length()
	var dir: Vector2 = Vector2.ZERO
	if dist > 0.01:
		dir = to_player / dist
	velocity = dir * move_speed
	move_and_slide()
	if dist <= radius + state.player_radius + 5.0 and attack_cd <= 0.0:
		if state.invuln <= 0.0:
			state.player_hp -= damage
			state.invuln = 0.45
			state.add_notice("Hit: -" + str(int(damage)) + " Life")
		attack_cd = 0.75

func take_damage(amount: float) -> void:
	life -= amount
	if life <= 0.0:
		died.emit(self)
		queue_free()
