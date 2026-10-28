@icon("res://addons/aether/icons/camera.svg")
class_name AetherCamera3D
extends Node3D
## Cámara en tercera persona: orbita alrededor del objetivo, no atraviesa paredes
## (brazo con colisión), gira con el dedo (lado derecho de la pantalla) o con el
## ratón (botón derecho), y tiembla con los golpes (Aether.shake).

## A quién sigue.
@export var target: Node3D
## Distancia al objetivo.
@export var distance := 6.5
## Altura del punto al que mira.
@export var height := 1.6
## Ángulo vertical inicial (grados, negativo = desde arriba).
@export var pitch := -18.0
## Sensibilidad del giro.
@export var sensitivity := 0.25
## Suavidad del seguimiento.
@export var follow_speed := 10.0
## Se coloca sola detrás del objetivo (coches, naves).
@export var auto_behind := false

var yaw := 0.0
var arm: SpringArm3D
var cam: Camera3D
var _trauma := 0.0
var _noise := FastNoiseLite.new()
var _t := 0.0

func _ready() -> void:
	arm = SpringArm3D.new()
	arm.spring_length = distance
	arm.margin = 0.3
	add_child(arm)
	cam = Camera3D.new()
	cam.fov = 62
	arm.add_child(cam)
	cam.make_current()
	Aether.camera = self
	if target:
		global_position = target.global_position + Vector3(0, height, 0)
		yaw = target.rotation.y

func shake(amount: float, _zoom := 0.0) -> void:
	_trauma = min(1.0, _trauma + amount / 30.0)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		Aether.look_delta += e.relative

func _process(delta: float) -> void:
	_t += delta
	yaw -= Aether.look_delta.x * sensitivity * 0.01
	pitch = clamp(pitch - Aether.look_delta.y * sensitivity, -70.0, 25.0)
	Aether.look_delta = Vector2.ZERO
	if target:
		var want := target.global_position + Vector3(0, height, 0)
		global_position = global_position.lerp(want, 1.0 - exp(-delta * follow_speed))
		if auto_behind and Aether.look_delta == Vector2.ZERO:
			var behind: float = target.global_rotation.y + (PI if target is VehicleBody3D else 0.0)
			yaw = lerp_angle(yaw, behind, 1.0 - exp(-delta * 3.0))
	rotation = Vector3(0, yaw, 0)
	arm.rotation = Vector3(deg_to_rad(pitch), 0, 0)
	_trauma = max(0.0, _trauma - delta * 1.5)
	var s := _trauma * _trauma
	cam.h_offset = _noise.get_noise_2d(_t * 50.0, 0) * 0.5 * s
	cam.v_offset = _noise.get_noise_2d(0, _t * 50.0) * 0.5 * s

## Dirección de avance en el suelo según hacia dónde mira la cámara.
func forward() -> Vector3:
	return -global_transform.basis.z.slide(Vector3.UP).normalized()

func right() -> Vector3:
	return global_transform.basis.x.slide(Vector3.UP).normalized()
