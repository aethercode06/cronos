@icon("res://addons/aether/icons/hazard.svg")
class_name AetherHazard
extends Node2D
## Peligros de los jefes: ondas de choque por el suelo y proyectiles en arco.

@export var kind := "wave"        # «wave» o «bubble»
var vel := Vector2.ZERO
var gravity := 0.0
var damage := 18.0
var radius := 26.0
var floor_y := 0.0
var life := 4.0
var col := Color(1.6, 1.3, 0.6)
var _hit := false
var _vis: Sprite2D
var _core: Sprite2D
var _t := 0.0

func _ready() -> void:
	_vis = Sprite2D.new()
	_vis.texture = FX.soft()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_vis.material = mat
	_vis.modulate = col
	add_child(_vis)
	_core = Sprite2D.new()
	_core.texture = FX.dot()
	_core.material = mat
	_core.modulate = Color(col.r * 1.5, col.g * 1.5, col.b * 1.5, 1.0)
	add_child(_core)
	if kind == "wave":
		_vis.scale = Vector2(2.2, 1.6)
		_vis.position = Vector2(0, -26)
		_core.scale = Vector2(1.2, 0.5)
		_core.position = Vector2(0, -8)
	else:
		_vis.scale = Vector2.ONE * (radius / 18.0)
		_core.scale = Vector2.ONE * (radius / 40.0)

func _physics_process(delta: float) -> void:
	_t += delta
	life -= delta
	if life <= 0:
		queue_free()
		return
	vel.y += gravity * delta
	position += vel * delta
	if kind == "wave":
		_vis.scale.y = 1.6 + sin(_t * 30.0) * 0.25
		if fmod(_t, 0.05) < delta:
			FX.burst(get_parent(), position, Color(col.r, col.g, col.b, 0.7), 3, 220, 0.3, 10, 600, 30, Vector2.UP)
	else:
		_core.rotation += delta * 6.0
		if position.y >= floor_y:
			FX.burst(get_parent(), position, col, 18, 380, 0.35, 10, 700)
			FX.ring(get_parent(), position, Color(col.r, col.g, col.b, 0.8), 90, 0.25)
			Aether.sfx("bounce", 0.4, 0.8)
			queue_free()
			return
	var pl = Aether.player
	if _hit or pl == null or pl.dead:
		return
	var r: Rect2 = pl.hurt_rect()
	var mine := Rect2(position + Vector2(-36, -52), Vector2(72, 52)) if kind == "wave" else Rect2(position - Vector2.ONE * radius, Vector2.ONE * radius * 2)
	if r.intersects(mine):
		_hit = true
		pl.take_damage(damage, position.x - sign(vel.x) * 10.0)
		if kind == "bubble":
			queue_free()
