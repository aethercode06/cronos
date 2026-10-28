@icon("res://addons/aether/icons/aether.svg")
class_name AetherShooter
extends AetherKit
## Juego de DISPAROS completo (nave): muévete con las flechas o arrastrando el dedo,
## la nave dispara sola. Oleadas que se complican, mejoras, jefe cada 5 oleadas.
## Cambia las imágenes y los números en el Inspector.

@export_group("Aspecto")
## Imagen de la nave (opcional: si no hay, se dibuja una).
@export var ship_texture: Texture2D
## Imagen de los enemigos (opcional).
@export var enemy_texture: Texture2D
## Fondo que se desplaza (opcional).
@export var background: Texture2D
@export var ship_color := Color(0.35, 0.9, 1.0)
@export var enemy_color := Color(1.0, 0.35, 0.45)
@export_group("Juego")
@export var ship_speed := 560.0
## Disparos por segundo.
@export var fire_rate := 7.0
@export var lives := 3
## Oleadas para ganar (0 = sin fin).
@export var waves_to_win := 15

var ship := Vector2(160, 360)
var bullets: Array = []
var foes: Array = []
var powers: Array = []
var stars: Array = []
var fire_t := 0.0
var spawn_t := 1.2
var wave := 0
var triple := 0.0
var inv := 0.0
var bg_x := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	_kit_setup("disparos")
	rng.randomize()
	var vs := view()
	ship = Vector2(160, vs.y * 0.5)
	for i in 90:
		stars.append(Vector3(rng.randf() * vs.x, rng.randf() * vs.y, rng.randf_range(0.2, 1.0)))
	Aether.music("w0")
	_hud()

func _hud() -> void:
	set_top("♥ %d   ·   %s %d" % [lives, Aether.t("Oleada"), wave])
	set_top_right("%d   ·   %s %d" % [score, Aether.t("Récord"), max(best, score)])

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		ship += e.relative * 1.25

func _shoot(p: Vector2, v: Vector2, mine: bool) -> void:
	bullets.append({"p": p, "v": v, "mine": mine})

func _spawn_wave() -> void:
	wave += 1
	var vs := view()
	if waves_to_win > 0 and wave > waves_to_win:
		end_game(true)
		return
	if wave % 5 == 0:
		foes.append({"p": Vector2(vs.x + 120, vs.y * 0.5), "v": Vector2(-90, 0), "hp": 40 + wave * 6, "max": 40 + wave * 6, "t": 0.0, "kind": 3, "r": 70.0, "fl": 0.0, "pts": 2000, "cd": 1.0})
		big(Aether.t("¡JEFE!"))
		Aether.sfx("roar", 0.8)
	else:
		var kind := wave % 3
		var n := 5 + int(wave * 0.4)
		for i in n:
			var y := rng.randf_range(80, vs.y - 80)
			if kind == 0:
				y = vs.y * 0.2 + (vs.y * 0.6) * float(i) / max(1, n - 1)
			foes.append({"p": Vector2(vs.x + 60 + i * 70, y), "v": Vector2(-180 - wave * 8, 0), "hp": 1 + int(wave / 4.0), "max": 1, "t": rng.randf() * 6.0, "kind": kind, "r": 26.0, "fl": 0.0, "pts": 100, "cd": rng.randf_range(0.8, 2.0), "y0": y})
		big("%s %d" % [Aether.t("OLEADA"), wave], 0.8)
	spawn_t = max(4.0, 9.0 - wave * 0.2)
	_hud()

func _kill(f: Dictionary) -> void:
	foes.erase(f)
	add_score(int(f["pts"]))
	Aether.sfx("kill", 0.5, rng.randf_range(0.9, 1.2))
	FX.burst(self, f["p"], Color(enemy_color.r * 2, enemy_color.g * 2, enemy_color.b * 2), 16, 380, 0.4, 9, 0)
	if f["kind"] == 3:
		Aether.shake(18, 0.0)
		Aether.slowmo(0.3, 0.6)
		FX.ring(self, f["p"], Color(2, 1.6, 1), 300)
	elif rng.randf() < 0.08:
		powers.append({"p": f["p"], "k": rng.randi() % 2})
	_hud()

