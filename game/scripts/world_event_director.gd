extends Node3D

@export var wind_strength := 0.35

@onready var _wind_particles: GPUParticles3D = $WindParticles

func _ready() -> void:
	if _wind_particles:
		_wind_particles.emitting = true
	var goal := get_node_or_null("JourneyEnd")
	if goal is Area3D and not goal.body_entered.is_connected(_on_journey_end_body_entered):
		goal.body_entered.connect(_on_journey_end_body_entered)

func _process(_delta: float) -> void:
	if _wind_particles:
		_wind_particles.position.x = sin(Time.get_ticks_msec() * 0.001) * wind_strength

func _on_journey_end_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var label := get_node_or_null("HUD/EndLabel")
	if label is CanvasItem:
		label.visible = true
