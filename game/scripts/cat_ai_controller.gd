extends CharacterBody3D

enum State { WANDER, APPROACH, FOLLOW, LEAVE, LEFT }

@export var cat_name := "旅猫"
@export var move_speed := 3.5
@export var catchup_speed := 6.2
@export var notice_radius := 8.0
@export var meow_radius := 18.0
@export var join_radius := 1.7
@export var leave_z := -160.0
@export var starts_as_companion := false
@export var body_material: Material

var state := State.WANDER
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _player: Node3D
var _companion_manager: Node
var _anchor := Vector3.ZERO
var _leave_target := Vector3.ZERO

func _ready() -> void:
	if body_material != null:
		for node_name in ["Body", "Head"]:
			var mesh := get_node_or_null(node_name)
			if mesh is MeshInstance3D:
				mesh.set_surface_override_material(0, body_material)
	_anchor = global_position
	_find_actors()
	_connect_meow()
	if starts_as_companion:
		_join()

func _physics_process(delta: float) -> void:
	_find_actors()
	_connect_meow()

	if global_position.y < -6.0:
		_recover_from_fall()

	if not is_on_floor():
		velocity.y -= _gravity * delta

	match state:
		State.WANDER:
			_tick_wander(delta)
		State.APPROACH:
			_tick_approach(delta)
		State.FOLLOW:
			_tick_follow(delta)
		State.LEAVE:
			_tick_leave(delta)
		State.LEFT:
			_halt_horizontal(delta)

	move_and_slide()

func _on_player_meowed(origin: Vector3) -> void:
	if state == State.FOLLOW or state == State.LEAVE or state == State.LEFT:
		return
	if global_position.distance_to(origin) <= meow_radius:
		state = State.APPROACH

func _tick_wander(delta: float) -> void:
	_halt_horizontal(delta)
	if _player != null and _flat_distance_to(_player.global_position) <= notice_radius:
		state = State.APPROACH

func _tick_approach(delta: float) -> void:
	if _player == null:
		state = State.WANDER
		return
	var distance := _flat_distance_to(_player.global_position)
	if distance <= join_radius:
		_join()
		return
	if distance > meow_radius:
		state = State.WANDER
		_halt_horizontal(delta)
		return
	_move_toward(_player.global_position, _speed_for(distance), delta)

func _tick_follow(delta: float) -> void:
	if _player == null:
		return
	if _player.global_position.z <= leave_z:
		_depart()
		return
	var target := _follow_target()
	var distance := _flat_distance_to(target)
	if distance < 0.75:
		_halt_horizontal(delta)
		_face_toward(_player.global_position, delta)
		return
	_move_toward(target, _speed_for(distance), delta)

func _tick_leave(delta: float) -> void:
	if _flat_distance_to(_leave_target) < 0.55:
		state = State.LEFT
		_halt_horizontal(delta)
		return
	_move_toward(_leave_target, move_speed * 0.75, delta)

func _join() -> void:
	if _companion_manager != null and _companion_manager.has_method("register"):
		_companion_manager.register(self)
	state = State.FOLLOW

func _depart() -> void:
	if _companion_manager != null and _companion_manager.has_method("unregister"):
		_companion_manager.unregister(self)
	var side := 5.4 if global_position.x >= 0.0 else -5.4
	_leave_target = Vector3(side, global_position.y, global_position.z + 1.2)
	state = State.LEAVE

func _follow_target() -> Vector3:
	var offset := Vector3(1.3, 0.0, 2.2)
	if _companion_manager != null and _companion_manager.has_method("get_follow_offset"):
		offset = _companion_manager.get_follow_offset(self)
	var forward := Vector3(0.0, 0.0, -1.0)
	if _player != null and _player.has_method("get_flat_forward"):
		forward = _player.get_flat_forward()
	if forward.length() < 0.01:
		forward = Vector3(0.0, 0.0, -1.0)
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP).normalized()
	return _player.global_position - forward * offset.z + right * offset.x

func _speed_for(distance: float) -> float:
	return catchup_speed if distance > 4.0 else move_speed

func _move_toward(target: Vector3, speed: float, delta: float) -> void:
	var direction := target - global_position
	direction.y = 0.0
	if direction.length() < 0.05:
		_halt_horizontal(delta)
		return
	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	_face_direction(direction, delta)

func _halt_horizontal(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, move_speed * 4.0 * delta)

func _face_toward(target: Vector3, delta: float) -> void:
	var direction := target - global_position
	direction.y = 0.0
	_face_direction(direction, delta)

func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 8.0 * delta)

func _flat_distance_to(point: Vector3) -> float:
	var offset := point - global_position
	offset.y = 0.0
	return offset.length()

func _recover_from_fall() -> void:
	velocity = Vector3.ZERO
	if (state == State.FOLLOW or state == State.APPROACH) and _player != null:
		global_position = _player.global_position + Vector3(1.5, 0.4, 1.8)
	else:
		global_position = _anchor + Vector3(0.0, 0.4, 0.0)

func _find_actors() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _companion_manager == null:
		_companion_manager = get_tree().get_first_node_in_group("companion_manager")

func _connect_meow() -> void:
	if _player == null or not _player.has_signal("meowed"):
		return
	if not _player.meowed.is_connected(_on_player_meowed):
		_player.meowed.connect(_on_player_meowed)

func get_player() -> Node3D:
	return _player

func get_companion_manager() -> Node:
	return _companion_manager
