extends Node3D

const DIALOGUE_PATH := "res://data/white_cat.dialogue"

@export var trigger_radius := 3.6
@export var retrigger_cooldown := 12.0

var _player: Node3D
var _cooldown := 0.0
var _dialogue_resource: DialogueResource
var _showing := false
var _meetings := 0
@onready var _model: CatModel = $Model

func _ready() -> void:
	add_to_group("white_cat")
	_player = get_tree().get_first_node_in_group("player")
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _showing or _cooldown > 0.0:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() < 6.0:
		rotation.y = lerp_angle(rotation.y, atan2(-to_player.x, -to_player.z), 3.0 * delta)
	if global_position.distance_to(_player.global_position) <= trigger_radius:
		_show_lines()

func _show_lines() -> void:
	_dialogue_resource = _load_dialogue()
	if _dialogue_resource == null:
		return
	_showing = true
	_set_player_control(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DialogueManager.show_dialogue_balloon(_dialogue_resource, _next_cue())

func _load_dialogue() -> DialogueResource:
	if ResourceLoader.exists(DIALOGUE_PATH):
		var loaded: Resource = load(DIALOGUE_PATH)
		if loaded is DialogueResource:
			return loaded
	if not FileAccess.file_exists(DIALOGUE_PATH):
		push_error("找不到白猫台词: %s" % DIALOGUE_PATH)
		return null
	return DialogueManager.create_resource_from_text(FileAccess.get_file_as_string(DIALOGUE_PATH))

## The white cat has three conversations: the first meeting, a second one, and a
## closing one once the player is near the end of the road.
func _next_cue() -> String:
	if _meetings == 0:
		return "first_meeting"
	if _player != null and _player.global_position.z < -330.0:
		return "last_meeting"
	return "second_meeting"

func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource != _dialogue_resource:
		return
	_showing = false
	_meetings += 1
	_cooldown = retrigger_cooldown
	_set_player_control(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _set_player_control(enabled: bool) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _player != null and _player.has_method("set_control_enabled"):
		_player.set_control_enabled(enabled)
