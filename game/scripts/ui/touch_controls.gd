extends CanvasLayer

## Mobile controls:
##   finger 1 (anywhere) -> floating joystick appears under that finger
##   finger 2            -> drag to orbit the camera
##   buttons             -> jump / meow, hit-tested by rect here

@export var player_path: NodePath = ^"../PlayerCat"
@export var look_sensitivity := 0.0045

var _player: Node3D
var _stick: VirtualJoystick
var _stick_index := -1
var _look_index := -1
var _jump_rect := Rect2()
var _meow_rect := Rect2()

func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		visible = false
		return
	_player = get_node_or_null(player_path)
	_build()

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_stick = VirtualJoystick.new()
	_stick.vector_changed.connect(_on_stick)
	root.add_child(_stick)

	var viewport_size := get_viewport().get_visible_rect().size
	var button_size := 96.0
	_jump_rect = Rect2(Vector2(viewport_size.x - 132.0, viewport_size.y - 240.0), Vector2(button_size, button_size))
	_meow_rect = Rect2(Vector2(viewport_size.x - 132.0, viewport_size.y - 132.0), Vector2(button_size, button_size))
	root.add_child(_action_button("跳", _jump_rect))
	root.add_child(_action_button("喵", _meow_rect))

func _action_button(label: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.text = label
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 24)
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return button

func _input(event: InputEvent) -> void:
	if not visible or _stick == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position, event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(0, event.position)
		else:
			_release(0)
	elif event is InputEventMouseMotion and _stick.active:
		_stick.update_to(event.position)

func _press(index: int, position: Vector2) -> void:
	if _jump_rect.has_point(position):
		_player_request("request_jump")
		return
	if _meow_rect.has_point(position):
		_player_request("request_meow")
		return
	if not _stick.active:
		_stick_index = index
		_stick.show_at(position)
		return
	if _look_index < 0:
		_look_index = index

func _release(index: int) -> void:
	if index == _stick_index:
		_stick_index = -1
		_stick.release()
	elif index == _look_index:
		_look_index = -1

func _drag(index: int, position: Vector2, relative: Vector2) -> void:
	if index == _stick_index:
		_stick.update_to(position)
	elif index == _look_index:
		_player_request("add_look_delta", relative * look_sensitivity / 0.0045)

func _player_request(method: String, argument: Variant = null) -> void:
	if _player == null or not _player.has_method(method):
		return
	if argument == null:
		_player.call(method)
	else:
		_player.call(method, argument)

func _on_stick(value: Vector2) -> void:
	if _player != null and _player.has_method("set_virtual_move"):
		_player.set_virtual_move(value)
	if _player != null and _player.has_method("set_virtual_run"):
		_player.set_virtual_run(value.length() > 0.85)
