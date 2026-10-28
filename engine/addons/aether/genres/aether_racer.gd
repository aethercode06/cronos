@icon("res://addons/aether/icons/aether.svg")
class_name AetherRacer
extends AetherKit
## CARRERAS vista cenital completas: acelera (▲ o ATAQUE), gira (◀ ▶), frena (▼)
## y derrapa con SALTO. En el teléfono acelera solo: toca la mitad izquierda o
## derecha para girar. Rivales con IA, vueltas, puesto y récord.

@export_group("Circuito")
## Puntos del circuito (cerrado). Muévelos para cambiar la pista.
@export var track := PackedVector2Array([Vector2(0, 0), Vector2(1500, 0), Vector2(2100, 400), Vector2(2100, 1200), Vector2(1500, 1650), Vector2(700, 1500), Vector2(350, 1000), Vector2(-350, 1350), Vector2(-950, 950), Vector2(-750, 250)])
@export var road_width := 240.0
@export var grass_color := Color(0.18, 0.42, 0.2)
@export var road_color := Color(0.25, 0.25, 0.28)
@export_group("Carrera")
@export var laps := 3
@export_range(0, 5) var rivals := 3
## Habilidad de los rivales (0,5 lentos · 1 rápidos).
@export_range(0.5, 1.1) var rival_skill := 0.86
## Imagen del coche (mirando a la derecha, opcional).
@export var car_texture: Texture2D
@export var max_speed := 900.0
@export var accel := 900.0
@export var turn_speed := 2.8

const CAR_COLS := [Color(0.2, 0.7, 1.0), Color(1, 0.3, 0.3), Color(1, 0.85, 0.2), Color(0.5, 1, 0.4), Color(0.9, 0.5, 1), Color(1, 0.6, 0.2)]

var cars: Array = []
var cam: Camera2D
var _seg_len: Array = []
var _total := 0.0
var _time := 0.0
var _count := 3.0
var _skid: Array = []
var _shown := -1

func _ready() -> void:
	_kit_setup("carreras")
	_measure()
	var dir := (track[1] - track[0]).normalized()
	var side := dir.orthogonal()
	for i in rivals + 1:
		var row := i / 2
		var lane: float = -1.0 if i % 2 == 0 else 1.0
		var p := track[0] - dir * (120 + row * 130) + side * lane * road_width * 0.22
		cars.append({"p": p, "v": Vector2.ZERO, "a": dir.angle(), "prog": -(120.0 + row * 130.0), "last": _total - (120.0 + row * 130.0), "ai": i > 0, "col": CAR_COLS[i % CAR_COLS.size()], "done": -1.0, "lane": randf_range(-0.25, 0.25)})
	cam = Camera2D.new()
	cam.zoom = Vector2(0.7, 0.7)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	add_child(cam)
	cam.position = cars[0]["p"]
	cam.make_current()
	Aether.music("w0")

func _measure() -> void:
	_seg_len = [0.0]
	_total = 0.0
	for i in track.size():
		_total += track[i].distance_to(track[(i + 1) % track.size()])
		_seg_len.append(_total)

## Posición a lo largo del circuito y distancia al centro de la pista.
func _locate(p: Vector2) -> Vector2:
	var best_d := INF
	var best_s := 0.0
	for i in track.size():
		var a := track[i]
		var b := track[(i + 1) % track.size()]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var dd := q.distance_to(p)
		if dd < best_d:
			best_d = dd
			best_s = float(_seg_len[i]) + a.distance_to(q)
	return Vector2(best_s, best_d)

func _point_at(s: float) -> Vector2:
	s = fposmod(s, _total)
	for i in track.size():
		if s <= _seg_len[i + 1]:
			var k: float = (s - _seg_len[i]) / max(0.001, float(_seg_len[i + 1]) - float(_seg_len[i]))
			return track[i].lerp(track[(i + 1) % track.size()], k)
	return track[0]

func _place(c: Dictionary) -> int:
	var n := 1
	for o in cars:
		if not is_same(o, c) and (o["prog"] > c["prog"] or (o["done"] >= 0.0 and (c["done"] < 0.0 or o["done"] < c["done"]))):
			n += 1
	return n

func _steer_touch() -> float:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return 0.0
	var x := get_viewport().get_mouse_position().x
	return -1.0 if x < view().x * 0.5 else 1.0

