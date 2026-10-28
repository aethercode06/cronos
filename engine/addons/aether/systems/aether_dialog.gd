@icon("res://addons/aether/icons/ui.svg")
class_name AetherDialog
extends CanvasLayer
## Diálogos con retrato y nombre, texto que aparece letra a letra y toque para seguir.
## Escribe las líneas en «lines» así:  Nombre: texto  (una por línea).
## Se lanza con el evento «Mostrar diálogo» o desde código: $Dialogo.play()

signal finished

## Líneas del diálogo, una por línea: «Tic: ¡Hola, Kael!»
@export_multiline var lines := "Tic: ¡Hola! Soy Tic.\nKael: Vamos allá."
## Retratos por nombre (Nombre → imagen).
@export var portraits: Dictionary[String, Texture2D] = {}
## Pausa el juego mientras se habla.
@export var pause_game := true
## Letras por segundo.
@export var speed := 45.0

var _box: PanelContainer
var _name: Label
var _text: RichTextLabel
var _face: TextureRect
var _queue: Array = []
var _shown := 0.0
var _active := false

func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box = PanelContainer.new()
	_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box.position = Vector2(40, -250)
	_box.custom_minimum_size = Vector2(0, 200)
	_box.offset_left = 40
	_box.offset_right = -40
	_box.offset_top = -240
	_box.offset_bottom = -30
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.03, 0.09, 0.92)
	sb.border_color = Color(1, 0.8, 0.4, 0.8)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	_box.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	_box.add_child(h)
	_face = TextureRect.new()
	_face.custom_minimum_size = Vector2(150, 150)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(_face)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 30)
	_name.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
	v.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 28)
	v.add_child(_text)
	_box.visible = false
	add_child(_box)

func play(custom := "") -> void:
	var src := custom if custom != "" else lines
	_queue = []
	for l in src.split("\n"):
		if l.strip_edges() != "":
			_queue.append(l)
	if _queue.is_empty():
		return
	_active = true
	_box.visible = true
	if pause_game:
		get_tree().paused = true
	_next()

func _next() -> void:
	if _queue.is_empty():
		_active = false
		_box.visible = false
		if pause_game:
			get_tree().paused = false
		finished.emit()
		return
	var l: String = _queue.pop_front()
	var who := ""
	var txt := l
	var i := l.find(":")
	if i > 0 and i < 24:
		who = l.substr(0, i).strip_edges()
		txt = l.substr(i + 1).strip_edges()
	_name.text = Aether.t(who)
	_text.text = Aether.t(txt)
	_text.visible_characters = 0
	_shown = 0.0
	_face.texture = portraits.get(who)
	_face.visible = _face.texture != null
	Aether.sfx("check", 0.3, 1.6)

func _process(delta: float) -> void:
	if not _active:
		return
	_shown += delta * speed
	_text.visible_characters = int(_shown)

func _input(e: InputEvent) -> void:
	if not _active:
		return
	var tap: bool = (e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed) or e.is_action_pressed("jump") or e.is_action_pressed("attack")
	if tap:
		get_viewport().set_input_as_handled()
		if _text.visible_characters < _text.get_total_character_count():
			_shown = 9999
			_text.visible_characters = -1
		else:
			_next()
