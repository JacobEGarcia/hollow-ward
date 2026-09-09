extends CharacterBody3D
## XR player rig (WebXR on Quest browser; OpenXR native if ever exported).

const Sfx = preload("res://scripts/sfx.gd")
const Gun = preload("res://scripts/player/gun.gd")
const Util = preload("res://scripts/util.gd")

const SPEED := 2.2
const GRAVITY := 20.0
const SNAP_ANGLE := PI / 4.0
const POINTER_DIST := 3.0

var origin: XROrigin3D
var camera: XRCamera3D
var left: XRController3D
var right: XRController3D
var gun: Node3D
var laser: MeshInstance3D
var wrist: Label3D
var msg_label: Label3D
var msg_timer := 0.0
var snap_ready := true
var prev_buttons := {}
var font: Font

func _ready() -> void:
	collision_layer = 0b010
	collision_mask = 0b1011
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.6
	shape.shape = cap
	shape.position.y = 0.8
	add_child(shape)
	font = load("res://assets/fonts/IBMPlexMono-Regular.ttf")
	origin = XROrigin3D.new()
	add_child(origin)
	camera = XRCamera3D.new()
	origin.add_child(camera)
	var lamp := SpotLight3D.new()
	lamp.light_color = Color(0.95, 0.9, 0.78)
	lamp.light_energy = 2.4
	lamp.spot_range = 13.0
	lamp.spot_angle = 30.0
	lamp.shadow_enabled = true
	camera.add_child(lamp)
	left = XRController3D.new()
	left.tracker = "left_hand"
	origin.add_child(left)
	right = XRController3D.new()
	right.tracker = "right_hand"
	origin.add_child(right)
	gun = Gun.new()
	gun.aim_node = right
	gun.position = Vector3(0, -0.02, -0.08)
	right.add_child(gun)
	var lm := BoxMesh.new()
	lm.size = Vector3(0.008, 0.008, 1.0)
	laser = MeshInstance3D.new()
	laser.mesh = lm
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.9, 0.87, 0.8, 0.35)
	lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	laser.material_override = lmat
	laser.visible = false
	left.add_child(laser)
	wrist = Label3D.new()
	wrist.font = font
	wrist.font_size = 42
	wrist.pixel_size = 0.0018
	wrist.position = Vector3(0, 0.06, 0.05)
	wrist.rotation.x = -0.9
	left.add_child(wrist)
	msg_label = Label3D.new()
	msg_label.font = font
	msg_label.font_size = 48
	msg_label.pixel_size = 0.0016
	msg_label.modulate = Color(0.92, 0.89, 0.82)
	msg_label.position = Vector3(0, -0.32, -1.3)
	msg_label.visible = false
	camera.add_child(msg_label)
	GS.message.connect(_on_message)
	GS.health_changed.connect(func(_v, _m): _refresh_wrist())
	GS.ammo_changed.connect(func(_a, _b): _refresh_wrist())
	GS.inventory_changed.connect(_refresh_wrist)
	_refresh_wrist()

func _physics_process(delta: float) -> void:
	var stick := left.get_vector2("thumbstick")
	var fwd := -camera.global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	var sidev := camera.global_transform.basis.x
	sidev.y = 0
	sidev = sidev.normalized()
	var dir := fwd * (-stick.y) + sidev * stick.x
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	var snap := right.get_vector2("thumbstick").x
	if absf(snap) > 0.7 and snap_ready:
		snap_ready = false
		_snap_turn(-signf(snap) * SNAP_ANGLE)
	elif absf(snap) < 0.3:
		snap_ready = true
	_button_edge(right, "trigger_click", func(): gun.try_fire(self))
	_button_edge(right, "ax_button", func(): gun.try_reload())
	_button_edge(left, "grip_click", _pointer_act)
	_button_edge(left, "ax_button", _combine_salves)
	_button_edge(left, "by_button", _use_best_salve)
	_update_pointer()
	if msg_timer > 0.0:
		msg_timer -= delta
		if msg_timer <= 0.0:
			msg_label.visible = false

func _snap_turn(angle: float) -> void:
	var cam_pos := camera.global_position
	var pivot := Vector3(cam_pos.x, global_position.y, cam_pos.z)
	var offset := global_position - pivot
	global_position = pivot + offset.rotated(Vector3.UP, angle)
	rotate_y(angle)

func _button_edge(ctrl: XRController3D, button: String, action: Callable) -> void:
	var key := str(ctrl.tracker) + "_" + button
	var now: bool = ctrl.is_button_pressed(button)
	var was: bool = prev_buttons.get(key, false)
	if now and not was:
		action.call()
	prev_buttons[key] = now

func _pointer_ray() -> Dictionary:
	var from := left.global_position
	var to := from + -left.global_transform.basis.z * POINTER_DIST
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to, 0b10001001, [self])
	return space.intersect_ray(q)

func _update_pointer() -> void:
	var hit := _pointer_ray()
	if hit.is_empty():
		laser.visible = false
		return
	laser.visible = true
	var d: float = left.global_position.distance_to(hit.position)
	laser.scale = Vector3(1, 1, d)
	laser.position = Vector3(0, 0, -d / 2.0)

func _pointer_act() -> void:
	var hit := _pointer_ray()
	if hit.is_empty():
		return
	var it := Util.find_owner_with(hit.collider, "interact")
	if it != null:
		it.interact(self)
		return
	var ck := Util.find_owner_with(hit.collider, "clicked")
	if ck != null:
		ck.clicked(self)

func _combine_salves() -> void:
	if GS.combine_salves():
		Sfx.play(self, "heal", -6.0)

func _use_best_salve() -> void:
	if GS.count_item("potent_salve") > 0 and GS.health <= GS.max_health - 90:
		GS.use_item("potent_salve")
		Sfx.play(self, "heal", -4.0)
	elif GS.count_item("salve") > 0:
		GS.use_item("salve")
		Sfx.play(self, "heal", -4.0)
	elif GS.count_item("potent_salve") > 0:
		GS.use_item("potent_salve")
		Sfx.play(self, "heal", -4.0)

func _on_message(text: String) -> void:
	msg_label.text = text
	msg_label.visible = true
	msg_timer = 4.0

func _refresh_wrist() -> void:
	var inv := ""
	for it in GS.inventory:
		inv += "%s x%d  " % [it.name, it.qty]
	wrist.text = "HP %d   MAG %d/%d\n%s" % [GS.health, GS.ammo_mag, GS.ammo_reserve, inv]

func get_state() -> Dictionary:
	return {"pos": [global_position.x, global_position.y, global_position.z], "yaw": rotation.y}

func set_state(st: Dictionary) -> void:
	if st.has("pos"):
		global_position = Vector3(st.pos[0], st.pos[1], st.pos[2])
	if st.has("yaw"):
		rotation.y = st.yaw
