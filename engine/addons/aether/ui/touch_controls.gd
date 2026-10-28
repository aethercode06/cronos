class_name AetherTouchControls
extends CanvasLayer
## Controles táctiles de Aether Engine: se muestran solo en pantallas táctiles.
## Cada botón dispara la misma acción que el teclado o el mando.

const BUTTONS := [
	# acción, texto, posición desde la esquina (x desde la izquierda o -x desde la derecha), radio
	["left", "◀", Vector2(120, -150), 78.0],
	["right", "▶", Vector2(300, -150), 78.0],
	["jump", "SALTO", Vector2(-130, -150), 90.0],
	["attack", "ESPADA", Vector2(-320, -110), 78.0],
	["dash", "DASH", Vector2(-290, -300), 64.0],
	["guard", "GUARDIA", Vector2(-120, -350), 60.0],
]

func _ready() -> void:
	layer = 60
	for b in BUTTONS:
		var btn := TouchScreenButton.new()
		btn.action = b[0]
		var r: float = b[3]
		btn.texture_normal = _circle(r, Color(1, 1, 1, 0.16))
		btn.texture_pressed = _circle(r, Color(1, 0.85, 0.4, 0.38))
		btn.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
		btn.passby_press = b[0] in ["left", "right"]
		var shape := CircleShape2D.new()
		shape.radius = r
		btn.shape = shape
		btn.shape_centered = true
		btn.set_meta("anchor", b[2])
		btn.set_meta("r", r)
		var l := Label.new()
		l.text = b[1]
		l.size = Vector2(r * 2, r * 2)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 26 if b[1].length() > 1 else 40)
		l.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override("outline_size", 6)
		btn.add_child(l)
		add_child(btn)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	for btn in get_children():
		if not btn is TouchScreenButton:
			continue
		var a: Vector2 = btn.get_meta("anchor")
		var r: float = btn.get_meta("r")
		var x := a.x if a.x > 0 else vs.x + a.x
		var y := vs.y + a.y
		btn.position = Vector2(x - r, y - r)

func _circle(r: float, col: Color) -> Texture2D:
	var s := int(r * 2)
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c := Vector2(r, r)
	for y in s:
		for x in s:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var a := 0.0
			if d < r:
				a = col.a
				if d > r - 4:
					a = min(1.0, col.a * 3.0)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)
