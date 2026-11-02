class_name CrVfx
extends Node2D
## Efectos de poderes renderizados en Blender (hojas fx_*.png con fondo negro).
## Se dibujan con mezcla aditiva: el negro desaparece y la luz suma brillo.
## Cada efecto tiene un número (id); así no se guardan referencias cruzadas en los diccionarios del juego.

var _list: Array = []
var _next_id := 1

func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	z_index = 8

## Lanza un efecto y devuelve su id (0 si no existe). `size` = ancho en unidades del mundo.
## `loops` = -1 para repetir hasta `stop(id)`. `follow` = diccionario con x/y que el efecto sigue.
func spawn(fx: String, x: float, y: float, size: float, flip := false, fps := 24.0, loops := 0, follow = null, off := Vector2.ZERO, rot := 0.0) -> int:
	var key := "fx_" + fx
	var m: Dictionary = Aether.sheet(key)
	if m.is_empty():
		return 0
	var id := _next_id
	_next_id += 1
	_list.append({"id": id, "k": key, "x": x, "y": y, "size": size, "flip": flip, "t": 0.0, "fps": fps, "n": int(m.get("n", 1)),
		"loops": loops, "follow": follow, "off": off, "rot": rot})
	return id

func stop(id: int) -> void:
	for i in range(_list.size() - 1, -1, -1):
		if _list[i].id == id:
			_list.remove_at(i)

## Quita los efectos que seguían a proyectiles que ya no existen.
func prune(projs: Array) -> void:
	for i in range(_list.size() - 1, -1, -1):
		var f = _list[i].follow
		if f is Dictionary and str(f.get("type", "")) == "lightwave":
			var alive := false
			for q in projs:
				if is_same(q, f):
					alive = true
					break
			if not alive:
				_list.remove_at(i)

func clear() -> void:
	_list.clear()

func _process(dt: float) -> void:
	for i in range(_list.size() - 1, -1, -1):
		var e: Dictionary = _list[i]
		e.t += dt
		var total: float = float(e.n) / e.fps
		if e.loops >= 0 and e.t >= total * (e.loops + 1):
			_list.remove_at(i)
			continue
		var f = e.follow
		if f is Dictionary and not f.is_empty():
			e.x = float(f.x) + float(f.get("w", 0.0)) / 2 + e.off.x
			e.y = float(f.y) + float(f.get("h", 0.0)) / 2 + e.off.y
			if str(f.get("type", "")) == "lightwave":
				e.flip = float(f.vx) < 0.0
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
		draw_texture_rect_region(t, Rect2(-w / 2, -h / 2, w, h), Rect2(fr * fw, 0, fw, fh))
	draw_set_transform(Vector2.ZERO)
