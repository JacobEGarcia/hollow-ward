extends Node
## Automated systems test: HOLLOW_TEST=1 godot --headless

var main: Node
var passed := 0
var failed := 0

func run(m: Node) -> void:
	main = m
	call_deferred("_go")

func check(label: String, cond: bool) -> void:
	if cond:
		passed += 1
		print("  PASS  " + label)
	else:
		failed += 1
		print("  FAIL  " + label)

func _find_door(id: String) -> Node:
	for d in get_tree().get_nodes_in_group("doors"):
		if d.door_id == id:
			return d
	return null

func _find_shambler(id: String) -> Node:
	for s in get_tree().get_nodes_in_group("shamblers"):
		if s.shambler_id == id:
			return s
	return null

func _go() -> void:
	print("--- HOLLOW WARD SYSTEMS TEST ---")
	await get_tree().process_frame
	main.new_game()
	await get_tree().create_timer(0.6).timeout
	check("world built", main.level_root != null and main.level_root.get_child_count() > 0)
	check("player spawned flat", main.player != null)
	var shambs := get_tree().get_nodes_in_group("shamblers")
	check("4 shamblers", shambs.size() == 4)
	check("5 doors", get_tree().get_nodes_in_group("doors").size() == 5)
	check("8 pickups", get_tree().get_nodes_in_group("pickups").size() == 8)
	for i in 8:
		await get_tree().physics_frame
	# navmesh
	var s0: Node = _find_shambler("shambler_corr")
	check("shambler found", s0 != null)
	var map: RID = s0.agent.get_navigation_map()
	var path := NavigationServer3D.map_get_path(map, Vector3(3, 0.2, 3), Vector3(-4, 0.2, -7), true)
	check("navmesh path hall->day room (%d pts)" % path.size(), path.size() > 2)
	# gun
	var player: Node = main.player
	var sh: Node = _find_shambler("shambler_day")
	player.global_position = Vector3(-4, 0.05, -5.0)
	player.set_state({"yaw": 0.0})
	await get_tree().physics_frame
	await get_tree().physics_frame
	GS.set_ammo(6, 60)
	var hp0: int = sh.hp
	player.gun.try_fire(player)
	check("shot connected (%d->%d)" % [hp0, sh.hp], sh.hp < hp0)
	var guard := 0
	while sh.hp > 0 and guard < 10:
		GS.set_ammo(6, 60)
		player.gun.cooldown = 0.0
		player.gun.try_fire(player)
		await get_tree().physics_frame
		guard += 1
	await get_tree().create_timer(1.0).timeout
	check("shambler down, kill counted", sh.state == "dead" and GS.kills >= 1)
	check("death flag set", GS.flags.get("dead_shambler_day", false))
	# noise aggro
	var s3: Node = _find_shambler("shambler_dorm1")
	GS.emit_noise(s3.global_position + Vector3(1.5, 0, 0), 6.0)
	await get_tree().physics_frame
	check("noise aggro", s3.state == "chase")
	# attack
	var s1: Node = _find_shambler("shambler_corr")
	GS.health = 100
	player.global_position = s1.global_position + Vector3(1.1, 0, 0)
	await get_tree().create_timer(3.2).timeout
	check("shambler attacks player (hp=%d)" % GS.health, GS.health < 100)
	player.global_position = Vector3(3, 0.05, 4.5)
	await get_tree().create_timer(0.3).timeout
	# pickups + inventory
	var salve: Node = null
	for p in get_tree().get_nodes_in_group("pickups"):
		if p.kind == "salve":
			salve = p
			break
	salve.interact(player)
	check("salve picked up", GS.count_item("salve") == 1)
	GS.health = 100
	GS.damage_player(50)
	GS.use_item("salve")
	check("salve heals to 90", GS.health == 90)
	GS.add_item("salve", "Morrowfern salve")
	GS.add_item("salve", "Morrowfern salve")
	check("combine salves", GS.combine_salves() and GS.count_item("potent_salve") == 1)
	var key_pk: Node = null
	for p in get_tree().get_nodes_in_group("pickups"):
		if p.kind == "ward_key":
			key_pk = p
	key_pk.interact(player)
	check("brass key acquired", GS.has_key("brass_key"))
	# keypad door
	var closet: Node = _find_door("door_closet")
	closet.keypad.press("9")
	closet.keypad.press("9")
	closet.keypad.press("9")
	closet.keypad.press("E")
	check("wrong code rejected", not closet.unlocked)
	closet.keypad.press("3")
	closet.keypad.press("1")
	closet.keypad.press("7")
	closet.keypad.press("E")
	check("317 unlocks closet", closet.unlocked)
	closet.interact(player)
	await get_tree().create_timer(1.2).timeout
	check("closet door opens", closet.open)
	# key door
	var exit_door: Node = _find_door("door_exit")
	var exit2: Node = _find_door("door_exit")
	check("exit door found", exit_door != null)
	exit_door.interact(player)
	await get_tree().create_timer(1.2).timeout
	check("brass key opens exit", exit2.open)
	# save/load
	GS.health = 77
	GS.saved_player = {"pos": [3, 0.05, 4.5], "yaw": 0.0}
	GS.save_game()
	GS.damage_player(30)
	check("damaged before load", GS.health == 47)
	var data := GS.load_save_data()
	check("save file roundtrip", data.get("health", 0) == 77)
	GS.restore(data)
	check("restore health", GS.health == 77)
	check("restore keeps key", GS.has_key("brass_key"))
	# win zone
	player.global_position = Vector3(3, 0.05, -18.2)
	await get_tree().create_timer(1.0).timeout
	check("win zone triggers", main.game_won_fired)
	print("--- RESULT: %d passed, %d failed ---" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
