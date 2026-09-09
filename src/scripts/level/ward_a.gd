extends Node3D
## Ward A: entry hall, corridor, day room, dormitory, supply closet, exit.
## Axis-aligned architecture, navmesh baked at runtime, contract-driven props.

const Factory = preload("res://scripts/asset_factory.gd")
const Mats = preload("res://scripts/materials.gd")
const Door = preload("res://scripts/props/door.gd")
const Pickup = preload("res://scripts/props/pickup.gd")
const SaveDesk = preload("res://scripts/props/save_desk.gd")
const Note = preload("res://scripts/props/note.gd")
const Shambler = preload("res://scripts/enemy/shambler.gd")

const SPAWN := Vector3(3, 0.05, 4.5)
const KEYPAD_CODE := "317"

var nav_region: NavigationRegion3D
var flickers := []
var t := 0.0

func build() -> void:
	nav_region = NavigationRegion3D.new()
	add_child(nav_region)
	_architecture()
	_furniture()
	_bake_nav()
	_doors()
	_pickups()
	_notes()
	_enemies()
	_lights()
	_environment()
	_win_zone()

func _process(delta: float) -> void:
	t += delta
	for f in flickers:
		var v: float = f.base * (0.82 + 0.18 * sin(t * f.speed + f.phase) * sin(t * f.speed * 2.7 + f.phase * 2.0))
		if randf() < 0.012:
			v = f.base * randf_range(0.05, 0.3)
		f.light.light_energy = v

# ---------- architecture ----------

