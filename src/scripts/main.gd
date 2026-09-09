extends Node3D
## HOLLOW WARD entry point: menus, mode switching (flat <-> WebXR), world, audio.

const InputSetup = preload("res://scripts/input_setup.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Hud = preload("res://scripts/ui/hud.gd")
const NotePanel = preload("res://scripts/ui/note_panel.gd")
const WardA = preload("res://scripts/level/ward_a.gd")
const PlayerFlat = preload("res://scripts/player/player_flat.gd")
const PlayerXR = preload("res://scripts/player/player_xr.gd")
const TestDriver = preload("res://scripts/test/test_driver.gd")

var hud: CanvasLayer
var level_root: Node3D
var ward: Node3D
var player: Node3D
var note_panel: StaticBody3D
var xr_interface: XRInterface
var webxr_ready := false
var xr_native := false
var in_xr := false
var pending_xr := false
var game_won_fired := false
var drone_player: AudioStreamPlayer
var heartbeat_player: AudioStreamPlayer
var shot_mode := false
var test_mode := false

func _ready() -> void:
	InputSetup.setup()
	test_mode = OS.get_environment("HOLLOW_TEST") == "1"
	shot_mode = OS.get_environment("HOLLOW_SHOT") == "1"
	hud = Hud.new()
	add_child(hud)
	hud.new_game_pressed.connect(new_game)
	hud.continue_pressed.connect(continue_game)
	hud.load_save_pressed.connect(continue_game)
	hud.enter_vr_pressed.connect(enter_vr)
	GS.game_over.connect(_on_game_over)
	GS.game_won.connect(_on_game_won)
	GS.note_requested.connect(_on_note)
	_setup_audio()
	_build_note_panel()
	_setup_xr()
	if test_mode:
		var drv := TestDriver.new()
		add_child(drv)
		drv.run(self)
	elif shot_mode:
		_run_shots()
	_setup_js_debug()

func _setup_js_debug() -> void:
	if not OS.has_feature("web"):
		return
	var win = JavaScriptBridge.get_interface("window")
	win.hollowCapture = JavaScriptBridge.create_callback(_on_js_capture)
	win.hollowNewGame = JavaScriptBridge.create_callback(func(_a): new_game())

func _on_js_capture(_args) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		JavaScriptBridge.eval("window.__hollowPng = 'ERR:no-image'")
		return
	var tw := 480
	var th := int(float(img.get_height()) / float(img.get_width()) * tw)
	img.resize(tw, th, Image.INTERPOLATE_BILINEAR)
	var b64 := Marshalls.raw_to_base64(img.save_png_to_buffer())
	JavaScriptBridge.eval("window.__hollowPng = '" + b64 + "'")

# ---------- audio ----------

func _loop_stream(name: String) -> AudioStreamWAV:
	var s := Sfx.stream(name)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(s.get_length() * s.mix_rate)
	return s

func _setup_audio() -> void:
	drone_player = AudioStreamPlayer.new()
	drone_player.stream = _loop_stream("drone")
	drone_player.volume_db = -17.0
	add_child(drone_player)
	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.stream = _loop_stream("heartbeat")
	heartbeat_player.volume_db = -80.0
	add_child(heartbeat_player)

func _process(_delta: float) -> void:
	if GS.health < 45 and GS.health > 0:
		heartbeat_player.volume_db = lerpf(-16.0, -3.0, 1.0 - GS.health / 45.0)
	else:
		heartbeat_player.volume_db = -80.0
	if player != null and player.global_position.y < -4.0:
		player.global_position = WardA.SPAWN + Vector3(0, 0.2, 0)

# ---------- game flow ----------

func new_game() -> void:
	GS.new_run()
	game_won_fired = false
	start_world(false)

func continue_game() -> void:
	var data := GS.load_save_data()
	if data.is_empty():
		new_game()
		return
	GS.restore(data)
	game_won_fired = false
	start_world(true)

func start_world(from_save: bool) -> void:
	if level_root != null:
		level_root.queue_free()
		level_root = null
		player = null
	level_root = Node3D.new()
	level_root.name = "World"
	add_child(level_root)
	ward = WardA.new()
	level_root.add_child(ward)
	ward.build()
	_spawn_player(from_save)
	hud.game_started()
	hud.player = player
	note_panel.visible = false
	if not drone_player.playing:
		drone_player.play()
	heartbeat_player.play()
	if not from_save:
		GS.message.emit("Find a way out of the ward.")

func _spawn_player(from_save: bool) -> void:
	if in_xr:
		player = PlayerXR.new()
		player.add_to_group("xr")
	else:
		player = PlayerFlat.new()
	player.add_to_group("player")
	level_root.add_child(player)
	player.global_position = WardA.SPAWN
	if from_save and not GS.saved_player.is_empty():
		player.set_state(GS.saved_player)
	if player.has_method("set_active"):
		player.set_active(true)

func _on_game_over() -> void:
	Sfx.play(self, "death", -4.0)
	if player != null and player.has_method("set_active"):
		player.set_active(false)
	hud.show_death()

func _on_game_won() -> void:
	if game_won_fired:
		return
	game_won_fired = true
	Sfx.play(self, "win", -4.0)
	if player != null and player.has_method("set_active"):
		player.set_active(false)
	hud.show_win()

# ---------- note reader ----------

func _build_note_panel() -> void:
	note_panel = NotePanel.new()
	note_panel.visible = false
	note_panel.dismissed.connect(func(): note_panel.visible = false)
	add_child(note_panel)

func _active_camera() -> Camera3D:
	if player != null:
		var c = player.get("camera")
		if c != null:
			return c
	return get_viewport().get_camera_3d()

func _on_note(title: String, body: String) -> void:
	var cam := _active_camera()
	if cam == null:
		return
	note_panel.set_note(title, body)
	var fwd := -cam.global_transform.basis.z
	note_panel.global_position = cam.global_position + fwd * 1.6 + Vector3(0, -0.05, 0)
	note_panel.look_at(cam.global_position, Vector3.UP)
	note_panel.rotate_y(PI)
	note_panel.visible = true

# ---------- XR ----------

func _setup_xr() -> void:
	if OS.has_feature("web"):
		var w = XRServer.find_interface("WebXR")
		if w != null:
			xr_interface = w
			w.session_supported.connect(_on_session_supported)
			w.session_started.connect(_on_xr_started)
			w.session_ended.connect(_on_xr_ended)
			w.session_failed.connect(_on_xr_failed)
			w.is_session_supported("immersive-vr")
	else:
		var o = XRServer.find_interface("OpenXR")
		if o != null and o.initialize():
			xr_interface = o
			xr_native = true
			get_viewport().use_xr = true

func _on_session_supported(mode: String, supported: bool) -> void:
	if mode == "immersive-vr" and supported:
		webxr_ready = true
		hud.show_enter_vr(true)

func enter_vr() -> void:
	if xr_native:
		_swap_player(true)
		return
	if not webxr_ready or xr_interface == null:
		return
	xr_interface.session_mode = "immersive-vr"
	xr_interface.requested_reference_space_types = "local-floor, local"
	xr_interface.required_features = "local-floor"
	xr_interface.optional_features = ""
	if not xr_interface.initialize():
		OS.alert("Failed to initialize WebXR")

func _on_xr_started() -> void:
	get_viewport().use_xr = true
	in_xr = true
	if player != null:
		_swap_player(true)
	else:
		pending_xr = true

func _on_xr_ended() -> void:
	get_viewport().use_xr = false
	in_xr = false
	if player != null:
		_swap_player(false)

func _on_xr_failed(msg: String) -> void:
	OS.alert("Unable to enter VR: " + msg)

func _swap_player(to_xr: bool) -> void:
	var st := {}
	if player != null and player.has_method("get_state"):
		st = player.get_state()
		player.queue_free()
	player = null
	if to_xr:
		player = PlayerXR.new()
		player.add_to_group("xr")
	else:
		player = PlayerFlat.new()
	player.add_to_group("player")
	level_root.add_child(player)
	if not st.is_empty():
		player.set_state(st)
	if player.has_method("set_active"):
		player.set_active(true)
	hud.player = player

# ---------- screenshot harness ----------

func _run_shots() -> void:
	await get_tree().process_frame
	new_game()
	await get_tree().create_timer(1.0).timeout
	var shots := [
		[Vector3(3, 0.05, 4.5), 0.0],
		[Vector3(1.6, 0.05, 4.9), -0.9],
		[Vector3(3, 0.05, -2.5), 0.0],
		[Vector3(-0.5, 0.05, -5.5), PI / 2],
		[Vector3(5.5, 0.05, -5.2), -PI / 2],
		[Vector3(3, 0.05, -12.5), PI / 2],
		[Vector3(3, 0.05, -15.3), 0.0],
	]
	for i in shots.size():
		player.global_position = shots[i][0]
		player.set_state({"yaw": shots[i][1]})
		await get_tree().create_timer(0.4).timeout
		var img := get_viewport().get_texture().get_image()
		img.save_png("/tmp/hw_shot_%d.png" % i)
		print("SHOT /tmp/hw_shot_%d.png" % i)
	get_tree().quit()
