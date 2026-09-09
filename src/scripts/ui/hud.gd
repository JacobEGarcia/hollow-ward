extends CanvasLayer
## Flat-mode HUD + menus. VR gets its own wrist/message labels on the rig.

signal new_game_pressed
signal continue_pressed
signal enter_vr_pressed
signal load_save_pressed

const Sfx = preload("res://scripts/sfx.gd")
const Util = preload("res://scripts/util.gd")

const BONE := Color(0.82, 0.79, 0.72)
const DIM := Color(0.48, 0.47, 0.43)
const TEAL := Color(0.30, 0.62, 0.60)
const AMBER := Color(1.0, 0.62, 0.18)
const BLOOD := Color(0.55, 0.12, 0.10)
const PANEL_BG := Color(0.03, 0.035, 0.04, 0.94)

var font_body: Font
var font_mono: Font
var font_mono_bold: Font

var crosshair: ColorRect
var prompt_label: Label
var message_label: Label
var vitals_fill: ColorRect
var vitals_label: Label
var ammo_label: Label
var vignette: TextureRect
var vignette_flash := 0.0
var last_health := 100
var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var inventory_open := false
var title_panel: PanelContainer
var death_panel: PanelContainer
var win_panel: PanelContainer
var win_stats: Label
var continue_btn: Button
var enter_vr_btn: Button
var enter_vr_btn_title: Button
var player: Node

func _ready() -> void:
	font_body = load("res://assets/fonts/Inter.ttf")
	font_mono = load("res://assets/fonts/IBMPlexMono-Regular.ttf")
	font_mono_bold = load("res://assets/fonts/IBMPlexMono-Bold.ttf")
	_build_vignette()
	_build_game_hud()
	_build_inventory()
	_build_title()
	_build_death()
	_build_win()
	GS.health_changed.connect(_on_health)
	GS.ammo_changed.connect(_on_ammo)
	GS.message.connect(_on_message)
	show_title()

# ---------- construction ----------

func _mk_label(text: String, font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _mk_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font_mono)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", BONE)
	b.add_theme_color_override("font_hover_color", TEAL)
	b.add_theme_color_override("font_focus_color", TEAL)
	b.add_theme_color_override("font_disabled_color", DIM)
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0, 0, 0, 0)
	flat.content_margin_left = 12
	flat.content_margin_right = 12
	flat.content_margin_top = 6
	flat.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", flat)
	var hover := flat.duplicate()
	hover.border_color = TEAL
	hover.border_width_bottom = 1
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", hover)
	return b

func _mk_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = Color(0.62, 0.6, 0.55, 0.5)
	sb.set_border_width_all(1)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	p.add_theme_stylebox_override("panel", sb)
	return p

func _fullscreen(p: Control) -> void:
	p.set_anchors_preset(Control.PRESET_FULL_RECT)

func _build_vignette() -> void:
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in 256:
		for x in 256:
			var dx := (x - 128) / 128.0
			var dy := (y - 128) / 128.0
			var d := sqrt(dx * dx + dy * dy)
			var a := clampf((d - 0.45) / 0.6, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.28, 0.03, 0.02, a))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.modulate = Color(1, 1, 1, 0)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fullscreen(tr)
	add_child(tr)
	vignette = tr

