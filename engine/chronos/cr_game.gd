class_name CrGame
extends Node2D
## Chronos & The Shift en Aether Engine — Mundo 1 (etapa 1 de la migración).
## Traducción directa de logic.js: misma física de Kael (MOVE 290, JUMP 600,
## GRAV 1750, DASH 760), mismas cajas de golpe, enemigos, Gran Sapo y fases.

signal hp_changed(hp: float, max_hp: float)

const MOVE := 290.0
const JUMP := 600.0
const GRAV := 1750.0
const DASH := 760.0
const PW := 22.0
const PH := 48.0
const VW := 640.0
const VH := 360.0
const GY := 480.0
const DIFFS := [
	{"name": "FÁCIL", "hp": 150.0, "dmg": 0.7, "spd": 0.85, "boss": 0.8, "aggr": 0.9},
	{"name": "NORMAL", "hp": 100.0, "dmg": 1.25, "spd": 1.0, "boss": 1.15, "aggr": 1.15},
	{"name": "DIFÍCIL", "hp": 80.0, "dmg": 2.1, "spd": 1.3, "boss": 1.5, "aggr": 1.45},
]
const HINTS := {
	"move": "◀ ▶ para moverte · SALTO para saltar",
	"sword": "ESPADA: golpea a los enemigos (3 golpes seguidos = combo)",
	"doublejump": "Pulsa SALTO en el aire: ¡doble salto!",
	"spring": "Los resortes te lanzan muy alto",
	"mover": "Súbete a las plataformas que se mueven",
	"dash": "DASH: un impulso rápido para cruzar huecos largos",
	"spikes": "Golpea hacia abajo sobre los pinchos para rebotar",
	"wallclimb": "Salta contra una pared y vuelve a saltar para subir",
}

@export_range(0, 2) var act := 0
@export_range(0, 2) var diff_idx := 1
## Juega solo (para vídeos y pruebas).
@export var autoplay := false

var level := {}
var p := {}
var boss := {}
var projs: Array = []
var waves: Array = []
var parts: Array = []
var floats: Array = []
var cam := Vector2.ZERO
var time := 0.0
var score := 0
var shake := 0.0
var hit_stop := 0.0
var arena_lock := false
var boss_intro := 0.0
var state := "playing"
var state_t := 0.0
var hint_txt := ""
var hint_t := 0.0
var _pressed := {}
var _camera: Camera2D
var _kael: SheetSprite
var _boss_proxy: Node
var _hud: Node
var _bg: Sprite2D
var _font: Font

# ---------------- arranque ----------------
func _ready() -> void:
	_font = ThemeDB.fallback_font
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	_camera.make_current()
	var bgl := CanvasLayer.new()
	bgl.layer = -10
	add_child(bgl)
	_bg = Sprite2D.new()
	_bg.texture = Aether.tex("pbg0")
	_bg.centered = false
	bgl.add_child(_bg)
	_kael = SheetSprite.new()
	_kael.unit_scale = 0.25
	_kael.z_index = 5
	add_child(_kael)
	_boss_proxy = preload("res://chronos/cr_boss_proxy.gd").new()
	add_child(_boss_proxy)
	Aether.player = self
	if "--autoplay" in OS.get_cmdline_user_args():
		autoplay = true
	start_stage(act)

func start_stage(a: int) -> void:
	act = a
	var gen := CrLevel.new()
	level = gen.build(0, act, diff_idx)
	var D: Dictionary = DIFFS[diff_idx]
	var st: Vector2 = level.start
	p = {"x": st.x, "y": st.y, "w": PW, "h": PH, "vx": 0.0, "vy": 0.0, "face": 1, "onGround": false, "ground": null, "jumps": 0,
		"coyote": 0.0, "buf": 0.0, "dashT": 0.0, "dashCD": 0.0, "atkT": 0.0, "atkCD": 0.0, "atkN": 0, "lastAtk": -9.0, "air": false,
		"hitSet": [], "pogoDone": false, "wall": 0, "wjLock": 0.0, "wjDir": 0, "inv": 0.0, "stun": 0.0, "hp": D.hp, "maxHp": D.hp,
		"noCut": false, "dead": false, "deadT": 0.0, "anim": 0.0, "respawn": st, "safe": st, "sq": 1.0, "look": 0.0, "combo": 0, "comboT": 0.0}
	boss = {}
	projs = []
	waves = []
	arena_lock = false
	boss_intro = 0.0
	state = "playing"
	time = 0.0
	hint_txt = ""
	_update_camera(0.0, true)
	hp_changed.emit(p.hp, p.maxHp)
	Aether.music("w0")
	var names := ["1-1 · EL DESPERTAR", "1-2 · LA JUNGLA FLOTANTE", "1-3 · GUARIDA DEL GRAN SAPO"]
	_banner(names[act])

func _banner(t: String) -> void:
	for h in get_tree().get_nodes_in_group("aether_hud"):
		h.banner(t, "")

# ---------------- utilidades ----------------
static func ov(a: Dictionary, b: Dictionary) -> bool:
	return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y

func _is_solid(s: Dictionary) -> bool:
	return s.k == "solid" or s.k == "move" or s.k == "bounce" or (s.k == "break" and s.get("st", 0) < 2)

func _is_wall(s: Dictionary) -> bool:
	return s.k == "solid" and not s.get("float", false)

func _ground_below(x: float, y: float, maxd := 12.0):
	for s in level.plats:
		if _is_solid(s) and x >= s.x and x <= s.x + s.w and s.y >= y - 4 and s.y - y < maxd:
			return s
	return null

func _burst(x: float, y: float, c: Color, n: int, sp := 160.0, gr := 300.0, life := 0.6, size := 2.0) -> void:
	for i in n:
		var a := randf() * TAU
		var v := randf() * sp
		parts.append({"x": x, "y": y, "vx": cos(a) * v, "vy": sin(a) * v, "life": life * randf_range(0.5, 1.0), "max": life, "c": c, "s": size + (1.0 if randf() < 0.3 else 0.0), "g": gr})
	if parts.size() > 600:
		parts = parts.slice(parts.size() - 600)

func _float(x: float, y: float, t: String, c := Color.WHITE, s := 18) -> void:
	floats.append({"x": x, "y": y, "t": t, "c": c, "life": 1.1, "s": s})

