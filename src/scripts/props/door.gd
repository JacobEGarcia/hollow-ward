extends Node3D
## Ward door: none / key / keypad locks. Leaf rotates open; state persists in GS.flags.

const Sfx = preload("res://scripts/sfx.gd")
const Factory = preload("res://scripts/asset_factory.gd")
const Keypad = preload("res://scripts/props/keypad.gd")

@export var door_id := "door_x"
@export var lock_type := "none"
@export var key_id := ""
@export var code := ""
@export var start_open := false

var open := false
var unlocked := true
var leaf: Node3D
var keypad: Node3D
var busy := false

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("doors")
	var visual := Factory.instantiate("door_ward")
	add_child(visual)
	leaf = visual.find_child("Leaf", true, false)
	if leaf == null:
		leaf = visual.find_child("leaf", true, false)
	if leaf == null:
		leaf = Node3D.new()
		leaf.name = "Leaf"
		leaf.position = Vector3(-0.5, 0, 0)
		visual.add_child(leaf)
	var frame_body := StaticBody3D.new()
	frame_body.collision_layer = 1
	frame_body.collision_mask = 0
	for x in [-0.56, 0.56]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.12, 2.2, 0.24)
		cs.shape = bs
		cs.position = Vector3(x, 1.1, 0)
		frame_body.add_child(cs)
	add_child(frame_body)
	var leaf_body := StaticBody3D.new()
	leaf_body.collision_layer = 0b1000
	leaf_body.collision_mask = 0
	var lcs := CollisionShape3D.new()
	var lbs := BoxShape3D.new()
	lbs.size = Vector3(1.0, 2.1, 0.07)
	lcs.shape = lbs
	lcs.position = Vector3(0.5, 1.05, 0)
	leaf_body.add_child(lcs)
	leaf.add_child(leaf_body)
	unlocked = lock_type == "none"
	if GS.flags.get("door_unlocked_" + door_id, false):
		unlocked = true
	if lock_type == "keypad" and not unlocked:
		keypad = Keypad.new()
		keypad.code = code
		keypad.position = Vector3(0.78, 1.25, -0.15)
		keypad.unlocked.connect(_on_keypad_unlocked)
		add_child(keypad)
	if start_open or GS.flags.get("door_open_" + door_id, false):
		_set_open(true, true)

func get_prompt() -> String:
	if open:
		return "Close door"
	if not unlocked:
		match lock_type:
			"key":
				return "Locked - brass ward key" if not GS.has_key(key_id) else "Unlock with brass ward key"
			"keypad":
				return "Locked - keypad"
	return "Open door"

func interact(_player: Node) -> void:
	if busy:
		return
	if not unlocked:
		if lock_type == "key" and GS.has_key(key_id):
			unlocked = true
			GS.flags["door_unlocked_" + door_id] = true
			Sfx.play(self, "unlock", -2.0)
			GS.message.emit("The brass key turns heavy. Unlocked.")
			_set_open(true)
		else:
			Sfx.play(self, "dryfire", -2.0, 0.55)
			if lock_type == "keypad":
				GS.message.emit("Locked. A keypad blinks beside the frame.")
			else:
				GS.message.emit("Locked.")
		return
	_set_open(not open)

func _set_open(v: bool, instant: bool = false) -> void:
	open = v
	GS.flags["door_open_" + door_id] = open
	var target := -1.85 if open else 0.0
	if instant:
		leaf.rotation.y = target
		return
	busy = true
	Sfx.play(self, "door_creak", -4.0, randf_range(0.9, 1.1))
	var tw := create_tween()
	tw.tween_property(leaf, "rotation:y", target, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): busy = false)

func _on_keypad_unlocked() -> void:
	unlocked = true
	GS.flags["door_unlocked_" + door_id] = true
	GS.message.emit("The keypad clicks. Unlocked.")
