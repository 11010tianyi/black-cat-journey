extends CanvasLayer

## Title card shown before the walk starts. It also exists because browsers only
## grant pointer lock (and start audio) after a real user gesture, so the game
## must wait for one click.

signal started

@export var player_path: NodePath = ^"../PlayerCat"
@export var title := "黑猫旅程"
@export var subtitle := "一只黑猫，走过草原、废墟与雪。\n路上会遇到别的猫，也会和它们分开。"

var _root: Control
var _started := false

func _ready() -> void:
	var player := get_node_or_null(player_path)
	if player != null and player.has_method("set_control_enabled"):
		player.set_control_enabled(false)
	# A headless run has no UI to click, so gameplay tests start immediately.
	if DisplayServer.get_name() == "headless":
		start()
		return
	_build()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 46)
	heading.add_theme_color_override("font_color", Color(1.0, 0.93, 0.78))
	box.add_child(heading)

	var copy := Label.new()
	copy.text = subtitle
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_theme_font_size_override("font_size", 18)
	copy.add_theme_color_override("font_color", Color(0.86, 0.86, 0.88))
	box.add_child(copy)

	var hint := Label.new()
	hint.text = "WASD 走 · 鼠标环顾 · Shift 跑 · 空格跳 · E 呼唤" if not DisplayServer.is_touchscreen_available() else "左下摇杆走 · 右侧按钮跳和呼唤 · 拖动屏幕转视角"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.7, 0.72, 0.76))
	box.add_child(hint)

	var button := Button.new()
	button.text = "开始旅程"
	button.custom_minimum_size = Vector2(240, 62)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(start)
	box.add_child(button)
	button.grab_focus()

func start() -> void:
	if _started:
		return
	_started = true
	if _root != null:
		_root.queue_free()
		_root = null
	if not DisplayServer.is_touchscreen_available():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var player := get_node_or_null(player_path)
	if player != null and player.has_method("set_control_enabled"):
		player.set_control_enabled(true)
	started.emit()