func _press(a: String) -> bool:
	return _pressed.get(a, false)

# ---------------- bucle ----------------
func _process(delta: float) -> void:
	var dt: float = min(delta, 1.0 / 30.0)
	if autoplay:
		_bot()
	for a in ["jump", "attack", "dash"]:
		_pressed[a] = Input.is_action_just_pressed(a)
	if hit_stop > 0.0:
		hit_stop -= dt
		queue_redraw()
		return
	time += dt
	if state == "playing":
		_update_plats(dt)
		_update_player(dt)
		_update_hazards(dt)
		_update_enemies(dt)
		_update_projs(dt)
		_update_boss(dt)
	elif state in ["clear", "gameover"]:
		state_t -= dt
		if state_t <= 0.0:
			if state == "clear":
				if act < 2:
					start_stage(act + 1)
				else:
					state = "victory"
					_banner("¡MUNDO 1 SUPERADO!")
			else:
				start_stage(act)
	_update_particles(dt)
	_update_camera(dt, false)
	shake = max(0.0, shake - dt * 30.0)
	if hint_t > 0.0:
		hint_t -= dt
	_update_kael()
	queue_redraw()

func _update_particles(dt: float) -> void:
	for q in parts.duplicate():
		q.life -= dt
		if q.life <= 0.0:
			parts.erase(q)
			continue
		q.vy += q.g * dt
		q.x += q.vx * dt
		q.y += q.vy * dt
		q.vx *= (1.0 - 2.5 * dt)
	for f in floats.duplicate():
		f.life -= dt
		f.y -= 30.0 * dt
		if f.life <= 0.0:
			floats.erase(f)

func _update_plats(dt: float) -> void:
	for s in level.plats:
		if s.k == "move":
			s.t += dt
			var u := (1.0 - cos(s.t * s.spd)) / 2.0
			var nx: float = lerp(float(s.ax), float(s.bx), u)
			var ny: float = lerp(float(s.ay), float(s.by), u)
			s.dx = nx - s.x
			s.dy = ny - s.y
			s.x = nx
			s.y = ny
		elif s.k == "bounce" and s.sq > 0.0:
			s.sq -= dt

func _update_hazards(_dt: float) -> void:
	for h in level.hazards:
		if h.k == "spike" and not p.dead and p.inv <= 0.0 and ov(p, {"x": h.x + 2, "y": h.y + 4, "w": h.w - 4, "h": h.h - 4}):
			_burst(p.x + p.w / 2, h.y, Color.WHITE, 8, 120, 300, 0.4)
			_hazard_respawn(15)

# ---------------- Kael ----------------
func _hurt(dmg: float, src_x: float) -> bool:
	if p.inv > 0.0 or p.dead:
		return false
	var D: Dictionary = DIFFS[diff_idx]
	p.hp -= dmg * D.dmg
	p.inv = 0.8
	p.stun = 0.28
	p.vx = (-1.0 if p.x + p.w / 2 < src_x else 1.0) * 340.0
	p.vy = -360.0
	p.noCut = true
	p.dashT = 0.0
	p.atkT = 0.0
	p.combo = 0
	shake = max(shake, 7.0)
	hit_stop = 0.07
	Aether.flash(Color(1, 0.25, 0.3), 0.25)
	Aether.sfx("hurt")
	_burst(p.x + p.w / 2, p.y + 18, Color(1, 0.25, 0.38), 10, 160, 300, 0.5)
	_float(p.x + p.w / 2, p.y - 8, "-%d" % roundi(dmg * D.dmg), Color(1, 0.33, 0.44))
	hp_changed.emit(max(0.0, p.hp), p.maxHp)
	if p.hp <= 0.0:
		_kill()
	return true

func _kill() -> void:
	p.hp = 0.0
	p.dead = true
	p.deadT = 1.3
	p.anim = 0.0
	shake = 14.0
	hit_stop = 0.2
	Aether.sfx("kill")
	_burst(p.x + p.w / 2, p.y + p.h / 2, Color(1, 0.25, 0.38), 24, 200, 300, 0.8)

func _hazard_respawn(dmg: float) -> void:
	var D: Dictionary = DIFFS[diff_idx]
	p.hp -= dmg * D.dmg
	shake = 8.0
	Aether.sfx("hurt")
	p.combo = 0
	hp_changed.emit(max(0.0, p.hp), p.maxHp)
	if p.hp <= 0.0:
		_kill()
		return
	var s: Vector2 = p.safe
	_float(s.x + p.w / 2, s.y - 10, "-%d" % roundi(dmg * D.dmg), Color(1, 0.33, 0.44))
	p.x = s.x
	p.y = s.y
	p.vx = 0.0
	p.vy = 0.0
	p.inv = 1.3
	p.dashT = 0.0
	p.ground = null
	p.onGround = false

func _attack_box() -> Dictionary:
	var w := 96.0 if p.atkN == 2 else 76.0
	return {"x": (p.x + p.w - 4 if p.face > 0 else p.x - w + 4), "y": p.y - (12.0 if p.atkN == 2 else 6.0), "w": w, "h": p.h + (18.0 if p.atkN == 2 else 8.0)}

func _down_box() -> Dictionary:
	return {"x": p.x - 16, "y": p.y + p.h - 8, "w": p.w + 32, "h": 44.0}

func _pogo() -> void:
	if p.pogoDone:
		return
	p.pogoDone = true
	p.vy = -560.0
	p.jumps = 1
	p.dashCD = 0.0
	p.noCut = true
	Aether.sfx("bounce", 0.7)
	hit_stop = max(hit_stop, 0.04)
	_burst(p.x + p.w / 2, p.y + p.h + 8, Color.WHITE, 8, 140, 200, 0.3)

