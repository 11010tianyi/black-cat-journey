extends Node3D

## Builds the corridor. Terrain is a Terrain3D heightmap (C++ extension) painted
## with a triplanar grass/rock/snow palette; props are low-poly CC0 models
## scattered as MultiMeshes.

@export var use_terrain3d := true
@export var use_nature_models := false
@export var terrain_width := 170.0
@export var terrain_length := 560.0
@export var columns := 64
@export var rows := 200
@export var hill_height := 8.0
@export var region_size := 128
@export var vertex_spacing := 1.0

const NATURE := "res://assets/nature/%s.fbx"

var _noise := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _terrain: Terrain3D

func _ready() -> void:
	_noise.seed = 20260528
	_noise.frequency = 0.018
	_noise.fractal_octaves = 3
	_detail.seed = 771
	_detail.frequency = 0.12
	# The native Terrain3D library is not guaranteed to be packed into exported
	# builds yet, so fall back to the mesh rather than shipping a terrainless map.
	if use_terrain3d and ClassDB.class_exists("Terrain3D"):
		_build_terrain3d()
	else:
		push_warning("Terrain3D 不可用，退回程序化地形网格")
		_build_terrain_mesh()
	_scatter_nature()

func height_at(x: float, z: float) -> float:
	# Flat within |x| <= 5 so the walking lane and the slice test stay level.
	var edge := clampf((absf(x) - 5.0) / 24.0, 0.0, 1.0)
	var ridge := _noise.get_noise_2d(x, z) * hill_height * edge * edge
	var roll := _noise.get_noise_2d(x * 0.4, z * 0.4) * 0.6 * edge
	return ridge + roll

func _build_terrain3d() -> void:
	_terrain = Terrain3D.new()
	_terrain.name = "Terrain3D"
	_terrain.vertex_spacing = vertex_spacing
	_terrain.region_size = region_size
	_terrain.collision_mode = 0
	_terrain.show_checkered = false
	_terrain.show_grey = false
	add_child(_terrain)

	var half := terrain_width * 0.5
	var z_start := 30.0
	var z_end := z_start - terrain_length
	var rx0 := floori(-half / float(region_size))
	var rx1 := floori((half - 1.0) / float(region_size))
	var rz0 := floori(z_end / float(region_size))
	var rz1 := floori((z_start - 1.0) / float(region_size))

	var filled := 0
	for rx in range(rx0, rx1 + 1):
		for rz in range(rz0, rz1 + 1):
			_terrain.data.add_region_blank(Vector2i(rx, rz))
			var base_x := float(rx * region_size)
			var base_z := float(rz * region_size)
			for px in range(region_size):
				var x := base_x + float(px) * vertex_spacing
				if absf(x) > 95.0:
					continue
				for pz in range(region_size):
					var z := base_z + float(pz) * vertex_spacing
					_terrain.data.set_height(Vector3(x, 0.0, z), height_at(x, z))
					filled += 1
	_terrain.data.update_maps()
	print("WORLD terrain3d regions=", rx1 - rx0 + 1, "x", rz1 - rz0 + 1, " heights=", filled)
	_apply_palette_material()
	_build_collision_mesh()

## Terrain3D builds its own collision asynchronously, which makes the first frames
## of a level (and headless tests) fall through the floor. A coarse mesh from the
## same height function gives deterministic collision from frame one.
func _build_collision_mesh() -> void:
	const STEP := 2.0
	var half := terrain_width * 0.5
	var z_near := 30.0
	var z_far := z_near - terrain_length
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z := z_near
	while z > z_far:
		var x := -half
		while x < half:
			var p00 := Vector3(x, height_at(x, z), z)
			var p10 := Vector3(x + STEP, height_at(x + STEP, z), z)
			var p01 := Vector3(x, height_at(x, z - STEP), z - STEP)
			var p11 := Vector3(x + STEP, height_at(x + STEP, z - STEP), z - STEP)
			for tri in [[p00, p01, p11], [p00, p11, p10]]:
				for point in tri:
					st.add_vertex(point)
			x += STEP
		z -= STEP
	st.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = "TerrainCollision"
	instance.mesh = st.commit()
	instance.visible = false
	add_child(instance)
	instance.create_trimesh_collision()

func _apply_palette_material() -> void:
	var material = _terrain.material
	if material == null:
		push_warning("Terrain3D 没有 material")
		return
	material.show_checkered = false
	material.show_grey = false
	var shader: Shader = load("res://shaders/terrain_palette.gdshader")
	if shader == null:
		return
	material.shader_override = shader
	material.enable_shader_override(true)
	material.set_shader_param("tex_grass", load("res://assets/textures/terrain/grass_ground_diff.jpg"))
	material.set_shader_param("tex_rock", load("res://assets/textures/terrain/aerial_rocks_01_diff.jpg"))
	material.set_shader_param("tex_snow", load("res://assets/textures/terrain/snow_01_diff.jpg"))
	material.update()

