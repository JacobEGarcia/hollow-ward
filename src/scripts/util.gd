extends RefCounted

static func find_owner_with(node: Object, method: String) -> Node:
	var n := node as Node
	while n != null:
		if n.has_method(method):
			return n
		n = n.get_parent()
	return null

static func fmt_time(sec: float) -> String:
	var m := int(sec) / 60
	var s := int(sec) % 60
	return "%02d:%02d" % [m, s]