func _process(d: float) -> void:
	queue_redraw()
	if over:
		return
	if _count > 0.0:
		_count -= d
		var n := ceili(_count)
		if n != _shown:
			_shown = n
			big(str(ceili(_count)) if _count > 0.0 else Aether.t("¡YA!"), 0.4)
			Aether.sfx("check" if _count > 0.0 else "win", 0.6)
		_hud()
		return
	_time += d
	var touch := DisplayServer.is_touchscreen_available()
	for c in cars:
		var fwd := Vector2.RIGHT.rotated(c["a"])
		var gas := 0.0
		var steer := 0.0
		var drift := false
		var top := max_speed
		if c["ai"]:
			var loc := _locate(c["p"])
			var target: Vector2 = _point_at(loc.x + 320.0) + _point_at(loc.x + 320.0).direction_to(_point_at(loc.x + 380.0)).orthogonal() * c["lane"] * road_width
			var want: float = (target - c["p"]).angle()
			steer = clamp(wrapf(want - c["a"], -PI, PI) * 2.5, -1.0, 1.0)
			gas = 1.0
			top = max_speed * rival_skill * (1.0 - 0.3 * abs(steer))
		elif c["done"] < 0.0:
			gas = Input.get_action_strength("up") + Input.get_action_strength("attack")
			if touch:
				gas = 1.0
			gas -= Input.get_action_strength("down") * 1.5
			steer = Input.get_axis("left", "right") + _steer_touch()
			drift = Input.is_action_pressed("jump")
		else:
			gas = -0.3
		var loc2 := _locate(c["p"])
		var off_road: bool = loc2.y > road_width * 0.5
		if off_road:
			top *= 0.45
		var spd: float = c["v"].dot(fwd)
		var v: Vector2 = c["v"]
		v += fwd * gas * accel * d
		var lat := fwd.orthogonal()
		var lat_v := v.dot(lat)
		var grip: float = 0.9 if drift else 8.0
		v -= lat * lat_v * min(1.0, grip * d)
		if v.length() > top:
			v = v.move_toward(v.normalized() * top, 1400.0 * d)
		v = v.move_toward(Vector2.ZERO, (380.0 if off_road else 120.0) * d)
		c["a"] += clamp(steer, -1.0, 1.0) * turn_speed * clamp(spd / 260.0, -1.0, 1.0) * d * (1.25 if drift else 1.0)
		c["v"] = v
		c["p"] += v * d
		if drift and abs(lat_v) > 120 and not c["ai"]:
			_skid.append([c["p"] - fwd * 30, 1.0])
		var s: float = loc2.x
		var ds := wrapf(s - float(c["last"]), -_total * 0.5, _total * 0.5)
		c["last"] = s
		c["prog"] += ds
		if c["done"] < 0.0 and c["prog"] >= laps * _total:
			c["done"] = _time
			if not c["ai"]:
				_finish(c)
	for i in cars.size():
		for j in range(i + 1, cars.size()):
			var a: Dictionary = cars[i]
			var b: Dictionary = cars[j]
			var dv: Vector2 = b["p"] - a["p"]
			if dv.length() < 56 and dv.length() > 0.01:
				var push := dv.normalized() * (56 - dv.length()) * 0.5
				a["p"] -= push
				b["p"] += push
				var vv: Vector2 = (a["v"] - b["v"]) * 0.3
				a["v"] -= vv
				b["v"] += vv
				if i == 0:
					Aether.sfx("clang", 0.3)
	for k in _skid.duplicate():
		k[1] -= d * 0.5
		if k[1] <= 0:
			_skid.erase(k)
	cam.position = cars[0]["p"] + cars[0]["v"] * 0.35
	_hud()

func _finish(c: Dictionary) -> void:
	var pos := _place(c)
	score = int(max(0.0, 400.0 - _time) * 100.0) + (rivals + 1 - pos) * 5000
	end_game(pos == 1, "%dº %s" % [pos, Aether.t("PUESTO")])

func _hud() -> void:
	var c: Dictionary = cars[0]
	var lap: int = clamp(int(floor(c["prog"] / _total)) + 1, 1, laps)
	set_top("%s %d/%d   ·   %dº/%d" % [Aether.t("Vuelta"), lap, laps, _place(c), cars.size()])
	set_top_right("%.1f s   ·   %d km/h" % [_time, int(c["v"].length() * 0.25)])

func _draw() -> void:
	draw_rect(Rect2(-5000, -5000, 12000, 12000), grass_color)
	var loop := PackedVector2Array(track)
	loop.append(track[0])
	loop.append(track[1])
	draw_polyline(loop, Color(0.9, 0.9, 0.9), road_width + 26, true)
	draw_polyline(loop, Color(0.85, 0.2, 0.2), road_width + 14, true)
	draw_polyline(loop, road_color, road_width, true)
	for i in track.size():
		draw_circle(track[i], road_width * 0.5, road_color)
	var a := track[0]
	var n := (track[1] - track[0]).normalized().orthogonal()
	for k in 8:
		var p := a + n * (-road_width * 0.5 + k * road_width / 8.0)
		draw_rect(Rect2(p - Vector2(10, 0), Vector2(20, road_width / 8.0)), Color(1, 1, 1) if k % 2 == 0 else Color(0.1, 0.1, 0.1))
	for k in _skid:
		draw_circle(k[0], 7, Color(0.05, 0.05, 0.05, 0.35 * k[1]))
	for c in cars:
		draw_set_transform(c["p"], c["a"], Vector2.ONE)
		draw_rect(Rect2(-30, -14, 66, 34), Color(0, 0, 0, 0.3))
		if car_texture and not c["ai"]:
			draw_texture_rect(car_texture, Rect2(-36, -20, 72, 40), false)
		else:
			draw_rect(Rect2(-34, -18, 68, 36), c["col"])
			draw_rect(Rect2(-6, -14, 22, 28), Color(0.1, 0.15, 0.25))
			for w in [Vector2(-22, -20), Vector2(14, -20), Vector2(-22, 16), Vector2(14, 16)]:
				draw_rect(Rect2(w, Vector2(14, 5)), Color(0.05, 0.05, 0.05))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func selftest() -> bool:
	_count = 0.0
	Input.action_press("up")
	for i in 200:
		_process(0.05)
	Input.action_release("up")
	return cars[0]["prog"] > 300.0
