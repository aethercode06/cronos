@icon("res://addons/aether/icons/enemy.svg")
class_name AetherEnemy3D
extends CharacterBody3D
## Enemigo 3D: patrulla, te ve, avisa, embiste y te golpea. Con modelo propio o
## figura sencilla. Destello, retroceso y explosión al morir.

@export var model: PackedScene
@export var model_scale := 1.0
@export var color := Color(0.6, 0.2, 0.8)
@export var hp := 3.0
@export var speed := 3.5
@export var damage := 15.0
@export var sight := 12.0

var _mat: StandardMaterial3D
var _flash := 0.0
var _hit_t := 0.0
var _state := "patrol"
var _st := 0.0
var _home := Vector3.ZERO
var _visual: Node3D
var dead := false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	_home = global_position
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = 1.4
	cs.shape = cap
	cs.position.y = 0.7
	add_child(cs)
	_visual = Node3D.new()
	add_child(_visual)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = color
	_mat.emission_enabled = true
	_mat.emission = Color(0, 0, 0)
	if model:
		var m := model.instantiate()
		m.scale = Vector3.ONE * model_scale
		_visual.add_child(m)
	else:
		var mi := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.6
		sph.height = 1.1
		mi.mesh = sph
		mi.material_override = _mat
		mi.position.y = 0.6
		_visual.add_child(mi)
		for sx in [-0.22, 0.22]:
			var eye := MeshInstance3D.new()
			var es := SphereMesh.new()
			es.radius = 0.1
			es.height = 0.2
			eye.mesh = es
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(1, 0.9, 0.3)
			em.emission_enabled = true
			em.emission = Color(1, 0.8, 0.2)
			em.emission_energy_multiplier = 3.0
			eye.material_override = em
			eye.position = Vector3(sx, 0.8, -0.5)
			_visual.add_child(eye)
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if dead:
		return
	_st += delta
	_hit_t = max(0.0, _hit_t - delta)
	_flash = max(0.0, _flash - delta * 6.0)
	_mat.emission = Color(1, 1, 1) * _flash * 2.0
	var pl = Aether.player
	var to := Vector3.ZERO
	if pl:
		to = pl.global_position - global_position
		to.y = 0
	var dist := to.length()
	if not is_on_floor():
		velocity.y -= 26.0 * delta
	if _hit_t > 0:
		velocity.x = move_toward(velocity.x, 0, 20 * delta)
		velocity.z = move_toward(velocity.z, 0, 20 * delta)
	elif _state == "wind":
		velocity.x = 0
		velocity.z = 0
		_visual.scale = Vector3(1.15, 0.85, 1.15)
		if _st > 0.45:
			_state = "lunge"; _st = 0
			var d := to.normalized()
			velocity.x = d.x * speed * 4.0
			velocity.z = d.z * speed * 4.0
			Aether.sfx("dash", 0.4, 1.3)
	elif _state == "lunge":
		_visual.scale = Vector3(0.9, 1.1, 0.9)
		if _st > 0.35:
			_state = "chase"; _st = -0.8
	elif pl and not pl.dead and dist < sight:
		_state = "chase"
		_visual.scale = _visual.scale.lerp(Vector3.ONE, 0.2)
		var d2 := to.normalized()
		velocity.x = d2.x * speed
		velocity.z = d2.z * speed
		_visual.rotation.y = atan2(-d2.x, -d2.z)
		if dist < 3.0 and _st > 0:
			_state = "wind"; _st = 0
	else:
		var t := Time.get_ticks_msec() / 1000.0
		var p := _home + Vector3(sin(t * 0.6) * 3.0, 0, cos(t * 0.6) * 3.0) - global_position
		p.y = 0
		velocity.x = p.x
		velocity.z = p.z
	move_and_slide()
	if pl and not pl.dead and _hit_t <= 0 and dist < 1.1 and abs(pl.global_position.y - global_position.y) < 1.5:
		pl.take_damage(damage, global_position)

func take_hit(dmg: float, from: Node3D, heavy := false) -> void:
	if dead:
		return
	hp -= dmg
	_flash = 1.0
	_hit_t = 0.3
	_state = "chase"; _st = -0.5
	var push := global_position - from.global_position
	push.y = 0
	velocity = push.normalized() * (10.0 if heavy else 6.0) + Vector3(0, 3, 0)
	Aether.hitstop(0.07 if heavy else 0.045)
	Aether.shake(6 if heavy else 3)
	Aether.sfx("hit", 0.8)
	_burst(Color(2.5, 2.0, 1.0), 14)
	if hp <= 0:
		dead = true
		collision_layer = 0
		Aether.sfx("kill", 0.7, 1.2)
		_burst(Color(2.0, 1.4, 2.6), 40)
		var tw := create_tween()
		tw.tween_property(_visual, "scale", Vector3(1.6, 0.1, 1.6), 0.25)
		tw.tween_callback(queue_free)

func _burst(col: Color, n: int) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = n
	p.explosiveness = 1.0
	p.lifetime = 0.6
	p.direction = Vector3.UP
	p.spread = 180
	p.initial_velocity_min = 3
	p.initial_velocity_max = 8
	p.gravity = Vector3(0, -12, 0)
	p.scale_amount_min = 0.06
	p.scale_amount_max = 0.14
	var m := SphereMesh.new()
	m.radius = 1.0
	m.height = 2.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	m.material = mat
	p.mesh = m
	p.position = global_position + Vector3(0, 0.8, 0)
	get_parent().add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)
