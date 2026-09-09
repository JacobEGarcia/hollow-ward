extends RefCounted
## Loads contract GLBs from res://assets/models/ when present, otherwise
## builds styled placeholder geometry with the same node names the game
## scripts expect (e.g. shambler ArmL/ArmR/Head/Body, door "Leaf").

const Mats = preload("res://scripts/materials.gd")

static func instantiate(asset_name: String) -> Node3D:
	var path := "res://assets/models/%s.glb" % asset_name
	if ResourceLoader.exists(path):
		var packed: PackedScene = load(path)
		if packed:
			return packed.instantiate()
	return _placeholder(asset_name)

static func has_real_asset(asset_name: String) -> bool:
	return ResourceLoader.exists("res://assets/models/%s.glb" % asset_name)

static func _placeholder(asset_name: String) -> Node3D:
	match asset_name:
		"hollowed_shambler": return _shambler()
		"pistol": return _pistol()
		"door_ward": return _door()
		"save_desk": return _save_desk()
		"ward_key": return _ward_key()
		"salve_plant": return _salve_plant()
		"ammo_box": return _ammo_box()
		"keypad_lock": return _keypad()
		"gurney": return _gurney()
		"wheelchair": return _wheelchair()
		"cabinet": return _cabinet()
		"ceiling_lamp": return _ceiling_lamp()
		"note_paper": return _note_paper()
	return Node3D.new()

