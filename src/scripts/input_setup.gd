extends RefCounted
## Runtime input map so project.godot stays minimal.

static func setup() -> void:
	_key("move_forward", KEY_W)
	_key("move_back", KEY_S)
	_key("move_left", KEY_A)
	_key("move_right", KEY_D)
	_key("interact", KEY_E)
	_key("reload", KEY_R)
	_key("inventory", KEY_TAB)
	_key("snap_left", KEY_LEFT)
	_key("snap_right", KEY_RIGHT)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	_ensure("fire")
	InputMap.action_add_event("fire", ev)

static func _key(action: String, keycode: Key) -> void:
	_ensure(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)

static func _ensure(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
