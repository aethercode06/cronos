@icon("res://addons/aether/icons/aether.svg")
class_name AetherFighter
extends AetherKit
## LUCHA 1 contra 1 completa: ◀ ▶ moverse, SALTO, ATAQUE = puñetazo,
## DASH = patada, GUARDIA = bloquear, ▼ + ATAQUE = onda de energía (barra llena).
## Rival con IA, rondas (al mejor de 3), tiempo, combos y cámara lenta al final.

@export_group("Luchadores")
@export var player_name := "KAEL"
@export var rival_name := "SOMBRA"
@export var player_color := Color(0.3, 0.75, 1.0)
@export var rival_color := Color(1.0, 0.35, 0.4)
## Dificultad del rival (0 fácil · 1 muy difícil).
@export_range(0.0, 1.0) var rival_level := 0.5
@export_group("Combate")
@export var max_hp := 100.0
@export var round_time := 60.0
@export var rounds_to_win := 2
## Fondo (opcional).
@export var background: Texture2D

var f: Array = []
var waves: Array = []
var _time := 0.0
var _round := 1
var _wins := [0, 0]
var _pause := 1.6
var _combo := 0
var _combo_t := 0.0
var floor_y := 600.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	_kit_setup("lucha")
	rng.randomize()
	floor_y = view().y - 120
	_new_round()
	Aether.music("w0")

func _fighter(x: float, face: float, col: Color, ai: bool) -> Dictionary:
	return {"p": Vector2(x, floor_y), "v": Vector2.ZERO, "face": face, "hp": max_hp, "col": col, "ai": ai, "atk": "", "at": 0.0, "hit_done": false, "stun": 0.0, "guard": false, "ki": 0.0, "think": 0.0, "walk": 0.0, "fl": 0.0}

func _new_round() -> void:
	var vs := view()
	f = [_fighter(vs.x * 0.3, 1.0, player_color, false), _fighter(vs.x * 0.7, -1.0, rival_color, true)]
	waves = []
	_time = round_time
	_pause = 1.6
	big("%s %d" % [Aether.t("RONDA"), _round], 1.0)
	Aether.sfx("v_fight", 0.8)

func _hud() -> void:
	set_top("%s  %s" % [player_name, "★".repeat(_wins[0])])
	set_top_right("%s  %s" % ["★".repeat(_wins[1]), rival_name])

const MOVES := {
	"punch": {"t": 0.28, "hit": 0.1, "reach": 95.0, "dmg": 6.0, "push": 180.0, "stun": 0.25},
	"kick": {"t": 0.45, "hit": 0.2, "reach": 135.0, "dmg": 10.0, "push": 380.0, "stun": 0.4},
	"wave": {"t": 0.5, "hit": 0.22, "reach": 0.0, "dmg": 16.0, "push": 420.0, "stun": 0.5},
}

func _start(a: Dictionary, m: String) -> void:
	if a["atk"] != "" or a["stun"] > 0.0:
		return
	if m == "wave":
		if a["ki"] < 100.0:
			m = "punch"
		else:
			a["ki"] = 0.0
	a["atk"] = m
	a["at"] = 0.0
	a["hit_done"] = false
	Aether.sfx("swing", 0.5, 1.2 if m == "punch" else 0.9)

func _input_player(a: Dictionary) -> void:
	var mv := Input.get_axis("left", "right")
	a["guard"] = Input.is_action_pressed("guard") and a["p"].y >= floor_y
	if a["atk"] == "" and a["stun"] <= 0.0 and not a["guard"]:
		a["v"].x = mv * 340.0
		if Input.is_action_just_pressed("jump") and a["p"].y >= floor_y:
			a["v"].y = -820.0
			Aether.sfx("jump", 0.5)
	if Input.is_action_just_pressed("attack"):
		_start(a, "wave" if Input.is_action_pressed("down") else "punch")
	if Input.is_action_just_pressed("dash"):
		_start(a, "kick")

