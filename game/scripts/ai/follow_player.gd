extends ActionLeaf

@export var move_speed := 2.4

func tick(delta: float, _blackboard: Blackboard) -> int:
	var player: Node3D = _blackboard.get_value("player")
	var cat: CharacterBody3D = _blackboard.get_value("cat")
	var companion_manager: Node = _blackboard.get_value("companion_manager")
	if player == null or cat == null:
		return FAILURE

	var offset := Vector3(0, 0, 2)
	if companion_manager != null:
		offset = companion_manager.get_follow_offset(cat)
	var target := player.global_transform * offset
	var direction := target - cat.global_position
	direction.y = 0.0
	direction = direction.normalized()
	cat.velocity.x = direction.x * move_speed
	cat.velocity.z = direction.z * move_speed
	_face_direction(cat, cat.global_position + direction, delta)
	return RUNNING

func _face_direction(cat: CharacterBody3D, target: Vector3, delta: float) -> void:
	var direction := target - cat.global_position
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	cat.rotation.y = lerp_angle(cat.rotation.y, target_yaw, 6.0 * delta)
