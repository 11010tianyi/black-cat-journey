extends Node3D

@export var trigger_radius := 4.0
@export var retrigger_cooldown := 10.0

var _player: Node3D
var _dialogue: Node
var _cooldown := 0.0

func _ready() -> void:
	add_to_group("white_cat")
	_player = get_tree().get_first_node_in_group("player")
	_dialogue = get_tree().get_first_node_in_group("dialogue_system")

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _dialogue == null:
		_dialogue = get_tree().get_first_node_in_group("dialogue_system")
	if _player == null or _dialogue == null or _cooldown > 0.0:
		return
	if global_position.distance_to(_player.global_position) <= trigger_radius:
		_dialogue.show_next_white_cat_line()
		_cooldown = retrigger_cooldown
