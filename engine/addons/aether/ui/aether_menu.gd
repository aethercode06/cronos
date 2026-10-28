@icon("res://addons/aether/icons/ui.svg")
class_name AetherMenu
extends CanvasLayer
## Menús listos: pantalla de título, pausa y opciones (música, efectos, idioma).
## - Modo «titulo»: pon esta pieza en una escena vacía y elige la escena del juego.
## - Modo «pausa»: ponla en tu nivel; aparece un botón de pausa arriba a la derecha.

## «titulo» o «pausa».
@export_enum("titulo", "pausa") var mode := "pausa"
## Nombre del juego (pantalla de título).
@export var game_title := "MI JUEGO"
## Escena que se abre al pulsar JUGAR.
@export_file("*.tscn") var play_scene := ""
## Imagen de fondo del título (opcional).
@export var background: Texture2D
## Muestra la opción «Sangre» (sin / poca / toda) en Opciones.
@export var gore_option := false

var _panel: Control
var _opts: Control
var _pause_btn: Button

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	if mode == "titulo":
		_build_title()
	else:
		_build_pause()

func _btn(parent: Node, text: String, f: Callable) -> Button:
	var b := Button.new()
	b.text = Aether.t(text)
	b.custom_minimum_size = Vector2(320, 70)
	b.add_theme_font_size_override("font_size", 30)
	b.pressed.connect(func():
		Aether.sfx("check", 0.5, 1.3)
		f.call())
	parent.add_child(b)
	return b

func _center_box() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	v.position = Vector2(-160, -150)
	return v

func _build_title() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	if background:
		var bg := TextureRect.new()
		bg.texture = background
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		root.add_child(bg)
	else:
		var c := ColorRect.new()
		c.color = Color(0.04, 0.03, 0.09)
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(c)
	var t := Label.new()
	t.text = game_title
	t.set_anchors_preset(Control.PRESET_TOP_WIDE)
	t.position.y = 90
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 72)
	t.add_theme_color_override("font_color", Color(1, 0.86, 0.4))
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t.add_theme_constant_override("outline_size", 14)
	root.add_child(t)
	var v := _center_box()
	v.position.y = -40
	root.add_child(v)
	_btn(v, "JUGAR", func():
		if play_scene != "":
			get_tree().change_scene_to_file(play_scene))
	_btn(v, "OPCIONES", _show_options)
	_btn(v, "SALIR", func(): get_tree().quit())
	_panel = root

func _build_pause() -> void:
	_pause_btn = Button.new()
	_pause_btn.text = "II"
	_pause_btn.custom_minimum_size = Vector2(76, 76)
	_pause_btn.add_theme_font_size_override("font_size", 32)
	_pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pause_btn.position = Vector2(-100, 24)
	_pause_btn.pressed.connect(func(): _set_paused(true))
	add_child(_pause_btn)
	var root := ColorRect.new()
	root.color = Color(0, 0, 0, 0.65)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	add_child(root)
	var v := _center_box()
	root.add_child(v)
	var l := Label.new()
	l.text = Aether.t("PAUSA")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 56)
	v.add_child(l)
	_btn(v, "CONTINUAR", func(): _set_paused(false))
	_btn(v, "REINICIAR", func():
		_set_paused(false)
		get_tree().reload_current_scene())
	_btn(v, "OPCIONES", _show_options)
	_panel = root

func _unhandled_input(e: InputEvent) -> void:
	if mode == "pausa" and e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		_set_paused(not get_tree().paused)

func _set_paused(on: bool) -> void:
	get_tree().paused = on
	_panel.visible = on
	if _opts:
		_opts.visible = false
	_pause_btn.visible = not on

func _show_options() -> void:
	if _opts:
		_opts.visible = true
		return
	_opts = ColorRect.new()
	(_opts as ColorRect).color = Color(0.03, 0.03, 0.08, 0.95)
	_opts.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_opts)
	var v := _center_box()
	v.position = Vector2(-220, -220)
	_opts.add_child(v)
	for row in [["Música", Aether.vol_music, true], ["Efectos", Aether.vol_sfx, false]]:
		var l := Label.new()
		l.text = Aether.t(row[0])
		l.add_theme_font_size_override("font_size", 28)
		v.add_child(l)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 1
		s.step = 0.05
		s.value = row[1]
		s.custom_minimum_size = Vector2(440, 50)
		var is_music: bool = row[2]
		s.value_changed.connect(func(val):
			if is_music:
				Aether.set_volumes(val, Aether.vol_sfx)
			else:
				Aether.set_volumes(Aether.vol_music, val)
				Aether.sfx("hit", 0.6))
		v.add_child(s)
	var ll := Label.new()
	ll.text = Aether.t("Idioma")
	ll.add_theme_font_size_override("font_size", 28)
	v.add_child(ll)
	var ob := OptionButton.new()
	ob.custom_minimum_size = Vector2(440, 60)
	var langs := Aether.lang.available()
	for i in langs.size():
		ob.add_item(Aether.lang.display_name(langs[i]))
		if langs[i] == Aether.lang.code:
			ob.select(i)
	ob.item_selected.connect(func(i): Aether.lang.set_lang(langs[i]))
	v.add_child(ob)
	if gore_option:
		var gl := Label.new()
		gl.text = Aether.t("Sangre")
		gl.add_theme_font_size_override("font_size", 28)
		v.add_child(gl)
		var go := OptionButton.new()
		go.custom_minimum_size = Vector2(440, 60)
		for t in ["Sin sangre", "Poca", "Toda"]:
			go.add_item(Aether.t(t))
		go.select(Aether.gore)
		go.item_selected.connect(func(i):
			Aether.gore = i
			Aether.save.set_value("gore", i))
		v.add_child(go)
	_btn(v, "VOLVER", func(): _opts.visible = false)
