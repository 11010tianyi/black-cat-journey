extends CanvasLayer

@export_file("*.json") var dialogue_path := "res://data/white_cat_dialogue.json"

var lines: Array = []
var _line_index := 0

@onready var _panel: Panel = $Panel
@onready var _label: Label = $Panel/MarginContainer/Label
@onready var _timer: Timer = $Timer

func _ready() -> void:
	add_to_group("dialogue_system")
	_panel.visible = false
	_load_lines()
	_timer.timeout.connect(func(): _panel.visible = false)

func show_next_white_cat_line() -> void:
	if lines.is_empty():
		return
	var entry: Dictionary = lines[_line_index % lines.size()]
	_line_index += 1
	show_line(entry.get("speaker", "白猫"), entry.get("text", ""))

func show_line(speaker: String, text: String, seconds := 5.0) -> void:
	_label.text = "%s：%s" % [speaker, text]
	_panel.visible = true
	_timer.start(seconds)

func _load_lines() -> void:
	if not FileAccess.file_exists(dialogue_path):
		return
	var raw := FileAccess.get_file_as_string(dialogue_path)
	var parsed = JSON.parse_string(raw)
	if parsed is Array:
		lines = parsed
