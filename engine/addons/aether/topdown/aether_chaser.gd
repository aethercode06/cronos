@icon("res://addons/aether/icons/enemy.svg")
class_name AetherChaser
extends CharacterBody2D
## Criatura con vista desde arriba: pasea, te ve y te persigue.
## En modo «acechador» (terror) es invencible y solo se mueve cuando NO la
## miras: si te toca, pierdes.

@export_enum("perseguir", "acechador") var mode := "perseguir"
@export var speed := 170.0
@export var hp := 3.0
@export var damage := 20.0
## Distancia a la que te ve.
@export var sight := 380.0
@export var texture: Texture2D
@export var art_scale := 0.5
@export var color := Color(0.9, 0.3, 0.35)
## Sangra al recibir golpes (kit de gore).
@export var gore := false

var _dir := Vector2.ZERO
var _wander := 0.0
var _fl := 0.0
var _cd := 0.0
var _beat := 0.0
var _seen := false
var _detour := 0.0
var _detour_dir := Vector2.ZERO

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("enemies")
	add_to_group("aether_enemy")
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 24
	cs.shape = c
	add_child(cs)

func _watched(pl: Node2D) -> bool:
	var to_me := global_position - pl.global_position
	var f: Vector2 = pl.get("facing") if pl.get("facing") != null else Vector2.RIGHT
	return to_me.length() < 520.0 and f.dot(to_me.normalized()) > 0.55

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_fl = max(0.0, _fl - delta)
	_cd = max(0.0, _cd - delta)
	queue_redraw()
	var pl = Aether.player
	if pl == null or not pl is Node2D:
		return
	var to := (pl as Node2D).global_position - global_position
	var dist := to.length()
	if mode == "acechador":
		var frozen := _watched(pl)
		velocity = Vector2.ZERO if (frozen or dist > 650.0) else to.normalized() * speed
		_beat -= delta
		if dist < 500 and _beat <= 0.0:
			_beat = clamp(dist / 500.0, 0.25, 1.0)
			Aether.sfx("step", 0.5, 0.45)
		if frozen and not _seen and dist < 400:
			Aether.shake(4)
		_seen = frozen
	else:
		if dist < sight:
			velocity = velocity.move_toward(to.normalized() * speed, 900.0 * delta)
		else:
			_wander -= delta
			if _wander <= 0.0:
				_wander = randf_range(1.0, 2.5)
				_dir = Vector2.RIGHT.rotated(randf() * TAU) * (0.0 if randf() < 0.3 else speed * 0.4)
			velocity = velocity.move_toward(_dir, 600.0 * delta)
	if _detour > 0.0:
		_detour -= delta
		if velocity.length() > 1.0:
			velocity = _detour_dir * velocity.length()
	var want := velocity
	move_and_slide()
	if want.length() > 40.0 and get_real_velocity().length() < want.length() * 0.3 and _detour <= 0.0:
		_detour = 0.6
		_detour_dir = want.normalized().rotated(PI / 2 if randf() < 0.5 else -PI / 2)
	if dist < 46 and _cd <= 0.0 and pl.has_method("take_damage"):
		_cd = 0.8
		pl.take_damage(999.0 if mode == "acechador" else damage, global_position.x)

func take_hit(dmg: float, _src: Node = null, _heavy := false) -> void:
	if mode == "acechador":
		Aether.sfx("clang", 0.5)
		return
	hp -= dmg
	_fl = 0.1
	if gore:
		var from: Vector2 = (_src as Node2D).global_position if _src is Node2D else global_position
		AetherGore.spray_2d(get_parent(), global_position, global_position - from, 0.6)
	Aether.sfx("hit", 0.6)
	var pl = Aether.player
	if pl:
		velocity = (global_position - pl.global_position).normalized() * 500.0
	if hp <= 0.0:
		Aether.sfx("kill", 0.7)
		FX.burst(get_parent(), global_position, Color(2, 0.7, 0.6), 18, 360, 0.45, 9, 0)
		Aether.enemy_killed.emit()
		queue_free()

func _draw() -> void:
	draw_circle(Vector2(0, 18), 24, Color(0, 0, 0, 0.3))
	var col: Color = Color(3, 3, 3) if _fl > 0.0 else color
	if texture:
		var s := texture.get_size() * art_scale
		draw_texture_rect(texture, Rect2(-s.x * 0.5, -s.y + 20, s.x, s.y), false, col if _fl > 0.0 else Color(1, 1, 1))
	elif mode == "acechador":
		draw_rect(Rect2(-18, -70, 36, 90), Color(0.92, 0.92, 0.95, 0.85))
		draw_circle(Vector2(0, -78), 18, Color(0.95, 0.95, 1.0, 0.9))
		draw_circle(Vector2(-6, -80), 4, Color(0, 0, 0))
		draw_circle(Vector2(6, -80), 4, Color(0, 0, 0))
	else:
		draw_circle(Vector2(0, -6), 24, col)
		draw_circle(Vector2(-8, -12), 6, Color(1, 1, 0.7))
		draw_circle(Vector2(8, -12), 6, Color(1, 1, 0.7))
