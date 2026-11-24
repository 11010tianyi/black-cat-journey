extends CanvasLayer

## On-screen stick and action buttons. Shown only on touch devices so the same
## build stays clean with a keyboard and mouse.

@export var player_path: NodePath = ^"../PlayerCat"

var _player: Node3D
var _stick: VirtualJoystick

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
	_stick.anchor_left = 0.0
	_stick.anchor_top = 1.0
	_stick.anchor_right = 0.0
	_stick.anchor_bottom = 1.0
	_stick.offset_left = 28.0
	_stick.offset_right = 28.0 + 160.0
	_stick.offset_top = -196.0
	_stick.offset_bottom = -36.0
	_stick.vector_changed.connect(_on_stick)
	root.add_child(_stick)

	root.add_child(_action_button("跳", Vector2(-108.0, -196.0), _on_jump))
	root.add_child(_action_button("喵", Vector2(-108.0, -108.0), _on_meow))

func _action_button(label: String, offset: Vector2, handler: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(72, 72)
	button.add_theme_font_size_override("font_size", 20)
	button.anchor_left = 1.0
	button.anchor_top = 1.0
	button.anchor_right = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = offset.x
	button.offset_right = offset.x + 72.0
	button.offset_top = offset.y
	button.offset_bottom = offset.y + 72.0
	button.pressed.connect(handler)
	return button

func _on_stick(value: Vector2) -> void:
	if _player != null and _player.has_method("set_virtual_move"):
		_player.set_virtual_move(value)
	if _player != null and _player.has_method("set_virtual_run"):
		_player.set_virtual_run(value.length() > 0.85)

func _on_jump() -> void:
	if _player != null and _player.has_method("request_jump"):
		_player.request_jump()

func _on_meow() -> void:
	if _player != null and _player.has_method("request_meow"):
		_player.request_meow()
