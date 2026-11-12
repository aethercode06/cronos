@icon("res://addons/aether/icons/ui.svg")
class_name AetherTouchFP
extends CanvasLayer
## Controles táctiles para primera persona.
## Mitad izquierda: joystick que aparece donde pones el dedo (al máximo = correr).
## Mitad derecha: arrastrar para mirar. Botones configurables a la derecha.
##   touch.buttons = [["usar", "USAR", Vector2(-150, -170), 82.0], ...]

@export var radius := 110.0
@export var player_path: NodePath
## Mostrar aunque no haya pantalla táctil (pruebas).
@export var force := false

var buttons: Array = []
var player: AetherPlayerFP
var _move_id := -1
var _look_id := -1
var _center := Vector2.ZERO
var _base: Control
var _dot: Control
var _btns: Array[TouchScreenButton] = []
var _labels := {}

func _ready() -> void:
	layer = 60
	if not (force or DisplayServer.is_touchscreen_available()):
		return
	if player == null and player_path != NodePath():
		player = get_node_or_null(player_path)
	_base = _circle_ctrl(radius, Color(1, 1, 1, 0.08))
	_dot = _circle_ctrl(radius * 0.42, Color(1, 1, 1, 0.28))
	_base.visible = false
	_dot.visible = false
	add_child(_base)
	add_child(_dot)
	build_buttons()
	get_viewport().size_changed.connect(build_buttons)

func enabled() -> bool:
	return _base != null

func build_buttons() -> void:
	if _base == null:
		return
	for b in _btns:
		b.queue_free()
	_btns.clear()
	_labels.clear()
	var vs := get_viewport().get_visible_rect().size
	for b in buttons:
		var btn := TouchScreenButton.new()
		btn.action = b[0]
		var r: float = b[3]
		var shape := CircleShape2D.new()
		shape.radius = r
		btn.shape = shape
		btn.texture_normal = _circle_tex(r, Color(0.9, 0.85, 0.75, 0.13))
		btn.texture_pressed = _circle_tex(r, Color(1, 0.8, 0.5, 0.35))
		var off: Vector2 = b[2]
		btn.position = Vector2(vs.x + off.x - r, vs.y + off.y - r)
		var l := Label.new()
		l.text = b[1]
		l.size = Vector2(r * 2, r * 2)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", int(r * 0.34))
		l.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 0.75))
		btn.add_child(l)
		_labels[b[0]] = l
		add_child(btn)
		_btns.append(btn)

## Cambia el texto de un botón (por ejemplo USAR → SALIR).
func set_label(action: String, text: String) -> void:
	if _labels.has(action):
		_labels[action].text = text

func set_visible_button(action: String, v: bool) -> void:
	for b in _btns:
		if b.action == action:
			b.visible = v

func _on_button(p: Vector2) -> bool:
	for b in _btns:
		if not b.visible:
			continue
		var r: float = (b.shape as CircleShape2D).radius
		if p.distance_to(b.position + Vector2(r, r)) <= r * 1.15:
			return true
	return false

func _input(e: InputEvent) -> void:
	if _base == null or not visible:
		return
	var vs := get_viewport().get_visible_rect().size
	if e is InputEventScreenTouch:
		if e.pressed:
			if _on_button(e.position):
				return
			if e.position.x < vs.x * 0.45 and _move_id == -1:
				_move_id = e.index
				_center = e.position
				_base.visible = true
				_dot.visible = true
				_place(_base, _center, radius)
				_place(_dot, _center, radius * 0.42)
			elif _look_id == -1:
				_look_id = e.index
		else:
			if e.index == _move_id:
				_move_id = -1
				_base.visible = false
				_dot.visible = false
				if player:
					player.move_override = Vector2.ZERO
					player.run_override = false
			elif e.index == _look_id:
				_look_id = -1
	elif e is InputEventScreenDrag:
		if e.index == _move_id:
			var d: Vector2 = e.position - _center
			if d.length() > radius:
				_center += d - d.normalized() * radius
				_place(_base, _center, radius)
				d = e.position - _center
			_place(_dot, _center + d, radius * 0.42)
			var v := d / radius
			if player:
				player.move_override = v
				player.run_override = v.length() > 0.93
		elif e.index == _look_id:
			Aether.look_delta += e.relative

func _place(c: Control, p: Vector2, r: float) -> void:
	c.position = p - Vector2(r, r)

func _circle_ctrl(r: float, col: Color) -> Control:
	var t := TextureRect.new()
	t.texture = _circle_tex(r, col)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func _circle_tex(r: float, col: Color) -> Texture2D:
	var s := int(r * 2)
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d := Vector2(x - r, y - r).length()
			if d <= r:
				var a := col.a * (1.0 if d > r - 3.0 else 0.55)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)
