@icon("res://addons/aether/icons/aether.svg")
class_name AetherMatch3
extends AetherKit
## PUZLE de unir 3 completo: desliza una gema hacia su vecina para juntar
## 3 o más iguales. Cascadas con combo, meta de puntos y movimientos limitados.

@export_group("Tablero")
@export_range(5, 10) var columns := 8
@export_range(5, 10) var rows := 8
## Número de tipos de gema (3-6).
@export_range(3, 6) var kinds := 6
## Imágenes de las gemas (opcional; si faltan se dibujan formas).
@export var gem_textures: Array[Texture2D] = []
@export_group("Nivel")
@export var moves := 25
@export var target_score := 3000

const COLS := [Color(1, 0.3, 0.35), Color(0.3, 0.75, 1), Color(0.4, 1, 0.45), Color(1, 0.85, 0.3), Color(0.8, 0.45, 1), Color(1, 0.6, 0.25)]

var grid: Array = []
var off: Array = []
var pop: Array = []
var cell := 72.0
var origin := Vector2.ZERO
var _press := Vector2i(-1, -1)
var _press_pos := Vector2.ZERO
var _revert: Array = []
var _combo := 0
var _checked := false
var _left := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	_kit_setup("puzle")
	rng.randomize()
	_left = moves
	_layout()
	for x in columns:
		grid.append([])
		off.append([])
		pop.append([])
		for y in rows:
			grid[x].append(_safe_kind(x, y))
			off[x].append(Vector2(0, -cell * (rows + 2)))
			pop[x].append(0.0)
	_hud()
	Aether.music("w0")

func _layout() -> void:
	var vs := view()
	cell = floor(min((vs.y - 140) / rows, (vs.x - 80) / columns))
	origin = Vector2((vs.x - cell * columns) * 0.5, 90 + (vs.y - 110 - cell * rows) * 0.5)

func _safe_kind(x: int, y: int) -> int:
	for i in 20:
		var k := rng.randi() % kinds
		if x >= 2 and grid[x - 1][y] == k and grid[x - 2][y] == k:
			continue
		if y >= 2 and grid[x][y - 1] == k and grid[x][y - 2] == k:
			continue
		return k
	return rng.randi() % kinds

func _hud() -> void:
	set_top("%s %d   ·   %s %d / %d" % [Aether.t("Movimientos"), _left, Aether.t("Puntos"), score, target_score])
	set_top_right("%s %d" % [Aether.t("Récord"), max(best, score)])

func _cell_at(p: Vector2) -> Vector2i:
	var q := (p - origin) / cell
	var c := Vector2i(floori(q.x), floori(q.y))
	if c.x < 0 or c.y < 0 or c.x >= columns or c.y >= rows:
		return Vector2i(-1, -1)
	return c

func _busy() -> bool:
	for x in columns:
		for y in rows:
			if off[x][y].length() > 0.5 or pop[x][y] > 0.0:
				return true
	return false

func _unhandled_input(e: InputEvent) -> void:
	if over:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position() - global_position
		if e.pressed:
			_press = _cell_at(p)
			_press_pos = p
		else:
			_press = Vector2i(-1, -1)
	elif e is InputEventMouseMotion and _press.x >= 0:
		var p := get_global_mouse_position() - global_position
		var dv := p - _press_pos
		if dv.length() > cell * 0.4:
			var dir: Vector2i = Vector2i(1, 0) if abs(dv.x) > abs(dv.y) else Vector2i(0, 1)
			if (dv.x < 0 and abs(dv.x) > abs(dv.y)) or (dv.y < 0 and abs(dv.y) >= abs(dv.x)):
				dir = -dir
			try_swap(_press, _press + dir)
			_press = Vector2i(-1, -1)

## Intercambia dos gemas vecinas (si no hacen grupo, vuelven a su sitio).
func try_swap(a: Vector2i, b: Vector2i) -> bool:
	if _busy() or over:
		return false
	if b.x < 0 or b.y < 0 or b.x >= columns or b.y >= rows or a.x < 0:
		return false
	_swap(a, b)
	_combo = 0
	_checked = false
	if _matches().is_empty():
		_revert = [a, b]
	else:
		_left -= 1
		_revert = []
	Aether.sfx("swing", 0.4, 1.4)
	_hud()
	return true

func _swap(a: Vector2i, b: Vector2i) -> void:
	var t: int = grid[a.x][a.y]
	grid[a.x][a.y] = grid[b.x][b.y]
	grid[b.x][b.y] = t
	off[a.x][a.y] = Vector2(b - a) * cell
	off[b.x][b.y] = Vector2(a - b) * cell

func _matches() -> Dictionary:
	var out := {}
	for y in rows:
		var run := 1
		for x in range(1, columns + 1):
			if x < columns and grid[x][y] >= 0 and grid[x][y] == grid[x - 1][y]:
				run += 1
			else:
				if run >= 3:
					for i in run:
						out[Vector2i(x - 1 - i, y)] = run
				run = 1
	for x in columns:
		var run := 1
		for y in range(1, rows + 1):
			if y < rows and grid[x][y] >= 0 and grid[x][y] == grid[x][y - 1]:
				run += 1
			else:
				if run >= 3:
					for i in run:
						out[Vector2i(x, y - 1 - i)] = run
				run = 1
	return out

