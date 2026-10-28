@icon("res://addons/aether/icons/aether.svg")
class_name AetherTowerDefense
extends AetherKit
## DEFENSA DE TORRES completa: los enemigos siguen el camino; toca el suelo
## para construir la torre elegida abajo (Arquero, Cañón, Hielo). Toca una torre
## para mejorarla. Gana al aguantar todas las oleadas.

@export_group("Camino")
## Puntos del camino (en píxeles). Muévelos para cambiar el recorrido.
@export var path_points := PackedVector2Array([Vector2(-40, 160), Vector2(300, 160), Vector2(300, 520), Vector2(640, 520), Vector2(640, 230), Vector2(980, 230), Vector2(980, 600), Vector2(1320, 600)])
@export var path_width := 64.0
@export var ground_color := Color(0.16, 0.3, 0.17)
@export var path_color := Color(0.55, 0.45, 0.3)
@export_group("Juego")
@export var start_gold := 120
@export var lives := 20
@export var total_waves := 12
## Imagen de los enemigos (opcional).
@export var enemy_texture: Texture2D

const TOWERS := [
	{"name": "Arquero", "cost": 50, "range": 190.0, "rate": 1.6, "dmg": 6.0, "splash": 0.0, "slow": 0.0, "col": Color(0.4, 0.85, 1.0)},
	{"name": "Cañón", "cost": 90, "range": 160.0, "rate": 0.55, "dmg": 16.0, "splash": 80.0, "slow": 0.0, "col": Color(1.0, 0.6, 0.25)},
	{"name": "Hielo", "cost": 70, "range": 150.0, "rate": 1.0, "dmg": 2.0, "splash": 60.0, "slow": 0.5, "col": Color(0.7, 0.9, 1.0)},
]

var gold := 0
var wave := 0
var towers: Array = []
var foes: Array = []
var shots: Array = []
var _sel := 0
var _len: Array = []
var _total := 0.0
var _to_spawn := 0
var _spawn_t := 0.0
var _next_wave_t := 4.0
var _buttons: Array = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	_kit_setup("defensa")
	rng.randomize()
	gold = start_gold
	_measure()
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.position = Vector2(view().x * 0.5 - 420, view().y - 96)
	bar.size = Vector2(840, 84)
	bar.add_theme_constant_override("separation", 12)
	hud.add_child(bar)
	for i in TOWERS.size():
		var b := Button.new()
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(190, 80)
		b.add_theme_font_size_override("font_size", 24)
		b.text = "%s\n%d ◆" % [Aether.t(TOWERS[i]["name"]), TOWERS[i]["cost"]]
		b.pressed.connect(select_tower.bind(i))
		bar.add_child(b)
		_buttons.append(b)
	var go := Button.new()
	go.text = Aether.t("¡OLEADA!")
	go.custom_minimum_size = Vector2(200, 80)
	go.add_theme_font_size_override("font_size", 26)
	go.pressed.connect(func() -> void: _next_wave_t = 0.0)
	bar.add_child(go)
	select_tower(0)
	_hud()
	Aether.music("w0")

func select_tower(i: int) -> void:
	_sel = i
	for j in _buttons.size():
		_buttons[j].button_pressed = j == i

func _measure() -> void:
	_len = [0.0]
	_total = 0.0
	for i in range(1, path_points.size()):
		_total += path_points[i - 1].distance_to(path_points[i])
		_len.append(_total)

func _pos_at(s: float) -> Vector2:
	for i in range(1, path_points.size()):
		if s <= _len[i]:
			var seg: float = _len[i] - _len[i - 1]
			var k: float = (s - _len[i - 1]) / max(seg, 0.001)
			return path_points[i - 1].lerp(path_points[i], k)
	return path_points[path_points.size() - 1]

func _near_path(p: Vector2) -> bool:
	for i in range(1, path_points.size()):
		var q := Geometry2D.get_closest_point_to_segment(p, path_points[i - 1], path_points[i])
		if q.distance_to(p) < path_width * 0.5 + 30:
			return true
	return false

func _hud() -> void:
	set_top("◆ %d   ·   ♥ %d   ·   %s %d/%d" % [gold, lives, Aether.t("Oleada"), wave, total_waves])
	set_top_right("%d" % score)

