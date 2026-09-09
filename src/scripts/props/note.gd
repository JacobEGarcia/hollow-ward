extends StaticBody3D
## Readable note; text shows on the floating 3D panel (flat + VR).

const Sfx = preload("res://scripts/sfx.gd")
const Factory = preload("res://scripts/asset_factory.gd")

@export var note_id := "note_x"
@export var note_title := "Note"
@export_multiline var note_text := ""

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 0b10000000
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.35, 0.15, 0.4)
	shape.shape = box
	add_child(shape)
	add_child(Factory.instantiate("note_paper"))

func get_prompt() -> String:
	return "Read - " + note_title

func interact(_player: Node) -> void:
	if not GS.notes_read.has(note_id):
		GS.notes_read.append(note_id)
	GS.note_requested.emit(note_title, note_text)
	Sfx.play(self, "ledger", -10.0, 1.3)