func _think(a: Dictionary, o: Dictionary, d: float) -> void:
	a["think"] -= d
	var dist: float = abs(o["p"].x - a["p"].x)
	a["guard"] = false
	if o["atk"] != "" and dist < 160 and rng.randf() < rival_level * 0.9 and a["atk"] == "":
		a["guard"] = true
		a["v"].x = 0.0
		return
	if a["atk"] != "" or a["stun"] > 0.0:
		return
	if a["think"] > 0.0:
		a["v"].x = a["walk"] * 300.0
		return
	a["think"] = lerp(0.6, 0.15, rival_level) + rng.randf() * 0.2
	if a["ki"] >= 100.0 and dist > 300:
		_start(a, "wave")
	elif dist < 110:
		_start(a, "punch" if rng.randf() < 0.6 else "kick")
		a["walk"] = 0.0
	elif dist < 150 and rng.randf() < 0.5:
		_start(a, "kick")
	else:
		a["walk"] = signf(o["p"].x - a["p"].x) * (1.0 if rng.randf() < 0.75 else -0.6)
		if rng.randf() < 0.12 and a["p"].y >= floor_y:
			a["v"].y = -780.0

func _process(d: float) -> void:
	queue_redraw()
	_hud()
	if over:
		return
	if _pause > 0.0:
		_pause -= d
		return
	_time -= d
	_combo_t -= d
	if _combo_t <= 0.0:
		_combo = 0
	var a: Dictionary = f[0]
	var b: Dictionary = f[1]
	_input_player(a)
	_think(b, a, d)
	var vs := view()
	for i in 2:
		var me: Dictionary = f[i]
		var other: Dictionary = f[1 - i]
		me["stun"] = max(0.0, me["stun"] - d)
		me["fl"] = max(0.0, me["fl"] - d)
		me["v"].y += 2200.0 * d
		if me["atk"] != "" or me["guard"]:
			me["v"].x = move_toward(me["v"].x, 0.0, 2400.0 * d)
		if me["stun"] > 0.0:
			me["v"].x = move_toward(me["v"].x, 0.0, 900.0 * d)
		me["p"] += me["v"] * d
		if me["p"].y >= floor_y:
			me["p"].y = floor_y
			me["v"].y = 0.0
		me["p"].x = clamp(me["p"].x, 60.0, vs.x - 60.0)
		if me["atk"] == "" and me["stun"] <= 0.0:
			me["face"] = signf(other["p"].x - me["p"].x) if other["p"].x != me["p"].x else me["face"]
		if me["atk"] != "":
			var mv: Dictionary = MOVES[me["atk"]]
			me["at"] += d
			if not me["hit_done"] and me["at"] >= mv["hit"]:
				me["hit_done"] = true
				if me["atk"] == "wave":
					waves.append({"p": me["p"] + Vector2(me["face"] * 60, -90), "dir": me["face"], "owner": i})
					Aether.sfx("dash", 0.7)
				elif abs(other["p"].x - me["p"].x) < mv["reach"] and abs(other["p"].y - me["p"].y) < 140:
					_hit(me, other, mv, i)
			if me["at"] >= mv["t"]:
				me["atk"] = ""
	if abs(a["p"].x - b["p"].x) < 70 and abs(a["p"].y - b["p"].y) < 100:
		var push := signf(a["p"].x - b["p"].x)
		if push == 0.0:
			push = 1.0
		a["p"].x += push * 200.0 * d
		b["p"].x -= push * 200.0 * d
	for w in waves.duplicate():
		w["p"].x += w["dir"] * 760.0 * d
		var tgt: Dictionary = f[1 - int(w["owner"])]
		if w["p"].distance_to(tgt["p"] + Vector2(0, -90)) < 70:
			waves.erase(w)
			_hit(f[w["owner"]], tgt, MOVES["wave"], int(w["owner"]))
		elif w["p"].x < -100 or w["p"].x > vs.x + 100:
			waves.erase(w)
	if a["hp"] <= 0.0 or b["hp"] <= 0.0 or _time <= 0.0:
		_end_round()

