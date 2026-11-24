class_name CatModel
extends Node3D

## Wraps the Quaternius cat rig: normalises the FBX unit scale, fixes the model's
## forward axis (+X in the source file) and drives the Idle / Walking clips.

@export var model_scale := 0.15
@export var yaw_offset_degrees := 90.0
@export var fur_material: Material

var _anim: AnimationPlayer
var _clip := ""

func _ready() -> void:
	scale = Vector3.ONE * model_scale
	rotation_degrees.y = yaw_offset_degrees
	_anim = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if fur_material != null:
		apply_fur(fur_material)
	play_idle()

func apply_fur(material: Material) -> void:
	var mesh := find_child("Cat", true, false) as MeshInstance3D
	if mesh == null or mesh.mesh == null:
		return
	# Surfaces 0 and 1 are the fur; surface 2 is the pink nose and inner ears.
	var fur_surfaces: int = mini(2, mesh.mesh.get_surface_count())
	for index in fur_surfaces:
		mesh.set_surface_override_material(index, material)

func play_idle() -> void:
	_play("CatArmature|Idle", 1.0)

func play_walk(speed_scale := 1.0) -> void:
	_play("CatArmature|Walking", clampf(speed_scale, 0.45, 2.2))

func _play(clip: String, speed: float) -> void:
	if _anim == null:
		return
	_anim.speed_scale = speed
	if _clip == clip:
		return
	_clip = clip
	_anim.play(clip)
