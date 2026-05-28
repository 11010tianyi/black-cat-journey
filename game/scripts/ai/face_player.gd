extends ActionLeaf

func tick(delta: float, _blackboard: Blackboard) -> int:
	var player: Node3D = _blackboard.get_value("player")
	var cat: CharacterBody3D = _blackboard.get_value("cat")
	if player == null or cat == null:
		return FAILURE
	var direction := player.global_position - cat.global_position
	direction.y = 0.0
	if direction.length() < 0.01:
		return SUCCESS
	var target_yaw := atan2(-direction.x, -direction.z)
	cat.rotation.y = lerp_angle(cat.rotation.y, target_yaw, 6.0 * delta)
	return SUCCESS
