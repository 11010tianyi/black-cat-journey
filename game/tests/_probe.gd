extends SceneTree
func _initialize() -> void:
	for name in ["Grass1", "Bush1", "Rock1", "Tree1"]:
		var packed: PackedScene = load("res://assets/nature/%s.fbx" % name)
		var inst := packed.instantiate()
		root.add_child(inst)
		print("PROBE == ", name)
		for node in inst.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			var m := mi.mesh
			var verts := 0
			if m != null:
				for s in m.get_surface_count():
					var arr := m.surface_get_arrays(s)
					verts += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			print("PROBE   mesh=", mi.name, " surfaces=", m.get_surface_count() if m else -1,
				" verts=", verts, " aabb=", m.get_aabb().size if m else Vector3.ZERO,
				" visible=", mi.visible, " skin=", mi.skin != null)
		inst.queue_free()
	quit(0)
