class_name CrStory
extends CanvasLayer
## Historia de Chronos: cuadros de diálogo con retrato (Kael, Tic, Lyra…),
## texto que aparece letra a letra y escenas ilustradas con movimiento de cámara.
## Los textos vienen de historia.json (exportado del juego web).

signal done

static var DATA := {}
var lines: Array = []
var i := 0
var shown := 0.0
var hold := false
var auto_t := 0.0
var cut := []
var cut_i := 0
var cut_t := 0.0
var _then: Callable
var _box: Panel
var _face: TextureRect
var _name: Label
var _text: Label
var _cut_img: TextureRect
var _cut_box: Control
var _cut_text: Label
var _cut_name: Label
var _last_tap := 0

static func data() -> Dictionary:
	if DATA.is_empty():
		DATA = JSON.parse_string(FileAccess.get_file_as_string("res://chronos/niveles/historia.json"))
	return DATA

func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cut_img = TextureRect.new()
	_cut_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cut_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_cut_img.visible = false
	add_child(_cut_img)
	_cut_box = ColorRect.new()
	(_cut_box as ColorRect).color = Color(0, 0, 0, 0.6)
	_cut_box.visible = false
	add_child(_cut_box)
	_cut_name = _mk_label(26, Color(1, 0.9, 0.6))
	_cut_box.add_child(_cut_name)
	_cut_text = _mk_label(26, Color.WHITE)
	_cut_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cut_box.add_child(_cut_text)
	_box = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.1, 0.88)
	sb.border_color = Color(1, 0.85, 0.5, 0.6)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	_box.add_theme_stylebox_override("panel", sb)
	_box.visible = false
	add_child(_box)
	_face = TextureRect.new()
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_box.add_child(_face)
	_name = _mk_label(22, Color(1, 0.8, 0.4))
	_box.add_child(_name)
	_text = _mk_label(22, Color.WHITE)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(_text)
	_layout()
	get_viewport().size_changed.connect(_layout)

func _mk_label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	return l

func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	_box.position = Vector2(vs.x * 0.12, vs.y - 190)
	_box.size = Vector2(vs.x * 0.76, 150)
	_face.position = Vector2(12, 12)
	_face.size = Vector2(126, 126)
	_name.position = Vector2(150, 10)
	_text.position = Vector2(150, 44)
	_text.size = Vector2(_box.size.x - 170, 100)
	_cut_img.size = vs
	_cut_box.position = Vector2(0, vs.y - 170)
	_cut_box.size = Vector2(vs.x, 170)
	_cut_name.position = Vector2(60, 14)
	_cut_text.position = Vector2(60, 50)
	_cut_text.size = Vector2(vs.x - 120, 110)

func busy() -> bool:
	return hold and (_box.visible or _cut_img.visible)

func in_cut() -> bool:
	return _cut_img.visible

## Muestra líneas [[quién, texto], …]. Con hold el juego espera.
func say(p_lines: Array, p_hold := false, then := Callable()) -> void:
	lines = p_lines.filter(func(l): return l is Array and l.size() >= 2 and str(l[1]) != "")
	i = 0
	hold = p_hold
	_then = then
	if lines.is_empty():
		_finish()
		return
	_show_line()

func _who(k: String) -> Dictionary:
	var w: Dictionary = data().get("who", {})
	return w.get(k, {"n": k, "c": "#ffffff"})

func _show_line() -> void:
	var l: Array = lines[i]
	var who := _who(str(l[0]))
	var nm: String = str(who.get("n", ""))
	if str(l[0]) == "BOSS":
		nm = str(get_meta("boss_name", "GUARDIÁN"))
	_name.text = nm
	_name.add_theme_color_override("font_color", Color.from_string(str(who.get("c", "#ffffff")), Color.WHITE))
	var pt = who.get("pt")
	_face.texture = Aether.tex(str(pt)) if pt else null
	_face.visible = _face.texture != null
	_text.position.x = 150 if _face.visible else 20
	_text.text = Aether.t(str(l[1]))
	_text.visible_characters = 0
	shown = 0.0
	auto_t = 2.0 + _text.text.length() / 22.0
	_box.visible = true

