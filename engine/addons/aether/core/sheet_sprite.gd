@icon("res://addons/aether/icons/anim.svg")
class_name SheetSprite
extends Sprite2D
## Reproduce animaciones en tira. Acepta dos fuentes:
## 1) un AetherAnimSet hecho en el Inspector (lo normal en juegos nuevos);
## 2) las hojas de Chronos descritas en assets/chronos/meta.json.
## El punto de apoyo (los pies) queda en el origen del nodo.

signal finished(anim: String)

## Animaciones del personaje (opcional; si está vacío se usan las de Chronos).
@export var anim_set: AetherAnimSet
## Nombres alternativos: «idle» → «KH_idle», etc.
@export var aliases: Dictionary = {}
## Escala de las hojas de Chronos respecto al mundo.
@export var unit_scale := 0.5

var anim := ""
var frame_f := 0.0
var fps := 12.0
var loop := true
var _done := false

func _init() -> void:
	centered = false

func has_anim(key: String) -> bool:
	if anim_set and anim_set.anims.has(key):
		return true
	var k: String = aliases.get(key, key)
	return Aether.meta.has(k)

func play(key: String, p_fps := 12.0, p_loop := true, restart := false) -> void:
	if key == anim and not restart:
		if not (anim_set and anim_set.anims.has(key)):
			fps = p_fps
			loop = p_loop
		return
	# 1) animación del Inspector
	if anim_set and anim_set.anims.has(key):
		var a: AetherAnim = anim_set.anims[key]
		if a == null or a.texture == null:
			return
		anim = key
		texture = a.texture
		hframes = max(1, a.frames)
		frame = 0
		frame_f = 0.0
		fps = a.fps
		loop = a.loop
		_done = false
		var fw: float = float(a.texture.get_width()) / hframes
		var fh: float = float(a.texture.get_height())
		var anc := a.anchor if a.anchor != Vector2.ZERO else Vector2(fw * 0.5, fh)
		offset = -anc
		scale = Vector2.ONE * anim_set.scale
		return
	# 2) hoja de Chronos
	var k: String = aliases.get(key, key)
	var m: Dictionary = Aether.sheet(k)
	var t := Aether.tex(k)
	if t == null:
		return
	anim = key
	texture = t
	var n: int = int(m.get("n", 1))
	hframes = max(1, n)
	frame = 0
	frame_f = 0.0
	fps = p_fps
	loop = p_loop
	_done = false
	var fw2: float = float(m.get("fw", t.get_width() / hframes))
	var fh2: float = float(m.get("fh", t.get_height()))
	var ax: float = float(m.get("ax", fw2 * 0.5))
	var ay: float = float(m.get("ay", fh2))
	offset = Vector2(-ax, -ay)
	scale = Vector2.ONE * unit_scale

func frame_count() -> int:
	return hframes

func is_done() -> bool:
	return _done

func _process(delta: float) -> void:
	if hframes <= 1 or texture == null:
		return
	frame_f += delta * fps
	var n := hframes
	if loop:
		frame = int(frame_f) % n
	else:
		if frame_f >= n:
			frame = n - 1
			if not _done:
				_done = true
				finished.emit(anim)
		else:
			frame = int(frame_f)
