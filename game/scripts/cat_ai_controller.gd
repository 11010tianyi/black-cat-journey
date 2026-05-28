extends CharacterBody3D

enum CatState { WANDER, NOTICE_PLAYER, APPROACH, ACCOMPANY, WAIT, LEAVE }

@export var cat_name := "旅猫"
@export var move_speed := 2.4
@export var notice_radius := 8.0
@export var join_radius := 1.8
@export var leave_after := 35.0
@export var starts_as_companion := false
@export var body_material: Material

var state := CatState.WANDER
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _player: Node3D
var _companion_manager: Node
var _wander_anchor := Vector3.ZERO
var _wander_target := Vector3.ZERO
var _state_time := 0.0

func _ready() -> void:
	if body_material != null:
		for node_name in ["Body", "Head", "Tail"]:
			var mesh := get_node_or_null(node_name)
			if mesh is MeshInstance3D:
				mesh.set_surface_override_material(0, body_material)
	_wander_anchor = global_position
	_pick_wander_target()
	_player = get_tree().get_first_node_in_group("player")
	_companion_manager = get_tree().get_first_node_in_group("companion_manager")
	if starts_as_companion:
		_become_companion()

func _physics_process(delta: float) -> void:
	_state_time += delta
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return

	match state:
		CatState.WANDER:
			_move_toward(_wander_target, delta, 0.55)
			if global_position.distance_to(_wander_target) < 0.8:
				_pick_wander_target()
			if global_position.distance_to(_player.global_position) < notice_radius:
				state = CatState.NOTICE_PLAYER
				_state_time = 0.0
		CatState.NOTICE_PLAYER:
			_look_at_flat(_player.global_position, delta)
			if _state_time > 0.7:
				state = CatState.APPROACH
				_state_time = 0.0
		CatState.APPROACH:
			_move_toward(_player.global_position, delta, 1.0)
			if global_position.distance_to(_player.global_position) < join_radius:
				_become_companion()
		CatState.ACCOMPANY:
			var offset := Vector3(0, 0, 2)
			if _companion_manager != null:
				offset = _companion_manager.get_follow_offset(self)
			var target := _player.global_transform * offset
			_move_toward(target, delta, 1.0)
			if _state_time > leave_after:
				state = CatState.LEAVE
				_state_time = 0.0
				if _companion_manager != null:
					_companion_manager.unregister(self)
				_wander_anchor = global_position + Vector3(randf_range(-6, 6), 0, randf_range(8, 12))
				_pick_wander_target()
		CatState.WAIT:
			velocity.x = move_toward(velocity.x, 0, move_speed * delta)
			velocity.z = move_toward(velocity.z, 0, move_speed * delta)
		CatState.LEAVE:
			_move_toward(_wander_target, delta, 0.9)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()

func _become_companion() -> void:
	state = CatState.ACCOMPANY
	_state_time = 0.0
	if _companion_manager != null:
		_companion_manager.register(self)

func _move_toward(target: Vector3, delta: float, speed_scale: float) -> void:
	var direction := target - global_position
	direction.y = 0.0
	if direction.length() < 0.15:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta)
		return
	direction = direction.normalized()
	velocity.x = direction.x * move_speed * speed_scale
	velocity.z = direction.z * move_speed * speed_scale
	_look_at_flat(global_position + direction, delta)

func _look_at_flat(target: Vector3, delta: float) -> void:
	var direction := target - global_position
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 6.0 * delta)

func _pick_wander_target() -> void:
	_wander_target = _wander_anchor + Vector3(randf_range(-4.0, 4.0), 0, randf_range(-4.0, 4.0))
