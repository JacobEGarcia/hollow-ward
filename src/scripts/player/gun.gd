extends Node3D
## Hitscan pistol. Ammo lives in GS; visuals from asset factory.

const Sfx = preload("res://scripts/sfx.gd")
const Factory = preload("res://scripts/asset_factory.gd")
const Util = preload("res://scripts/util.gd")

const DAMAGE := 34
const RANGE := 30.0
const FIRE_COOLDOWN := 0.28
const RELOAD_TIME := 1.15

var aim_node: Node3D
var flash: OmniLight3D
var cooldown := 0.0
var reloading := 0.0
var recoil := 0.0
var visual: Node3D
var muzzle: Node3D

func _ready() -> void:
	visual = Factory.instantiate("pistol")
	add_child(visual)
	muzzle = Node3D.new()
	muzzle.position = Vector3(0, 0.06, -0.3)
	add_child(muzzle)
	flash = OmniLight3D.new()
	flash.light_color = Color(1.0, 0.75, 0.4)
	flash.light_energy = 0.0
	flash.omni_range = 5.0
	muzzle.add_child(flash)

func _process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	if reloading > 0.0:
		reloading -= delta
		visual.rotation.x = lerpf(visual.rotation.x, 0.7, delta * 10.0)
		if reloading <= 0.0:
			var take = mini(GS.mag_size - GS.ammo_mag, GS.ammo_reserve)
			GS.set_ammo(GS.ammo_mag + take, GS.ammo_reserve - take)
	if recoil > 0.0:
		recoil = maxf(0.0, recoil - delta * 6.0)
		visual.position.z = recoil * 0.09
		visual.rotation.x = recoil * 0.3
	flash.light_energy = maxf(0.0, flash.light_energy - delta * 60.0)

func can_fire() -> bool:
	return cooldown <= 0.0 and reloading <= 0.0

func try_fire(shooter: Node) -> bool:
	if not can_fire():
		return false
	if GS.ammo_mag <= 0:
		Sfx.play(self, "dryfire", -4.0)
		GS.message.emit("Empty. Reload.")
		cooldown = 0.25
		return false
	cooldown = FIRE_COOLDOWN
	recoil = 1.0
	GS.set_ammo(GS.ammo_mag - 1, GS.ammo_reserve)
	Sfx.play(self, "gunshot", -2.0, randf_range(0.96, 1.05))
	flash.light_energy = 6.0
	var from: Vector3 = aim_node.global_position
	var dir: Vector3 = -aim_node.global_transform.basis.z
	dir = (dir + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.008).normalized()
	var to := from + dir * RANGE
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to, 0b101, [shooter])
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		var target := Util.find_owner_with(hit.collider, "take_damage")
		if target != null:
			target.take_damage(DAMAGE, hit.position)
		else:
			Sfx.play_at(self, "enemy_hit", hit.position, -16.0, 1.6)
	GS.emit_noise(from, 16.0)
	return true

func try_reload() -> void:
	if reloading > 0.0 or GS.ammo_mag >= GS.mag_size or GS.ammo_reserve <= 0:
		return
	reloading = RELOAD_TIME
	Sfx.play(self, "reload", -6.0)
