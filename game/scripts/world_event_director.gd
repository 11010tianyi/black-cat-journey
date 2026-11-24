extends Node3D

@export var wind_strength := 0.35

@onready var _wind_particles: GPUParticles3D = $WindParticles

func _ready() -> void:
	if _wind_particles:
		_wind_particles.emitting = true
	var goal := get_node_or_null("JourneyEnd")
	if goal is Area3D and not goal.body_entered.is_connected(_on_journey_end_body_entered):
		goal.body_entered.connect(_on_journey_end_body_entered)
	var checkpoints := get_node_or_null("Checkpoints")
	if checkpoints != null and checkpoints.has_signal("reached"):
		checkpoints.reached.connect(_on_checkpoint_reached)
	var overlay := get_node_or_null("StartOverlay")
	if overlay != null and overlay.has_signal("started"):
		overlay.started.connect(_on_journey_started)

func _process(_delta: float) -> void:
	if _wind_particles:
		_wind_particles.position.x = sin(Time.get_ticks_msec() * 0.001) * wind_strength

func _on_checkpoint_reached(id: String, position: Vector3) -> void:
	var white := get_node_or_null("WhiteCat")
	var meetings := 0
	if white != null and white.has_method("meetings_count"):
		meetings = white.meetings_count()
	JourneySave.write({
		"checkpoint": id,
		"position": [position.x, position.y, position.z],
		"meetings": meetings,
		"saved_at": Time.get_unix_time_from_system(),
	})
	_show_toast("旅途已记录")

func _on_journey_started(resume: bool) -> void:
	if not resume:
		return
	var data := JourneySave.read()
	if data.is_empty():
		return
	var player := get_node_or_null("PlayerCat")
	if player != null:
		player.global_position = JourneySave.position_of(data) + Vector3(0.0, 0.15, 0.0)
		if "velocity" in player:
			player.velocity = Vector3.ZERO
	var white := get_node_or_null("WhiteCat")
	if white != null and white.has_method("set_meetings"):
		white.set_meetings(int(data.get("meetings", 0)))
	_show_toast("继续上次的旅途")

func _show_toast(text: String) -> void:
	var label := get_node_or_null("HUD/Toast") as Label
	if label == null:
		return
	label.text = text
	label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)

func _on_journey_end_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var label := get_node_or_null("HUD/EndLabel")
	if label is CanvasItem:
		label.visible = true