func _update_player(dt: float) -> void:
	p.anim += dt
	if p.dead:
		p.deadT -= dt
		if p.deadT <= 0.0:
			state = "gameover"
			state_t = 1.6
			_banner("¡HAS CAÍDO!")
		return
	p.sq = lerp(float(p.sq), 1.0, min(1.0, dt * 12.0))
	p.inv = max(0.0, p.inv - dt)
	p.dashCD = max(0.0, p.dashCD - dt)
	p.atkCD -= dt
	p.wjLock -= dt
	if p.comboT > 0.0:
		p.comboT -= dt
		if p.comboT <= 0.0:
			p.combo = 0
	if p.onGround and p.ground != null and p.ground.k == "move":
		p.x += p.ground.dx
		p.y += p.ground.dy
	var dir := Input.get_axis("left", "right")
	dir = 0.0 if abs(dir) < 0.3 else signf(dir)
	if p.wjLock > 0.0:
		dir = p.wjDir
	if p.stun > 0.0:
		p.stun -= dt
	var ctrl: bool = p.stun <= 0.0
	if ctrl and dir != 0.0 and p.dashT <= 0.0 and p.atkT <= 0.0:
		p.face = int(dir)
	if _press("jump"):
		p.buf = 0.13
	else:
		p.buf -= dt
	if p.onGround:
		p.coyote = 0.12
	else:
		p.coyote -= dt
	if ctrl and _press("dash") and p.dashCD <= 0.0:
		if dir != 0.0:
			p.face = int(dir)
		p.dashT = 0.17
		p.dashCD = 0.7
		p.inv = max(p.inv, 0.17)
		p.vy = 0.0
		p.atkT = 0.0
		p.wall = 0
		Aether.sfx("dash", 0.6)
	if p.dashT > 0.0:
		p.dashT -= dt
		p.vx = p.face * DASH
		p.vy = 0.0
		if p.dashT <= 0.0:
			p.vx = p.face * MOVE
	else:
		var atk_slow := 0.35 if (p.atkT > 0.0 and p.onGround) else 1.0
		var accel := 2600.0 if p.onGround else 1800.0
		if not ctrl:
			p.vx = move_toward(p.vx, 0.0, 600.0 * dt)
		else:
			p.vx = move_toward(p.vx, dir * MOVE * atk_slow, accel * dt)
		if ctrl and p.buf > 0.0:
			if p.coyote > 0.0:
				p.vy = -JUMP
				p.jumps = 1
				p.coyote = 0.0
				p.buf = 0.0
				p.onGround = false
				p.ground = null
				p.noCut = false
				p.sq = 1.18
				Aether.sfx("jump", 0.5)
			elif p.wall != 0:
				p.vy = -JUMP * 0.95
				p.vx = -p.wall * 330.0
				p.face = -p.wall
				p.wjDir = -p.wall
				p.wjLock = 0.16
				p.jumps = 1
				p.buf = 0.0
				p.noCut = false
				Aether.sfx("jump", 0.6, 1.2)
				p.wall = 0
			elif p.jumps < 2:
				p.vy = -JUMP * 0.92
				p.jumps = 2
				p.buf = 0.0
				p.noCut = false
				p.sq = 1.14
				Aether.sfx("dj", 0.5)
				_burst(p.x + p.w / 2, p.y + p.h, Color(0.75, 0.96, 1), 10, 120, 0, 0.35)
		var gr := GRAV
		if p.vy >= 0.0:
			p.noCut = false
		if not Input.is_action_pressed("jump") and p.vy < 0.0 and not p.noCut:
			gr *= 2.3
		if Input.is_action_pressed("jump") and abs(p.vy) < 90.0:
			gr *= 0.55
		if p.vy > 0.0:
			gr *= 1.12
		p.vy = min(p.vy + gr * dt, 110.0 if (p.wall != 0 and p.vy > 0.0) else 900.0)
	if ctrl and _press("attack") and p.atkCD <= 0.0 and p.dashT <= 0.0:
		p.air = not p.onGround
		p.atkN = (p.atkN + 1) % 3 if (not p.air and time - p.lastAtk < 0.6) else 0
		p.lastAtk = time
		p.atkT = 0.38 if p.atkN == 2 else 0.3
		p.atkCD = 0.42 if p.atkN == 2 else 0.24
		p.hitSet = []
		p.pogoDone = false
		if p.atkN == 2:
			p.vx += p.face * 220.0
			Aether.sfx("swing", 1.0, 0.75)
		else:
			Aether.sfx("swing", 0.7, 1.12 if p.atkN else 1.0)
		if p.air and p.vy > 0.0:
			p.vy *= 0.4
	if p.atkT > 0.0:
		p.atkT -= dt
		if p.atkT < 0.24 and p.atkT > 0.04:
			_do_attack()
	_move_and_collide(dt)
	_pickups()

func _move_and_collide(dt: float) -> void:
	var sol: Array = []
	for s in level.plats:
		if _is_solid(s):
			sol.append(s)
	p.x += p.vx * dt
	var touch_wall := 0
	for s in sol:
		if not _is_wall(s):
			continue
		if p.x < s.x + s.w and p.x + p.w > s.x and p.y + p.h > s.y + 2 and p.y < s.y + s.h - 2:
			if p.y + p.h - s.y <= 12 and p.vy >= -50:
				p.y = s.y - p.h
				continue
			if p.x + p.w / 2 < s.x + s.w / 2:
				p.x = s.x - p.w
				touch_wall = 1
			else:
				p.x = s.x + s.w
				touch_wall = -1
			if p.dashT <= 0.0:
				p.vx = 0.0
	if touch_wall == 0 and not p.onGround:
		for s in sol:
			if not _is_wall(s) or p.y + p.h <= s.y + 6 or p.y >= s.y + s.h:
				continue
			if abs(p.x + p.w - s.x) < 2:
				touch_wall = 1
			elif abs(p.x - (s.x + s.w)) < 2:
				touch_wall = -1
	var prev_y: float = p.y
	var was_ground: bool = p.onGround
	var fall_speed: float = p.vy
	p.y += p.vy * dt
	p.onGround = false
	var land = null
	for s in sol:
		if p.x < s.x + s.w and p.x + p.w > s.x and p.y + p.h > s.y and p.y < s.y + s.h:
			var tol: float = 8.0 + abs(float(s.get("dy", 0.0)))
			if p.vy >= 0.0 and prev_y + p.h <= s.y + tol:
				p.y = s.y - p.h
				p.vy = 0.0
				land = s
			elif p.vy < 0.0 and _is_wall(s) and prev_y >= s.y + s.h - tol:
				var o_l: float = p.x + p.w - s.x
				var o_r: float = s.x + s.w - p.x
				if o_l <= 8:
					p.x = s.x - p.w
					continue
				if o_r <= 8:
					p.x = s.x + s.w
					continue
				p.y = s.y + s.h
				p.vy = 0.0
	var pushing: bool = touch_wall != 0 and ((touch_wall > 0 and Input.is_action_pressed("right")) or (touch_wall < 0 and Input.is_action_pressed("left")))
	var new_wall: int = touch_wall if (land == null and touch_wall != 0 and (pushing or p.wall == touch_wall) and p.dashT <= 0.0) else 0
	if new_wall != 0 and p.wall == 0:
		p.jumps = 1
	p.wall = new_wall
	if land != null:
		if not was_ground and fall_speed > 380:
			p.sq = 0.8
			Aether.sfx("step", 0.45)
		p.onGround = true
		p.ground = land
		p.jumps = 0
		if land.k == "bounce":
			p.vy = -1000.0
			p.onGround = false
			p.ground = null
			p.jumps = 1
			p.noCut = true
			land.sq = 0.3
			Aether.sfx("bounce", 0.8)
			_burst(land.x + land.w / 2, land.y, Color(1, 0.48, 0.69), 12, 140, 300, 0.5)
		elif land.k == "solid":
			var cx: float = p.x + p.w / 2
			var near := false
			for h in level.hazards:
				if abs(h.x + h.w / 2 - cx) < h.w / 2 + 50:
					near = true
			if not near and cx > land.x + 12 and cx < land.x + land.w - 12:
				p.safe = Vector2(p.x, p.y)
	else:
		p.ground = null
	p.x = clamp(p.x, 0.0, level.width - p.w)
	var A: Dictionary = level.arena
	if arena_lock:
		p.x = clamp(p.x, A.x1, A.x2 - p.w)
	if p.y > level.deathY:
		_hazard_respawn(20)

