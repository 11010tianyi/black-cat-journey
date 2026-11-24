extends SceneTree
var f := 0
func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	process_frame.connect(_t)
func _t() -> void:
	f += 1
	if f == 4:
		var overlay := current_scene.get_node_or_null("StartOverlay")
		if overlay != null and overlay.has_method("begin"):
			overlay.begin(false)