func _unhandled_input(e: InputEvent) -> void:
	if over:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		tap(get_global_mouse_position() - global_position)

## Toque en el mapa: construye o mejora.
func tap(p: Vector2) -> void:
	for t in towers:
		if t["p"].distance_to(p) < 36:
			var cost := 40 * int(t["lvl"])
			if gold >= cost and t["lvl"] < 3:
				gold -= cost
				t["lvl"] += 1
				Aether.sfx("check", 0.7)
				FX.ring(self, t["p"], Color(1.6, 1.4, 0.6), 70)
				FX.float_text(self, t["p"] + Vector2(0, -40), Aether.t("¡MEJORA!"), Color(1, 0.9, 0.4), 26)
			else:
				Aether.toast("%s: %d ◆" % [Aether.t("Mejorar"), cost])
			_hud()
			return
	if _near_path(p) or p.y > view().y - 110 or p.y < 70:
		return
	for t in towers:
		if t["p"].distance_to(p) < 70:
			return
	var d: Dictionary = TOWERS[_sel]
	if gold < int(d["cost"]):
		Aether.toast(Aether.t("Faltan gemas"))
		return
	gold -= int(d["cost"])
	towers.append({"p": p, "k": _sel, "cd": 0.0, "lvl": 1, "ang": 0.0})
	Aether.sfx("stomp", 0.6)
	FX.burst(self, p, Color(1.4, 1.2, 0.8), 12, 240, 0.35, 8, 300)
	_hud()

func _start_wave() -> void:
	wave += 1
	_to_spawn = 6 + wave * 2
	_spawn_t = 0.0
	big("%s %d" % [Aether.t("OLEADA"), wave], 0.8)
	Aether.sfx("roar", 0.5)
	_hud()

func _process(d: float) -> void:
	queue_redraw()
	if over:
		return
	if _to_spawn <= 0 and foes.is_empty():
		if wave >= total_waves:
			end_game(true)
			return
		_next_wave_t -= d
		if _next_wave_t <= 0.0:
			_start_wave()
			_next_wave_t = 6.0
	if _to_spawn > 0:
		_spawn_t -= d
		if _spawn_t <= 0.0:
			_spawn_t = max(0.35, 0.9 - wave * 0.04)
			_to_spawn -= 1
			var tough := wave % 4 == 0 and _to_spawn == 0
			var hp: float = (18.0 + wave * 9.0) * (8.0 if tough else 1.0)
			foes.append({"s": 0.0, "hp": hp, "max": hp, "spd": (70.0 if tough else 95.0 + wave * 3.0), "slow": 0.0, "r": (34.0 if tough else 18.0), "gold": (60 if tough else 6 + wave), "fl": 0.0})
	for f in foes.duplicate():
		f["slow"] = max(0.0, f["slow"] - d)
		f["fl"] = max(0.0, f["fl"] - d)
		f["s"] += f["spd"] * (0.5 if f["slow"] > 0.0 else 1.0) * d
		if f["s"] >= _total:
			foes.erase(f)
			lives -= 1
			Aether.sfx("hurt", 0.6)
			Aether.shake(6)
			_hud()
			if lives <= 0:
				end_game(false)
				return
	for t in towers:
		var td: Dictionary = TOWERS[t["k"]]
		t["cd"] -= d
		if t["cd"] > 0.0:
			continue
		var target = null
		var far := -1.0
		var rg: float = td["range"] * (1.0 + 0.15 * (t["lvl"] - 1))
		for f in foes:
			if _pos_at(f["s"]).distance_to(t["p"]) < rg and f["s"] > far:
				far = f["s"]
				target = f
		if target != null:
			t["cd"] = 1.0 / float(td["rate"])
			var tp := _pos_at(target["s"])
			t["ang"] = (tp - t["p"]).angle()
			shots.append({"p": t["p"], "f": target, "k": t["k"], "lvl": t["lvl"]})
	for s in shots.duplicate():
		var f: Dictionary = s["f"]
		var tp := _pos_at(f["s"])
		s["p"] = s["p"].move_toward(tp, 900.0 * d)
		if s["p"].distance_to(tp) < 8 or not foes.has(f):
			shots.erase(s)
			if foes.has(f):
				_hit(s, tp)
	_hud()

