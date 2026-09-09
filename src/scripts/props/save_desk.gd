extends StaticBody3D
## Ledger desk: the save station.

const Sfx = preload("res://scripts/sfx.gd")
const Factory = preload("res://scripts/asset_factory.gd")

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 1.0, 0.7)
	shape.shape = box
	shape.position.y = 0.5
	add_child(shape)
	add_child(Factory.instantiate("save_desk"))

func get_prompt() -> String:
	return "Record progress in the ledger"

func interact(player: Node) -> void:
	if player != null and player.has_method("get_state"):
		GS.saved_player = player.get_state()
	GS.save_game()
	Sfx.play(self, "ledger", -4.0)
	GS.message.emit("Recorded in the ward ledger.")
