extends Node3D

## Three glow rings along the road. Walking through one records the journey.

signal reached(id: String, position: Vector3)

const POINTS := [
	{"id": "grass_end", "z": -140.0, "label": "草原尽头"},
	{"id": "ruin_end", "z": -300.0, "label": "废墟尽头"},
	{"id": "snow_gate", "z": -430.0, "label": "雪原入口"},
]

func _ready() -> void:
	for point in POINTS:
		_build(point["id"], float(point["z"]))

func _build(id: String, z: float) -> void:
	var area := Area3D.new()
	area.name = "Checkpoint_%s" % id
	area.position = Vector3(0.0, 1.2, z)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.2
	shape.shape = sphere
	area.add_child(shape)

	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.6
	mesh.bottom_radius = 2.6
	mesh.height = 0.06
	disc.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.86, 0.58, 0.28)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.74, 0.36)
	material.emission_energy_multiplier = 1.4
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = material
	disc.position = Vector3(0.0, -1.15, 0.0)
	area.add_child(disc)

	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			reached.emit(id, Vector3(0.0, 0.3, z))
	)
	add_child(area)
