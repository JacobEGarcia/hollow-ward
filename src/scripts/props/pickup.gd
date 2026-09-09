extends StaticBody3D
## World pickup: salve / ammo / ward key.

const Sfx = preload("res://scripts/sfx.gd")
const Factory = preload("res://scripts/asset_factory.gd")

@export var pickup_id := "pickup_x"
@export var kind := "salve"
@export var amount := 12

const INFO := {
	"salve": {"asset": "salve_plant", "label": "Take Morrowfern salve"},
	"ammo": {"asset": "ammo_box", "label": "Take 9mm rounds"},
	"ward_key": {"asset": "ward_key", "label": "Take the brass ward key"},
}

var visual: Node3D
var t := 0.0

func _ready() -> void:
	if GS.flags.get("picked_" + pickup_id, false):
		queue_free()
		return
	add_to_group("interactable")
	add_to_group("pickups")
	collision_layer = 0b10000000
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 0.5, 0.4)
	shape.shape = box
	shape.position.y = 0.25
	add_child(shape)
	visual = Factory.instantiate(INFO[kind].asset)
	add_child(visual)

func _process(delta: float) -> void:
	t += delta
	visual.rotation.y = t * 0.9
	visual.position.y = 0.06 + sin(t * 2.0) * 0.045

func get_prompt() -> String:
	return INFO[kind].label

func interact(_player: Node) -> void:
	GS.flags["picked_" + pickup_id] = true
	match kind:
		"salve":
			GS.add_item("salve", "Morrowfern salve")
			GS.message.emit("Morrowfern salve. Crush the fronds to close wounds.")
		"ammo":
			GS.add_ammo_rounds(amount)
			GS.message.emit("+%d 9mm rounds." % amount)
		"ward_key":
			GS.add_key("brass_key")
			GS.message.emit("The brass ward key. The north door will open now.")
	Sfx.play(self, "pickup", -4.0)
	queue_free()