func _build_terrain_mesh() -> void:
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
			var color := _zone_color(z0)
			for tri in [[p00, p01, p11], [p00, p11, p10]]:
				for point in tri:
					st.set_color(color.srgb_to_linear())
					st.add_vertex(point)
	st.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = "Terrain"
	instance.mesh = st.commit()
	instance.create_trimesh_collision()
	add_child(instance)

func _zone_color(z: float) -> Color:
	var ruin := clampf((-z - 130.0) / 110.0, 0.0, 1.0)
	var snow := clampf((-z - 300.0) / 90.0, 0.0, 1.0)
	return Color(0.23, 0.36, 0.28).lerp(Color(0.43, 0.40, 0.36), ruin).lerp(Color(0.72, 0.78, 0.82), snow)

func _scatter_nature() -> void:
	if not use_nature_models:
		_scatter_primitives()
		return
	_scatter(["Bush1", "Bush2", "Bush3"], 2400, 20.0, -530.0, 26.0, 0.38, Color(0.26, 0.40, 0.24))
	_scatter(["Rock1", "Rock2", "Rock3"], 220, 10.0, -530.0, 34.0, 1.1, Color(0.42, 0.40, 0.37))
	_scatter(["Tree1", "Tree2", "Tree3", "Tree4"], 130, 10.0, -530.0, 46.0, 4.5, Color(0.20, 0.30, 0.22))
	# Grass1-3 are flat ground cards, so the 3D bushes double as tufts.
	_scatter(["Bush1", "Bush2", "Bush3"], 2400, 20.0, -530.0, 26.0, 0.38, Color(0.26, 0.40, 0.24))
	_scatter(["Rock1", "Rock2", "Rock3"], 220, 10.0, -530.0, 34.0, 1.1, Color(0.42, 0.40, 0.37))
	_scatter(["Tree1", "Tree2", "Tree3", "Tree4"], 130, 10.0, -530.0, 46.0, 4.5, Color(0.20, 0.30, 0.22))

## The FBX models carry their unit conversion on an ancestor node, so their mesh
## resources are ~100x too small. Measure the assembled world height once and
## scale every instance to `target_height`.
func _scatter_primitives() -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.05
	cone.height = 0.45
	cone.radial_segments = 3
	var rock := SphereMesh.new()
	rock.radius = 0.5
	rock.height = 0.9
	rock.radial_segments = 5
	rock.rings = 3
	_primitive_field(cone, 2200, 24.0, 0.55, Color(0.30, 0.44, 0.27))
	_primitive_field(rock, 220, 32.0, 1.1, Color(0.42, 0.40, 0.37))

func _primitive_field(mesh: Mesh, count: int, spread: float, size: float, tint: Color) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = count
	for index in count:
		var z := rng.randf_range(20.0, -530.0)
		var x := rng.randf_range(-spread, spread)
		if absf(x) < 5.5:
			x += 7.0 * (1.0 if x >= 0.0 else -1.0)
		var s := size * rng.randf_range(0.6, 1.4)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.6), s))
		multimesh.set_instance_transform(index, Transform3D(basis, Vector3(x, height_at(x, z) - 0.05, z)))
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var node := MultiMeshInstance3D.new()
	node.name = "Scatter_%d" % count
	node.multimesh = multimesh
	node.material_override = material
	add_child(node)

func _scatter(names: Array, count: int, z_near: float, z_far: float, spread: float, target_height: float, tint: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(names[0]) + count
	var per_model := int(ceil(float(count) / float(names.size())))
	for model_name in names:
		var packed: PackedScene = load(NATURE % model_name)
		if packed == null:
			continue
		var probe := packed.instantiate()
		add_child(probe)
		var mesh := _find_mesh(probe)
		if mesh == null or mesh.mesh == null:
			probe.queue_free()
			continue
		var world_aabb: AABB = mesh.global_transform * mesh.get_aabb()
		var base_scale := target_height / maxf(world_aabb.size.y, 0.001)
		remove_child(probe)
		probe.queue_free()
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh.mesh
		multimesh.instance_count = per_model
		var placed := 0
		for index in per_model:
			var z := rng.randf_range(z_far, z_near)
			var x := rng.randf_range(-spread, spread)
			if absf(x) < 6.0:
				x += 7.0 * (1.0 if x >= 0.0 else -1.0)
			var s := base_scale * rng.randf_range(0.75, 1.35)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.85, 1.25), s))
			multimesh.set_instance_transform(index, Transform3D(basis, Vector3(x, height_at(x, z) - 0.04, z)))
			placed += 1
		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		material.roughness = 0.95
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		print("WORLD scatter ", model_name, " placed=", placed, " base_scale=", snappedf(base_scale, 0.001))
		multimesh.custom_aabb = AABB(Vector3(-80.0, -20.0, -560.0), Vector3(180.0, 60.0, 620.0))
		var node := MultiMeshInstance3D.new()
		node.name = "Scatter_%s" % model_name
		node.multimesh = multimesh
		node.material_override = material
		add_child(node)
		probe.free()

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _find_mesh(child)
		if found != null:
			return found
	return null
