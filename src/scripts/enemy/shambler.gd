extends CharacterBody3D
## "Hollowed" shambler: dormant/patrol/alert/chase/attack/stagger/dead.

const Sfx = preload("res://scripts/sfx.gd")
const Factory = preload("res://scripts/asset_factory.gd")

@export var shambler_id := "shambler_0"
@export var dormant := false
@export var patrol_radius := 3.0

const HP_MAX := 100
const SPEED_WALK := 0.55
const SPEED_CHASE := 1.35
const SIGHT_DIST := 8.5
const SIGHT_DOT := 0.25
const ATTACK_RANGE := 1.6
const ATTACK_HIT_RANGE := 2.0
const ATTACK_DAMAGE := 20
const GRAVITY := 20.0

var hp := HP_MAX
var state := "idle"
var agent: NavigationAgent3D
var visual: Node3D
var anim: AnimationPlayer
var body_node: Node3D
var arm_l: Node3D
var arm_r: Node3D
var home := Vector3.ZERO
var patrol_target := Vector3.ZERO
var repath := 0.0
var windup := 0.0
var attack_cd := 0.0
var stagger := 0.0
var moan_timer := 5.0
var anim_t := 0.0
var player: Node3D

func _ready() -> void:
	if GS.flags.get("dead_" + shambler_id, false):
		queue_free()
		return
	add_to_group("shamblers")
	collision_layer = 0b100
	collision_mask = 0b1011
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	shape.shape = cap
	shape.position.y = 0.85
	add_child(shape)
	visual = Factory.instantiate("hollowed_shambler")
	add_child(visual)
	anim = _find_anim_player(visual)
	body_node = visual.find_child("Body", true, false)
	arm_l = visual.find_child("ArmL", true, false)
	arm_r = visual.find_child("ArmR", true, false)
	agent = NavigationAgent3D.new()
	agent.radius = 0.35
	agent.height = 1.7
	agent.path_desired_distance = 0.4
	agent.target_desired_distance = 0.6
	add_child(agent)
	home = global_position
	_patrol_target_new()
	state = "dormant" if dormant else "patrol"
	moan_timer = randf_range(4.0, 9.0)
	GS.noise_emitted.connect(_on_noise)
	_update_player.call_deferred()

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r := _find_anim_player(c)
		if r != null:
			return r
	return null

func _update_player() -> void:
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if state == "dead":
		return
	if player == null or not is_instance_valid(player):
		_update_player()
		if player == null:
			return
	anim_t += delta
	attack_cd = maxf(0.0, attack_cd - delta)
	moan_timer -= delta
	if moan_timer <= 0.0 and state in ["chase", "attack", "alert"]:
		moan_timer = randf_range(4.0, 9.0)
		Sfx.play_at(self, "moan", global_position, -6.0, randf_range(0.85, 1.15))
	if stagger > 0.0:
		stagger -= delta
		velocity = Vector3.ZERO
		_gravity(delta)
		move_and_slide()
		return
	match state:
		"dormant":
			velocity.x = 0
			velocity.z = 0
			if _can_sense():
				_alert()
		"idle", "patrol":
			_move_toward(patrol_target, SPEED_WALK, delta)
			if global_position.distance_to(patrol_target) < 0.6:
				patrol_target = home + Vector3(randf_range(-patrol_radius, patrol_radius), 0, randf_range(-patrol_radius, patrol_radius))
			if _can_sense():
				_alert()
		"chase":
			repath -= delta
			if repath <= 0.0:
				repath = 0.4
				agent.target_position = player.global_position
			var dist := global_position.distance_to(player.global_position)
			if dist < ATTACK_RANGE:
				state = "attack"
				windup = 0.7
				_play_anim("attack")
			elif dist > 18.0:
				state = "patrol"
			else:
				_move_along_path(SPEED_CHASE, delta)
		"attack":
			_face(player.global_position, delta, 6.0)
			windup -= delta
			velocity.x = 0
			velocity.z = 0
			if windup <= 0.0:
				if global_position.distance_to(player.global_position) < ATTACK_HIT_RANGE and attack_cd <= 0.0:
					attack_cd = 1.2
					GS.damage_player(ATTACK_DAMAGE)
					Sfx.play_at(self, "hurt", player.global_position, -4.0)
				state = "chase"
	_gravity(delta)
	move_and_slide()
	_animate_placeholder(delta)

