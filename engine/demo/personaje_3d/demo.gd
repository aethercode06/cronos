extends Node3D
## Demostración: personaje 3D animado con Aether Engine.
## Reposo → saludar → andar → correr → saltar → golpe → bailar → herido → morir,
## con cámara de cine que lo rodea.

@onready var pj: AetherAnimated3D = $Personaje
@onready var cam: Camera3D = $Camara
@onready var label: Label = $Texto/Nombre

const SEQ := [
	["reposo", 2.0, "REPOSO"], ["saludar", 2.2, "SALUDAR"], ["andar", 3.5, "ANDAR"], ["correr", 3.0, "CORRER"],
	["saltar", 1.4, "SALTAR"], ["correr", 1.2, "CORRER"], ["golpe", 1.6, "GOLPE"], ["bailar", 3.5, "BAILAR"],
	["herido", 1.6, "HERIDO"], ["morir", 2.6, "MORIR"],
]

var _i := -1
var _left := 0.0
var _t := 0.0
var _ang := 0.0

func _ready() -> void:
	print("AETHER: animaciones reconocidas = ", pj.available())
	_next()

func _next() -> void:
	_i += 1
	if _i >= SEQ.size():
		_i = SEQ.size() - 1
		_left = 99.0
		return
	pj.play(SEQ[_i][0])
	_left = SEQ[_i][1]
	label.text = SEQ[_i][2]
	label.modulate.a = 0.0
	label.create_tween().tween_property(label, "modulate:a", 1.0, 0.25)

func _process(delta: float) -> void:
	_t += delta
	_left -= delta
	if _left <= 0.0:
		_next()
	var cur: String = pj.current
	var sp := 0.0
	if cur == "andar":
		sp = 1.6
	elif cur == "correr" or cur == "saltar":
		sp = 4.5
	if sp > 0.0:
		_ang += sp / 4.0 * delta
		pj.position = Vector3(cos(_ang), 0, sin(_ang)) * 4.0
		pj.rotation.y = -_ang + PI
	# cámara de cine: gira despacio alrededor y se acerca en los momentos fuertes
	var close := 1.0
	if cur in ["golpe", "morir", "herido", "saludar"]:
		close = 0.65
	var orbit := _t * 0.18
	var target := pj.global_position + Vector3(0, 1.4, 0)
	var want := target + Vector3(sin(orbit) * 7.5, 2.6, cos(orbit) * 7.5) * close
	cam.global_position = cam.global_position.lerp(want, 1.0 - exp(-delta * 2.5))
	cam.look_at(target)
