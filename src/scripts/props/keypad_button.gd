extends StaticBody3D
## One physical keypad button; pressed via pointer ray (mouse click or VR grip).

var value := ""
var pad: Node

func _ready() -> void:
	collision_layer = 0b10000000
	collision_mask = 0
	add_to_group("clickable")

func clicked(_player: Node) -> void:
	if pad != null:
		pad.press(value)