func _hit(me: Dictionary, other: Dictionary, mv: Dictionary, who: int) -> void:
	var blocked: bool = other["guard"] and signf(me["p"].x - other["p"].x) == other["face"]
	var dmg: float = mv["dmg"] * (0.15 if blocked else 1.0)
	other["hp"] = max(0.0, other["hp"] - dmg)
	other["v"].x = me["face"] * mv["push"] * (0.4 if blocked else 1.0)
	me["ki"] = min(100.0, me["ki"] + (6.0 if blocked else 14.0))
	other["ki"] = min(100.0, other["ki"] + 8.0)
	var at: Vector2 = other["p"] + Vector2(-me["face"] * 20, -100)
	if blocked:
		Aether.sfx("shield", 0.7)
		FX.burst(self, at, Color(0.6, 1.4, 2.4), 10, 300, 0.25, 7, 0)
		return
	other["stun"] = mv["stun"]
	other["fl"] = 0.1
	other["atk"] = ""
	Aether.sfx("hit", 0.8, rng.randf_range(0.9, 1.1))
	Aether.hitstop(0.06 if mv["dmg"] < 12 else 0.1)
	Aether.shake(5.0 + mv["dmg"] * 0.6)
	FX.burst(self, at, Color(2.4, 1.8, 1.0), 14, 420, 0.3, 8, 0)
	FX.float_text(self, at + Vector2(0, -30), str(int(dmg)), Color(1, 0.9, 0.4), 30)
	if who == 0:
		_combo += 1
		_combo_t = 0.9
		add_score(int(dmg * 10) * _combo)
		if _combo >= 3:
			FX.float_text(self, at + Vector2(0, -80), "%d %s" % [_combo, Aether.t("GOLPES")], Color(1, 0.6, 0.3), 36)

func _end_round() -> void:
	var a: Dictionary = f[0]
	var b: Dictionary = f[1]
	_pause = 99.0
	var winner: int = 0 if a["hp"] >= b["hp"] else 1
	_wins[winner] += 1
	Aether.slowmo(0.25, 0.9)
	Aether.flash(Color(1, 1, 1), 0.5)
	if winner == 0:
		add_score(int(a["hp"]) * 20 + int(_time) * 10)
	_hud()
	if _wins[winner] >= rounds_to_win:
		end_game(winner == 0, Aether.t("¡GANASTE!") if winner == 0 else Aether.t("DERROTA"))
		return
	big(Aether.t("¡K.O.!") if (a["hp"] <= 0.0 or b["hp"] <= 0.0) else Aether.t("¡TIEMPO!"), 1.2)
	_round += 1
	await get_tree().create_timer(1.6).timeout
	if not over:
		_new_round()

func _draw() -> void:
	var vs := view()
	if background:
		draw_texture_rect(background, Rect2(Vector2.ZERO, vs), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.08, 0.06, 0.14))
		draw_circle(Vector2(vs.x * 0.5, floor_y - 260), 180, Color(0.35, 0.2, 0.45, 0.4))
	draw_rect(Rect2(0, floor_y, vs.x, vs.y - floor_y), Color(0.12, 0.1, 0.14))
	draw_line(Vector2(0, floor_y), Vector2(vs.x, floor_y), Color(0.6, 0.5, 0.8), 3)
	for i in 2:
		_bars(i, vs)
		_body(f[i])
	for w in waves:
		draw_circle(w["p"], 34, Color(0.4, 0.9, 2.0, 0.35))
		draw_circle(w["p"], 20, Color(1.2, 2.0, 2.6))
	draw_string(ThemeDB.fallback_font, Vector2(vs.x * 0.5 - 30, 92), str(max(0, ceili(_time))), HORIZONTAL_ALIGNMENT_CENTER, 60, 48, Color(1, 1, 1))