func _hit(s: Dictionary, at: Vector2) -> void:
	var td: Dictionary = TOWERS[s["k"]]
	var dmg: float = td["dmg"] * (1.0 + 0.6 * (s["lvl"] - 1))
	var list: Array = []
	if td["splash"] > 0.0:
		for f in foes:
			if _pos_at(f["s"]).distance_to(at) < td["splash"]:
				list.append(f)
		FX.ring(self, at, Color(td["col"].r * 1.8, td["col"].g * 1.8, td["col"].b * 1.8, 0.8), td["splash"], 0.25)
	else:
		list.append(s["f"])
	for f in list:
		f["hp"] -= dmg
		f["fl"] = 0.06
		if td["slow"] > 0.0:
			f["slow"] = 1.5
		if f["hp"] <= 0.0 and foes.has(f):
			foes.erase(f)
			gold += int(f["gold"])
			add_score(10 * int(f["gold"]))
			Aether.sfx("kill", 0.4, rng.randf_range(0.9, 1.2))
			FX.burst(self, _pos_at(f["s"]), Color(2, 0.8, 0.6), 10, 260, 0.35, 8, 300)
			Aether.enemy_killed.emit()

func _draw() -> void:
	var vs := view()
	draw_rect(Rect2(Vector2.ZERO, vs), ground_color)
	for i in 40:
		var gp := Vector2(fmod(i * 337.0, vs.x), fmod(i * 191.0, vs.y))
		draw_circle(gp, 6, ground_color.lightened(0.1))
	draw_polyline(path_points, path_color.darkened(0.3), path_width + 12, true)
	draw_polyline(path_points, path_color, path_width, true)
	for t in towers:
		var td: Dictionary = TOWERS[t["k"]]
		var c: Color = td["col"]
		draw_circle(t["p"] + Vector2(0, 8), 30, Color(0, 0, 0, 0.3))
		draw_circle(t["p"], 28, c.darkened(0.45))
		draw_circle(t["p"], 20, c)
		draw_line(t["p"], t["p"] + Vector2(30, 0).rotated(t["ang"]), Color(0.15, 0.15, 0.2), 9)
		for l in int(t["lvl"]):
			draw_circle(t["p"] + Vector2(-12 + l * 12, 34), 4, Color(1, 0.9, 0.3))
	for f in foes:
		var p := _pos_at(f["s"])
		var r: float = f["r"]
		var col: Color = Color(3, 3, 3) if f["fl"] > 0.0 else (Color(0.6, 0.8, 1.0) if f["slow"] > 0.0 else Color(0.85, 0.25, 0.3))
		if enemy_texture:
			draw_texture_rect(enemy_texture, Rect2(p - Vector2(r, r) * 1.2, Vector2(r, r) * 2.4), false, col if f["fl"] > 0.0 else Color(1, 1, 1))
		else:
			draw_circle(p, r, col)
			draw_circle(p + Vector2(r * 0.3, -r * 0.2), r * 0.25, Color(1, 1, 0.8))
		draw_rect(Rect2(p + Vector2(-r, -r - 12), Vector2(r * 2, 5)), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(p + Vector2(-r, -r - 12), Vector2(r * 2 * f["hp"] / f["max"], 5)), Color(0.3, 1, 0.4))
	for s in shots:
		var c: Color = TOWERS[s["k"]]["col"]
		draw_circle(s["p"], 7, Color(c.r * 2, c.g * 2, c.b * 2))
	var m := get_global_mouse_position() - global_position
	if not over and not _near_path(m) and m.y < vs.y - 110:
		draw_arc(m, TOWERS[_sel]["range"], 0, TAU, 48, Color(1, 1, 1, 0.15), 2)

func selftest() -> bool:
	gold = 999
	tap(Vector2(460, 340))
	tap(Vector2(800, 400))
	_next_wave_t = 0.0
	for i in 400:
		_process(0.05)
	return towers.size() == 2 and score > 0
