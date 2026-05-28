extends ConditionLeaf

@export var notice_radius := 8.0

func tick(_delta: float, _blackboard: Blackboard) -> int:
	var player: Node3D = _blackboard.get_value("player")
	var cat: CharacterBody3D = _blackboard.get_value("cat")
	if player == null or cat == null:
		return FAILURE
	return SUCCESS if cat.global_position.distance_to(player.global_position) < notice_radius else FAILURE
