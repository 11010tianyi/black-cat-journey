extends CharacterBody3D

@export var cat_name := "旅猫"
@export var move_speed := 2.4
@export var notice_radius := 8.0
@export var join_radius := 1.8
@export var leave_after := 35.0
@export var starts_as_companion := false
@export var body_material: Material

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _player: Node3D
var _companion_manager: Node

func _ready() -> void:
	if body_material != null:
		for node_name in ["Body", "Head"]:
			var mesh := get_node_or_null(node_name)
			if mesh is MeshInstance3D:
				mesh.set_surface_override_material(0, body_material)
	_player = get_tree().get_first_node_in_group("player")
	_companion_manager = get_tree().get_first_node_in_group("companion_manager")

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _companion_manager == null:
		_companion_manager = get_tree().get_first_node_in_group("companion_manager")

	if not is_on_floor():
		velocity.y -= _gravity * delta

	move_and_slide()

func get_player() -> Node3D:
	return _player

func get_companion_manager() -> Node:
	return _companion_manager
