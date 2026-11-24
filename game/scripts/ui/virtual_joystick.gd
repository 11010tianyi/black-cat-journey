class_name VirtualJoystick
extends Control

## Fixed-base touch stick. The owner feeds it positions and this node only draws;
## hit-testing is done by the owner so it cannot be swallowed by GUI routing.

signal vector_changed(value: Vector2)

@export var radius := 78.0
@export var deadzone := 0.15

var _knob := Vector2.ZERO
var active := false

func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func center_global() -> Vector2:
	return get_global_rect().position + size * 0.5

func set_from_global(point: Vector2) -> void:
	var offset := point - center_global()
	if offset.length() > radius:
		offset = offset.normalized() * radius
	_knob = offset
	active = true
	var value := offset / radius
	if value.length() < deadzone:
		value = Vector2.ZERO
	vector_changed.emit(value)
	queue_redraw()

func release() -> void:
	active = false
	_knob = Vector2.ZERO
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(1.0, 1.0, 1.0, 0.09))
	draw_arc(center, radius, 0.0, TAU, 60, Color(1.0, 1.0, 1.0, 0.26), 2.0, true)
	draw_circle(center + _knob, radius * 0.42, Color(0.98, 0.88, 0.62, 0.5))
	draw_arc(center + _knob, radius * 0.42, 0.0, TAU, 40, Color(1.0, 0.93, 0.78, 0.65), 2.0, true)