func _advance() -> void:
	if _text.visible_characters >= 0 and _text.visible_characters < _text.text.length():
		_text.visible_characters = -1
		return
	i += 1
	if i >= lines.size():
		_box.visible = false
		_finish()
	else:
		_show_line()

func _finish() -> void:
	hold = false
	var f := _then
	_then = Callable()
	done.emit()
	if f.is_valid():
		f.call()

## Escena ilustrada: CUTS[id] = [{img, pan, lines}, …]
func play_cut(id: String, then := Callable()) -> void:
	var c = data().get("cuts", {}).get(id)
	if not c is Array or c.is_empty():
		if then.is_valid():
			then.call()
		return
	cut = c
	cut_i = 0
	hold = true
	_then = then
	_cut_img.visible = true
	_cut_box.visible = true
	_box.visible = false
	Aether.music("menu")
	_show_cut()

func _show_cut() -> void:
	var sc: Dictionary = cut[cut_i]
	_cut_img.texture = Aether.tex(str(sc.get("img", "")))
	cut_t = 0.0
	lines = sc.get("lines", [])
	i = 0
	_show_cut_line()

func _show_cut_line() -> void:
	if lines.is_empty():
		return
	var l: Array = lines[i]
	var who := _who(str(l[0]))
	_cut_name.text = str(who.get("n", ""))
	_cut_name.add_theme_color_override("font_color", Color.from_string(str(who.get("c", "#ffe7a8")), Color.WHITE))
	_cut_text.text = Aether.t(str(l[1]))
	_cut_text.visible_characters = 0
	shown = 0.0

func _advance_cut() -> void:
	if _cut_text.visible_characters >= 0 and _cut_text.visible_characters < _cut_text.text.length():
		_cut_text.visible_characters = -1
		return
	i += 1
	if i < lines.size():
		_show_cut_line()
		return
	cut_i += 1
	if cut_i < cut.size():
		_show_cut()
		return
	_cut_img.visible = false
	_cut_box.visible = false
	_finish()

func _process(delta: float) -> void:
	if _cut_img.visible:
		cut_t += delta
		var sc: Dictionary = cut[cut_i]
		var pan: Array = sc.get("pan", [0, 0, 1, 1])
		var vs := get_viewport().get_visible_rect().size
		var k: float = clamp(cut_t / 9.0, 0.0, 1.0)
		var zoom: float = lerp(float(pan[2]) if pan.size() > 2 else 1.0, float(pan[3]) if pan.size() > 3 else 1.0, k)
		_cut_img.size = vs * zoom
		_cut_img.position = -Vector2(vs.x * (zoom - 1.0) * lerp(float(pan[0]), float(pan[1]), k) * 4.0, vs.y * (zoom - 1.0) * 0.5)
		shown += delta * 40.0
		_cut_text.visible_characters = int(shown) if _cut_text.visible_characters >= 0 else -1
		return
	if _box.visible:
		shown += delta * 45.0
		if _text.visible_characters >= 0:
			_text.visible_characters = int(shown)
			if _text.visible_characters >= _text.text.length():
				_text.visible_characters = -1
		if not hold:
			auto_t -= delta
			if auto_t <= 0.0:
				_advance()

func _input(e: InputEvent) -> void:
	if not (_box.visible or _cut_img.visible):
		return
	var tap: bool = (e is InputEventMouseButton and e.pressed) or e.is_action_pressed("jump") or e.is_action_pressed("attack")
	if not tap or Time.get_ticks_msec() - _last_tap < 180:
		return
	_last_tap = Time.get_ticks_msec()
	if _cut_img.visible:
		_advance_cut()
		get_viewport().set_input_as_handled()
	elif hold:
		_advance()
		get_viewport().set_input_as_handled()
