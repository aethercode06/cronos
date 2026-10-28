extends CanvasLayer
## Mapa de mundos de Chronos en Aether: 18 mundos en el orden del juego,
## 3 fases cada uno, progreso guardado y elección de dificultad.

const DIFF_NAMES := ["FÁCIL", "NORMAL", "DIFÍCIL", "PESADILLA"]

var _grid: GridContainer
var _diff := 1
var _diff_btn: Button
var _info: Label
var _modes: HBoxContainer

func _ready() -> void:
	var D: Dictionary = CrGame.data()
	_diff = int(Aether.save.get_value("cr_diff", 1))
	var bg := TextureRect.new()
	bg.texture = Aether.tex("keyart")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(0.45, 0.45, 0.55)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 30
	root.offset_right = -30
	root.offset_top = 16
	root.offset_bottom = -16
	add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var t := Label.new()
	t.text = "CHRONOS & THE SHIFT"
	t.add_theme_font_size_override("font_size", 40)
	t.add_theme_color_override("font_outline_color", Color.BLACK)
	t.add_theme_constant_override("outline_size", 10)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	_diff_btn = Button.new()
	_diff_btn.custom_minimum_size = Vector2(240, 60)
	_diff_btn.add_theme_font_size_override("font_size", 24)
	_diff_btn.pressed.connect(_next_diff)
	top.add_child(_diff_btn)
	_info = Label.new()
	_info.add_theme_font_size_override("font_size", 20)
	root.add_child(_info)
	_modes = HBoxContainer.new()
	_modes.add_theme_constant_override("separation", 12)
	root.add_child(_modes)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sc)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	sc.add_child(_grid)
	_build()
	Aether.music("menu")

func _next_diff() -> void:
	_diff = (_diff + 1) % 4
	Aether.save.set_value("cr_diff", _diff)
	_build()

func _build() -> void:
	_diff_btn.text = Aether.t(DIFF_NAMES[_diff])
	for c in _grid.get_children():
		c.queue_free()
	var D: Dictionary = CrGame.data()
	var prog: int = int(Aether.save.get_value("cr_prog", 1))
	if OS.has_feature("editor") or Aether.save.get_value("cr_todo_abierto", false):
		prog = 999
	_info.text = "%s: %d / 54   ·   %s %d" % [Aether.t("Fases"), min(prog - 1, 54), Aether.t("Récord"), int(Aether.save.get_value("cr_score", 0))]
	for c in _modes.get_children():
		c.queue_free()
	var today := int(Time.get_unix_time_from_system() / 86400.0)
	var dbest: float = float(Aether.save.get_value("cr_diario_%d" % today, 0.0))
	for m in [["torre", "TORRE DEL TIEMPO", "Récord: piso %d" % int(Aether.save.get_value("cr_torre", 0)), 4],
			["rush", "BOSS RUSH", "Récord: %d guardianes" % int(Aether.save.get_value("cr_rush", 0)), 10],
			["diario", "RETO DIARIO", ("Hoy: %.1f s" % dbest) if dbest > 0.0 else "¡Juega el de hoy!", 2]]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(250, 72)
		b.add_theme_font_size_override("font_size", 20)
		b.text = "%s\n%s" % [Aether.t(m[1]), m[2]]
		b.disabled = prog < int(m[3])
		b.pressed.connect(_play_mode.bind(m[0]))
		_modes.add_child(b)
	var order: Array = D.order
	for i in order.size():
		var w: Dictionary = D.worlds[int(order[i])]
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(380, 0)
		var lbl := Label.new()
		lbl.text = "%d · %s" % [i + 1, w.name]
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color.from_string(str(w.get("c", "#ffffff")), Color.WHITE))
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 6)
		box.add_child(lbl)
		var row := HBoxContainer.new()
		box.add_child(row)
		for a in 3:
			var idx := i * 3 + a
			var b := Button.new()
			b.custom_minimum_size = Vector2(118, 64)
			b.add_theme_font_size_override("font_size", 22)
			b.text = ("%d-%d" % [i + 1, a + 1]) if a < 2 else "☠ %d-3" % (i + 1)
			b.disabled = idx >= prog
			b.pressed.connect(_play.bind(int(order[i]), a))
			row.add_child(b)
		_grid.add_child(box)

func _play(w: int, a: int) -> void:
	CrGame.launch = {"wi": w, "act": a, "diff": _diff}
	Aether.sfx("check", 0.6)
	get_tree().change_scene_to_file("res://chronos/chronos.tscn")

func _play_mode(m: String) -> void:
	CrGame.launch = {"mode": m, "diff": _diff}
	Aether.sfx("check", 0.6)
	get_tree().change_scene_to_file("res://chronos/chronos.tscn")