func _pickups() -> void:
	for gm in level.gems:
		if gm.taken:
			continue
		if p.x < gm.x + 9 and p.x + p.w > gm.x - 9 and p.y < gm.y + 9 and p.y + p.h > gm.y - 9:
			gm.taken = true
			score += 100
			Aether.sfx("gem", 0.45)
			_float(gm.x, gm.y - 12, "+100", Color(1, 0.9, 0.4), 16)
			_burst(gm.x, gm.y, Color(1, 0.95, 0.5), 6, 90, 0, 0.35)
	for c in level.cherries:
		if c.taken:
			continue
		if p.x < c.x + 10 and p.x + p.w > c.x - 10 and p.y < c.y + 10 and p.y + p.h > c.y - 10:
			var hv := 12.0 if diff_idx >= 1 else 20.0
			c.taken = true
			p.hp = min(p.maxHp, p.hp + hv)
			score += 50
			Aether.sfx("heal", 0.5)
			_float(c.x, c.y - 12, "+%d VIDA" % hv, Color(1, 0.48, 0.69), 16)
			hp_changed.emit(p.hp, p.maxHp)
	for c in level.checks:
		if not c.on and ov(p, c):
			c.on = true
			p.respawn = Vector2(c.x, c.y + c.h - p.h)
			p.safe = p.respawn
			p.hp = min(p.maxHp, p.hp + (0.0 if diff_idx >= 2 else (15.0 if diff_idx == 1 else 10.0)))
			hp_changed.emit(p.hp, p.maxHp)
			Aether.sfx("check", 0.6)
			_float(c.x + 12, c.y - 18, Aether.t("PUNTO DE CONTROL"), Color(0.6, 1, 0.69), 16)
			_burst(c.x + 12, c.y + 6, Color(0.6, 1, 0.69), 16, 140, 60, 0.8)
	for h in level.hints:
		if not h.shown and p.x > h.x and p.x < h.x + 400 and HINTS.has(h.k):
			h.shown = true
			hint_txt = HINTS[h.k]
			hint_t = 5.5
	var gl: Dictionary = level.goal
	if not gl.is_empty() and ov(p, gl):
		_stage_clear()
	var A: Dictionary = level.arena
	if not A.is_empty() and not arena_lock and p.x > A.x1 + 90:
		arena_lock = true
		p.respawn = Vector2(A.x1 + 60, A.floor - p.h)
		p.safe = p.respawn
		_spawn_boss()
		boss_intro = 2.8
		Aether.music("boss")
		Aether.sfx("roar", 0.8)
		shake = 8.0

func _stage_clear() -> void:
	if state != "playing":
		return
	state = "clear"
	state_t = 2.6
	Aether.sfx("win", 0.9)
	Aether.slowmo(0.35, 0.8)
	Aether.flash(Color(1, 0.95, 0.7), 0.4)
	_banner("¡FASE SUPERADA!")
	for i in 3:
		_burst(p.x + randf_range(-80, 80), p.y - randf_range(40, 120), Color.from_hsv(randf(), 0.6, 1.0), 30, 260, 120, 1.2, 3)

func _do_attack() -> void:
	var hb := _attack_box()
	_hit_enemies(hb)
	if p.air:
		var db := _down_box()
		if _hit_enemies(db):
			_pogo()
		for h in level.hazards:
			if h.k == "spike" and ov(db, h):
				_pogo()
				break
		if not boss.is_empty() and not boss.dying and boss_intro <= 0.0 and ov(db, boss) and not p.hitSet.has("boss"):
			_hit_boss(db)
			_pogo()
	for q in projs.duplicate():
		if ov(hb, {"x": q.x - q.hw, "y": q.y - q.hh, "w": q.hw * 2, "h": q.hh * 2}):
			projs.erase(q)
			score += 10
			Aether.sfx("clang", 0.5)
			_float(q.x, q.y - 10, "PARRY", Color(0.2, 0.89, 1), 15)
	if not boss.is_empty() and not boss.dying and not boss.done and boss_intro <= 0.0 and not p.hitSet.has("boss") and ov(hb, boss):
		_hit_boss(hb)

func _hit_enemies(hb: Dictionary) -> bool:
	var hit := false
	for e in level.enemies:
		if not e.dead and not p.hitSet.has(e) and ov(hb, e):
			p.hitSet.append(e)
			_damage_enemy(e, hb)
			hit = true
	return hit

