class_name CrVfx
extends Node2D
## Efectos de poderes renderizados en Blender (hojas fx_*.png con fondo negro).
## Se dibujan con mezcla aditiva: el negro desaparece y la luz suma brillo.

var _list: Array = []

func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	z_index = 8

## Lanza un efecto. `size` = ancho en unidades del mundo. `fps` = velocidad.
## `follow` = diccionario con x/y (p. ej. el jugador) para que el efecto lo siga.
func spawn(fx: String, x: float, y: float, size: float, flip := false, fps := 24.0, loops := 0, follow = null, off := Vector2.ZERO, rot := 0.0) -> Dictionary:
	var key := "fx_" + fx
	var m: Dictionary = Aether.sheet(key)
	if m.is_empty():
		return {}
	var e := {"k": key, "x": x, "y": y, "size": size, "flip": flip, "t": 0.0, "fps": fps, "n": int(m.get("n", 1)),
		"loops": loops, "follow": follow, "off": off, "rot": rot, "alpha": 1.0}
	_list.append(e)
	return e

func stop(e: Dictionary) -> void:
	_list.erase(e)

func _process(dt: float) -> void:
	for e in _list.duplicate():
		e.t += dt
		var total: float = float(e.n) / e.fps
		if e.loops >= 0 and e.t >= total * (e.loops + 1):
			_list.erase(e)
		elif e.follow is Dictionary and not e.follow.is_empty():
			e.x = float(e.follow.x) + float(e.follow.get("w", 0.0)) / 2 + e.off.x
			e.y = float(e.follow.y) + float(e.follow.get("h", 0.0)) / 2 + e.off.y
	queue_redraw()

func _draw() -> void:
	for e in _list:
		var m: Dictionary = Aether.sheet(e.k)
		var t := Aether.tex(e.k)
		if not t:
			continue
		var fw: float = float(m.fw)
		var fh: float = float(m.fh)
		var fr: int = int(e.t * e.fps) % int(e.n)
		var w: float = e.size
		var h: float = e.size * fh / fw
		draw_set_transform(Vector2(e.x, e.y), e.rot, Vector2(-1.0 if e.flip else 1.0, 1.0))
		draw_texture_rect_region(t, Rect2(-w / 2, -h / 2, w, h), Rect2(fr * fw, 0, fw, fh), Color(1, 1, 1, e.alpha))
	draw_set_transform(Vector2.ZERO)