func _build_game_hud() -> void:
	var root := Control.new()
	root.name = "GameHud"
	root.visible = false
	_fullscreen(root)
	add_child(root)
	crosshair = ColorRect.new()
	crosshair.color = Color(0.9, 0.87, 0.8, 0.85)
	crosshair.custom_minimum_size = Vector2(4, 4)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-2, -2)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)
	prompt_label = _mk_label("", font_mono, 15, BONE)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-200, -120)
	prompt_label.custom_minimum_size = Vector2(400, 24)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(prompt_label)
	message_label = _mk_label("", font_mono, 15, BONE)
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-320, 42)
	message_label.custom_minimum_size = Vector2(640, 24)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.modulate = Color(1, 1, 1, 0)
	root.add_child(message_label)
	var vit := VBoxContainer.new()
	vit.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	vit.position = Vector2(24, -64)
	vit.add_theme_constant_override("separation", 4)
	root.add_child(vit)
	vitals_label = _mk_label("VITALS", font_mono, 11, DIM)
	vit.add_child(vitals_label)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.12, 0.12, 0.12, 0.8)
	bar_bg.custom_minimum_size = Vector2(180, 6)
	vit.add_child(bar_bg)
	vitals_fill = ColorRect.new()
	vitals_fill.color = BONE
	vitals_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.add_child(vitals_fill)
	ammo_label = _mk_label("", font_mono_bold, 20, BONE)
	ammo_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_label.position = Vector2(-180, -58)
	ammo_label.custom_minimum_size = Vector2(156, 28)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(ammo_label)
	enter_vr_btn = _mk_button("ENTER VR")
	enter_vr_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	enter_vr_btn.position = Vector2(-140, 10)
	enter_vr_btn.visible = false
	enter_vr_btn.pressed.connect(func(): enter_vr_pressed.emit())
	root.add_child(enter_vr_btn)
	root.name = "GameHud"
	_game_hud = root

var _game_hud: Control

func _build_inventory() -> void:
	inventory_panel = _mk_panel()
	inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	inventory_panel.position = Vector2(-220, -160)
	inventory_panel.visible = false
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.custom_minimum_size = Vector2(440, 0)
	inventory_panel.add_child(vb)
	vb.add_child(_mk_label("FIELD KIT", font_mono_bold, 14, DIM))
	inventory_list = VBoxContainer.new()
	inventory_list.add_theme_constant_override("separation", 4)
	vb.add_child(inventory_list)
	var combine := _mk_button("Distill two salves into a potent dose")
	combine.pressed.connect(func(): GS.combine_salves(); _refresh_inventory())
	combine.name = "CombineBtn"
	vb.add_child(combine)
	var close := _mk_button("Close  [Tab]")
	close.pressed.connect(toggle_inventory)
	vb.add_child(close)
	add_child(inventory_panel)