func _slash_fx(hb: Dictionary) -> void:
	var cx: float = hb.x + hb.w / 2
	var cy: float = hb.y + hb.h * 0.45
	for i in 10:
		var a := (randf() - 0.5) * 1.2
		var v := randf_range(160, 380)
		parts.append({"x": cx, "y": cy, "vx": cos(a) * v * p.face, "vy": sin(a) * v - 40, "life": randf_range(0.15, 0.3), "max": 0.3, "c": (Color.WHITE if i % 3 else Color(1, 0.9, 0.5)), "s": 2.0, "g": 300.0})

func _damage_enemy(e: Dictionary, hb: Dictionary) -> void:
	e.hp -= 1.6 if p.atkN == 2 else 1.0
	e.hit = 0.15
	if p.atkN == 2:
		hit_stop = max(hit_stop, 0.07)
	hit_stop = max(hit_stop, 0.045)
	Aether.sfx("hit", 0.8)
	_slash_fx(hb)
	p.combo += 1
	p.comboT = 2.5
	if e.b != "flyer":
		e.kx = p.face * 220.0
	else:
		e.x += p.face * 10.0
	if e.hp <= 0.01:
		e.dead = true
		score += 50
		Aether.sfx("kill", 0.6)
		_burst(e.x + e.w / 2, e.y + e.h / 2, Color(0.9, 0.9, 1), 16, 160, 100, 0.5, 3)
		_float(e.x + e.w / 2, e.y - 8, "+50", Color(1, 0.9, 0.4), 16)
		if randf() < 0.05:
			level.cherries.append({"x": e.x + e.w / 2, "y": e.y + e.h - 14, "taken": false, "ph": 0.0})

# ---------------- enemigos ----------------
func _shoot(e: Dictionary, tx: float, ty: float) -> void:
	var D: Dictionary = DIFFS[diff_idx]
	var cx: float = e.x + e.w / 2
	var cy: float = e.y + e.h / 2
	var d := Vector2(tx - cx, ty - cy)
	var l: float = max(1.0, d.length())
	var sp: float = 210.0 * D.spd
	projs.append({"x": cx, "y": cy, "vx": d.x / l * sp, "vy": d.y / l * sp, "hw": 5.0, "hh": 5.0, "type": "orb", "dmg": 12.0, "life": 4.0})

func _update_enemies(dt: float) -> void:
	var D: Dictionary = DIFFS[diff_idx]
	var pcx: float = p.x + p.w / 2
	var pcy: float = p.y + p.h / 2
	for e in level.enemies:
		if e.dead:
			continue
		e.hit = max(0.0, e.hit - dt)
		e.t += dt
		if abs(e.x - cam.x - VW / 2) > 900:
			continue
		var cx: float = e.x + e.w / 2
		var dx: float = pcx - cx
		var dy: float = pcy - (e.y + e.h / 2)
		var adx: float = abs(dx)
		if e.kx != 0.0:
			var nx: float = e.x + e.kx * dt
			if _ground_below(nx + e.w if e.kx > 0 else nx, e.y + e.h, 14) != null or e.air:
				e.x = nx
			e.kx *= max(0.0, 1.0 - 9.0 * dt)
			if abs(e.kx) < 8:
				e.kx = 0.0
		match e.b:
			"walker":
				if e.hit <= 0.0:
					e.x += e.dir * float(e.d.spd) * D.spd * dt
				if e.x < e.minX:
					e.x = e.minX
					e.dir = 1
				if e.x > e.maxX:
					e.x = e.maxX
					e.dir = -1
			"jumper":
				if not e.air:
					e.cd -= dt
					e.dir = 1 if dx > 0 else -1
					if e.cd <= 0.0 and adx < 320:
						e.air = true
						e.vy = -430.0
						e.vx = e.dir * 130.0 * D.spd
						e.cd = randf_range(1.1, 1.8) / D.aggr
				else:
					e.vy += 1400.0 * dt
					var ny: float = e.y + e.vy * dt
					var nx2: float = e.x + e.vx * dt
					var gnd = _ground_below(nx2 + e.w / 2, ny + e.h, 16) if e.vy > 0 else null
					if gnd != null and e.y + e.h <= gnd.y + 4:
						e.y = gnd.y - e.h
						e.air = false
						e.vy = 0.0
					else:
						e.y = ny
						if _ground_below(nx2 + e.w / 2, e.y + e.h, 400) != null or e.vy < 0:
							e.x = nx2
					if e.y > level.deathY:
						e.dead = true
			"flyer":
				var ox: float = e.x
				e.x = e.x0 + sin(e.t * 1.2) * 60.0
				e.y = e.y0 + sin(e.t * 2.3) * 18.0
				e.dir = 1 if e.x >= ox else -1
				e.cd -= dt
				if e.cd <= 0.0 and Vector2(dx, dy).length() < 400 and not p.dead:
					e.cd = randf_range(2.2, 3.2) / D.aggr
					_shoot(e, pcx, pcy)
					Aether.sfx("swing", 0.25, 1.5)
		if not p.dead and ov(p, e):
			_hurt(12.0 if e.b == "flyer" else 15.0, e.x + e.w / 2)

func _update_projs(dt: float) -> void:
	for q in projs.duplicate():
		q.life -= dt
		q.x += q.vx * dt
		q.y += q.vy * dt
		var rem: bool = q.life <= 0.0
		var rr := {"x": q.x - q.hw, "y": q.y - q.hh, "w": q.hw * 2, "h": q.hh * 2}
		if not rem and not p.dead and ov(rr, p):
			if _hurt(q.dmg, q.x):
				rem = true
		if rem:
			projs.erase(q)
	var A: Dictionary = level.arena
	for w in waves.duplicate():
		w.x += w.dir * w.spd * dt
		if A.is_empty() or w.x < A.x1 - 30 or w.x > A.x2 + 30:
			waves.erase(w)
			continue
		if not p.dead and ov(p, {"x": w.x - 12, "y": w.y - 30, "w": 24.0, "h": 30.0}):
			_hurt(18.0, w.x - w.dir * 50)
		if randf() < 0.7:
			parts.append({"x": w.x + randf_range(-8, 8), "y": w.y - 2, "vx": -w.dir * randf_range(20, 80), "vy": randf_range(-180, -60), "life": 0.4, "max": 0.4, "c": (Color(0.78, 0.63, 0.44) if randf() < 0.5 else Color(0.6, 0.86, 0.35)), "s": 3.0, "g": 600.0})

