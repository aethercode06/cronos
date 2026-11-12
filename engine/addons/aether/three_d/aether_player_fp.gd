@icon("res://addons/aether/icons/player.svg")
class_name AetherPlayerFP
extends CharacterBody3D
## Jugador en primera persona (terror, exploración). Mirar con el ratón o
## arrastrando en la mitad derecha de la pantalla (AetherTouchFP); moverse con
## WASD / flechas / joystick. Correr: Shift o empujar el joystick al máximo.
## Señal `step(noise)` en cada paso: el ruido sirve para que los enemigos oigan.

signal step(noise: float)

@export var walk_speed := 3.1
@export var run_speed := 5.4
@export var stamina_max := 6.0
@export var eye_height := 1.62
@export var mouse_sens := 0.0022
@export var touch_sens := 0.0042
@export var gravity := 22.0

var head: Node3D
var camera: Camera3D
var frozen := false
var running := false
var stamina := 6.0
var move_override := Vector2.ZERO   # lo escribe AetherTouchFP
var run_override := false
var speed_mult := 1.0
var moving := 0.0                   # 0..1 cuánto se mueve (para el balanceo)
var _yaw := 0.0
var _pitch := 0.0
var _bob := 0.0
var _step_acc := 0.0
var _shake := 0.0
var _exhaust := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.75
	cs.shape = cap
	cs.position.y = 0.875
	add_child(cs)
	head = Node3D.new()
	head.position.y = eye_height
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 72.0
	camera.near = 0.05
	camera.far = 80.0
	head.add_child(camera)
	camera.current = true
	_yaw = rotation.y
	stamina = stamina_max
	Aether.player = self

func set_look(yaw: float, pitch: float) -> void:
	_yaw = yaw
	_pitch = pitch
	rotation.y = _yaw
	head.rotation.x = _pitch

func shake(amount: float, _zoom := 0.0) -> void:
	_shake = maxf(_shake, amount * 0.02)

func forward() -> Vector3:
	return -global_transform.basis.z

func look_dir() -> Vector3:
	return -camera.global_transform.basis.z

func _unhandled_input(e: InputEvent) -> void:
	if frozen:
		return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_turn(e.relative * mouse_sens)

func _turn(d: Vector2) -> void:
	_yaw -= d.x
	_pitch = clampf(_pitch - d.y, -1.35, 1.35)
	rotation.y = _yaw
	head.rotation.x = _pitch

func _physics_process(delta: float) -> void:
	if Aether.look_delta != Vector2.ZERO:
		if not frozen:
			_turn(Aether.look_delta * touch_sens)
		Aether.look_delta = Vector2.ZERO
	var inp := move_override
	if inp == Vector2.ZERO:
		inp = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	if frozen:
		inp = Vector2.ZERO
	var want_run := (run_override or Input.is_action_pressed("dash")) and inp.length() > 0.3
	if stamina <= 0.05:
		_exhaust = true
	if _exhaust and stamina > stamina_max * 0.35:
		_exhaust = false
	running = want_run and not _exhaust
	if running:
		stamina = maxf(0.0, stamina - delta)
	else:
		stamina = minf(stamina_max, stamina + delta * (0.6 if inp.length() > 0.1 else 1.1))
	var spd := (run_speed if running else walk_speed) * speed_mult
	if inp.length() > 1.0:
		inp = inp.normalized()
	var dir := (global_transform.basis * Vector3(inp.x, 0, inp.y))
	dir.y = 0.0
	var target := dir * spd
	velocity.x = lerpf(velocity.x, target.x, minf(1.0, delta * 12.0))
	velocity.z = lerpf(velocity.z, target.z, minf(1.0, delta * 12.0))
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	var hv := Vector2(velocity.x, velocity.z).length()
	moving = clampf(hv / walk_speed, 0.0, 1.6)
	# Balanceo de cabeza y pasos.
	if hv > 0.4:
		var f := 1.9 if running else 1.35
		_bob += delta * TAU * f
		_step_acc += delta * f * 2.0
		if _step_acc >= 1.0:
			_step_acc -= 1.0
			step.emit(12.0 if running else 3.5)
	else:
		_bob = lerpf(_bob, round(_bob / PI) * PI, delta * 4.0)
	var amp := 0.055 if running else 0.03
	var sh := Vector3.ZERO
	if _shake > 0.0:
		sh = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake
		_shake = maxf(0.0, _shake - delta * 0.12)
	camera.position = Vector3(cos(_bob * 0.5) * amp * 0.6, absf(sin(_bob)) * amp - amp * 0.5, 0) + sh
	camera.rotation.z = sin(_bob * 0.5) * (0.012 if running else 0.006)