func _static_box(center: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	body.add_child(mi)
	body.position = center
	nav_region.add_child(body)
	return body

func wall_x(x1: float, x2: float, z: float, h := 3.0, th := 0.3) -> void:
	_static_box(Vector3((x1 + x2) / 2.0, h / 2.0, z), Vector3(x2 - x1, h, th), Mats.grime(Mats.WALL, 0.10))

func wall_z(z1: float, z2: float, x: float, h := 3.0, th := 0.3) -> void:
	_static_box(Vector3(x, h / 2.0, (z1 + z2) / 2.0), Vector3(th, h, z2 - z1), Mats.grime(Mats.WALL, 0.10))

func _architecture() -> void:
	# floor + ceiling slabs
	_static_box(Vector3(1, -0.06, -6.5), Vector3(22, 0.12, 29), Mats.grime(Mats.FLOOR, 0.12))
	_static_box(Vector3(1, 3.06, -6.5), Vector3(22, 0.12, 29), Mats.flat(Mats.CEIL, 0.95))
	# hall x0..6 z0..6
	wall_x(0, 6, 6)              # south
	wall_z(0, 6, 0)              # west
	wall_z(0, 6, 6)              # east
	wall_x(0, 2.38, 0)           # north, left of door
	wall_x(3.62, 6, 0)           # north, right of door
	# corridor walls x=2 / x=4, z -16..0
	wall_z(-16, -13.62, 2)
	wall_z(-12.38, -6.42, 2)
	wall_z(-5.18, 0, 2)
	wall_z(-16, -6.42, 4)
	wall_z(-5.18, 0, 4)
	# day room x -8..2, z -10..-4
	wall_z(-10, -4, -8)
	wall_x(-8, 2, -10)
	wall_x(-8, 2, -4)
	# dormitory x 4..10, z -10..-4
	wall_z(-10, -4, 10)
	wall_x(4, 10, -10)
	wall_x(4, 10, -4)
	# closet x -2..2, z -16..-12
	wall_z(-16, -12, -2)
	wall_x(-2, 2, -12)
	# north end wall z=-16 with exit-door gap x 2.38..3.62
	wall_x(-2, 2.38, -16)
	wall_x(3.62, 4, -16)
	# exit room x 2..4, z -19..-16
	wall_z(-19, -16, 2)
	wall_z(-19, -16, 4)
	wall_x(2, 4, -19)

func _furniture() -> void:
	_prop("cabinet", Vector3(5.55, 0, 5.5), 0.6, Vector3(0.8, 1.8, 0.4))
	_prop("wheelchair", Vector3(0.9, 0, 2.0), -0.7, Vector3(0.6, 1.0, 0.6))
	_prop("gurney", Vector3(3.4, 0, -8.2), 0.12, Vector3(0.7, 0.9, 1.9))
	_prop("gurney", Vector3(-5, 0, -7), 0.3, Vector3(0.7, 0.9, 1.9))
	_prop("gurney", Vector3(-2.2, 0, -8.6), -0.15, Vector3(0.7, 0.9, 1.9))
	_prop("wheelchair", Vector3(-6.8, 0, -5.2), 2.3, Vector3(0.6, 1.0, 0.6))
	_prop("cabinet", Vector3(-7.55, 0, -4.6), PI / 2, Vector3(0.8, 1.8, 0.4))
	_prop("gurney", Vector3(7, 0, -7), 1.65, Vector3(0.7, 0.9, 1.9))
	_prop("gurney", Vector3(5.2, 0, -5), 0.1, Vector3(0.7, 0.9, 1.9))
	_prop("cabinet", Vector3(9.55, 0, -9.5), -PI / 2, Vector3(0.8, 1.8, 0.4))
	_prop("cabinet", Vector3(-1.55, 0, -13), PI / 2, Vector3(0.8, 1.8, 0.4))
	_prop("wheelchair", Vector3(2.6, 0, -1.6), 0.9, Vector3(0.6, 1.0, 0.6))
	# crate the key sits on
	_static_box(Vector3(0, 0.25, -14.5), Vector3(0.6, 0.5, 0.6), Mats.grime(Mats.WOOD, 0.2))

func _prop(asset: String, pos: Vector3, roty: float, colsize: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = colsize
	cs.shape = bs
	cs.position.y = colsize.y / 2.0
	body.add_child(cs)
	body.add_child(Factory.instantiate(asset))
	body.position = pos
	body.rotation.y = roty
	nav_region.add_child(body)
	return body

func _bake_nav() -> void:
	var nm := NavigationMesh.new()
	nm.cell_size = 0.2
	nm.cell_height = 0.2
	nm.agent_radius = 0.35
	nm.agent_height = 1.7
	nm.agent_max_climb = 0.2
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nav_region.navigation_mesh = nm
	nav_region.bake_navigation_mesh()

# ---------- gameplay objects ----------

func _doors() -> void:
	_door("door_hall", "none", "", "", Vector3(3, 0, 0), 0.0, true)
	_door("door_day", "none", "", "", Vector3(2, 0, -5.8), -PI / 2)
	_door("door_dorm", "none", "", "", Vector3(4, 0, -5.8), PI / 2)
	_door("door_closet", "keypad", "", KEYPAD_CODE, Vector3(2, 0, -13), -PI / 2)
	_door("door_exit", "key", "brass_key", "", Vector3(3, 0, -16), 0.0)

func _door(id: String, lock: String, key: String, code: String, pos: Vector3, roty: float, start_open := false) -> void:
	var d := Door.new()
	d.door_id = id
	d.lock_type = lock
	d.key_id = key
	d.code = code
	d.start_open = start_open
	d.position = pos
	d.rotation.y = roty
	add_child(d)

func _pickups() -> void:
	_pickup("salve_day", "salve", 0, Vector3(-6.4, 0, -9.3))
	_pickup("salve_dorm", "salve", 0, Vector3(6.2, 0, -9.4))
	_pickup("salve_closet", "salve", 0, Vector3(0.5, 0, -15.2))
	_pickup("ammo_corr", "ammo", 12, Vector3(2.6, 0, -10.2))
	_pickup("ammo_dorm", "ammo", 12, Vector3(9.0, 0, -4.7))
	_pickup("ammo_dorm2", "ammo", 12, Vector3(4.6, 0, -9.3))
	_pickup("ammo_closet", "ammo", 18, Vector3(-0.9, 0, -15.1))
	_pickup("ward_key", "ward_key", 0, Vector3(0, 0.5, -14.5))

func _pickup(id: String, kind: String, amount: int, pos: Vector3) -> void:
	var p := Pickup.new()
	p.pickup_id = id
	p.kind = kind
	p.amount = amount
	p.position = pos
	add_child(p)

func _notes() -> void:
	_note("note_intro", "Admission ledger - final page", Vector3(1.0, 0.95, 5.05),
		"Night 31. They stopped answering the call bells three nights ago.\n\nThe patients are not dying. That would be a mercy I could record. They are emptying - the light goes out of them and something else walks around in the shape left behind.\n\nI locked the north door myself. The brass ward key is in the supply closet, and the closet code is the day she vanished.\n\nIf you are reading this: keep your light low, count your rounds, and do not let them touch you.\n\n- E.M., night clerk")
	_note("note_code", "Memo - supply closet", Vector3(-5.0, 0.95, -7.0),
		"MEMO\n\nMaintenance reset the supply keypad AGAIN. The code is the day Sister Maren vanished - the seventeenth of the third month. 3 - 1 - 7.\n\nDo NOT write it down.\n\n(You are reading the copy you were told not to make.)")
	_note("note_lore", "Observation log", Vector3(7.0, 0.95, -7.0),
		"Day 12 of the quiet ward.\n\nThe Hollowed do not sleep. They stand where you leave them, facing the wall, swaying like reeds. Loud sound stirs them. Light keeps them honest.\n\nDr. Ansel says the Morrowfern salve closes anything. He has stopped saying anything else.")
	_note("note_exit", "Scratched into the paint", Vector3(2.35, 1.1, -15.2),
		"THE KEY TURNS HEAVY.\n\nWhatever waits past the north door, it is not worse than what is behind you.")

func _note(id: String, title: String, pos: Vector3, text: String) -> void:
	var n := Note.new()
	n.note_id = id
	n.note_title = title
	n.note_text = text
	n.position = pos
	add_child(n)

func _enemies() -> void:
	_shambler("shambler_corr", Vector3(3, 0.05, -11), false, 1.1)
	_shambler("shambler_day", Vector3(-4, 0.05, -6.5), true)
	_shambler("shambler_dorm1", Vector3(7, 0.05, -6.5), true)
	_shambler("shambler_dorm2", Vector3(8.5, 0.05, -5.5), true)

func _shambler(id: String, pos: Vector3, dormant: bool, patrol_radius := 3.0) -> void:
	var s := Shambler.new()
	s.shambler_id = id
	s.dormant = dormant
	s.patrol_radius = patrol_radius
	s.position = pos
	add_child(s)

func _lights() -> void:
	_lamp(Vector3(3, 3, 3), 0.85, true)
	_lamp(Vector3(3, 3, -5), 0.7, true)
	_lamp(Vector3(3, 3, -11), 0.6, true, Color(1.0, 0.55, 0.2))
	_lamp(Vector3(-3, 3, -7), 0.65, true)
	_lamp(Vector3(7, 3, -7), 0.5, false)
	_lamp(Vector3(3, 2.9, -17.5), 0.9, true, Color(1.0, 0.55, 0.2))
	_lamp(Vector3(0, 3, -14), 0.35, true)

func _lamp(pos: Vector3, energy: float, flicker: bool, color := Color(0.85, 0.87, 0.8)) -> void:
	var fixture := Factory.instantiate("ceiling_lamp")
	fixture.position = pos
	add_child(fixture)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, -0.7, 0)
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 7.0
	light.omni_attenuation = 1.3
	light.shadow_enabled = false
	add_child(light)
	if flicker:
		flickers.append({"light": light, "base": energy, "speed": randf_range(6.0, 11.0), "phase": randf() * TAU})

func _environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.024, 0.028)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.10, 0.12, 0.12)
	env.ambient_light_energy = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.07, 0.07)
	env.fog_density = 0.055
	env.fog_sun_scatter = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.15
	we.environment = env
	add_child(we)

func _win_zone() -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 0b010
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.8, 2.4, 1.0)
	cs.shape = bs
	area.add_child(cs)
	area.position = Vector3(3, 1.2, -18.2)
	area.body_entered.connect(_on_win_zone_entered)
	add_child(area)

var _won := false
func _on_win_zone_entered(body: Node) -> void:
	if _won or not body.is_in_group("player"):
		return
	_won = true
	GS.game_won.emit()
