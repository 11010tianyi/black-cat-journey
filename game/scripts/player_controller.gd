extends CharacterBody3D

signal meowed(origin: Vector3)

@export var walk_speed := 3.2
@export var run_speed := 5.8
@export var jump_velocity := 4.8
@export var turn_speed := 10.0
@export var meow_cooldown := 0.8

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _meow_timer := 0.0

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _visual_root: Node3D = $VisualRoot

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_camera_pivot.rotate_y(-event.relative.x * 0.003)
		_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x - event.relative.y * 0.002, -0.45, 0.25)

func _physics_process(delta: float) -> void:
	_meow_timer = maxf(0.0, _meow_timer - delta)

	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()

	var forward := -_camera_pivot.global_transform.basis.z
	var right := _camera_pivot.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var direction := (right * input_dir.x + forward * -input_dir.y).normalized()
	var speed := run_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed

	if direction.length() > 0.01:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var target_yaw := atan2(-direction.x, -direction.z)
		_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 5.0 * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity

	if Input.is_key_pressed(KEY_E) and _meow_timer <= 0.0:
		_meow_timer = meow_cooldown
		meowed.emit(global_position)

	move_and_slide()
