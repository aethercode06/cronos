@icon("res://addons/aether/icons/player.svg")
class_name AetherTopDownPlayer
extends CharacterBody2D
## Jugador con vista desde arriba (RPG, terror, aventura): se mueve en 8
## direcciones, corre con DASH, golpea con ATAQUE y habla con ATAQUE junto a un
## personaje. Con cámara propia, vida y reaparición.

signal hp_changed(hp: float, max_hp: float)
signal died

@export var speed := 280.0
## Velocidad al mantener DASH (correr).
@export var run_speed := 430.0
@export var max_hp := 100.0
## Daño de cada golpe.
@export var attack_damage := 1.0
## Puede atacar (desactívalo en juegos de terror).
@export var can_attack := true
## Imagen del personaje (opcional; si no hay, se dibuja).
@export var texture: Texture2D
@export var art_scale := 0.5
@export var color := Color(0.35, 0.8, 1.0)
## Crea su propia cámara que lo sigue.
@export var own_camera := true
@export var camera_zoom := 1.0
## Reaparece al morir en el punto de inicio.
@export var auto_respawn := true

var hp := 100.0
var facing := Vector2.DOWN
var start_pos := Vector2.ZERO
var talking := false
var _inv := 0.0
var _atk := 0.0
var _hurt := 0.0
var _dead := false
var _step := 0.0
var _cam: Camera2D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 22
	cs.shape = c
	add_child(cs)
	hp = max_hp
	start_pos = global_position
	if Engine.is_editor_hint():
		return
	Aether.player = self
	if own_camera:
		_cam = Camera2D.new()
		_cam.zoom = Vector2(camera_zoom, camera_zoom)
		_cam.position_smoothing_enabled = true
		_cam.position_smoothing_speed = 7.0
		add_child(_cam)
		_cam.make_current()
	hp_changed.emit.call_deferred(hp, max_hp)

func _physics_process(delta: float) -> void:
	_inv = max(0.0, _inv - delta)
	_atk = max(0.0, _atk - delta)
	_hurt = max(0.0, _hurt - delta)
	queue_redraw()
	if _dead or talking:
		velocity = Vector2.ZERO
		return
	var mv := Input.get_vector("left", "right", "up", "down")
	if mv.length() > 0.1:
		facing = mv.normalized()
	var spd := run_speed if Input.is_action_pressed("dash") else speed
	if _hurt > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
	else:
		velocity = velocity.move_toward(mv * spd, 3000.0 * delta)
	move_and_slide()
	if velocity.length() > 40:
		_step -= delta * velocity.length() / speed
		if _step <= 0.0:
			_step = 0.42
			Aether.sfx("step", 0.25, randf_range(0.9, 1.1))
	if can_attack and Input.is_action_just_pressed("attack") and _atk <= 0.0 and not _near_npc():
		_attack()

func _near_npc() -> bool:
	for n in get_tree().get_nodes_in_group("aether_npc"):
		if n.global_position.distance_to(global_position) < 110:
			return true
	return false

func _attack() -> void:
	_atk = 0.32
	Aether.sfx("swing", 0.6)
	var center := global_position + facing * 56
	FX.slash(get_parent(), global_position + facing * 20, 1.0 if facing.x >= 0 else -1.0, Color(1.8, 1.7, 1.4), 70.0)
	var shape := CircleShape2D.new()
	shape.radius = 52
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0, center)
	q.collision_mask = 4
	q.collide_with_bodies = true
	q.collide_with_areas = true
	for h in get_world_2d().direct_space_state.intersect_shape(q, 16):
		var c = h.collider
		if c and c.has_method("take_hit"):
			c.take_hit(attack_damage, self, false)

## Daño recibido (lo usan enemigos, trampas y la lógica sin código).
func take_damage(amount: float, from_x := 0.0, unblockable := false) -> void:
	if _inv > 0.0 or _dead:
		return
	hp = max(0.0, hp - amount)
	_inv = 0.7
	_hurt = 0.2
	velocity = (global_position - Vector2(from_x, global_position.y)).normalized() * 300.0 if from_x != 0.0 else -facing * 300.0
	hp_changed.emit(hp, max_hp)
	Aether.sfx("hurt", 0.7)
	Aether.shake(8)
	Aether.flash(Color(1, 0.1, 0.1), 0.25)
	if hp <= 0.0:
		_die()

func heal(v: float) -> void:
	hp = min(max_hp, hp + v)
	hp_changed.emit(hp, max_hp)

func _die() -> void:
	_dead = true
	died.emit()
	Aether.player_died.emit()
	FX.burst(get_parent(), global_position, Color(2, 0.6, 0.6), 30, 400, 0.6, 10, 0)
	if auto_respawn:
		await get_tree().create_timer(1.4).timeout
		respawn()

func respawn() -> void:
	global_position = start_pos
	hp = max_hp
	_dead = false
	_inv = 1.5
	hp_changed.emit(hp, max_hp)

func _draw() -> void:
	if _dead:
		return
	if _inv > 0.0 and int(_inv * 14) % 2 == 0 and not Engine.is_editor_hint():
		return
	draw_circle(Vector2(0, 18), 22, Color(0, 0, 0, 0.3))
	if texture:
		var s := texture.get_size() * art_scale
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1 if facing.x < 0 else 1, 1))
		draw_texture_rect(texture, Rect2(-s.x * 0.5, -s.y + 20, s.x, s.y), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var bob := sin(Time.get_ticks_msec() / 80.0) * 3.0 if velocity.length() > 40 else 0.0
		draw_circle(Vector2(0, -6 + bob), 22, color)
		draw_circle(Vector2(0, -6 + bob) + facing * 12, 6, Color(1, 1, 1))
		draw_circle(Vector2(0, -6 + bob) + facing * 14, 3, Color(0.05, 0.05, 0.1))
	if _atk > 0.15:
		draw_arc(facing * 30, 40, facing.angle() - 1.0, facing.angle() + 1.0, 12, Color(2, 1.8, 1.2, 0.8), 6)