# ---------------- Gran Sapo Ancestral ----------------
func _spawn_boss() -> void:
	var A: Dictionary = level.arena
	var D: Dictionary = DIFFS[diff_idx]
	boss = {"w": 116.0, "h": 92.0, "x": A.x2 - 260, "y": A.floor - 92, "vx": 0.0, "vy": 0.0, "st": "idle", "t": 0.0, "face": -1, "anim": 0.0, "hit": 0.0, "dying": false, "done": false, "dieT": 0.0}
	boss.max = round(14 * D.boss)
	boss.hp = boss.max
	for e in level.enemies:
		if e.x > A.x1 - 300:
			e.dead = true
	_boss_proxy.activate("GRAN SAPO ANCESTRAL", boss.max)

func _hit_boss(hb: Dictionary) -> void:
	p.hitSet.append("boss")
	var dmg := 1.6 if p.atkN == 2 else 1.0
	boss.hp -= dmg
	boss.hit = 0.12
	score += 25
	hit_stop = 0.06
	_slash_fx(hb)
	Aether.sfx("hit")
	shake = max(shake, 5.0)
	_boss_proxy.set_hp(max(0.0, boss.hp), boss.max)
	if boss.hp <= 0.01:
		boss.hp = 0.0
		boss.dying = true
		boss.dieT = 2.8
		projs = []
		waves = []
		Aether.sfx("boom")
		shake = 20.0
		hit_stop = 0.3
		Aether.flash(Color.WHITE, 0.4)
		Aether.slowmo(0.3, 1.0)

func _update_boss(dt: float) -> void:
	if boss.is_empty() or boss.done:
		return
	var D: Dictionary = DIFFS[diff_idx]
	var A: Dictionary = level.arena
	var b := boss
	b.hit = max(0.0, b.hit - dt)
	b.anim += dt
	if b.dying:
		b.dieT -= dt
		if randf() < 0.25:
			_burst(b.x + randf() * b.w, b.y + randf() * b.h, Color(0.9, 0.95, 0.8), 10, 160, 100, 0.6, 3)
			shake = max(shake, 5.0)
			Aether.sfx("boom", 0.4)
		if b.dieT <= 0.0:
			b.done = true
			_burst(b.x + b.w / 2, b.y + b.h / 2, Color.WHITE, 50, 380, 100, 1.2, 3)
			_stage_clear()
		return
	if boss_intro > 0.0:
		boss_intro -= dt
		if boss_intro <= 0.0:
			hint_txt = Aether.t("¡Salta las ondas de choque!")
			hint_t = 3.0
		return
	b.t += dt
	var pcx: float = p.x + p.w / 2
	var bcx: float = b.x + b.w / 2
	var ag: float = D.aggr * (1.2 if b.hp <= b.max / 2 else 1.0)
	if b.st != "air":
		b.face = -1 if pcx < bcx else 1
	if b.st == "idle":
		if b.t > 1.2 / ag:
			b.st = "crouch"
			b.t = 0.0
	elif b.st == "crouch":
		if b.t > 0.45:
			b.st = "air"
			b.t = 0.0
			var tx: float = clamp(pcx - b.w / 2, A.x1 + 10, A.x2 - b.w - 10)
			b.vx = (tx - b.x) / 1.0
			b.vy = -900.0
			Aether.sfx("jump", 0.9, 0.55)
	elif b.st == "air":
		b.vy += 1800.0 * dt
		b.x += b.vx * dt
		b.y += b.vy * dt
		b.x = clamp(b.x, A.x1 + 10, A.x2 - b.w - 10)
		if b.vy > 0 and b.y + b.h >= A.floor:
			b.y = A.floor - b.h
			b.st = "idle"
			b.t = 0.0
			shake = 16.0
			Aether.sfx("stomp")
			Aether.sfx("boom", 0.6)
			var cx: float = b.x + b.w / 2
			var sp: float = 340.0 * ag
			waves.append({"x": cx - 56, "y": A.floor, "dir": -1.0, "spd": sp})
			waves.append({"x": cx + 56, "y": A.floor, "dir": 1.0, "spd": sp})
	if not p.dead and ov(p, b):
		_hurt(20.0, bcx)

# ---------------- cámara ----------------
func _update_camera(dt: float, snap: bool) -> void:
	var tx := 0.0
	var ty := 0.0
	var A: Dictionary = level.arena
	if arena_lock:
		var span: float = A.x2 - A.x1 + 80
		if VW >= span:
			tx = A.x1 - 40 - (VW - span) / 2
		else:
			var focus: float = p.x + p.w / 2
			if not boss.is_empty() and not boss.done:
				focus = lerp(focus, float(boss.x + boss.w / 2), 0.7 if boss_intro > 0 else 0.35)
			tx = clamp(focus - VW / 2, A.x1 - 40, A.x2 + 40 - VW)
		ty = A.floor - VH + 56
	else:
		p.look = p.face * 60.0 if snap else lerp(float(p.look), p.face * 60.0 + p.vx * 0.12, min(1.0, dt * 2.5))
		tx = clamp(p.x + p.w / 2 - VW / 2 + p.look, 0.0, level.width - VW)
		ty = clamp(p.y + p.h / 2 - VH * 0.58, level.top, level.bottom - VH)
	if snap:
		cam = Vector2(tx, ty)
	else:
		cam.x = lerp(cam.x, tx, min(1.0, dt * 7.0))
		cam.y = lerp(cam.y, ty, min(1.0, dt * 5.0))
	var vs := get_viewport_rect().size
	var z: float = vs.y / VH
	_camera.zoom = Vector2(z, z)
	var sh := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 0.4
	_camera.position = cam - Vector2((vs.x / z - VW) / 2, 0) + sh
	if _bg and _bg.texture:
		var k: float = vs.y * 1.15 / _bg.texture.get_height()
		_bg.scale = Vector2(k, k)
		var w: float = _bg.texture.get_width() * k - vs.x
		_bg.position = Vector2(-fmod(cam.x * 0.25 * z, max(1.0, w)), -vs.y * 0.1)

