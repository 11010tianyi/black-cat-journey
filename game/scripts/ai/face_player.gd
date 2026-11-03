extends ActionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
	var delta := actor.get_physics_process_delta_time()
	var player: Node3D = blackboard.get_value("player")
	var cat: CharacterBody3D = blackboard.get_value("cat")
	if player == null or cat == null:
		return FAILURE
	var direction := player.global_position - cat.global_position
	direction.y = 0.0
	if direction.length() < 0.01:
		return SUCCESS
	var target_yaw := atan2(-direction.x, -direction.z)
	cat.rotation.y = lerp_angle(cat.rotation.y, target_yaw, 6.0 * delta)
	return SUCCESS
