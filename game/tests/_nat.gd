extends SceneTree
var f := 0
var holder: Node3D
func _initialize() -> void:
	holder = Node3D.new()
	root.add_child(holder)
	physics_frame.connect(_t)
func _t() -> void:
	f += 1
	if f < 3: return
	for name in ["Grass1", "Rock1", "Tree1"]:
		var scene: PackedScene = load("res://assets/nature/%s.fbx" % name)
		var inst := scene.instantiate()
		holder.add_child(inst)
		var mesh := _find_mesh(inst)
		var world: AABB = mesh.global_transform * mesh.get_aabb()
		print("NAT ", name, " root_scale=", inst.global_transform.basis.get_scale(), " world_size=", world.size)
		inst.queue_free()
	quit(0)
func _find_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var m := _find_mesh(c)
		if m: return m
	return null