# ---------------- dibujo de Kael (hojas HD) ----------------
func _update_kael() -> void:
	var k := "KH_idle"
	var fps := 10.0
	var loop := true
	if p.dead:
		k = "KH_death"
		loop = false
	elif p.stun > 0.0:
		k = "KH_hurt"
	elif p.dashT > 0.0:
		k = "KH_dash"
		fps = 24.0
	elif p.atkT > 0.0:
		k = ["KH_atk1", "KH_atk2", "KH_atk3"][p.atkN] if not p.air else "KH_airslash"
		fps = 26.0
		loop = false
	elif p.wall != 0:
		k = "KH_wall"
	elif not p.onGround:
		k = "KH_jump" if p.vy < 0 else "KH_fallU"
		fps = 14.0
	elif abs(p.vx) > 30:
		k = "KH_run"
		fps = 26.0
	_kael.play(k, fps, loop)
	var face: int = -p.wall if p.wall != 0 else p.face
	var sy: float = p.sq
	_kael.position = Vector2(p.x + p.w / 2, p.y + p.h + 2)
	_kael.scale = Vector2(0.25 * face / sqrt(sy), 0.25 * sy)
	_kael.visible = p.dead or p.inv <= 0.0 or p.dashT > 0.0 or int(time * 20) % 2 != 0
	_kael.modulate = Color(3, 3, 3) if p.stun > 0.2 else Color.WHITE

# ---------------- dibujo del mundo ----------------
func _draw() -> void:
	var tx := Aether.tex("tx0")
	var ed := Aether.tex("ed0")
	for s in level.plats:
		if s.x > cam.x + VW + 300 or s.x + s.w < cam.x - 300:
			continue
		var r := Rect2(s.x, s.y, s.w, min(float(s.h), 320.0))
		match s.k:
			"solid":
				if tx:
					draw_texture_rect_region(tx, r, Rect2(s.x * 3.0, s.y * 3.0, r.size.x * 3.0, r.size.y * 3.0), Color(0.95, 0.95, 0.95))
				else:
					draw_rect(r, Color(0.35, 0.25, 0.2))
				if ed:
					var eh: float = 15.0
					draw_texture_rect_region(ed, Rect2(s.x, s.y - 4, s.w, eh), Rect2(s.x * 3.0, 0, s.w * 3.0, ed.get_height()))
				else:
					draw_rect(Rect2(s.x, s.y, s.w, 5), Color(0.45, 0.8, 0.3))
				draw_rect(Rect2(s.x, s.y + r.size.y - 30, s.w, 30), Color(0, 0, 0, 0.25))
			"move":
				draw_rect(r, Color(0.55, 0.42, 0.3))
				draw_rect(Rect2(s.x, s.y, s.w, 4), Color(0.6, 0.9, 0.4))
			"bounce":
				var sq: float = clamp(float(s.sq) / 0.3, 0.0, 1.0)
				draw_rect(Rect2(s.x + 4, s.y + 4 + sq * 5, s.w - 8, s.h - 4 - sq * 5), Color(1, 0.45, 0.65))
				draw_rect(Rect2(s.x, s.y + sq * 5, s.w, 5), Color(1, 0.8, 0.9))
	for h in level.hazards:
		if h.k == "spike":
			var n: int = int(h.w / 12)
			for i in n:
				var bx: float = h.x + i * 12
				draw_colored_polygon(PackedVector2Array([Vector2(bx, h.y + 12), Vector2(bx + 6, h.y), Vector2(bx + 12, h.y + 12)]), Color(0.85, 0.85, 0.9))
	for c in level.checks:
		var col := Color(0.6, 1, 0.69) if c.on else Color(0.6, 0.6, 0.7)
		draw_rect(Rect2(c.x + 10, c.y, 4, c.h), Color(0.4, 0.3, 0.25))
		draw_colored_polygon(PackedVector2Array([Vector2(c.x + 14, c.y + 2), Vector2(c.x + 30, c.y + 9), Vector2(c.x + 14, c.y + 16)]), col)
	var gl: Dictionary = level.goal
	if not gl.is_empty():
		var pulse := 0.6 + sin(time * 4) * 0.2
		draw_rect(Rect2(gl.x, gl.y, gl.w, gl.h), Color(0.4, 0.9, 1, 0.25 * pulse))
		draw_arc(Vector2(gl.x + gl.w / 2, gl.y + gl.h / 2), 26 + sin(time * 3) * 3, 0, TAU, 32, Color(0.6, 0.95, 1, pulse), 3)
	for gm in level.gems:
		if gm.taken:
			continue
		var y: float = gm.y + sin(time * 3 + gm.ph) * 2
		draw_colored_polygon(PackedVector2Array([Vector2(gm.x, y - 7), Vector2(gm.x + 6, y), Vector2(gm.x, y + 7), Vector2(gm.x - 6, y)]), Color(1, 0.85, 0.3))
		draw_circle(Vector2(gm.x - 1.5, y - 2), 1.5, Color.WHITE)
	for c in level.cherries:
		if not c.taken:
			draw_circle(Vector2(c.x - 3, c.y + 2), 4, Color(0.95, 0.2, 0.35))
			draw_circle(Vector2(c.x + 4, c.y + 3), 4, Color(0.95, 0.2, 0.35))
	for e in level.enemies:
		if e.dead or e.x > cam.x + VW + 100 or e.x + e.w < cam.x - 100:
			continue
		_draw_enemy(e)
	if not boss.is_empty() and not boss.done:
		_draw_boss()
	for w in waves:
		draw_colored_polygon(PackedVector2Array([Vector2(w.x - 14, w.y), Vector2(w.x, w.y - 26), Vector2(w.x + 14, w.y)]), Color(0.75, 0.62, 0.42, 0.85))
	for q in projs:
		draw_circle(Vector2(q.x, q.y), 7, Color(1, 0.5, 0.9, 0.35))
		draw_circle(Vector2(q.x, q.y), 4, Color(1, 0.75, 1))
	for q in parts:
		var a: float = clamp(q.life / q.max * 1.5, 0.0, 1.0)
		var c: Color = q.c
		draw_rect(Rect2(q.x, q.y, q.s, q.s), Color(c.r, c.g, c.b, a))
	if p.atkT > 0.0 and p.atkT < 0.24:
		var t: float = (0.24 - p.atkT) / 0.2
		draw_arc(Vector2(p.x + p.w / 2, p.y + p.h * 0.45), 30, (-1.2 if p.face > 0 else PI - 1.2) + t * 0.4, (1.2 if p.face > 0 else PI + 1.2), 16, Color(0.85, 0.97, 1, 1.0 - t), 3)
	for f in floats:
		var al: float = clamp(f.life / 0.4, 0.0, 1.0)
		draw_string_outline(_font, Vector2(f.x - 60, f.y), f.t, HORIZONTAL_ALIGNMENT_CENTER, 120, int(f.s * 0.7), 3, Color(0, 0, 0, al))
		draw_string(_font, Vector2(f.x - 60, f.y), f.t, HORIZONTAL_ALIGNMENT_CENTER, 120, int(f.s * 0.7), Color(f.c.r, f.c.g, f.c.b, al))
	if hint_t > 0.0 and hint_txt != "":
		var al2: float = clamp(hint_t, 0.0, 1.0)
		var hp := cam + Vector2(VW / 2 - 200, VH - 40)
		draw_rect(Rect2(hp.x - 8, hp.y - 16, 416, 26), Color(0, 0, 0, 0.55 * al2))
		draw_string(_font, hp, Aether.t(hint_txt), HORIZONTAL_ALIGNMENT_CENTER, 400, 13, Color(1, 1, 1, al2))

