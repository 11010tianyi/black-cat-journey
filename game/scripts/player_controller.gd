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

var state := State.IDLE
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _meow_timer := 0.0
var _camera_yaw := 0.0
var _camera_pitch := 0.0

@onready var _visual_root: Node3D = $VisualRoot

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_register_input_actions()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("play_char_mouse_mode_action"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_camera_yaw -= event.relative.x * 0.003
		_camera_pitch = clamp(_camera_pitch - event.relative.y * 0.002, -0.45, 0.25)
	if event.is_action_pressed("play_char_jump_action") and is_on_floor():
		velocity.y = jump_velocity
		state = State.JUMP
	if Input.is_key_pressed(KEY_E) and _meow_timer <= 0.0:
		_meow_timer = meow_cooldown
		meowed.emit(global_position)

func _physics_process(delta: float) -> void:
	_meow_timer = maxf(0.0, _meow_timer - delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
		state = State.IN_AIR

	var input_dir := Input.get_vector(
		"play_char_move_left_action", "play_char_move_right_action",
		"play_char_move_forward_action", "play_char_move_backward_action"
	)
	var is_running := Input.is_action_pressed("play_char_run_action")
	var speed := run_speed if is_running else walk_speed

	var forward := Vector3(sin(_camera_yaw), 0, cos(_camera_yaw))
	var right := Vector3(cos(_camera_yaw), 0, -sin(_camera_yaw))
	var direction := (right * input_dir.x + forward * -input_dir.y).normalized()

	if direction.length() > 0.01:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta * (1.0 if is_on_floor() else air_control))
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta * (1.0 if is_on_floor() else air_control))
		var target_yaw := atan2(-direction.x, -direction.z)
		_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_yaw, turn_speed * delta)
		state = State.RUN if is_running else State.WALK
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		if is_on_floor():
			state = State.IDLE

	move_and_slide()

func _register_input_actions() -> void:
	var actions := {
		"play_char_move_forward_action": [KEY_W, KEY_UP],
		"play_char_move_backward_action": [KEY_S, KEY_DOWN],
		"play_char_move_left_action": [KEY_A, KEY_LEFT],
		"play_char_move_right_action": [KEY_D, KEY_RIGHT],
		"play_char_run_action": [KEY_SHIFT],
		"play_char_jump_action": [KEY_SPACE],
		"play_char_mouse_mode_action": [KEY_CTRL],
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