func _build_title() -> void:
	title_panel = _mk_panel()
	_fullscreen(title_panel)
	var sb := title_panel.get_theme_stylebox("panel").duplicate()
	sb.border_width_left = 0
	sb.border_width_right = 0
	title_panel.add_theme_stylebox_override("panel", sb)
	var center := CenterContainer.new()
	_fullscreen(center)
	title_panel.add_child(center)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	center.add_child(vb)
	var title := _mk_label("HOLLOW WARD", font_mono_bold, 52, BONE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var rule := ColorRect.new()
	rule.color = DIM
	rule.custom_minimum_size = Vector2(220, 1)
	vb.add_child(rule)
	var sub := _mk_label("St. Maren's Convalescent Ward - 1:47 AM", font_body, 15, DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 18)
	vb.add_child(spacer)
	var new_btn := _mk_button("NEW GAME")
	new_btn.pressed.connect(func(): new_game_pressed.emit())
	vb.add_child(new_btn)
	continue_btn = _mk_button("CONTINUE")
	continue_btn.pressed.connect(func(): continue_pressed.emit())
	vb.add_child(continue_btn)
	enter_vr_btn_title = _mk_button("ENTER VR")
	enter_vr_btn_title.visible = false
	enter_vr_btn_title.pressed.connect(func(): enter_vr_pressed.emit())
	vb.add_child(enter_vr_btn_title)
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(1, 26)
	vb.add_child(spacer2)
	var foot := _mk_label("an original survival horror - desktop, and VR in the Quest browser", font_body, 12, DIM)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(foot)

func _build_death() -> void:
	death_panel = _mk_panel()
	death_panel.set_anchors_preset(Control.PRESET_CENTER)
	death_panel.position = Vector2(-180, -110)
	death_panel.visible = false
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	death_panel.add_child(vb)
	var t := _mk_label("FLATLINE", font_mono_bold, 34, BLOOD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(_mk_label("The ward keeps what it takes.", font_body, 14, DIM))
	var load_btn := _mk_button("LOAD LAST SAVE")
	load_btn.pressed.connect(func(): load_save_pressed.emit())
	vb.add_child(load_btn)
	var new_btn := _mk_button("NEW GAME")
	new_btn.pressed.connect(func(): new_game_pressed.emit())
	vb.add_child(new_btn)
	add_child(death_panel)

func _build_win() -> void:
	win_panel = _mk_panel()
	win_panel.set_anchors_preset(Control.PRESET_CENTER)
	win_panel.position = Vector2(-200, -130)
	win_panel.visible = false
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	win_panel.add_child(vb)
	var t := _mk_label("WARD CLEARED", font_mono_bold, 34, TEAL)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	win_stats = _mk_label("", font_mono, 14, BONE)
	vb.add_child(win_stats)
	vb.add_child(_mk_label("More wards are on the operating table.", font_body, 13, DIM))
	var new_btn := _mk_button("NEW GAME")
	new_btn.pressed.connect(func(): new_game_pressed.emit())
	vb.add_child(new_btn)
	add_child(win_panel)

# ---------- runtime ----------

func show_title() -> void:
	title_panel.visible = true
	death_panel.visible = false
	win_panel.visible = false
	_game_hud.visible = false
	continue_btn.disabled = not GS.has_save()

func game_started() -> void:
	title_panel.visible = false
	death_panel.visible = false
	win_panel.visible = false
	_game_hud.visible = true
	inventory_panel.visible = false
	inventory_open = false
	_on_health(GS.health, GS.max_health)
	_on_ammo(GS.ammo_mag, GS.ammo_reserve)

func show_death() -> void:
	death_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_win() -> void:
	win_stats.text = "time %s   hollowed down %d   ledger entries %d" % [Util.fmt_time(GS.play_time), GS.kills, GS.saves_used]
	win_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_enter_vr(v: bool) -> void:
	enter_vr_btn.visible = v
	enter_vr_btn_title.visible = v

func toggle_inventory() -> void:
	inventory_open = not inventory_open
	inventory_panel.visible = inventory_open
	if inventory_open:
		_refresh_inventory()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if player != null and player.has_method("set_active"):
			player.set_active(false)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if player != null and player.has_method("set_active"):
			player.set_active(true)

func _refresh_inventory() -> void:
	for c in inventory_list.get_children():
		c.queue_free()
	if GS.inventory.is_empty():
		inventory_list.add_child(_mk_label("(empty)", font_mono, 13, DIM))
	for it in GS.inventory:
		var row := HBoxContainer.new()
		var l := _mk_label("%s  x%d" % [it.name, it.qty], font_mono, 14, BONE)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if it.id in ["salve", "potent_salve", "ammo"]:
			var use := _mk_button("Use")
			var item_id: String = it.id
			use.pressed.connect(func(): GS.use_item(item_id); Sfx.play(self, "heal", -6.0); _refresh_inventory())
			row.add_child(use)
		inventory_list.add_child(row)
	inventory_panel.get_node("VBoxContainer/CombineBtn").disabled = GS.count_item("salve") < 2

func _process(delta: float) -> void:
	if player != null and player.get("current_prompt") != null:
		prompt_label.text = player.current_prompt
	if vignette_flash > 0.0:
		vignette_flash = maxf(0.0, vignette_flash - delta * 1.6)
	var low := 0.0
	if GS.health < 45:
		low = (1.0 - GS.health / 45.0) * (0.35 + 0.2 * sin(Time.get_ticks_msec() / 320.0))
	vignette.modulate = Color(1, 1, 1, clampf(vignette_flash + low, 0.0, 0.9))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and _game_hud.visible and player != null and not player.is_in_group("xr"):
		toggle_inventory()

func _on_health(value: int, maxv: int) -> void:
	vitals_fill.scale.x = clampf(float(value) / maxv, 0.0, 1.0)
	vitals_fill.color = BONE if value > 45 else (AMBER if value > 20 else BLOOD)
	vitals_label.text = "VITALS  %d" % value
	if value < last_health:
		vignette_flash = 0.75
	last_health = value

func _on_ammo(mag: int, reserve: int) -> void:
	ammo_label.text = "MAG %d / %d" % [mag, reserve]

func _on_message(text: String) -> void:
	message_label.text = text
	message_label.modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_interval(3.2)
	tw.tween_property(message_label, "modulate:a", 0.0, 0.8)
