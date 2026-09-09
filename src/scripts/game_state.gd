extends Node
## GS autoload: run state, inventory, save/load, signal bus.

signal health_changed(value, max_value)
signal ammo_changed(mag, reserve)
signal inventory_changed
signal message(text)
signal note_requested(title, body)
signal noise_emitted(pos, radius)
signal game_over
signal game_won
signal saved
signal world_reloaded

const SAVE_PATH := "user://hollow_ward_save.json"

var max_health := 100
var health := 100
var mag_size := 6
var ammo_mag := 6
var ammo_reserve := 24
var inventory: Array = []
var keys: Array = []
var notes_read: Array = []
var flags: Dictionary = {}
var kills := 0
var saves_used := 0
var play_time := 0.0
var run_seed := 0
var saved_player: Dictionary = {}
var is_dead := false

func _process(delta: float) -> void:
	play_time += delta

func new_run() -> void:
	health = max_health
	ammo_mag = mag_size
	ammo_reserve = 24
	inventory = []
	keys = []
	notes_read = []
	flags = {}
	kills = 0
	saves_used = 0
	play_time = 0.0
	is_dead = false
	saved_player = {}
	run_seed = randi()
	health_changed.emit(health, max_health)
	ammo_changed.emit(ammo_mag, ammo_reserve)
	inventory_changed.emit()

func damage_player(amount: int) -> void:
	if is_dead:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		is_dead = true
		game_over.emit()

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

func add_item(id: String, item_name: String, qty: int = 1) -> void:
	for it in inventory:
		if it.id == id:
			it.qty += qty
			inventory_changed.emit()
			return
	inventory.append({"id": id, "name": item_name, "qty": qty})
	inventory_changed.emit()

func count_item(id: String) -> int:
	for it in inventory:
		if it.id == id:
			return it.qty
	return 0

func remove_item(id: String, qty: int = 1) -> void:
	for i in range(inventory.size()):
		if inventory[i].id == id:
			inventory[i].qty -= qty
			if inventory[i].qty <= 0:
				inventory.remove_at(i)
			inventory_changed.emit()
			return

func use_item(id: String) -> bool:
	if count_item(id) <= 0:
		return false
	if id == "salve":
		heal(40)
	elif id == "potent_salve":
		heal(90)
	elif id == "ammo":
		ammo_reserve += 12
		ammo_changed.emit(ammo_mag, ammo_reserve)
	else:
		return false
	remove_item(id, 1)
	return true

func combine_salves() -> bool:
	if count_item("salve") < 2:
		return false
	remove_item("salve", 2)
	add_item("potent_salve", "Potent salve")
	message.emit("Two salves distilled into one potent dose.")
	return true

func add_key(key_id: String) -> void:
	if not keys.has(key_id):
		keys.append(key_id)

func has_key(key_id: String) -> bool:
	return keys.has(key_id)

func emit_noise(pos: Vector3, radius: float) -> void:
	noise_emitted.emit(pos, radius)

func add_ammo_rounds(n: int) -> void:
	ammo_reserve += n
	ammo_changed.emit(ammo_mag, ammo_reserve)

func set_ammo(mag: int, reserve: int) -> void:
	ammo_mag = mag
	ammo_reserve = reserve
	ammo_changed.emit(ammo_mag, ammo_reserve)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	saves_used += 1
	var data := {
		"health": health, "ammo_mag": ammo_mag, "ammo_reserve": ammo_reserve,
		"inventory": inventory, "keys": keys, "notes_read": notes_read,
		"flags": flags, "kills": kills, "saves_used": saves_used,
		"play_time": play_time, "run_seed": run_seed, "player": saved_player,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	saved.emit()

func load_save_data() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data

func restore(data: Dictionary) -> void:
	new_run()
	health = data.get("health", max_health)
	ammo_mag = data.get("ammo_mag", mag_size)
	ammo_reserve = data.get("ammo_reserve", 0)
	inventory = data.get("inventory", [])
	keys = data.get("keys", [])
	notes_read = data.get("notes_read", [])
	flags = data.get("flags", {})
	kills = data.get("kills", 0)
	saves_used = data.get("saves_used", 0)
	play_time = data.get("play_time", 0.0)
	run_seed = data.get("run_seed", randi())
	saved_player = data.get("player", {})
	health_changed.emit(health, max_health)
	ammo_changed.emit(ammo_mag, ammo_reserve)
	inventory_changed.emit()
