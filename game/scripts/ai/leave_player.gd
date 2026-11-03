extends ActionLeaf

func tick(_actor: Node, blackboard: Blackboard) -> int:
	var cat: CharacterBody3D = blackboard.get_value("cat")
	var companion_manager: Node = blackboard.get_value("companion_manager")
	if cat == null:
		return FAILURE
	if companion_manager != null:
		companion_manager.unregister(cat)
	blackboard.set_value("accompanying", false)
	return SUCCESS
