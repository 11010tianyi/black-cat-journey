extends SceneTree

var _phase := "boot"
var _frames := 0
var _scene: Node
var _player: CharacterBody3D
var _spawn := Vector3.ZERO
var _move_start := Vector3.ZERO
var _saw_dialogue := false
var _advanced_line := ""

func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	process_frame.connect(_on_frame)

func _fail(message: String) -> void:
	push_error(message)
	print("PLAYABLE_TEST FAIL: %s" % message)
	quit(1)

func _pass() -> void:
	print("PLAYABLE_TEST PASS")
	quit(0)

func _on_frame() -> void:
	if _phase == "done":
		return
	_frames += 1
	if _scene == null:
		_scene = current_scene
		if _scene == null:
			if _frames > 60:
				_fail("主场景没有加载")
			return
		_player = _scene.get_node_or_null("PlayerCat") as CharacterBody3D
		if _player == null:
			_fail("主场景里没有 PlayerCat")
			return
		_spawn = _player.global_position
		_phase = "settle"
		_frames = 0
		return

	match _phase:
		"settle":
			_step_settle()
		"walk":
			_step_walk()
		"path":
			_step_path()
		"fall":
			_step_fall()
		"join":
			_step_join()
		"follow":
			_step_follow()
		"leave":
			_step_leave()
		"join_second":
			_step_join_second()
		"leave_second":
			_step_leave_second()
		"meow":
			_step_meow()
		"talk":
			_step_talk()
		"walk_after":
			_step_walk_after()
		"goal":
			_step_goal()

func _step_settle() -> void:
	if _frames < 45:
		return
	if not _player.is_on_floor():
		_fail("玩家没有落在路面上，位置 %s" % _player.global_position)
		return
	_move_start = _player.global_position
	Input.action_press("play_char_move_forward_action")
	_phase = "walk"
	_frames = 0

func _step_walk() -> void:
	if _frames < 70:
		return
	Input.action_release("play_char_move_forward_action")
	var moved := _player.global_position - _move_start
	var planar := Vector3(moved.x, 0.0, moved.z)
	if planar.length() < 1.2:
		_fail("按住 W 几乎没有移动，位移 %s" % moved)
		return
	var camera := _player.get_node("CameraPivot/Camera3D") as Camera3D
	var look := -camera.global_transform.basis.z
	look.y = 0.0
	if look.length() < 0.01 or planar.normalized().dot(look.normalized()) < 0.85:
		_fail("W 没有朝镜头前方，位移 %s，镜头 %s" % [planar, look])
		return
	if _player.global_position.z >= _move_start.z:
		_fail("默认镜头下 W 没有沿路走向 -Z，现在 z=%s" % _player.global_position.z)
		return
	_phase = "path"
	_frames = 0

func _step_path() -> void:
	var space := (_scene as Node3D).get_world_3d().direct_space_state
	var z := 12.0
	while z >= -450.0:
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 3, z), Vector3(0, -3, z)))
		if hit.is_empty():
			_fail("路中间有裂缝，z=%s" % z)
			return
		z -= 0.5
	for side in [-4.0, 4.0]:
		var edge_hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(side, 3, -200), Vector3(side, -3, -200)))
		if edge_hit.is_empty():
			_fail("路面太窄，x=%s 没有地面" % side)
			return
	_player.global_position = Vector3(0, -30, 6)
	_player.velocity = Vector3.ZERO
	_phase = "fall"
	_frames = 0

func _step_fall() -> void:
	if _frames < 20:
		return
	if _player.global_position.distance_to(_spawn) > 1.5 or _player.global_position.y < -1.0:
		_fail("掉出平台后没有回到出生点，位置 %s，出生点 %s" % [_player.global_position, _spawn])
		return
	_place_player(Vector3(-2.4, 0.6, -44))
	_phase = "join"
	_frames = 0

func _step_join() -> void:
	if _frames > 240:
		_fail("狸花猫没有靠近登记结伴，同伴 %s" % _companion_names())
		return
	if _is_companion("TabbyCat"):
		_place_player(Vector3(-1.0, 0.6, -80))
		_phase = "follow"
		_frames = 0

func _step_follow() -> void:
	var tabby := _scene.get_node("TabbyCat") as Node3D
	if _flat_distance(_player.global_position, tabby.global_position) < 5.0:
		_place_player(Vector3(0, 0.6, -165))
		_phase = "leave"
		_frames = 0
		return
	if _frames > 500:
		_fail("狸花猫没有跟上，距离 %s" % _flat_distance(_player.global_position, tabby.global_position))

