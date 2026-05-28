extends ActionLeaf

func tick(_delta: float, _blackboard: Blackboard) -> int:
	var cat: CharacterBody3D = _blackboard.get_value("cat")
	var companion_manager: Node = _blackboard.get_value("companion_manager")
	if cat == null:
		return FAILURE
	if companion_manager != null:
		companion_manager.unregister(cat)
	_blackboard.set_value("accompanying", false)
	return SUCCESS
