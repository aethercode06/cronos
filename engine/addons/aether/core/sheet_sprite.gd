class_name SheetSprite
extends Sprite2D
## Reproduce hojas de animación en tira (formato de Chronos: fw, fh, n,
## ancla ax/ay). El ancla queda en el origen del nodo (los pies).

signal finished(anim: String)

var anim := ""
var frame_f := 0.0
var fps := 12.0
var loop := true
var unit_scale := 0.5           # escala de la hoja respecto al mundo
var _done := false

func _init() -> void:
	centered = false

func play(key: String, p_fps := 12.0, p_loop := true, restart := false) -> void:
	if key == anim and not restart:
		fps = p_fps
		loop = p_loop
		return
	var m: Dictionary = Aether.sheet(key)
	var t := Aether.tex(key)
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
	var fw: float = float(m.get("fw", t.get_width() / hframes))
	var fh: float = float(m.get("fh", t.get_height()))
	var ax: float = float(m.get("ax", fw * 0.5))
	var ay: float = float(m.get("ay", fh))
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
