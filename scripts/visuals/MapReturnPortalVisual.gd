extends Node2D

var portals_remaining: int = 0
var active: bool = false
var pulse: float = 0.0
var label: Label = null

func _ready() -> void:
	z_as_relative = false
	z_index = 12
	label = Label.new()
	label.name = "PortalLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-92.0, 54.0)
	label.size = Vector2(184.0, 36.0)
	add_child(label)
	set_process(true)
	queue_redraw()

func set_portal_state(enabled: bool, remaining: int) -> void:
	active = enabled
	portals_remaining = max(0, remaining)
	visible = active and portals_remaining > 0
	if label != null:
		label.text = "Map Portal (" + str(portals_remaining) + ")"
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	if not active or portals_remaining <= 0:
		return
	var glow: float = 0.5 + 0.5 * sin(pulse * 4.0)
	draw_circle(Vector2.ZERO, 54.0 + glow * 5.0, Color(1.0, 0.42, 0.12, 0.16))
	draw_arc(Vector2.ZERO, 48.0, 0.0, TAU, 64, Color(1.0, 0.55, 0.18, 0.88), 5.0)
	draw_arc(Vector2.ZERO, 30.0, pulse, pulse + TAU * 0.78, 48, Color(1.0, 0.86, 0.35, 0.75), 3.0)
	draw_circle(Vector2.ZERO, 18.0 + glow * 3.0, Color(0.55, 0.10, 0.95, 0.42))
	for i: int in range(6):
		var a: float = pulse * 1.3 + float(i) * TAU / 6.0
		var p: Vector2 = Vector2(cos(a), sin(a)) * 62.0
		draw_circle(p, 4.0, Color(1.0, 0.70, 0.22, 0.78))
