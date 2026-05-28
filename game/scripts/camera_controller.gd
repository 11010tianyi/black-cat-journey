extends SpringArm3D

@export var follow_target: Node3D
@export var follow_lerp := 8.0

func _process(delta: float) -> void:
	if follow_target == null:
		return
	global_position = global_position.lerp(follow_target.global_position + Vector3(0, 0.75, 0), follow_lerp * delta)