func _sheet_frame(key: String, frame: int, pos: Vector2, flip: bool, scale_k := 1.0, mod := Color.WHITE) -> void:
	var t := Aether.tex(key)
	var m: Dictionary = Aether.sheet(key)
	if t == null or m.is_empty():
		return
	var n: int = int(m.get("n", 1))
	var fw: float = m.get("fw", t.get_width())
	var fh: float = m.get("fh", t.get_height())
	var f: int = posmod(frame, n)
	var ax: float = m.get("ax", fw / 2)
	var ay: float = m.get("ay", fh)
	var src := Rect2(f * fw, 0, fw, fh)
	var w := fw * scale_k
	var h := fh * scale_k
	var x := pos.x - (fw - ax if flip else ax) * scale_k
	var dst := Rect2(x, pos.y - ay * scale_k, w, h)
	if flip:
		dst = Rect2(x + w, dst.position.y, -w, h)
	draw_texture_rect_region(t, dst, src, mod)

func _draw_enemy(e: Dictionary) -> void:
	var d: Dictionary = e.d
	var key: String = d.anim
	if e.b == "jumper" and e.air:
		key = d.get("jump", key)
	var fr := int(e.t * 10)
	var flip: bool = (e.dir > 0) == (d.face < 0)
	var mod := Color(3, 3, 3) if e.hit > 0.0 else Color.WHITE
	var sq := 1.0 + (0.12 if e.hit > 0.0 else 0.0)
	_sheet_frame(key, fr, Vector2(e.x + e.w / 2, e.y + e.h + (2 if e.b != "flyer" else 10)), flip, sq, mod)

func _draw_boss() -> void:
	var b := boss
	var t := Aether.tex("hdb_frog")
	var mod := Color(3, 3, 3) if b.hit > 0.0 else Color.WHITE
	if b.dying:
		mod.a = clamp(b.dieT / 2.8, 0.0, 1.0)
	var crouch := 0.0
	if b.st == "crouch":
		crouch = min(1.0, b.t / 0.45)
	var sx := 1.0 + crouch * 0.12
	var sy := 1.0 - crouch * 0.18
	if b.st == "air":
		sy = 1.12
		sx = 0.92
	var breathe := 1.0 + sin(b.anim * 3.0) * 0.02
	var w: float = b.w * 1.35 * sx
	var h: float = b.h * 1.35 * sy * breathe
	var base := Vector2(b.x + b.w / 2, b.y + b.h + 4)
	draw_circle(Vector2(base.x, b.y + b.h + 2 if b.st != "air" else level.arena.floor + 2), b.w * 0.45, Color(0, 0, 0, 0.25))
	if t:
		var r := Rect2(base.x - w / 2, base.y - h, w, h)
		if b.face > 0:
			r = Rect2(base.x + w / 2, base.y - h, -w, h)
		draw_texture_rect(t, r, false, mod)
	else:
		draw_rect(Rect2(b.x, b.y, b.w, b.h), Color(0.3, 0.6, 0.3))

# ---------------- jugador automático (vídeos y pruebas) ----------------
var _bot_jump_t := 0.0
func _bot() -> void:
	if state != "playing" or p.is_empty() or p.dead:
		for a in ["right", "left", "jump", "attack", "dash"]:
			Input.action_release(a)
		return
	var want_right := true
	if arena_lock and not boss.is_empty():
		want_right = boss.x + boss.w / 2 > p.x + p.w / 2
	Input.action_press("right" if want_right else "left")
	Input.action_release("left" if want_right else "right")
	var ahead: float = p.x + p.w / 2 + (40.0 if want_right else -40.0)
	var gap: bool = p.onGround and _ground_below(ahead, p.y + p.h, 40) == null
	var wall := false
	for s in level.plats:
		if _is_wall(s) and abs(s.x - (p.x + p.w)) < 24 and s.y < p.y + p.h - 4 and s.y + s.h > p.y:
			wall = true
	var foe := false
	for e in level.enemies:
		if not e.dead and abs(e.x + e.w / 2 - (p.x + p.w / 2)) < 70 and abs(e.y - p.y) < 60:
			foe = true
	if not boss.is_empty() and not boss.dying and abs(boss.x + boss.w / 2 - (p.x + p.w / 2)) < 90:
		foe = true
	_bot_jump_t -= get_process_delta_time()
	if (gap or wall or p.wall != 0) and _bot_jump_t <= 0.0:
		Input.action_press("jump")
		_bot_jump_t = 0.25
	elif not p.onGround and p.vy > 50 and p.jumps < 2 and _bot_jump_t <= 0.0:
		Input.action_press("jump")
		_bot_jump_t = 0.3
	elif _bot_jump_t < 0.12:
		Input.action_release("jump")
	if foe and int(time * 8) % 2 == 0:
		Input.action_press("attack")
	else:
		Input.action_release("attack")
	if gap and p.dashCD <= 0.0 and randf() < 0.05:
		Input.action_press("dash")
	else:
		Input.action_release("dash")
