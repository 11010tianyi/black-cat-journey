extends Node3D

## Builds the whole corridor at runtime: a height-mapped strip whose middle stays
## flat (the walking lane) and whose edges roll up into hills, tinted per zone
## (grassland -> ruins -> snow), plus scattered rocks and grass tufts.

const GRASS := Color(0.23, 0.36, 0.28)
const RUIN := Color(0.43, 0.40, 0.36)
const SNOW := Color(0.72, 0.78, 0.82)

@export var terrain_width := 170.0
@export var terrain_length := 560.0
@export var columns := 64
@export var rows := 200
@export var hill_height := 8.0

var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()

func _ready() -> void:
	_noise.seed = 20260528
	_noise.frequency = 0.018
	_noise.fractal_octaves = 3
	_detail.seed = 771
	_detail.frequency = 0.12
	var region := _create_navigation_region()
	_build_terrain(region)
	_scatter_rocks()
	_scatter_grass()
	_bake_navigation(region)

func height_at(x: float, z: float) -> float:
	# Flat within |x| <= 5 so the walking lane and the slice test stay level.
	var edge := clampf((absf(x) - 5.0) / 24.0, 0.0, 1.0)
	var ridge := _noise.get_noise_2d(x, z) * hill_height * edge * edge
	var roll := _noise.get_noise_2d(x * 0.4, z * 0.4) * 0.6 * edge
	return ridge + roll

func zone_color(z: float) -> Color:
	var ruin_mix := clampf((-z - 130.0) / 110.0, 0.0, 1.0)
	var snow_mix := clampf((-z - 300.0) / 90.0, 0.0, 1.0)
	return GRASS.lerp(RUIN, ruin_mix).lerp(SNOW, snow_mix)

func _create_navigation_region() -> NavigationRegion3D:
	var nav_mesh := NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.cell_size = 0.5
	nav_mesh.cell_height = 0.25
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 1.25
	nav_mesh.agent_max_climb = 0.5
	nav_mesh.agent_max_slope = 38.0
	# Only the walking corridor needs a path mesh; the outer hills would triple
	# the voxel count for nothing.
	nav_mesh.filter_baking_aabb = AABB(Vector3(-32.0, -6.0, -540.0), Vector3(64.0, 22.0, 580.0))
	var region := NavigationRegion3D.new()
	region.name = "NavigationRegion3D"
	region.navigation_mesh = nav_mesh
	add_child(region)
	return region

func _bake_navigation(region: NavigationRegion3D) -> void:
	region.bake_navigation_mesh(false)

func _build_terrain(region: NavigationRegion3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := terrain_width * 0.5
	for j in rows:
		for i in columns:
			var x0 := -half + terrain_width * float(i) / float(columns)
			var x1 := -half + terrain_width * float(i + 1) / float(columns)
			var z0 := 30.0 - terrain_length * float(j) / float(rows)
			var z1 := 30.0 - terrain_length * float(j + 1) / float(rows)
			var p00 := Vector3(x0, height_at(x0, z0), z0)
			var p10 := Vector3(x1, height_at(x1, z0), z0)
			var p01 := Vector3(x0, height_at(x0, z1), z1)
			var p11 := Vector3(x1, height_at(x1, z1), z1)
			_triangle(st, p00, p01, p11, z0)
			_triangle(st, p00, p11, p10, z0)
	st.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = "Terrain"
	instance.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	instance.material_override = material
	region.add_child(instance)
	instance.create_trimesh_collision()

func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, z_for_color: float) -> void:
	var base := zone_color(z_for_color)
	var tint := 0.9 + _detail.get_noise_2d(a.x, a.z) * 0.18
	# Vertex colours are linear; the palette above is authored in sRGB.
	var color := Color(base.r * tint, base.g * tint, base.b * tint).srgb_to_linear()
	for point in [a, b, c]:
		st.set_color(color)
		st.add_vertex(point)

func _scatter_rocks() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 0.9
	mesh.radial_segments = 5
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.38, 0.36, 0.33)
	material.roughness = 1.0
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = 48
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for index in multimesh.instance_count:
		var z := rng.randf_range(-150.0, -350.0)
		var x := rng.randf_range(-26.0, 26.0)
		if absf(x) < 6.5:
			x += 8.0 * signf(x if x != 0.0 else 1.0)
		var scale := rng.randf_range(0.6, 2.4)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale, scale * rng.randf_range(0.6, 1.2), scale))
		multimesh.set_instance_transform(index, Transform3D(basis, Vector3(x, height_at(x, z) + 0.1 * scale, z)))
	var instance := MultiMeshInstance3D.new()
	instance.name = "Rocks"
	instance.multimesh = multimesh
	instance.material_override = material
	add_child(instance)

func _scatter_grass() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.05
	mesh.height = 0.45
	mesh.radial_segments = 3
	mesh.rings = 1
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.29, 0.42, 0.3)
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = 900
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for index in multimesh.instance_count:
		var z := rng.randf_range(25.0, -330.0)
		var x := rng.randf_range(-40.0, 40.0)
		if absf(x) < 5.5:
			x += 7.5 * signf(x if x != 0.0 else 1.0)
		var height_scale := rng.randf_range(0.7, 1.9)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(1.0, height_scale, 1.0))
		multimesh.set_instance_transform(index, Transform3D(basis, Vector3(x, height_at(x, z) + 0.2 * height_scale, z)))
	var instance := MultiMeshInstance3D.new()
	instance.name = "Grass"
	instance.multimesh = multimesh
	instance.material_override = material
	add_child(instance)
