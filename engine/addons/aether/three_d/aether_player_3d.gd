@icon("res://addons/aether/icons/player.svg")
class_name AetherPlayer3D
extends CharacterBody3D
## Jugador 3D en tercera persona: se mueve según la cámara, salta, doble salto,
## dash, ataque con combo, recibe daño y reaparece. Funciona con un modelo 3D
## propio (glTF/GLB) o, si no hay, con una figura sencilla.
## Si el modelo trae un AnimationPlayer con animaciones llamadas idle, run,
## jump, attack, hurt o death, se reproducen solas.

signal hp_changed(hp: float, max_hp: float)
signal died

@export_group("Aspecto")
## Modelo 3D (arrastra aquí un .glb o una escena). Vacío = figura sencilla.
@export var model: PackedScene
## Escala del modelo.
@export var model_scale := 1.0
## Color de la figura sencilla.
@export var color := Color(0.95, 0.55, 0.25)
@export_group("Movimiento")
@export var speed := 7.5
@export var accel := 40.0
@export var jump_speed := 9.0
@export var gravity := 26.0
@export var double_jump := true
@export var dash_speed := 22.0
@export_group("Combate")
@export var max_hp := 100.0
@export var attack_damage := 1.0
@export var attack_range := 1.9

var hp := 100.0
var face := 1.0
var dead := false
var checkpoint := Vector3.ZERO
var _jumps := 0
var _dash_t := 0.0
var _dash_cd := 0.0
var _atk_t := 0.0
var _atk_n := 0
var _combo := 0.0
var _inv := 0.0
var _visual: Node3D
var _anim: AnimationPlayer
var _squash := 0.0
var _was_floor := true
var _hit_done := false
var _blade: MeshInstance3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	if model:
		var m := model.instantiate()
		_visual.add_child(m)
		m.scale = Vector3.ONE * model_scale
		_anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	else:
		_build_figure()
	hp = max_hp
	checkpoint = global_position
	Aether.player = self
	add_to_group("player")

func _build_figure() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.38
	cap.height = 1.5
	body.mesh = cap
	body.material_override = mat
	body.position.y = 0.85
	_visual.add_child(body)
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.3
	sph.height = 0.6
	head.mesh = sph
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(1.0, 0.85, 0.7)
	head.material_override = hm
	head.position.y = 1.8
	_visual.add_child(head)
	_blade = MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = Vector3(0.08, 0.08, 1.1)
	_blade.mesh = bx
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.85, 0.95, 1.0)
	bm.emission_enabled = true
	bm.emission = Color(0.6, 0.9, 1.0)
	bm.emission_energy_multiplier = 2.0
	_blade.material_override = bm
	_blade.position = Vector3(0.45, 1.0, -0.4)
	_visual.add_child(_blade)

func hurt_box() -> AABB:
	return AABB(global_position + Vector3(-0.45, 0, -0.45), Vector3(0.9, 1.9, 0.9))

