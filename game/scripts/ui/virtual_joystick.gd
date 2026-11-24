class_name VirtualJoystick
extends Control

## Floating stick: invisible until the first finger lands, then it appears under
## that finger. Drawn in screen space; hit-testing lives in touch_controls.gd.

signal vector_changed(value: Vector2)

@export var radius := 120.0
@export var deadzone := 0.12

var _center := Vector2.ZERO
var _knob := Vector2.ZERO
var active := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func show_at(point: Vector2) -> void:
	_center = point
	_knob = Vector2.ZERO
	active = true
	visible = true
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()

func update_to(point: Vector2) -> void:
	if not active:
		return
	var offset := point - _center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	_knob = offset
	var value := offset / radius
	if value.length() < deadzone:
		value = Vector2.ZERO
	vector_changed.emit(value)
	queue_redraw()

func release() -> void:
	active = false
	_knob = Vector2.ZERO
	visible = false
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	draw_circle(_center, radius, Color(1.0, 1.0, 1.0, 0.10))
	draw_arc(_center, radius, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.30), 3.0, true)
	draw_circle(_center + _knob, radius * 0.38, Color(0.98, 0.88, 0.62, 0.45))
	draw_arc(_center + _knob, radius * 0.38, 0.0, TAU, 48, Color(1.0, 0.93, 0.78, 0.75), 3.0, true)
