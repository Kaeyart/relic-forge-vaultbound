class_name RVFlaskHUD
extends Control

@onready var level_label: Label = get_node_or_null("%LevelLabel") as Label
@onready var xp_label: Label = get_node_or_null("%XPLabel") as Label
@onready var health_flask_label: Label = get_node_or_null("%HealthFlaskLabel") as Label
@onready var mana_flask_label: Label = get_node_or_null("%ManaFlaskLabel") as Label
@onready var passive_points_label: Label = get_node_or_null("%PassivePointsLabel") as Label

func update_from_state(state: Object) -> void:
	if state == null:
		visible = false
		return
	visible = true
	if level_label != null:
		level_label.text = "LV " + str(int(state.get("level")))
	if xp_label != null:
		var xp: float = float(state.get("xp"))
		var next_xp: float = 1.0
		if state.has_method("xp_to_next"):
			next_xp = max(1.0, float(state.call("xp_to_next")))
		xp_label.text = "XP " + str(int(xp)) + " / " + str(int(next_xp))
	if passive_points_label != null:
		passive_points_label.text = "Passive " + str(int(state.get("mastery_points"))) + " · Refund " + str(int(state.get("refund_points")))
	if health_flask_label != null:
		health_flask_label.text = "Z  Health Flask  " + str(int(_state_get(state, "health_flask_charges", 0))) + "/" + str(int(_state_get(state, "health_flask_max_charges", 3))) + "  +" + str(int(float(_state_get(state, "health_flask_recovery", 65.0))))
	if mana_flask_label != null:
		mana_flask_label.text = "X  Mana Flask    " + str(int(_state_get(state, "mana_flask_charges", 0))) + "/" + str(int(_state_get(state, "mana_flask_max_charges", 3))) + "  +" + str(int(float(_state_get(state, "mana_flask_recovery", 55.0))))

func _state_get(state: Object, key: String, fallback: Variant = null) -> Variant:
	var value: Variant = state.get(key)
	return fallback if value == null else value
