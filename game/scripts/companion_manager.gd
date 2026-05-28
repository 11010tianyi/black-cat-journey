extends Node

var companions: Array[Node3D] = []

func _ready() -> void:
	add_to_group("companion_manager")

func register(cat: Node3D) -> int:
	if not companions.has(cat):
		companions.append(cat)
	return companions.find(cat)

func unregister(cat: Node3D) -> void:
	companions.erase(cat)

func get_follow_offset(cat: Node3D) -> Vector3:
	var index: int = maxi(0, companions.find(cat))
	var side := -1.0 if index % 2 == 0 else 1.0
	var row := float(index / 2)
	return Vector3(side * (1.4 + row * 0.4), 0.0, 2.0 + row * 0.8)
