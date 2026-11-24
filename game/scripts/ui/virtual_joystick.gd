class_name VirtualJoystick
extends Control

## Fixed-base touch stick. Touch events arrive as emulated mouse events, so one
## handler covers phones and desktop testing.

signal vector_changed(value: Vector2)

@export var radius := 78.0
@export var deadzone := 0.15

var _knob := Vector2.ZERO
var _active := false

func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP

func reset() -> void:
	_active = false
	_knob = Vector2.ZERO
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(1.0, 1.0, 1.0, 0.09))
	draw_arc(center, radius, 0.0, TAU, 60, Color(1.0, 1.0, 1.0, 0.26), 2.0, true)
	draw_circle(center + _knob, radius * 0.42, Color(0.98, 0.88, 0.62, 0.5))
	draw_arc(center + _knob, radius * 0.42, 0.0, TAU, 40, Color(1.0, 0.93, 0.78, 0.65), 2.0, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_active = true
			_update(event.position)
		else:
			reset()
	elif event is InputEventMouseMotion and _active:
		_update(event.position)

func _update(position: Vector2) -> void:
	var center := size * 0.5
	var offset := position - center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	_knob = offset
	var value := offset / radius
	if value.length() < deadzone:
		value = Vector2.ZERO
	vector_changed.emit(value)
	queue_redraw()