func _resolve() -> void:
	if _revert.size() == 2:
		_swap(_revert[0], _revert[1])
		_revert = []
		Aether.sfx("clang", 0.3)
		return
	var m := _matches()
	if m.is_empty():
		_combo = 0
		if _checked:
			return
		_checked = true
		if _left <= 0 or score >= target_score:
			end_game(score >= target_score)
		elif not _has_moves():
			_shuffle()
		return
	_combo += 1
	_checked = false
	var pts := 0
	for c in m:
		var k: int = grid[c.x][c.y]
		pts += 20 * int(m[c])
		var col: Color = COLS[k % COLS.size()]
		FX.burst(self, origin + (Vector2(c) + Vector2(0.5, 0.5)) * cell, Color(col.r * 2, col.g * 2, col.b * 2), 8, 300, 0.35, 8, 300)
		grid[c.x][c.y] = -1
	pts *= _combo
	add_score(pts)
	FX.float_text(self, origin + Vector2(columns * cell * 0.5, rows * cell * 0.4), ("+%d" % pts) + (("  x%d" % _combo) if _combo > 1 else ""), Color(1, 0.9, 0.4), 40)
	Aether.sfx("gem", 0.6, 1.0 + _combo * 0.12)
	if _combo >= 3:
		Aether.shake(6)
		big(Aether.t("¡INCREÍBLE!") if _combo >= 4 else Aether.t("¡GENIAL!"), 0.5)
	# caída y relleno
	for x in columns:
		var w := rows - 1
		for y in range(rows - 1, -1, -1):
			if grid[x][y] >= 0:
				if w != y:
					grid[x][w] = grid[x][y]
					grid[x][y] = -1
					off[x][w] = Vector2(0, (y - w) * cell)
				w -= 1
		for y in range(w, -1, -1):
			grid[x][y] = rng.randi() % kinds
			off[x][y] = Vector2(0, -(w + 1) * cell - cell)
	_hud()

func _has_moves() -> bool:
	for x in columns:
		for y in rows:
			for dv in [Vector2i(1, 0), Vector2i(0, 1)]:
				var b: Vector2i = Vector2i(x, y) + dv
				if b.x >= columns or b.y >= rows:
					continue
				var t: int = grid[x][y]
				grid[x][y] = grid[b.x][b.y]
				grid[b.x][b.y] = t
				var ok := not _matches().is_empty()
				grid[b.x][b.y] = grid[x][y]
				grid[x][y] = t
				if ok:
					return true
	return false

func _shuffle() -> void:
	for x in columns:
		for y in rows:
			grid[x][y] = -1
	for x in columns:
		for y in rows:
			grid[x][y] = _safe_kind(x, y)
			off[x][y] = Vector2(0, -cell * rows)
	Aether.toast(Aether.t("Sin jugadas: ¡nuevo tablero!"))

func _process(d: float) -> void:
	_layout()
	var moving := false
	for x in columns:
		for y in rows:
			var o: Vector2 = off[x][y]
			if o.length() > 0.5:
				o = o.move_toward(Vector2.ZERO, d * cell * 12.0)
				off[x][y] = o
				moving = true
			else:
				off[x][y] = Vector2.ZERO
	if not moving and not over:
		_resolve()
	queue_redraw()

func _draw() -> void:
	var vs := view()
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.06, 0.05, 0.12))
	draw_rect(Rect2(origin - Vector2(10, 10), Vector2(columns, rows) * cell + Vector2(20, 20)), Color(0, 0, 0, 0.45))
	for x in columns:
		for y in rows:
			var r := Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell))
			if (x + y) % 2 == 0:
				draw_rect(r, Color(1, 1, 1, 0.04))
			var k: int = grid[x][y]
			if k < 0:
				continue
			var c: Vector2 = r.get_center() + off[x][y]
			if c.y < origin.y - cell * 0.5:
				continue
			var rad := cell * 0.38
			if k < gem_textures.size() and gem_textures[k]:
				draw_texture_rect(gem_textures[k], Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2), false)
			else:
				_gem(k, c, rad)
	if _press.x >= 0:
		draw_rect(Rect2(origin + Vector2(_press) * cell, Vector2(cell, cell)), Color(1, 1, 1, 0.8), false, 3)

func _gem(k: int, c: Vector2, r: float) -> void:
	var col: Color = COLS[k % COLS.size()]
	var n := [3, 4, 5, 6, 8, 4][k % 6] as int
	var rot: float = -PI / 2 if k != 1 else PI / 4
	var pts := PackedVector2Array()
	for i in n:
		pts.append(c + Vector2(r, 0).rotated(rot + TAU * i / n))
	if k == 4:
		pts = PackedVector2Array()
		for i in 10:
			pts.append(c + Vector2(r if i % 2 == 0 else r * 0.5, 0).rotated(-PI / 2 + TAU * i / 10.0))
	draw_colored_polygon(pts, col.darkened(0.25))
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(c + (p - c) * 0.7 + Vector2(0, -r * 0.08))
	draw_colored_polygon(inner, col.lightened(0.15))
	draw_circle(c + Vector2(-r * 0.25, -r * 0.3), r * 0.14, Color(1, 1, 1, 0.75))

func selftest() -> bool:
	for x in columns:
		for y in rows:
			off[x][y] = Vector2.ZERO
	for n in columns * rows * 2:
		var a := Vector2i((n / 2) % columns, (n / 2) / columns)
		var b: Vector2i = a + (Vector2i(1, 0) if n % 2 == 0 else Vector2i(0, 1))
		if b.x >= columns or b.y >= rows:
			continue
		_swap(a, b)
		var ok := not _matches().is_empty()
		_swap(a, b)
		for xx in columns:
			for yy in rows:
				off[xx][yy] = Vector2.ZERO
		if ok:
			try_swap(a, b)
			for i in 120:
				_process(0.05)
			return score > 0
	return false
