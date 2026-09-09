extends Node3D
## Physical 3-digit keypad: 12 clickable buttons + display. Works flat and VR.

const Sfx = preload("res://scripts/sfx.gd")
const Mats = preload("res://scripts/materials.gd")
const KeyButton = preload("res://scripts/props/keypad_button.gd")

signal unlocked

var code := "317"
var entry := ""
var display: Label3D
var panel: MeshInstance3D
var panel_mat: StandardMaterial3D
var flash_timer := 0.0

func _ready() -> void:
	panel_mat = Mats.flat(Color(0.10, 0.11, 0.12), 0.5, 0.5)
	var pm := BoxMesh.new()
	pm.size = Vector3(0.24, 0.36, 0.03)
	panel = MeshInstance3D.new()
	panel.mesh = pm
	panel.material_override = panel_mat
	add_child(panel)
	display = Label3D.new()
	display.font = load("res://assets/fonts/IBMPlexMono-Bold.ttf")
	display.font_size = 96
	display.pixel_size = 0.0011
	display.width = 220
	display.modulate = Color(0.4, 0.95, 0.85)
	display.position = Vector3(0, 0.115, -0.02)
	display.rotation.y = PI
	display.text = "_ _ _"
	add_child(display)
	var labels := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "E"]
	for i in labels.size():
		var col := i % 3
		var row := i / 3
		var b := KeyButton.new()
		b.value = labels[i]
		b.pad = self
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.055, 0.055, 0.03)
		shape.shape = bs
		b.add_child(shape)
		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05, 0.05, 0.02)
		mesh.mesh = bm
		mesh.material_override = Mats.flat(Color(0.22, 0.23, 0.24), 0.5, 0.4)
		mesh.position.z = -0.02
		b.add_child(mesh)
		var lbl := Label3D.new()
		lbl.font = load("res://assets/fonts/IBMPlexMono-Regular.ttf")
		lbl.font_size = 64
		lbl.pixel_size = 0.0007
		lbl.text = labels[i]
		lbl.position.z = -0.033
		lbl.rotation.y = PI
		b.add_child(lbl)
		b.position = Vector3((1 - col) * 0.068, 0.03 - row * 0.068, -0.015)
		add_child(b)

func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			panel_mat.albedo_color = Color(0.10, 0.11, 0.12)

func press(v: String) -> void:
	Sfx.play(self, "beep", -8.0)
	if v == "C":
		entry = ""
	elif v == "E":
		if entry == code:
			display.text = "OPEN"
			display.modulate = Color(0.5, 1.0, 0.5)
			panel_mat.albedo_color = Color(0.1, 0.35, 0.15)
			flash_timer = 0.6
			Sfx.play(self, "unlock", -4.0)
			unlocked.emit()
		else:
			display.text = "ERR"
			display.modulate = Color(1.0, 0.35, 0.3)
			panel_mat.albedo_color = Color(0.4, 0.08, 0.06)
			flash_timer = 0.6
			entry = ""
			_reset_display_later()
		return
	else:
		if entry.length() < 3:
			entry += v
	_reset_display()

func _reset_display() -> void:
	display.modulate = Color(0.4, 0.95, 0.85)
	var t := ""
	for i in 3:
		t += (entry.substr(i, 1) if i < entry.length() else "_") + " "
	display.text = t.strip_edges()

func _reset_display_later() -> void:
	await get_tree().create_timer(0.8).timeout
	_reset_display()
