extends StaticBody3D
## Floating 3D reading panel; works in flat (ray+E) and VR (ray+grip).

signal dismissed

var title_label: Label3D
var body_label: Label3D

func _ready() -> void:
	collision_layer = 0b10000000
	collision_mask = 0
	add_to_group("interactable")
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.3, 1.6, 0.05)
	cs.shape = bs
	add_child(cs)
	var font := load("res://assets/fonts/Inter.ttf")
	var mono := load("res://assets/fonts/IBMPlexMono-Bold.ttf")
	var border := MeshInstance3D.new()
	var bm := PlaneMesh.new()
	bm.size = Vector2(1.34, 1.64)
	border.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.55, 0.53, 0.48)
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	border.material_override = bmat
	border.position.z = -0.012
	add_child(border)
	var bg := MeshInstance3D.new()
	var qm := PlaneMesh.new()
	qm.size = Vector2(1.3, 1.6)
	bg.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.055, 0.06)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg.material_override = mat
	bg.position.z = -0.008
	add_child(bg)
	title_label = Label3D.new()
	title_label.font = mono
	title_label.font_size = 42
	title_label.pixel_size = 0.0024
	title_label.modulate = Color(0.92, 0.89, 0.82)
	title_label.width = 480
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector3(0, 0.60, 0.002)
	add_child(title_label)
	body_label = Label3D.new()
	body_label.font = font
	body_label.font_size = 30
	body_label.pixel_size = 0.0021
	body_label.modulate = Color(0.78, 0.75, 0.68)
	body_label.width = 520
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.position = Vector3(0, 0.02, 0.002)
	add_child(body_label)

func set_note(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body

func get_prompt() -> String:
	return "Put it down"

func interact(_player: Node) -> void:
	dismissed.emit()

func clicked(_player: Node) -> void:
	dismissed.emit()