func _hurt() -> void:
	lives -= 1
	inv = 1.6
	Aether.sfx("hurt", 0.8)
	Aether.shake(12)
	Aether.flash(Color(1, 0.2, 0.2), 0.35)
	FX.burst(self, ship, Color(2, 1.4, 1), 20, 400, 0.5, 10, 0)
	_hud()
	if lives <= 0:
		end_game(false)

func _process(d: float) -> void:
	queue_redraw()
	var vs := view()
	for i in stars.size():
		var s: Vector3 = stars[i]
		s.x -= 260.0 * s.z * d
		if s.x < 0:
			s.x += vs.x
		stars[i] = s
	bg_x -= 40.0 * d
	if over:
		return
	var mv := Input.get_vector("left", "right", "up", "down")
	ship += mv * ship_speed * d
	ship.x = clamp(ship.x, 40.0, vs.x * 0.6)
	ship.y = clamp(ship.y, 40.0, vs.y - 40.0)
	triple = max(0.0, triple - d)
	inv = max(0.0, inv - d)
	fire_t -= d
	if fire_t <= 0.0:
		fire_t = 1.0 / fire_rate
		_shoot(ship + Vector2(34, 0), Vector2(1000, 0), true)
		if triple > 0.0:
			_shoot(ship + Vector2(30, -8), Vector2(960, -200), true)
			_shoot(ship + Vector2(30, 8), Vector2(960, 200), true)
	spawn_t -= d
	if spawn_t <= 0.0 or foes.is_empty():
		_spawn_wave()
	for b in bullets.duplicate():
		b["p"] += b["v"] * d
		var p: Vector2 = b["p"]
		if p.x < -40 or p.x > vs.x + 40 or p.y < -40 or p.y > vs.y + 40:
			bullets.erase(b)
			continue
		if b["mine"]:
			for f in foes:
				if p.distance_to(f["p"]) < f["r"]:
					f["hp"] -= 1
					f["fl"] = 0.08
					bullets.erase(b)
					FX.burst(self, p, Color(2, 1.8, 1), 4, 200, 0.2, 6, 0)
					if f["hp"] <= 0:
						_kill(f)
					break
		elif inv <= 0.0 and p.distance_to(ship) < 16:
			bullets.erase(b)
			_hurt()
	for f in foes.duplicate():
		f["t"] += d
		f["fl"] = max(0.0, f["fl"] - d)
		var k: int = f["kind"]
		var fp: Vector2 = f["p"]
		if k == 1:
			fp.x += f["v"].x * d
			fp.y = f["y0"] + sin(f["t"] * 3.0) * 120.0
		elif k == 2:
			fp.x = max(vs.x * 0.7, fp.x + f["v"].x * d)
			f["cd"] -= d
			if f["cd"] <= 0.0:
				f["cd"] = max(0.7, 2.2 - wave * 0.08)
				_shoot(fp, (ship - fp).normalized() * 360.0, false)
		elif k == 3:
			fp.x = max(vs.x * 0.78, fp.x + f["v"].x * d)
			fp.y = vs.y * 0.5 + sin(f["t"] * 1.3) * vs.y * 0.3
			f["cd"] -= d
			if f["cd"] <= 0.0:
				f["cd"] = 1.1
				for a in range(-3, 4):
					_shoot(fp, Vector2(-320, 0).rotated(a * 0.22), false)
		else:
			fp += f["v"] * d
		f["p"] = fp
		if fp.x < -80:
			foes.erase(f)
		elif inv <= 0.0 and fp.distance_to(ship) < f["r"] + 14:
			if k != 3:
				_kill(f)
			_hurt()
	for pw in powers.duplicate():
		pw["p"] += Vector2(-120, 0) * d
		if pw["p"].distance_to(ship) < 40:
			powers.erase(pw)
			Aether.sfx("gem", 0.7)
			if pw["k"] == 0:
				triple = 10.0
				Aether.toast(Aether.t("¡TRIPLE DISPARO!"))
			else:
				lives += 1
				Aether.toast("+1 ♥")
			_hud()
		elif pw["p"].x < -40:
			powers.erase(pw)