func _physics_process(delta: float) -> void:
	var cam = Aether.camera
	_inv = max(0.0, _inv - delta)
	_dash_cd = max(0.0, _dash_cd - delta)
	_combo = max(0.0, _combo - delta)
	_squash = max(0.0, _squash - delta * 4.0)
	if dead:
		velocity.y -= gravity * delta
		move_and_slide()
		return
	var on_floor := is_on_floor()
	if on_floor:
		_jumps = 0
		if not _was_floor:
			_squash = 1.0
			Aether.sfx("step", 0.5, 0.8)
	var input := Input.get_vector("left", "right", "up", "down")
	var dir := Vector3.ZERO
	if cam and cam.has_method("forward"):
		dir = (cam.right() * input.x - cam.forward() * input.y)
	else:
		dir = Vector3(input.x, 0, input.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	# dash
	if Input.is_action_just_pressed("dash") and _dash_cd <= 0:
		_dash_t = 0.18
		_dash_cd = 0.6
		var fwd := -_visual.global_transform.basis.z
		velocity = Vector3(fwd.x, 0, fwd.z).normalized() * dash_speed
		Aether.sfx("dash", 0.7)
	if _dash_t > 0:
		_dash_t -= delta
		velocity.y = 0
		move_and_slide()
		_was_floor = is_on_floor()
		return
	# ataque
	if Input.is_action_just_pressed("attack") and _atk_t <= 0:
		_atk_n = (_atk_n % 3) + 1 if _combo > 0 else 1
		_atk_t = 0.32 if _atk_n < 3 else 0.45
		_combo = _atk_t + 0.35
		_hit_done = false
		Aether.sfx("swing", 0.6, 1.0 + _atk_n * 0.08)
		_play("attack")
	if _atk_t > 0:
		_atk_t -= delta
		if not _hit_done and _atk_t < (0.22 if _atk_n < 3 else 0.3):
			_hit_done = true
			_do_hit()
	# movimiento
	var target_v := dir * speed * (0.25 if _atk_t > 0 else 1.0)
	velocity.x = move_toward(velocity.x, target_v.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_v.z, accel * delta)
	if dir.length() > 0.1:
		var yaw := atan2(-dir.x, -dir.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, yaw, 1.0 - exp(-delta * 14.0))
	# salto
	if Input.is_action_just_pressed("jump"):
		if on_floor:
			velocity.y = jump_speed
			Aether.sfx("jump", 0.5)
			_play("jump")
		elif double_jump and _jumps < 1:
			_jumps += 1
			velocity.y = jump_speed * 0.9
			Aether.sfx("dj", 0.5)
	if Input.is_action_just_released("jump") and velocity.y > 3.0:
		velocity.y *= 0.55
	velocity.y -= gravity * delta
	move_and_slide()
	_was_floor = is_on_floor()
	if global_position.y < -30:
		take_damage(9999, global_position, true)
	# animación
	var sq := 1.0 - 0.15 * _squash
	_visual.scale = Vector3(1.0 / sqrt(sq), sq, 1.0 / sqrt(sq))
	if _blade:
		_blade.rotation.y = lerp(_blade.rotation.y, (-1.6 if _atk_t > 0.15 else 0.0) * (1 if _atk_n != 2 else -1), 1.0 - exp(-delta * 25.0))
	_visual.visible = not (_inv > 0 and fmod(_inv, 0.12) < 0.06)
	if _atk_t <= 0:
		if not is_on_floor():
			_play("jump")
		elif Vector2(velocity.x, velocity.z).length() > 0.5:
			_play("run")
		else:
			_play("idle")

func _play(n: String) -> void:
	if _anim == null:
		return
	var std := {"idle": "reposo", "run": "correr", "walk": "andar", "jump": "saltar", "attack": "golpe", "death": "morir", "hurt": "herido"}
	var a := AetherAnimated3D.find_anim(_anim, n)
	if a == "" and std.has(n):
		a = AetherAnimated3D.find_anim(_anim, std[n])
	if a != "" and _anim.current_animation != a:
		_anim.play(a, 0.15)

func _do_hit() -> void:
	var fwd := -_visual.global_transform.basis.z
	var center := global_position + Vector3(0, 1.0, 0) + fwd * attack_range * 0.6
	var shape := SphereShape3D.new()
	shape.radius = attack_range * 0.7
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), center)
	q.collision_mask = 4
	for h in get_world_3d().direct_space_state.intersect_shape(q, 16):
		var c = h.collider
		if c and c.has_method("take_hit"):
			c.take_hit(attack_damage * (1.6 if _atk_n == 3 else 1.0), self, _atk_n == 3)

func take_damage(amount: float, from: Vector3, unblockable := false) -> void:
	if dead or (_inv > 0 and not unblockable):
		return
	hp = max(0.0, hp - amount)
	hp_changed.emit(hp, max_hp)
	_inv = 0.9
	var push := (global_position - from)
	push.y = 0
	velocity = push.normalized() * 8.0 + Vector3(0, 6, 0)
	Aether.sfx("hurt", 0.9)
	Aether.hitstop(0.08)
	Aether.shake(10)
	Aether.flash(Color(1, 0.2, 0.2), 0.25)
	_play("hurt")
	if hp <= 0:
		dead = true
		_play("death")
		died.emit()
		Aether.player_died.emit()
		await get_tree().create_timer(1.5, true, false, true).timeout
		respawn()

func respawn() -> void:
	dead = false
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	global_position = checkpoint
	velocity = Vector3.ZERO
	_inv = 1.2