static func _mi(mesh: Mesh, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	return mi

static func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b

static func _cyl(r: float, h: float, top_r := -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.bottom_radius = r
	c.top_radius = r if top_r < 0.0 else top_r
	c.height = h
	return c

static func _shambler() -> Node3D:
	var root := Node3D.new()
	root.name = "ShamblerVisual"
	var gown := Mats.grime(Mats.GOWN, 0.2)
	var body := Node3D.new()
	body.name = "Body"
	var cap := CapsuleMesh.new()
	cap.radius = 0.26
	cap.height = 1.3
	body.add_child(_mi(cap, gown, Vector3(0, 0.9, 0)))
	body.add_child(_mi(_box(Vector3(0.5, 0.28, 0.3)), gown, Vector3(0, 1.28, 0)))
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.62, 0)
	var sph := SphereMesh.new()
	sph.radius = 0.14
	sph.height = 0.28
	head.add_child(_mi(sph, Mats.flat(Mats.SKIN, 0.7)))
	# hollow black eyes
	head.add_child(_mi(_box(Vector3(0.05, 0.03, 0.02)), Mats.flat(Color.BLACK), Vector3(-0.055, 0.02, -0.125)))
	head.add_child(_mi(_box(Vector3(0.05, 0.03, 0.02)), Mats.flat(Color.BLACK), Vector3(0.055, 0.02, -0.125)))
	for side in ["L", "R"]:
		var arm := Node3D.new()
		arm.name = "Arm" + side
		var sx := -0.34 if side == "L" else 0.34
		arm.position = Vector3(sx, 1.38, 0)
		arm.add_child(_mi(_box(Vector3(0.11, 0.58, 0.11)), gown, Vector3(0, -0.26, 0)))
		arm.add_child(_mi(sph, Mats.flat(Mats.SKIN, 0.7), Vector3(0, -0.56, 0)))
		body.add_child(arm)
	root.add_child(body)
	root.add_child(head)
	return root

static func _pistol() -> Node3D:
	var root := Node3D.new()
	root.name = "PistolVisual"
	var metal := Mats.flat(Color(0.16, 0.16, 0.18), 0.45, 0.8)
	root.add_child(_mi(_box(Vector3(0.05, 0.065, 0.26)), metal, Vector3(0, 0.05, -0.13)))
	root.add_child(_mi(_box(Vector3(0.045, 0.15, 0.07)), metal, Vector3(0, -0.045, -0.01), Vector3(0.16, 0, 0)))
	root.add_child(_mi(_box(Vector3(0.02, 0.02, 0.03)), Mats.glow(Mats.AMBER, 1.2), Vector3(0, 0.09, -0.24)))
	return root

static func _door() -> Node3D:
	var root := Node3D.new()
	root.name = "DoorVisual"
	var frame_mat := Mats.flat(Mats.TEAL, 0.6, 0.4)
	root.add_child(_mi(_box(Vector3(0.12, 2.2, 0.24)), frame_mat, Vector3(-0.56, 1.1, 0)))
	root.add_child(_mi(_box(Vector3(0.12, 2.2, 0.24)), frame_mat, Vector3(0.56, 1.1, 0)))
	root.add_child(_mi(_box(Vector3(1.24, 0.12, 0.24)), frame_mat, Vector3(0, 2.16, 0)))
	var leaf := Node3D.new()
	leaf.name = "Leaf"
	leaf.position = Vector3(-0.5, 0, 0)
	var wood := Mats.grime(Color(0.19, 0.22, 0.22), 0.2)
	leaf.add_child(_mi(_box(Vector3(1.0, 2.1, 0.07)), wood, Vector3(0.5, 1.05, 0)))
	leaf.add_child(_mi(_box(Vector3(0.3, 0.3, 0.02)), Mats.flat(Color(0.55, 0.56, 0.5), 0.3), Vector3(0.5, 1.5, -0.045)))
	leaf.add_child(_mi(_cyl(0.025, 0.12), Mats.flat(Mats.AMBER * 0.7, 0.4, 0.9), Vector3(0.88, 1.05, 0), Vector3(PI / 2, 0, 0)))
	root.add_child(leaf)
	return root

static func _save_desk() -> Node3D:
	var root := Node3D.new()
	root.name = "SaveDeskVisual"
	var wood := Mats.grime(Mats.WOOD, 0.22)
	root.add_child(_mi(_box(Vector3(1.4, 0.08, 0.6)), wood, Vector3(0, 0.86, 0)))
	root.add_child(_mi(_box(Vector3(0.08, 0.86, 0.56)), wood, Vector3(-0.62, 0.43, 0)))
	root.add_child(_mi(_box(Vector3(0.08, 0.86, 0.56)), wood, Vector3(0.62, 0.43, 0)))
	root.add_child(_mi(_box(Vector3(1.2, 0.3, 0.5)), wood, Vector3(0, 0.65, 0.03)))
	root.add_child(_mi(_box(Vector3(0.34, 0.02, 0.24)), Mats.flat(Mats.BONE, 0.85), Vector3(-0.09, 0.91, 0), Vector3(0, 0, 0.06)))
	root.add_child(_mi(_box(Vector3(0.34, 0.02, 0.24)), Mats.flat(Mats.BONE, 0.85), Vector3(0.09, 0.91, 0), Vector3(0, 0, -0.06)))
	root.add_child(_mi(_box(Vector3(0.4, 0.045, 0.26)), Mats.flat(Color(0.28, 0.2, 0.08), 0.6), Vector3(0, 0.895, 0)))
	root.add_child(_mi(_box(Vector3(0.1, 0.06, 0.1)), Mats.glow(Mats.AMBER, 1.4), Vector3(-0.5, 0.93, -0.15)))
	return root

static func _ward_key() -> Node3D:
	var root := Node3D.new()
	root.name = "KeyVisual"
	var brass := Mats.glow(Mats.AMBER * Color(0.9, 0.75, 0.3), 0.7)
	root.add_child(_mi(_cyl(0.035, 0.012), brass, Vector3(0, 0, 0.045), Vector3(PI / 2, 0, 0)))
	root.add_child(_mi(_box(Vector3(0.016, 0.016, 0.09)), brass, Vector3(0, 0, -0.02)))
	root.add_child(_mi(_box(Vector3(0.03, 0.016, 0.02)), brass, Vector3(0.014, 0, -0.06)))
	root.add_child(_mi(_box(Vector3(0.03, 0.016, 0.02)), brass, Vector3(0.014, 0, -0.045)))
	return root

static func _salve_plant() -> Node3D:
	var root := Node3D.new()
	root.name = "SalveVisual"
	root.add_child(_mi(_cyl(0.09, 0.14, 0.07), Mats.grime(Color(0.3, 0.2, 0.14), 0.25), Vector3(0, 0.07, 0)))
	var leaf_mat := Mats.glow(Color(0.55, 0.72, 0.55), 0.5)
	for i in 6:
		var ang := TAU * i / 6.0
		var blade := _mi(_box(Vector3(0.02, 0.3, 0.005)), leaf_mat, Vector3(cos(ang) * 0.04, 0.27, sin(ang) * 0.04), Vector3(0.35 * sin(ang), ang, 0.35 * cos(ang)))
		root.add_child(blade)
	return root

static func _ammo_box() -> Node3D:
	var root := Node3D.new()
	root.name = "AmmoVisual"
	root.add_child(_mi(_box(Vector3(0.18, 0.1, 0.12)), Mats.flat(Mats.METAL * 0.6, 0.5, 0.6)))
	root.add_child(_mi(_box(Vector3(0.185, 0.02, 0.125)), Mats.glow(Mats.AMBER, 0.9), Vector3(0, 0.03, 0)))
	return root

static func _keypad() -> Node3D:
	var root := Node3D.new()
	root.name = "KeypadVisual"
	root.add_child(_mi(_box(Vector3(0.2, 0.3, 0.04)), Mats.flat(Color(0.1, 0.11, 0.12), 0.5, 0.5)))
	root.add_child(_mi(_box(Vector3(0.14, 0.06, 0.01)), Mats.glow(Mats.TEAL * 2.0, 1.2), Vector3(0, 0.1, -0.021)))
	return root

static func _gurney() -> Node3D:
	var root := Node3D.new()
	root.name = "GurneyVisual"
	var metal := Mats.flat(Mats.METAL, 0.4, 0.7)
	root.add_child(_mi(_box(Vector3(0.7, 0.08, 1.9)), Mats.grime(Color(0.62, 0.63, 0.6), 0.2), Vector3(0, 0.82, 0)))
	root.add_child(_mi(_box(Vector3(0.6, 0.06, 1.7)), metal, Vector3(0, 0.4, 0)))
	for x in [-0.28, 0.28]:
		for z in [-0.75, 0.75]:
			root.add_child(_mi(_cyl(0.02, 0.78), metal, Vector3(x, 0.42, z)))
			root.add_child(_mi(_cyl(0.05, 0.02), metal, Vector3(x, 0.05, z), Vector3(PI / 2, 0, 0)))
	return root

static func _wheelchair() -> Node3D:
	var root := Node3D.new()
	root.name = "WheelchairVisual"
	var metal := Mats.flat(Mats.METAL * 0.7, 0.4, 0.7)
	root.add_child(_mi(_box(Vector3(0.45, 0.05, 0.4)), metal, Vector3(0, 0.5, 0)))
	root.add_child(_mi(_box(Vector3(0.45, 0.5, 0.05)), metal, Vector3(0, 0.75, 0.2)))
	for x in [-0.26, 0.26]:
		root.add_child(_mi(_cyl(0.3, 0.02), metal, Vector3(x, 0.3, 0), Vector3(0, 0, PI / 2)))
		root.add_child(_mi(_cyl(0.08, 0.02), metal, Vector3(x, 0.08, -0.28), Vector3(0, 0, PI / 2)))
	root.add_child(_mi(_box(Vector3(0.4, 0.03, 0.06)), metal, Vector3(0, 0.35, -0.3)))
	return root

static func _cabinet() -> Node3D:
	var root := Node3D.new()
	root.name = "CabinetVisual"
	var metal := Mats.grime(Mats.TEAL * 0.8, 0.2)
	root.add_child(_mi(_box(Vector3(0.8, 1.8, 0.4)), metal, Vector3(0, 0.9, 0)))
	root.add_child(_mi(_box(Vector3(0.02, 1.6, 0.02)), Mats.flat(Mats.METAL, 0.4, 0.8), Vector3(0, 0.9, -0.21)))
	return root

static func _ceiling_lamp() -> Node3D:
	var root := Node3D.new()
	root.name = "LampVisual"
	var metal := Mats.flat(Color(0.12, 0.12, 0.13), 0.5, 0.6)
	root.add_child(_mi(_cyl(0.015, 0.5), metal, Vector3(0, -0.25, 0)))
	root.add_child(_mi(_cyl(0.16, 0.1, 0.05), metal, Vector3(0, -0.55, 0)))
	root.add_child(_mi(_cyl(0.13, 0.02), Mats.glow(Color(0.9, 0.85, 0.7), 1.8), Vector3(0, -0.61, 0)))
	return root

static func _note_paper() -> Node3D:
	var root := Node3D.new()
	root.name = "NoteVisual"
	root.add_child(_mi(_box(Vector3(0.21, 0.005, 0.29)), Mats.flat(Mats.BONE, 0.9)))
	return root
