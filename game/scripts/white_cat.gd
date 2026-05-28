extends Node3D

@export var trigger_radius := 4.0
@export var retrigger_cooldown := 10.0

var _player: Node3D
var _cooldown := 0.0
var _dialogue_resource: DialogueResource
var _cues: Array[String] = ["first_meeting", "companions", "cold_joke", "farewell"]
var _cue_index := 0

func _ready() -> void:
	add_to_group("white_cat")
	_player = get_tree().get_first_node_in_group("player")
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	if _cooldown > 0.0:
		return
	if global_position.distance_to(_player.global_position) <= trigger_radius:
		_show_next_line()
		_cooldown = retrigger_cooldown

func _show_next_line() -> void:
	var dialogue_path := "res://data/white_cat.dialogue"
	if _dialogue_resource == null:
		if not ResourceLoader.exists(dialogue_path):
			return
		_dialogue_resource = load(dialogue_path)
	if _dialogue_resource == null:
		return
	var cue := _cues[_cue_index % _cues.size()]
	_cue_index += 1
	DialogueManager.show_dialogue_line_balloon(_dialogue_resource, cue)

func _on_dialogue_ended(_resource: DialogueResource) -> void:
	pass