func _gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.5

func _move_toward(target: Vector3, speed: float, delta: float) -> void:
	agent.target_position = target
	_move_along_path(speed, delta)

func _move_along_path(speed: float, delta: float) -> void:
	var next := agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0
	if dir.length() < 0.05:
		velocity.x = 0
		velocity.z = 0
		return
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	_face(global_position + dir, delta, 5.0)

func _face(target: Vector3, delta: float, rate: float) -> void:
	var d := target - global_position
	d.y = 0
	if d.length() < 0.01:
		return
	var want := atan2(-d.x, -d.z)
	rotation.y = lerp_angle(rotation.y, want, clampf(rate * delta, 0.0, 1.0))

func _can_sense() -> bool:
	var to_p: Vector3 = player.global_position - global_position
	var dist := to_p.length()
	if dist < 2.2:
		return true
	if dist > SIGHT_DIST:
		return false
	var fwd := -global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	var dir := to_p.normalized()
	dir.y = 0
	if fwd.dot(dir.normalized()) < SIGHT_DOT:
		return false
	var from := global_position + Vector3(0, 1.5, 0)
	var to := player.global_position + Vector3(0, 1.2, 0)
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to, 0b1001, [self])
	return space.intersect_ray(q).is_empty()

func _alert() -> void:
	if state == "dead":
		return
	state = "chase"
	Sfx.play_at(self, "moan", global_position, -4.0, randf_range(0.8, 1.0))

func _on_noise(pos: Vector3, radius: float) -> void:
	if state == "dead" or state == "chase" or state == "attack":
		return
	if global_position.distance_to(pos) < radius:
		_alert()

func take_damage(amount: int, at_pos: Vector3 = Vector3.ZERO) -> void:
	if state == "dead":
		return
	hp -= amount
	Sfx.play_at(self, "enemy_hit", at_pos if at_pos != Vector3.ZERO else global_position + Vector3(0, 1.2, 0), -6.0)
	if hp <= 0:
		_die()
	else:
		stagger = 0.35
		_play_anim("stagger")
		if state in ["dormant", "idle", "patrol"]:
			_alert()

func _die() -> void:
	state = "dead"
	GS.flags["dead_" + shambler_id] = true
	GS.kills += 1
	Sfx.play_at(self, "moan", global_position, -2.0, 0.6)
	_play_anim("death")
	var shape := get_child(0) as CollisionShape3D
	if shape:
		shape.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_property(visual, "rotation:x", -PI / 2.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(visual, "position:y", 0.25, 0.8)
	set_physics_process(false)

func _play_anim(anim_name: String) -> void:
	if anim != null and anim.has_animation(anim_name):
		anim.play(anim_name)

func _patrol_target_new() -> void:
	patrol_target = home

func _animate_placeholder(delta: float) -> void:
	if anim != null:
		return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.1
	if body_node == null:
		return
	if state == "attack":
		if arm_l: arm_l.rotation.x = lerpf(arm_l.rotation.x, -1.5, delta * 6.0)
		if arm_r: arm_r.rotation.x = lerpf(arm_r.rotation.x, -1.5, delta * 6.0)
	elif moving:
		body_node.position.y = sin(anim_t * 5.0) * 0.045
		if arm_l: arm_l.rotation.x = sin(anim_t * 5.0) * 0.5 - 0.3
		if arm_r: arm_r.rotation.x = -sin(anim_t * 5.0) * 0.5 - 0.3
	else:
		body_node.position.y = lerpf(body_node.position.y, 0.0, delta * 5.0)
		if arm_l: arm_l.rotation.x = lerpf(arm_l.rotation.x, 0.0, delta * 3.0)
		if arm_r: arm_r.rotation.x = lerpf(arm_r.rotation.x, 0.0, delta * 3.0)