func _draw() -> void:
	var vs := view()
	if background:
		var w := background.get_width() * vs.y / background.get_height()
		var x := fmod(bg_x, w)
		for i in 3:
			draw_texture_rect(background, Rect2(x + i * w, 0, w, vs.y), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.02, 0.07))
	for s in stars:
		draw_circle(Vector2(s.x, s.y), 1.0 + s.z * 1.6, Color(1, 1, 1, 0.3 + s.z * 0.6))
	for pw in powers:
		var c: Color = Color(0.4, 1, 0.5) if pw["k"] == 0 else Color(1, 0.4, 0.6)
		draw_circle(pw["p"], 22, Color(c.r, c.g, c.b, 0.3))
		draw_circle(pw["p"], 14, c)
	for f in foes:
		var col: Color = Color(3, 3, 3) if f["fl"] > 0 else enemy_color
		var r: float = f["r"]
		if enemy_texture:
			var ts := Vector2(r * 2.2, r * 2.2)
			draw_texture_rect(enemy_texture, Rect2(f["p"] - ts * 0.5, ts), false, col if f["fl"] > 0 else Color(1, 1, 1))
		else:
			draw_circle(f["p"], r, col)
			draw_circle(f["p"] + Vector2(-r * 0.35, -r * 0.2), r * 0.22, Color(1, 1, 0.8))
			draw_circle(f["p"] + Vector2(-r * 0.35, r * 0.2), r * 0.22, Color(1, 1, 0.8))
		if f["kind"] == 3:
			draw_rect(Rect2(f["p"] + Vector2(-80, -r - 24), Vector2(160, 10)), Color(0, 0, 0, 0.6))
			draw_rect(Rect2(f["p"] + Vector2(-80, -r - 24), Vector2(160.0 * f["hp"] / f["max"], 10)), Color(1, 0.3, 0.3))
	for b in bullets:
		if b["mine"]:
			draw_line(b["p"] - Vector2(14, 0), b["p"], Color(0.6, 2.0, 2.4), 5)
		else:
			draw_circle(b["p"], 9, Color(1, 0.4, 0.2, 0.4))
			draw_circle(b["p"], 5, Color(2, 1.2, 0.6))
	if not over or lives > 0:
		var blink := inv > 0.0 and int(inv * 12) % 2 == 0
		if not blink:
			if ship_texture:
				var ts := Vector2(80, 80 * ship_texture.get_height() / float(ship_texture.get_width()))
				draw_texture_rect(ship_texture, Rect2(ship - ts * 0.5, ts), false)
			else:
				var pts := PackedVector2Array([ship + Vector2(36, 0), ship + Vector2(-24, -24), ship + Vector2(-14, 0), ship + Vector2(-24, 24)])
				draw_colored_polygon(pts, ship_color)
				draw_circle(ship + Vector2(-20, 0), 8 + randf() * 4, Color(2, 1.2, 0.4))
				if triple > 0.0:
					draw_arc(ship, 44, 0, TAU, 32, Color(0.4, 1, 0.5, 0.5), 3)

func selftest() -> bool:
	_spawn_wave()
	var n := foes.size()
	for i in 60:
		_shoot(foes[0]["p"] - Vector2(10, 0), Vector2.ZERO, true)
		_process(0.016)
		if foes.size() < n:
			return true
	return foes.size() < n
