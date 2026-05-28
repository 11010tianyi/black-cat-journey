extends ActionLeaf

@export var move_speed := 2.4
@export var speed_scale := 1.0
@export var join_radius := 1.8

func tick(delta: float, _blackboard: Blackboard) -> int:
	var player: Node3D = _blackboard.get_value("player")
	var cat: CharacterBody3D = _blackboard.get_value("cat")
	if player == null or cat == null:
		return FAILURE

	var direction := player.global_position - cat.global_position
	direction.y = 0.0
	if direction.length() < join_radius:
		return SUCCESS

	direction = direction.normalized()
	cat.velocity.x = direction.x * move_speed * speed_scale
	cat.velocity.z = direction.z * move_speed * speed_scale
	_face_direction(cat, cat.global_position + direction, delta)
	return RUNNING

func _face_direction(cat: CharacterBody3D, target: Vector3, delta: float) -> void:
	var direction := target - cat.global_position
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	cat.rotation.y = lerp_angle(cat.rotation.y, target_yaw, 6.0 * delta)
