extends CharacterBody3D

signal meowed(origin: Vector3)

enum State { IDLE, WALK, RUN, JUMP, IN_AIR }

@export var walk_speed := 3.2
@export var run_speed := 5.8
@export var jump_velocity := 4.8
@export var turn_speed := 10.0
@export var meow_cooldown := 0.8
@export var acceleration := 12.0
@export var deceleration := 16.0
@export var air_control := 0.4
@export var camera_distance := 5.4
@export var fall_limit_y := -6.0

var state := State.IDLE
var control_enabled := true
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _meow_timer := 0.0
var _camera_yaw := 0.0
var _camera_pitch := -0.22
var _spawn_position := Vector3.ZERO

@onready var _visual_root: Node3D = $VisualRoot
@onready var _camera: Camera3D = $CameraPivot/Camera3D

func _ready() -> void:
	add_to_group("player")
	_spawn_position = global_position
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_register_input_actions()

func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not enabled:
		velocity.x = 0.0
		velocity.z = 0.0

func get_flat_forward() -> Vector3:
	var facing := Vector3(sin(_camera_yaw), 0.0, -cos(_camera_yaw))
	var planar := Vector3(velocity.x, 0.0, velocity.z)
	if planar.length() > 0.45:
		return planar.normalized()
	return facing.normalized()

func _unhandled_input(event: InputEvent) -> void:
	if not control_enabled:
		return
	if event.is_action_pressed("play_char_mouse_mode_action"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_camera_yaw -= event.relative.x * 0.003
		_camera_pitch = clampf(_camera_pitch - event.relative.y * 0.002, -0.55, 0.28)
	if event.is_action_pressed("play_char_jump_action") and is_on_floor():
		velocity.y = jump_velocity
		state = State.JUMP

func _physics_process(delta: float) -> void:
	if global_position.y < fall_limit_y:
		_respawn()
		return

	_meow_timer = maxf(0.0, _meow_timer - delta)
	if control_enabled and _meow_timer <= 0.0 and InputMap.has_action("play_char_meow_action") and Input.is_action_pressed("play_char_meow_action"):
		_meow()

	if not is_on_floor():
		velocity.y -= _gravity * delta
		if state != State.JUMP:
			state = State.IN_AIR

	if control_enabled:
		_apply_move_input(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		if is_on_floor() and state != State.JUMP:
			state = State.IDLE

	_update_camera()
	move_and_slide()

func _apply_move_input(delta: float) -> void:
	var input_dir := Input.get_vector(
		"play_char_move_left_action", "play_char_move_right_action",
		"play_char_move_forward_action", "play_char_move_backward_action"
	)
	var is_running := Input.is_action_pressed("play_char_run_action")
	var speed := run_speed if is_running else walk_speed
	var forward := Vector3(sin(_camera_yaw), 0.0, -cos(_camera_yaw))
	var right := Vector3(cos(_camera_yaw), 0.0, sin(_camera_yaw))
	var direction := right * input_dir.x + forward * -input_dir.y
	if direction.length() > 1.0:
		direction = direction.normalized()

	if direction.length() > 0.01:
		var control := 1.0 if is_on_floor() else air_control
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * control * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * control * delta)
		var target_yaw := atan2(-direction.x, -direction.z)
		_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_yaw, turn_speed * delta)
		state = State.RUN if is_running else State.WALK
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		if is_on_floor():
			state = State.IDLE

func _update_camera() -> void:
	var pivot := global_position + Vector3(0.0, 0.85, 0.0)
	var flat_forward := Vector3(sin(_camera_yaw), 0.0, -cos(_camera_yaw))
	var pitched := (flat_forward * cos(_camera_pitch) + Vector3.UP * sin(_camera_pitch)).normalized()
	_camera.global_position = pivot - pitched * camera_distance
	_camera.look_at(pivot + flat_forward * 0.35, Vector3.UP)

func _meow() -> void:
	_meow_timer = meow_cooldown
	meowed.emit(global_position)

func _respawn() -> void:
	global_position = _spawn_position
	velocity = Vector3.ZERO
	_camera_yaw = 0.0
	_camera_pitch = -0.22
	state = State.IDLE

func _register_input_actions() -> void:
	var actions := {
		"play_char_move_forward_action": [KEY_W, KEY_UP],
		"play_char_move_backward_action": [KEY_S, KEY_DOWN],
		"play_char_move_left_action": [KEY_A, KEY_LEFT],
		"play_char_move_right_action": [KEY_D, KEY_RIGHT],
		"play_char_run_action": [KEY_SHIFT],
		"play_char_jump_action": [KEY_SPACE],
		"play_char_mouse_mode_action": [KEY_CTRL, KEY_ESCAPE],
		"play_char_meow_action": [KEY_E],
		"play_char_cam_zoom_in_action": [KEY_V],
		"play_char_cam_zoom_out_action": [KEY_B],
	}
	for action_name: String in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for keycode: int in actions[action_name]:
				var event := InputEventKey.new()
				event.physical_keycode = keycode
				InputMap.action_add_event(action_name, event)
	if not InputMap.has_action("play_char_aim_cam_action"):
		InputMap.add_action("play_char_aim_cam_action")
		var rmb := InputEventMouseButton.new()
		rmb.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("play_char_aim_cam_action", rmb)
