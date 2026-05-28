extends Node3D

@export var wind_strength := 0.35

@onready var _wind_particles: GPUParticles3D = $WindParticles

func _ready() -> void:
	if _wind_particles:
		_wind_particles.emitting = true

func _process(delta: float) -> void:
	if _wind_particles:
		_wind_particles.position.x = sin(Time.get_ticks_msec() * 0.001) * wind_strength