func _bars(i: int, vs: Vector2) -> void:
	var me: Dictionary = f[i]
	var w := vs.x * 0.36
	var x: float = 30.0 if i == 0 else vs.x - 30.0 - w
	draw_rect(Rect2(x, 60, w, 26), Color(0, 0, 0, 0.6))
	var k: float = me["hp"] / max_hp
	var fx: float = x if i == 0 else x + w * (1.0 - k)
	draw_rect(Rect2(fx, 60, w * k, 26), Color(0.3, 1, 0.45) if k > 0.3 else Color(1, 0.3, 0.3))
	draw_rect(Rect2(x, 92, w * 0.5, 10), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(x, 92, w * 0.5 * me["ki"] / 100.0, 10), Color(0.4, 0.8, 2.0) if me["ki"] >= 100.0 else Color(0.3, 0.5, 1.0))

## Luchador dibujado con formas (cabeza, torso, brazos y piernas animados).
func _body(me: Dictionary) -> void:
	var p: Vector2 = me["p"]
	var s: float = me["face"]
	var col: Color = Color(3, 3, 3) if me["fl"] > 0.0 else me["col"]
	var t := Time.get_ticks_msec() / 1000.0
	var walk: float = sin(t * 14.0) * clamp(abs(me["v"].x) / 300.0, 0.0, 1.0)
	var air: bool = p.y < floor_y - 1
	var hip := p + Vector2(0, -70)
	var neck := hip + Vector2(s * 6, -70)
	var arm_r := Vector2(s * 40, 20)
	var arm_l := Vector2(-s * 20, 30)
	var leg_f := Vector2(s * (14 + walk * 22), 70)
	var leg_b := Vector2(-s * (14 + walk * 22), 70)
	var k := 0.0
	if me["atk"] != "":
		var mv: Dictionary = MOVES[me["atk"]]
		k = clamp(1.0 - abs(me["at"] - mv["hit"]) / mv["hit"], 0.0, 1.0)
		if me["atk"] == "punch":
			arm_r = Vector2(s * (40 + 60 * k), 4)
		elif me["atk"] == "kick":
			leg_f = Vector2(s * (30 + 90 * k), 70 - 80 * k)
		else:
			arm_r = Vector2(s * (40 + 50 * k), 0)
			arm_l = Vector2(s * (30 + 50 * k), 10)
	if me["guard"]:
		arm_r = Vector2(s * 30, -10)
		arm_l = Vector2(s * 26, 6)
	if me["stun"] > 0.0:
		neck += Vector2(-s * 16, 6)
	if air:
		leg_f = Vector2(s * 26, 44)
		leg_b = Vector2(-s * 10, 50)
	draw_circle(Vector2(p.x, floor_y + 4), 40, Color(0, 0, 0, 0.3))
	var dark := col.darkened(0.35)
	draw_line(hip, hip + leg_b, dark, 16)
	draw_line(neck + Vector2(0, 14), neck + Vector2(0, 14) + arm_l, dark, 13)
	draw_line(hip, neck, col, 30)
	draw_line(hip, hip + leg_f, col, 17)
	draw_line(neck + Vector2(0, 14), neck + Vector2(0, 14) + arm_r, col, 14)
	draw_circle(neck + Vector2(0, 14) + arm_r, 11, col.lightened(0.3))
	draw_circle(neck + Vector2(s * 4, -26), 24, col.lightened(0.15))
	draw_circle(neck + Vector2(s * 14, -30), 4, Color(1, 1, 1))
	if me["guard"]:
		draw_arc(neck + Vector2(s * 30, 10), 56, -1.2 if s > 0 else PI - 1.2, 1.2 if s > 0 else PI + 1.2, 16, Color(0.5, 1.2, 2.2, 0.6), 5)
	if me["atk"] == "wave" and k > 0.2:
		draw_circle(neck + Vector2(s * 80, 10), 22 * k, Color(1.2, 2.0, 2.6, 0.8))

func selftest() -> bool:
	_pause = 0.0
	var a: Dictionary = f[0]
	var b: Dictionary = f[1]
	b["p"].x = a["p"].x + 80.0
	rival_level = 0.0
	b["think"] = 99.0
	b["walk"] = 0.0
	_start(a, "punch")
	for i in 20:
		_process(0.02)
	return b["hp"] < max_hp