func _step_leave() -> void:
	if _frames < 8:
		return
	if not _is_companion("TabbyCat"):
		_place_player(Vector3(2.3, 0.6, -206))
		_phase = "join_second"
		_frames = 0
		return
	if _frames > 90:
		_fail("狸花猫过了离队点还在队伍里")

func _step_join_second() -> void:
	if _frames > 240:
		_fail("三花猫没有登记结伴，同伴 %s" % _companion_names())
		return
	if _is_companion("CalicoCat"):
		_place_player(Vector3(0, 0.6, -325))
		_phase = "leave_second"
		_frames = 0

func _step_leave_second() -> void:
	if _frames < 8:
		return
	if not _is_companion("CalicoCat"):
		_place_player(Vector3(-2.2, 0.6, -334))
		Input.action_press("play_char_meow_action")
		_phase = "meow"
		_frames = 0
		return
	if _frames > 90:
		_fail("三花猫过了离队点还在队伍里")

func _step_meow() -> void:
	var gray := _scene.get_node("GrayCat") as Node3D
	var distance := _flat_distance(_player.global_position, gray.global_position)
	if gray.state == gray.State.APPROACH or distance < 12.0:
		Input.action_release("play_char_meow_action")
		_place_player(Vector3(2.1, 0.6, -16.2))
		_phase = "talk"
		_frames = 0
		return
	if _frames > 180:
		Input.action_release("play_char_meow_action")
		_fail("E 叫声没有让灰猫靠近，距离 %s，状态 %s" % [distance, gray.state])

func _step_talk() -> void:
	if _frames > 700:
		_fail("白猫台词没有弹出或无法关闭，看见台词=%s，控制=%s" % [_saw_dialogue, _player.control_enabled])
		return
	var balloon := _find_balloon()
	if balloon != null and balloon.dialogue_line != null:
		var line_text: String = balloon.dialogue_line.text
		if "风不一定知道方向" in line_text or "毛太长" in line_text or "同行" in line_text or "脚印" in line_text:
			_saw_dialogue = true
		var label: Node = balloon.get("dialogue_label")
		if label != null and label.is_typing:
			label.skip_typing()
		elif balloon.is_waiting_for_input and balloon.dialogue_line.id != _advanced_line:
			_advanced_line = balloon.dialogue_line.id
			balloon.next(balloon.dialogue_line.next_id)
	if _saw_dialogue and _player.control_enabled and balloon == null:
		_move_start = _player.global_position
		Input.action_press("play_char_move_forward_action")
		_phase = "walk_after"
		_frames = 0

func _step_walk_after() -> void:
	if _frames < 40:
		return
	Input.action_release("play_char_move_forward_action")
	if _player.global_position.z >= _move_start.z - 0.6:
		_fail("关掉白猫台词后不能继续走，z=%s -> %s" % [_move_start.z, _player.global_position.z])
		return
	_place_player(Vector3(0, 0.6, -442))
	Input.action_press("play_char_move_forward_action")
	_phase = "goal"
	_frames = 0

func _step_goal() -> void:
	var label := _scene.get_node("HUD/EndLabel") as CanvasItem
	if label.visible:
		Input.action_release("play_char_move_forward_action")
		_phase = "done"
		_pass()
		return
	if _frames > 120:
		Input.action_release("play_char_move_forward_action")
		_fail("走到终点没有触发，玩家 z=%s" % _player.global_position.z)

func _place_player(position: Vector3) -> void:
	_player.global_position = position
	_player.velocity = Vector3.ZERO

func _is_companion(node_name: String) -> bool:
	var manager := _scene.get_node("CompanionManager")
	var cat := _scene.get_node(node_name)
	return manager.companions.has(cat)

func _companion_names() -> String:
	var manager := _scene.get_node("CompanionManager")
	var names: PackedStringArray = []
	for cat in manager.companions:
		names.append(str(cat.name))
	return ", ".join(names)

func _flat_distance(a: Vector3, b: Vector3) -> float:
	a.y = 0.0
	b.y = 0.0
	return a.distance_to(b)

func _find_balloon() -> Node:
	for child in _scene.get_children():
		var balloon_script := child.get_script() as Script
		if balloon_script != null and balloon_script.resource_path.ends_with("example_balloon.gd"):
			return child
	return null
