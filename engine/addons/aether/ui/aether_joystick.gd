@icon("res://addons/aether/icons/ui.svg")
class_name AetherJoystick
extends CanvasLayer
## Joystick táctil para juegos 3D (o 2D con movimiento libre).
## Mitad izquierda de la pantalla: mover (acciones left/right/up/down).
## Mitad derecha: arrastrar para girar la cámara (Aether.look_delta).
## Botones: SALTO, ATAQUE y DASH. Solo aparece en pantallas táctiles.

## Radio del joystick en píxeles.
@export var radius := 120.0

var _move_id := -1
var _look_id := -1
var _center := Vector2.ZERO
var _knob := Vector2.ZERO
var _last_look := Vector2.ZERO
var _base: Control
var _dot: Control
var _vec := Vector2.ZERO

func _ready() -> void:
	layer = 60
	if not DisplayServer.is_touchscreen_available():
		return
	_base = _circle_ctrl(radius, Color(1, 1, 1, 0.12))
	_dot = _circle_ctrl(radius * 0.42, Color(1, 1, 1, 0.35))
	_base.visible = false
	_dot.visible = false
	add_child(_base)
	add_child(_dot)
	var vs := get_viewport().get_visible_rect().size
	for b in [["jump", "SALTO", Vector2(-130, -150), 90.0], ["attack", "ATAQUE", Vector2(-320, -110), 76.0], ["dash", "DASH", Vector2(-290, -300), 62.0]]:
		var btn := TouchScreenButton.new()
		btn.action = b[0]
		var shape := CircleShape2D.new()
		shape.radius = b[3]
		btn.shape = shape
		btn.texture_normal = _circle_tex(b[3], Color(1, 1, 1, 0.16))
		btn.texture_pressed = _circle_tex(b[3], Color(1, 0.85, 0.4, 0.4))
		btn.position = Vector2(vs.x + b[2].x - b[3], vs.y + b[2].y - b[3])
		var l := Label.new()
		l.text = Aether.t(b[1])
		l.size = Vector2(b[3] * 2, b[3] * 2)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 24)
		btn.add_child(l)
		add_child(btn)

func _circle_tex(r: float, col: Color) -> Texture2D:
	var s := int(r * 2)
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(r, r))
			img.set_pixel(x, y, Color(col.r, col.g, col.b, col.a if d < r else 0.0))
	return ImageTexture.create_from_image(img)

func _circle_ctrl(r: float, col: Color) -> Control:
	var t := TextureRect.new()
	t.texture = _circle_tex(r, col)
	t.size = Vector2(r * 2, r * 2)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func _input(e: InputEvent) -> void:
	var half := get_viewport().get_visible_rect().size.x * 0.5
	if e is InputEventScreenTouch:
		if e.pressed:
			if e.position.x < half and _move_id < 0:
				_move_id = e.index
				_center = e.position
				_knob = e.position
				_show(true)
			elif e.position.x >= half and _look_id < 0:
				_look_id = e.index
				_last_look = e.position
		else:
			if e.index == _move_id:
				_move_id = -1
				_vec = Vector2.ZERO
				_apply()
				_show(false)
			elif e.index == _look_id:
				_look_id = -1
	elif e is InputEventScreenDrag:
		if e.index == _move_id:
			var d: Vector2 = e.position - _center
			if d.length() > radius:
				d = d.normalized() * radius
			_knob = _center + d
			_vec = d / radius
			_apply()
			_show(true)
		elif e.index == _look_id:
			Aether.look_delta += e.position - _last_look
			_last_look = e.position

func _show(on: bool) -> void:
	if _base == null:
		return
	_base.visible = on
	_dot.visible = on
	_base.position = _center - _base.size * 0.5
	_dot.position = _knob - _dot.size * 0.5

func _apply() -> void:
	var dz := 0.15
	_act("right", max(0.0, _vec.x) if _vec.x > dz else 0.0)
	_act("left", max(0.0, -_vec.x) if _vec.x < -dz else 0.0)
	_act("down", max(0.0, _vec.y) if _vec.y > dz else 0.0)
	_act("up", max(0.0, -_vec.y) if _vec.y < -dz else 0.0)

func _act(action: String, strength: float) -> void:
	if strength > 0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)
