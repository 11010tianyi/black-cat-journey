extends SceneTree
func _initialize() -> void:
	var packed: PackedScene = load("res://assets/nature/Grass1.fbx")
	var inst := packed.instantiate()
	root.add_child(inst)
	var mesh: MeshInstance3D = null
	for c in inst.find_children("*", "MeshInstance3D", true, false):
		mesh = c
		break
	var m: Mesh = mesh.mesh
	var fmt: int = m.surface_get_format(0)
	print("SCAT fmt=", fmt, " bones=", bool(fmt & Mesh.ARRAY_FORMAT_BONES), " skin=", mesh.skin != null)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = m
	mm.instance_count = 3
	for i in 3:
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(2, 2, 2)), Vector3(i * 2.0, 0, -5)))
	print("SCAT aabb=", mm.get_aabb(), " count=", mm.instance_count, " mesh=", mm.mesh)
	quit(0)
