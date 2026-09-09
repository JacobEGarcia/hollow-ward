extends CharacterBody3D
## Flat-mode FPS player (desktop browser / testing).

const Sfx = preload("res://scripts/sfx.gd")
const Gun = preload("res://scripts/player/gun.gd")
const Util = preload("res://scripts/util.gd")

const SPEED := 2.5
const GRAVITY := 20.0
const MOUSE_SENS := 0.0022
const INTERACT_DIST := 2.6

var yaw := 0.0
var pitch := 0.0
var head: Node3D
var camera: Camera3D
var flashlight: SpotLight3D
var interact_ray: RayCast3D
var gun: Node3D
var bob_phase := 0.0
var step_dist := 0.0
var active := false
var current_prompt := ""

func _ready() -> void:
	collision_layer = 0b010
	collision_mask = 0b1011
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.7
	shape.shape = cap
	shape.position.y = 0.85
	add_child(shape)
	head = Node3D.new()
	head.position.y = 1.58
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.current = true
	head.add_child(camera)
	flashlight = SpotLight3D.new()
	flashlight.light_color = Color(0.95, 0.9, 0.78)
	flashlight.light_energy = 2.4
	flashlight.spot_range = 13.0
	flashlight.spot_angle = 30.0
	flashlight.spot_attenuation = 1.1
	flashlight.shadow_enabled = true
	camera.add_child(flashlight)
	interact_ray = RayCast3D.new()
	interact_ray.target_position = Vector3(0, 0, -INTERACT_DIST)
	interact_ray.collision_mask = 0b100010011
	camera.add_child(interact_ray)
	gun = Gun.new()
	gun.aim_node = camera
	gun.position = Vector3(0.24, -0.22, -0.45)
	camera.add_child(gun)
	GS.noise_emitted.connect(_on_noise)

func set_active(v: bool) -> void:
	active = v
	set_physics_process(v)
	set_process_unhandled_input(v)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if v else Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * MOUSE_SENS
		pitch = clampf(pitch - event.relative.y * MOUSE_SENS, -1.45, 1.45)
		rotation.y = yaw
		head.rotation.x = pitch
	if event.is_action_pressed("fire"):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		var clicked := _pointer_clickable()
		if clicked != null:
			clicked.clicked(self)
		else:
			gun.try_fire(self)
	if event.is_action_pressed("interact"):
		var it := _pointer_interactable()
		if it != null:
			it.interact(self)
	if event.is_action_pressed("reload"):
		gun.try_reload()
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not active:
		return
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward"))
	var dir := (Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, yaw)
	var moving := dir.length() > 0.1
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	if moving and is_on_floor():
		step_dist += SPEED * delta
		bob_phase += delta * 7.0
		camera.position.y = sin(bob_phase) * 0.025
		if step_dist > 1.4:
			step_dist = 0.0
			Sfx.play_at(self, "footstep", global_position, -12.0, randf_range(0.9, 1.1))
			GS.emit_noise(global_position, 5.0)
	else:
		camera.position.y = lerpf(camera.position.y, 0.0, delta * 8.0)
	_update_prompt()

func _update_prompt() -> void:
	current_prompt = ""
	var it := _pointer_interactable()
	if it != null and it.has_method("get_prompt"):
		current_prompt = it.get_prompt()

func _pointer_collider() -> Object:
	interact_ray.force_raycast_update()
	if interact_ray.is_colliding():
		return interact_ray.get_collider()
	return null

func _pointer_interactable() -> Node:
	var c = _pointer_collider()
	if c == null:
		return null
	return Util.find_owner_with(c, "interact")

func _pointer_clickable() -> Node:
	var c = _pointer_collider()
	if c == null:
		return null
	return Util.find_owner_with(c, "clicked")

func _on_noise(_pos: Vector3, _radius: float) -> void:
	pass

func get_state() -> Dictionary:
	return {"pos": [global_position.x, global_position.y, global_position.z], "yaw": yaw}

func set_state(st: Dictionary) -> void:
	if st.has("pos"):
		global_position = Vector3(st.pos[0], st.pos[1], st.pos[2])
	if st.has("yaw"):
		yaw = st.yaw
		rotation.y = yaw
