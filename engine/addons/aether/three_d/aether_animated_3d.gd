@icon("res://addons/aether/icons/anim.svg")
class_name AetherAnimated3D
extends Node3D
## Personaje 3D animado listo: pon tu modelo (.glb/.gltf con animaciones) y
## elige la animación por su nombre normal (reposo, andar, correr, saltar,
## golpe, morir…). Reconoce solo los nombres en inglés o español de cualquier
## modelo (Mixamo, Quaternius, three.js…) y mezcla suave entre animaciones.
## Extras automáticos: respiración y mirar hacia un objetivo.

signal finished(anim: String)

## Modelo 3D con animaciones.
@export var model: PackedScene:
	set(v):
		model = v
		if is_inside_tree():
			_build()
## Animación con la que empieza.
@export var start_anim := "reposo"
## Segundos de mezcla entre animaciones.
@export var blend := 0.25
## Velocidad de las animaciones.
@export var speed := 1.0
@export var model_scale := 1.0

## Nombres normales → palabras que se buscan en el nombre de la animación.
const ALIASES := {
	"reposo": ["idle", "reposo", "breath", "stand"],
	"andar": ["walking", "walk", "andar", "caminar"],
	"correr": ["running", "run", "correr", "sprint"],
	"saltar": ["jump", "saltar", "salto"],
	"golpe": ["punch", "attack", "slash", "hit", "golpe", "ataque"],
	"morir": ["death", "die", "dying", "morir", "muerte"],
	"herido": ["hurt", "damage", "herido", "no"],
	"bailar": ["dance", "bailar"],
	"saludar": ["wave", "saludar", "hello"],
	"sentarse": ["sitting", "sit", "sentar"],
	"levantarse": ["standing", "getup", "levantar"],
	"gritar": ["scream", "roar", "gritar"],
}

var anim: AnimationPlayer
var current := ""
var _model_node: Node3D
var _t := 0.0

func _ready() -> void:
	_build()

func _build() -> void:
	if _model_node:
		_model_node.queue_free()
		_model_node = null
	anim = null
	if model == null:
		return
	_model_node = model.instantiate()
	_model_node.scale = Vector3.ONE * model_scale
	add_child(_model_node)
	anim = _model_node.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim:
		anim.animation_finished.connect(func(n: StringName) -> void: finished.emit(String(n)))
		play(start_anim)

## Busca en un AnimationPlayer la animación que corresponde a un nombre normal.
static func find_anim(ap: AnimationPlayer, wanted: String) -> String:
	if ap == null:
		return ""
	if ap.has_animation(wanted):
		return wanted
	var keys: Array = ALIASES.get(wanted.to_lower(), [wanted.to_lower()])
	var list := ap.get_animation_list()
	for k in keys:
		for a in list:
			var low := String(a).to_lower().get_file()
			if low == k or low.ends_with("|" + k):
				return a
	for k in keys:
		for a in list:
			if String(a).to_lower().contains(k):
				return a
	return ""

## Reproduce una animación por su nombre normal (o el nombre exacto del modelo).
func play(wanted: String, loop := true) -> bool:
	var a := find_anim(anim, wanted)
	if a == "":
		return false
	var res := anim.get_animation(a)
	if res and not wanted in ["morir", "saltar", "golpe", "herido", "sentarse", "levantarse", "saludar", "gritar"]:
		res.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	elif res:
		res.loop_mode = Animation.LOOP_NONE
	anim.play(a, blend, speed)
	current = wanted
	return true

## Lista de animaciones que reconoce en el modelo.
func available() -> PackedStringArray:
	var out := PackedStringArray()
	for k in ALIASES:
		if find_anim(anim, k) != "":
			out.append(k)
	return out

func _process(delta: float) -> void:
	_t += delta
	if _model_node and current in ["reposo", ""]:
		# respiración suave encima de la animación
		_model_node.scale = Vector3.ONE * model_scale * Vector3(1.0, 1.0 + sin(_t * 2.2) * 0.008, 1.0)
