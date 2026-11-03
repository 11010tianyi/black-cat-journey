extends ActionLeaf

@export var move_speed := 2.4
@export var speed_scale := 0.55
@export var wander_range := 4.0

func tick(actor: Node, blackboard: Blackboard) -> int:
	var delta := actor.get_physics_process_delta_time()
	var cat: CharacterBody3D = blackboard.get_value("cat")
	if cat == null:
		return FAILURE

	var wander_target: Vector3 = blackboard.get_value("wander_target", cat.global_position)
	var wander_anchor: Vector3 = blackboard.get_value("wander_anchor", cat.global_position)

	if cat.global_position.distance_to(wander_target) < 0.8:
		wander_target = wander_anchor + Vector3(randf_range(-wander_range, wander_range), 0, randf_range(-wander_range, wander_range))
		blackboard.set_value("wander_target", wander_target)

	var direction := wander_target - cat.global_position
	direction.y = 0.0
	if direction.length() < 0.15:
		cat.velocity.x = move_toward(cat.velocity.x, 0.0, move_speed * delta)
		cat.velocity.z = move_toward(cat.velocity.z, 0.0, move_speed * delta)
		return RUNNING

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
