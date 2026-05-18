class_name RVCombatRewardExitSystem
extends RefCounted

# Patch 083C: reward/exit state helper. This is not yet a full replacement for
# CombatArena.interact(); it gives us a clean target for the next refactor.

static func set_reward_visible(reward_node: Variant, value: bool) -> void:
	if reward_node != null and is_instance_valid(reward_node) and reward_node is CanvasItem:
		(reward_node as CanvasItem).visible = value

static func set_exit_visible(exit_node: Variant, value: bool) -> void:
	if exit_node != null and is_instance_valid(exit_node) and exit_node is CanvasItem:
		(exit_node as CanvasItem).visible = value

static func mark_reward_ready(state: Object, objective_text: String = "Open the reward chest.") -> void:
	if state == null:
		return
	state.set("room_reward_ready", true)
	state.set("room_reward_claimed", false)
	state.set("room_exit_ready", false)
	state.set("room_objective", objective_text)

static func mark_exit_ready(state: Object, objective_text: String = "Use the exit portal.") -> void:
	if state == null:
		return
	state.set("room_reward_ready", false)
	state.set("room_reward_claimed", true)
	state.set("room_exit_ready", true)
	state.set("room_objective", objective_text)
