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
## Agacharse: más lento, pasos casi sin ruido y la vista baja (la cabeza pasa por debajo de las cosas).
@export var crouch_speed := 1.45
@export var crouch_eye := 0.95
var crouching := false
## El juego fija la altura de la vista (escondida, debajo de la cama…): no la toca el agacharse.
var altura_fija := false
var _shape: CollisionShape3D
var _roll := 0.0
var _yaw_prev := 0.0
var _t_resp := 0.0
var base_fov := 72.0
## Multiplicador de sensibilidad elegido por el jugador (opciones).
var sens_mult := 1.0
## Adrenalina (segundos): al verte el enemigo corres más y sin cansarte un momento.
var adrenalina := 0.0
var _look_suave := Vector2.ZERO

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
	_shape = cs
	head = Node3D.new()
	head.position.y = eye_height
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 72.0
	camera.near = 0.05
	camera.far = 60.0 if OS.get_name() == "Android" else 80.0
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

## Altura máxima de un escalón que se sube andando (umbrales, tablones, bordillos, el borde de un puente).
@export var step_height := 0.36

## Si al andar te para un borde bajo (más bajo que step_height), sube encima en vez de quedarte atascado.
func _subir_escalon(antes: Vector3, quiere: Vector3, delta: float) -> void:
	var hq := Vector3(quiere.x, 0, quiere.z)
	if hq.length() < 0.5 or not is_on_floor():
		return
	var avance := Vector3(global_position.x - antes.x, 0, global_position.z - antes.z).length()
	if avance > hq.length() * delta * 0.5:
		return  # avanza bien: no hay escalón
	var paso := hq.normalized() * maxf(0.12, hq.length() * delta)
	var t := global_transform
	# ¿hay sitio arriba y hacia delante?
	if test_move(t, Vector3(0, step_height, 0)):
		return
	var arriba := t.translated(Vector3(0, step_height, 0))
	if test_move(arriba, paso):
		return
	# baja hasta tocar el escalón
	var adelante := arriba.translated(paso)
	var col := KinematicCollision3D.new()
	if test_move(adelante, Vector3(0, -step_height - 0.05, 0), col):
		var subida: float = step_height + 0.05 - col.get_travel().length()
		if subida > 0.02 and col.get_normal().y > 0.7:
			global_position = adelante.origin + col.get_travel()

func _physics_process(delta: float) -> void:
	# mirar con el dedo: suavizado de un par de fotogramas y un poco de aceleración (giros rápidos llegan lejos,
	# los pequeños son precisos); sin esto la cámara va a saltos en pantallas de 120 Hz
	var ld := Aether.look_delta
	Aether.look_delta = Vector2.ZERO
	var acel := 1.0 + clampf(ld.length() / maxf(delta, 0.001) / 2600.0, 0.0, 0.8)
	_look_suave = _look_suave.lerp(ld * acel, minf(1.0, delta * 30.0)) if ld != Vector2.ZERO else _look_suave * maxf(0.0, 1.0 - delta * 25.0)
	if _look_suave.length() > 0.01 and not frozen:
		_turn(_look_suave * touch_sens * sens_mult)
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
	if crouching:
		running = false
	adrenalina = maxf(0.0, adrenalina - delta)
	if adrenalina > 0.0:
		stamina = maxf(stamina, stamina_max * 0.6)
	var spd := (crouch_speed if crouching else (run_speed if running else walk_speed)) * speed_mult * (1.18 if adrenalina > 0.0 else 1.0)
	if inp.length() > 1.0:
		inp = inp.normalized()
	var dir := (global_transform.basis * Vector3(inp.x, 0, inp.y))
	dir.y = 0.0
	var target := dir * spd
	velocity.x = lerpf(velocity.x, target.x, minf(1.0, delta * 12.0))
	velocity.z = lerpf(velocity.z, target.z, minf(1.0, delta * 12.0))
	if altura_fija:
		# escondida (armario, bajo la cama) o en el suelo tras el hachazo: el cuerpo no se mueve ni cae
		# (en el escondite la cápsula está desactivada; sin esto caería atravesando el suelo)
		velocity = Vector3.ZERO
	else:
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = -0.5
		var antes := global_position
		move_and_slide()
		_subir_escalon(antes, target, delta)
	var hv := Vector2(velocity.x, velocity.z).length()
	moving = clampf(hv / walk_speed, 0.0, 1.6)
	# Balanceo de cabeza y pasos.
	if hv > 0.4:
		var f := 1.9 if running else 1.35
		_bob += delta * TAU * f
		_step_acc += delta * f * 2.0
		if _step_acc >= 1.0:
			_step_acc -= 1.0
			step.emit(12.0 if running else (0.9 if crouching else 3.5))
	else:
		_bob = lerpf(_bob, round(_bob / PI) * PI, delta * 4.0)
	var amp := 0.055 if running else (0.018 if crouching else 0.03)
	# altura de los ojos y de la cápsula al agacharse (no mientras está escondido: lo controla el juego)
	if not frozen and not altura_fija:
		var ojo := crouch_eye if crouching else eye_height
		head.position.y = lerpf(head.position.y, ojo, minf(1.0, delta * 9.0))
		if _shape:
			var cap := _shape.shape as CapsuleShape3D
			var alto_obj := 1.15 if crouching else 1.75
			# solo tocar la forma mientras cambia (cambiarla en cada fotograma hace saltar al jugador)
			if absf(cap.height - alto_obj) > 0.002:
				cap.height = alto_obj if absf(cap.height - alto_obj) < 0.01 else lerpf(cap.height, alto_obj, minf(1.0, delta * 10.0))
				_shape.position.y = cap.height * 0.5
	# respiración en reposo (más fuerte y rápida si está agotada) e inclinación al girar y al ir de lado
	_t_resp += delta * (2.6 if _exhaust or stamina < stamina_max * 0.3 else 1.4)
	var resp := sin(_t_resp) * (0.014 if _exhaust else 0.005) * (1.0 - clampf(hv / walk_speed, 0.0, 1.0))
	var giro := wrapf(_yaw - _yaw_prev, -PI, PI) / maxf(delta, 0.001)
	_yaw_prev = _yaw
	_roll = lerpf(_roll, clampf(-giro * 0.012 - inp.x * 0.022, -0.06, 0.06), minf(1.0, delta * 6.0))
	if camera:
		camera.fov = lerpf(camera.fov, base_fov + (5.0 if running else 0.0) - (3.0 if crouching else 0.0), minf(1.0, delta * 4.0))
	var sh := Vector3.ZERO
	if _shake > 0.0:
		sh = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake
		_shake = maxf(0.0, _shake - delta * 0.12)
	camera.position = Vector3(cos(_bob * 0.5) * amp * 0.6, absf(sin(_bob)) * amp - amp * 0.5 + resp, 0) + sh
	camera.rotation.z = sin(_bob * 0.5) * (0.012 if running else 0.006) + _roll
