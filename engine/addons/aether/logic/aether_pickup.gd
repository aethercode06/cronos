@tool
@icon("res://addons/aether/icons/anim.svg")
class_name AetherPickup
extends Area2D
## Objeto que se recoge al tocarlo: moneda, gema, llave, vida…
## Suma a una variable (ej. «monedas») y lanza «Cuando se recoge…».

## Variable a la que suma.
@export var var_name := "monedas"
## Cuánto suma.
@export var amount := 1.0
## Cura al jugador al recogerlo (0 = no).
@export var heal := 0.0
## Imagen (vacío = gema brillante).
@export var texture: Texture2D:
	set(v):
		texture = v
		queue_redraw()
## Escala de la imagen.
@export var art_scale := 0.6
## Color de la gema por defecto y del brillo.
@export var color := Color(1.0, 0.8, 0.3)
## Sonido al recogerlo.
@export var sound := "gem"

var _t := 0.0
var _taken := false
var _spr: Sprite2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 28
	cs.shape = c
	add_child(cs)
	_t = randf() * 6.0
	if texture:
		_spr = Sprite2D.new()
		_spr.texture = texture
		_spr.scale = Vector2.ONE * art_scale
		add_child(_spr)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body)

func _process(delta: float) -> void:
	_t += delta
	if _spr:
		_spr.position.y = sin(_t * 3.0) * 6.0
	queue_redraw()

func _draw() -> void:
	if texture:
		return
	var y := sin(_t * 3.0) * 6.0
	var s := 14.0
	var pts := PackedVector2Array([Vector2(0, -s * 1.3 + y), Vector2(s, y), Vector2(0, s * 1.3 + y), Vector2(-s, y)])
	draw_circle(Vector2(0, y), s * 2.2, Color(color.r, color.g, color.b, 0.18))
	draw_colored_polygon(pts, Color(color.r * 1.6, color.g * 1.6, color.b * 1.6))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1, 1, 1, 0.8), 2.0)

func _on_body(b: Node) -> void:
	if _taken or not b.is_in_group("player"):
		return
	_taken = true
	Aether.add_var(var_name, amount)
	if heal > 0 and b.has_method("heal"):
		b.heal(heal)
	Aether.sfx(sound, 0.6, randf_range(1.1, 1.3))
	FX.burst(get_parent(), global_position, Color(color.r * 2, color.g * 2, color.b * 2), 14, 300, 0.4, 9, 200)
	FX.ring(get_parent(), global_position, Color(color.r * 1.8, color.g * 1.8, color.b * 1.8, 0.8), 60, 0.2)
	Aether.picked.emit(var_name)
	queue_free()
