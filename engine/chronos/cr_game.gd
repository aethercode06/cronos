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
## Vista del mundo igual que el juego web: 270 de alto explorando, 420 en la arena.
var VW := 480.0
var VH := 270.0
const GY := 480.0
const DIFFS := [
	{"name": "FÁCIL", "hp": 150.0, "dmg": 0.7, "spd": 0.85, "boss": 0.8, "aggr": 0.9},
	{"name": "NORMAL", "hp": 100.0, "dmg": 1.25, "spd": 1.0, "boss": 1.15, "aggr": 1.15},
	{"name": "DIFÍCIL", "hp": 80.0, "dmg": 2.1, "spd": 1.3, "boss": 1.5, "aggr": 1.45},
	{"name": "PESADILLA", "hp": 70.0, "dmg": 2.5, "spd": 1.42, "boss": 1.75, "aggr": 1.65},
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

## Mundo (0-17, el número interno del juego web) y fase (0-2).
@export_range(0, 17) var wi := 0
@export_range(0, 2) var act := 0
@export_range(0, 3) var diff_idx := 1
## Juega solo (para vídeos y pruebas).
@export var autoplay := false
## Sin diálogos ni escenas (pruebas).
@export var no_story := false

var level := {}
var WD := {}
var dim := 0
var shift_cd := 0.0
static var DATA := {}
## Lo que eligió el mapa (mundo, fase, dificultad) antes de abrir la escena.
static var launch := {}
const BOSS_ART := {0: "hdb_frog", 1: "boss_ship", 2: "hdb_wizard", 3: "hdb_eye", 4: "hdb_knight", 5: "hdb_beast", 6: "hdb_demon", 8: "boss_lev", 9: "boss_sph", 10: "boss_ser", 11: "boss_devo"}
const BOSS_HP := [14, 16, 28, 20, 22, 22, 26, 30, 22, 22, 26, 40]
var p := {}
var boss := {}
var projs: Array = []
var waves: Array = []
var warns: Array = []
var invert_t := 0.0
var lives := 4
## Modo de juego: historia, torre, rush, grieta, diario.
var mode := "historia"
var tower := {}
var rush := {}
var rift_ret := {}
var daily := {}
var level_time := 0.0
var attempt := 1
var slow_t := 0.0
const LIVES_BY := [99, 4, 2, 1]
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
var _shift_btn: TouchScreenButton
var _time_btn: TouchScreenButton
var story: CrStory
var tic := {"x": 0.0, "y": 0.0, "vx": 0.0, "vy": 0.0, "face": 1}
var tic_cd := 6.0
var tic_idle := 0.0

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
	add_child(CrFx.new())
	_kael = SheetSprite.new()
	_kael.unit_scale = 0.25
	_kael.z_index = 5
	add_child(_kael)
	_boss_proxy = preload("res://chronos/cr_boss_proxy.gd").new()
	add_child(_boss_proxy)
	Aether.player = self
	if "--autoplay" in OS.get_cmdline_user_args():
		autoplay = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mundo="):
			wi = int(arg.get_slice("=", 1))
			act = 0
	if not InputMap.has_action("shift"):
		InputMap.add_action("shift")
		for k in [KEY_Q, KEY_C]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event("shift", ev)
		var jb := InputEventJoypadButton.new()
		jb.button_index = JOY_BUTTON_Y
		InputMap.action_add_event("shift", jb)
	if not InputMap.has_action("tiempo"):
		InputMap.add_action("tiempo")
		var ev2 := InputEventKey.new()
		ev2.physical_keycode = KEY_E
		InputMap.action_add_event("tiempo", ev2)
		var jb2 := InputEventJoypadButton.new()
		jb2.button_index = JOY_BUTTON_BACK
		InputMap.action_add_event("tiempo", jb2)
	for a in [["cr_primeros", "Primeros pasos", "Supera la fase 1-1"], ["cr_guardian1", "Cazador de guardianes", "Vence a tu primer guardián"],
			["cr_guardian18", "Guardián del Tiempo", "Vence a los 18 guardianes"], ["cr_perfecto", "Sin un rasguño", "Supera una fase sin perder ninguna vida"],
			["cr_torre10", "Escalador del tiempo", "Llega al piso 10 de la Torre"], ["cr_torre25", "Señor de la Torre", "Llega al piso 25 de la Torre"],
			["cr_rush6", "Seis seguidos", "Vence a 6 guardianes en el Boss Rush"], ["cr_rush18", "Imparable", "Completa el Boss Rush"],
			["cr_grieta1", "Explorador de grietas", "Supera una Grieta del Tiempo"], ["cr_diario", "Cita diaria", "Supera un Reto diario"]]:
		Aether.achievements.define(a[0], a[1], a[2])
	story = CrStory.new()
	add_child(story)
	_add_shift_button()
	_time_btn = _round_button("tiempo", "TIEMPO", Color(0.45, 0.85, 1, 0.25), Vector2(-150, -470))
	if not launch.is_empty():
		wi = int(launch.get("wi", wi))
		act = int(launch.get("act", act))
		diff_idx = int(launch.get("diff", diff_idx))
		mode = str(launch.get("mode", "historia"))
		launch = {}
		if mode != "historia":
			start_mode(mode)
			return
	if wi == 0 and act == 0 and not Aether.save.get_value("cr_intro", false) and not autoplay and not no_story:
		start_stage(act, wi)
		story.play_cut("intro", func() -> void:
			Aether.save.set_value("cr_intro", true)
			start_stage(0, 0))
		return
	start_stage(act, wi)

static func data() -> Dictionary:
	if DATA.is_empty():
		DATA = JSON.parse_string(FileAccess.get_file_as_string("res://chronos/niveles/datos.json"))
	return DATA

## Lee la fase exportada del juego web y vuelve a unir las referencias ($ref).
static func load_level(d: int, w: int, a: int) -> Dictionary:
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://chronos/niveles/d%d_%d_%d.json" % [d, w, a]))
	if not raw is Dictionary:
		return {}
	var ids := {}
	_collect(raw, ids)
	return _resolve(raw, ids)

static func _collect(o, ids: Dictionary) -> void:
	if o is Dictionary:
		if o.has("$id"):
			ids[int(o["$id"])] = o
		for k in o:
			_collect(o[k], ids)
	elif o is Array:
		for v in o:
			_collect(v, ids)

static func _resolve(o, ids: Dictionary):
	if o is Dictionary:
		if o.has("$ref"):
			return ids.get(int(o["$ref"]), {})
		for k in o.keys():
			o[k] = _resolve(o[k], ids)
		return o
	if o is Array:
		for i in o.size():
			o[i] = _resolve(o[i], ids)
	return o

func start_stage(a: int, w := -1, file := "") -> void:
	act = a
	if w >= 0:
		wi = w
	WD = data().worlds[wi]
	if file != "":
		var raw = JSON.parse_string(FileAccess.get_file_as_string("res://chronos/niveles/%s.json" % file))
		level = {}
		if raw is Dictionary:
			var ids := {}
			_collect(raw, ids)
			level = _resolve(raw, ids)
			wi = int(level.get("wi", wi))
			act = int(level.get("act", act))
			WD = data().worlds[wi]
	else:
		level = load_level(diff_idx, wi, act)
	if level.is_empty():
		level = CrLevel.new().build(0, act, diff_idx)
	for k in ["arena", "goal", "lava"]:
		if not level.get(k) is Dictionary:
			level[k] = {}
	for k in ["plats", "enemies", "gems", "cherries", "checks", "hazards", "hints", "zones", "lavaStrips", "decor", "plates", "doors", "anchors", "levers"]:
		if not level.get(k) is Array:
			level[k] = []
	var EN: Dictionary = data().enemy
	for e in level.enemies:
		e["d"] = EN.get(e.get("id", ""), {"b": "walker", "anim": "opossum", "w": 32, "h": 22, "hp": 2, "face": -1})
		for k in ["kx", "vx", "vy", "hit", "alert", "cd", "t", "fire"]:
			if not e.has(k) or e[k] == null:
				e[k] = 0.0
		e["air"] = bool(e.get("air", false)) if typeof(e.get("air", false)) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT] else false
	for s in level.plats:
		for k in ["dx", "dy", "t", "sq", "oy", "vy"]:
			if not s.has(k):
				s[k] = 0.0
	dim = 0
	if _shift_btn:
		_shift_btn.visible = wi != 0
	_bg.texture = Aether.tex("pbg%d" % wi)
	var D: Dictionary = DIFFS[diff_idx]
	var st0 = level.start
	var st: Vector2 = Vector2(st0.x, st0.y) if st0 is Dictionary else Vector2(70, GY - PH)
	level.start = st
	p = {"x": st.x, "y": st.y, "w": PW, "h": PH, "vx": 0.0, "vy": 0.0, "face": 1, "onGround": false, "ground": null, "jumps": 0,
		"coyote": 0.0, "buf": 0.0, "dashT": 0.0, "dashCD": 0.0, "atkT": 0.0, "atkCD": 0.0, "atkN": 0, "lastAtk": -9.0, "air": false,
		"hitSet": [], "pogoDone": false, "wall": 0, "wjLock": 0.0, "wjDir": 0, "inv": 0.0, "stun": 0.0, "hp": D.hp, "maxHp": D.hp,
		"noCut": false, "time": 0.0, "hook": null, "dead": false, "deadT": 0.0, "anim": 0.0, "respawn": st, "safe": st, "sq": 1.0, "look": 0.0, "combo": 0, "comboT": 0.0}
	boss = {}
	projs = []
	waves = []
	warns = []
	invert_t = 0.0
	slow_t = 0.0
	lives = LIVES_BY[diff_idx]
	attempt = 1
	arena_lock = false
	boss_intro = 0.0
	state = "playing"
	time = 0.0
	hint_txt = ""
	_update_camera(0.0, true)
	hp_changed.emit(p.hp, p.maxHp)
	Aether.music(str(WD.get("music", "w0")))
	tic = {"x": st.x - 30, "y": st.y - 30, "vx": 0.0, "vy": 0.0, "face": 1}
	if _story_on():
		var H: Dictionary = CrStory.data()
		var L0: Array = []
		if mode != "historia":
			L0 = [["TIC", ""]]
		if act == 0:
			L0.append(["NARR", H.lore[wi]])
		L0.append(["TIC", H.ticl[wi][act]])
		story.say(L0, false)
	level_time = 0.0
	if mode != "historia":
		return
	var pos: int = data().order.find(wi) + 1
	_banner("MUNDO %d-%d · %s" % [pos, act + 1, ("GUARDIÁN: " + str(WD.boss.name)) if act == 2 else str(WD.name)])

func _add_shift_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 61
	add_child(layer)
	var btn := TouchScreenButton.new()
	btn.action = "shift"
	btn.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	var sh := CircleShape2D.new()
	sh.radius = 58
	btn.shape = sh
	btn.shape_centered = true
	var img := Image.create(116, 116, false, Image.FORMAT_RGBA8)
	for y in 116:
		for x in 116:
			if Vector2(x - 58, y - 58).length() < 58:
				img.set_pixel(x, y, Color(0.8, 0.5, 1, 0.22))
	btn.texture_normal = ImageTexture.create_from_image(img)
	var l := Label.new()
	l.text = "SHIFT"
	l.size = Vector2(116, 116)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 24)
	btn.add_child(l)
	layer.add_child(btn)
	var vs := get_viewport_rect().size
	btn.position = Vector2(vs.x - 470 - 58, vs.y - 300 - 58)
	_shift_btn = btn

func _round_button(action: String, text: String, col: Color, anchor: Vector2) -> TouchScreenButton:
	var layer := CanvasLayer.new()
	layer.layer = 61
	add_child(layer)
	var btn := TouchScreenButton.new()
	btn.action = action
	btn.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	var sh := CircleShape2D.new()
	sh.radius = 54
	btn.shape = sh
	btn.shape_centered = true
	var img := Image.create(108, 108, false, Image.FORMAT_RGBA8)
	for y in 108:
		for x in 108:
			if Vector2(x - 54, y - 54).length() < 54:
				img.set_pixel(x, y, col)
	btn.texture_normal = ImageTexture.create_from_image(img)
	var l := Label.new()
	l.text = text
	l.size = Vector2(108, 108)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 20)
	btn.add_child(l)
	layer.add_child(btn)
	var vs := get_viewport_rect().size
	btn.position = Vector2(vs.x + anchor.x - 54, vs.y + anchor.y - 54)
	return btn

func _banner(t: String) -> void:
	var parts_t := t.split(" · ")
	for i in parts_t.size():
		parts_t[i] = Aether.t(parts_t[i])
	for h in get_tree().get_nodes_in_group("aether_hud"):
		h.banner(" · ".join(parts_t), "")

# ---------------- utilidades ----------------
static func ov(a: Dictionary, b: Dictionary) -> bool:
	return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y

func _door_closed(s: Dictionary) -> bool:
	var pl = s.get("plate")
	return not (pl is Dictionary and pl.get("on", false))

func _is_solid(s: Dictionary) -> bool:
	match s.k:
		"solid", "move", "bounce":
			return true
		"door":
			return _door_closed(s)
		"laser":
			return s.get("on", true)
		"break":
			return s.get("st", 0) < 2
		"phase":
			return int(s.get("ph", 0)) == dim
	return false

func _is_wall(s: Dictionary) -> bool:
	return (s.k == "solid" and not s.get("float", false)) or (s.k == "door" and _door_closed(s)) or (s.k == "phase" and int(s.get("ph", 0)) == dim and s.h > 16)

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
	for a in ["jump", "attack", "dash", "shift", "tiempo"]:
		_pressed[a] = Input.is_action_just_pressed(a)
	if hit_stop > 0.0:
		hit_stop -= dt
		queue_redraw()
		return
	time += dt
	if story and story.busy():
		_update_camera(dt, false)
		queue_redraw()
		return
	if state == "playing":
		_update_tic(dt)
		_update_plats(dt)
		_update_player(dt)
		_update_hazards(dt)
		var wdt: float = dt * (0.4 if slow_t > 0.0 else 1.0)
		_update_enemies(wdt)
		_update_projs(wdt)
		_update_boss(wdt)
	elif state == "victory":
		state_t -= dt
		if state_t <= -3.0 and ResourceLoader.exists("res://chronos/mapa.tscn") and get_tree().current_scene == owner:
			get_tree().change_scene_to_file("res://chronos/mapa.tscn")
	elif state in ["clear", "gameover"]:
		state_t -= dt
		if state_t <= 0.0:
			if state == "clear" and mode != "historia":
				_mode_clear()
			elif state == "clear":
				var order: Array = data().order
				var idx: int = order.find(wi) * 3 + act + 1
				var prog: int = int(Aether.save.get_value("cr_prog", 1))
				if idx + 1 > prog:
					Aether.save.set_value("cr_prog", idx + 1)
				var best: int = int(Aether.save.get_value("cr_score", 0))
				Aether.save.set_value("cr_score", max(best, score))
				if autoplay or idx < order.size() * 3:
					if idx >= order.size() * 3:
						state = "victory"
						_banner("¡HAS SALVADO EL TIEMPO!")
					else:
						start_stage(idx % 3, int(order[idx / 3]))
			else:
				start_stage(act)
	_update_particles(dt)
	_update_camera(dt, false)
	shake = max(0.0, shake - dt * 30.0)
	if hint_t > 0.0:
		hint_t -= dt
	_update_kael()
	queue_redraw()

func _story_on() -> bool:
	return story != null and not autoplay and not no_story and mode == "historia"

func _update_tic(dt: float) -> void:
	var tx: float = p.x + p.w / 2 - p.face * 26
	var ty: float = p.y - 18 + sin(time * 3) * 5
	if boss.is_empty():
		var bd := 120.0
		for gm in level.gems:
			if gm.taken:
				continue
			var d := Vector2(gm.x - tic.x, gm.y - tic.y).length()
			if d < bd and Vector2(gm.x - p.x, gm.y - p.y).length() < 170:
				bd = d
				tx = gm.x
				ty = gm.y
	tic.vx += (tx - tic.x) * 14 * dt
	tic.vy += (ty - tic.y) * 14 * dt
	tic.vx *= 1 - 5 * dt
	tic.vy *= 1 - 5 * dt
	tic.x += tic.vx * dt
	tic.y += tic.vy * dt
	tic.face = int(signf(tic.vx)) if abs(tic.vx) > 20 else p.face
	for gm in level.gems:
		if not gm.taken and Vector2(gm.x - tic.x, gm.y - tic.y).length() < 16:
			gm.taken = true
			score += 100
			_add_time(3)
			Aether.sfx("gem", 0.45)
			_float(gm.x, gm.y - 12, "+100", Color(1, 0.9, 0.4), 16)
	# frases de Tic
	tic_cd -= dt
	if abs(p.vx) < 10 and p.onGround and p.atkT <= 0:
		tic_idle += dt
	else:
		tic_idle = 0.0
	if _story_on() and not story._box.visible and tic_cd <= 0.0 and boss.is_empty():
		var Q: Dictionary = CrStory.data().ticq
		var k := ""
		if tic_idle > 7:
			k = "idle"
		elif p.hp < p.maxHp * 0.3 and Q.has("low"):
			k = "low"
		if k != "":
			var arr: Array = Q[k]
			story.say([["TIC", arr[randi() % arr.size()]]], false)
			tic_cd = 14.0
			tic_idle = 0.0

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
		elif s.k == "laser":
			var c: float = fmod(time + float(s.get("phase", 0.0)), 3.2)
			s.on = c < 2.0
			s.warn = c > 1.55 and c < 2.0
		elif s.k == "break":
			if s.st == 1:
				s.t -= dt
				if s.t <= 0.0:
					s.st = 2
					s.t = 3.0
					s.vy = 0.0
					s.oy = 0.0
					Aether.sfx("crumble", 0.7)
					_burst(s.x + s.w / 2, s.y + 8, Color(0.35, 0.19, 0.19), 14, 120, 600, 0.8, 3)
			elif s.st == 2:
				s.t -= dt
				s.vy += 900.0 * dt
				s.oy += s.vy * dt
				if s.t <= 0.0 and not ov(p, s):
					s.st = 0
					s.oy = 0.0
		elif s.k == "door":
			var want := 0.0 if _door_closed(s) else 1.0
			s.open = move_toward(float(s.get("open", 0.0)), want, dt * 3.0)
		elif s.k == "bounce" and s.sq > 0.0:
			s.sq -= dt

func _update_hazards(dt: float) -> void:
	for l in level.lavaStrips:
		if not p.dead and p.y + p.h > l.y + 4 and p.x + p.w > l.x and p.x < l.x + l.w:
			_burst(p.x + p.w / 2, l.y, Color(1, 0.8, 0.25), 20, 200, 400, 0.7)
			Aether.sfx("fire")
			_hazard_respawn(25)
	for h in level.hazards:
		if h.k == "jet":
			var c: float = fmod(time + float(h.get("ph", 0.0)), 2.4)
			h.on = c > 1.8
			h.warn = c > 1.4 and c <= 1.8
			if h.on and randf() < 0.8:
				parts.append({"x": h.x + 10 + randf_range(-6, 6), "y": GY - randf_range(0, 66), "vx": randf_range(-20, 20), "vy": randf_range(-120, -40), "life": 0.35, "max": 0.35, "c": (Color(1, 0.8, 0.25) if randf() < 0.5 else Color(1, 0.42, 0.1)), "s": 3.0, "g": -100.0})
			if h.on and not p.dead and ov(p, h):
				_hurt(18, h.x + 10)
		elif h.k == "icicle":
			var st: int = int(h.get("st", 0))
			if st == 0 and abs(p.x + p.w / 2 - (h.x + 6)) < 34 and p.y > h.y and p.y - h.y < 260:
				h.st = 1
				h.t = 0.35
				Aether.sfx("ice", 0.4, 1.4)
			elif st == 1:
				h.t -= dt
				if h.t <= 0.0:
					h.st = 2
			elif st == 2:
				h.vy = float(h.get("vy", 0.0)) + 1500.0 * dt
				h.y += h.vy * dt
				if not p.dead and ov(p, h):
					_hurt(15, h.x + 6)
					h.st = 3
				for s in level.plats:
					if s.k == "solid" and h.y + h.h > s.y and h.y < s.y + 8 and h.x + 6 > s.x and h.x + 6 < s.x + s.w and s.y > h.y0 + 20:
						h.st = 3
						break
				if h.y > level.deathY:
					h.st = 3
				if h.st == 3:
					_burst(h.x + 6, h.y + h.h, Color(0.8, 0.94, 1), 12, 140, 500, 0.5)
					Aether.sfx("ice", 0.5)
					h.t = 5.0
			elif st == 3:
				h.t -= dt
				if h.t <= 0.0:
					h.st = 0
					h.y = h.y0
					h.vy = 0.0
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

func _revive() -> void:
	var s: Vector2 = p.respawn
	attempt += 1
	p.merge({"dead": false, "deadT": 0.0, "hp": p.maxHp, "x": s.x, "y": s.y, "vx": 0.0, "vy": 0.0, "inv": 2.2, "stun": 0.0, "dashT": 0.0, "atkT": 0.0, "hook": null, "ground": null, "onGround": false, "combo": 0, "counted": false}, true)
	projs = []
	waves = []
	warns = []
	invert_t = 0.0
	slow_t = 0.0
	score = max(0, score - 250)
	for z in level.get("seals", []):
		if z.st == 1:
			z.st = 0
			for e in z.live:
				e.dead = true
			z.live = []
			z.plate.on = true
	for t in level.get("trials", []):
		if t.st == 1:
			t.st = 0
			for e in t.live:
				e.dead = true
			t.live = []
			for q in t.plates:
				q.on = true
	for c in level.get("chases", []):
		if c.st == 1:
			c.st = 0
	if arena_lock and not boss.is_empty() and not boss.done and not boss.dying:
		_spawn_boss()
		boss_intro = 1.2
	hp_changed.emit(p.hp, p.maxHp)
	Aether.sfx("check", 0.7)
	Aether.sfx("heal", 0.5)
	var pct := int(100.0 * s.x / max(1.0, float(level.width)))
	_banner("INTENTO %d · Llegaste al %d %%" % [attempt, pct])
	_update_camera(0.0, true)

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
		if p.deadT <= 0.7 and not p.get("counted", false):
			p.counted = true
			lives -= 1
		if p.deadT <= 0.7 and mode in ["torre", "rush"]:
			_mode_over()
			return
		if p.deadT <= 0.7 and mode == "grieta":
			_leave_rift(false)
			return
		if p.deadT <= 0.7 and mode == "diario":
			daily.deaths = int(daily.get("deaths", 0)) + 1
			lives = 99
		if p.deadT <= 0.7:
			if lives > 0:
				_revive()
			else:
				state = "gameover"
				state_t = 1.8
				_banner("¡SIN VIDAS! La fase empieza de nuevo")
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
	if p.onGround and p.ground != null and p.ground.get("conv", 0) != 0:
		p.x += float(p.ground.conv) * 120.0 * dt
	shift_cd -= dt
	slow_t = max(0.0, slow_t - dt)
	if _time_btn:
		_time_btn.visible = p.time >= 100.0
	if _press("tiempo") and p.time >= 100.0 and slow_t <= 0.0 and not p.dead:
		slow_t = 5.5
		p.time = 0.0
		Aether.sfx("slow", 0.9)
		Aether.flash(Color(0.47, 0.78, 1), 0.25)
		_float(p.x + p.w / 2, p.y - 24, "¡TIEMPO RALENTIZADO!", Color(0.62, 0.89, 1), 18)
	if _press("shift") and shift_cd <= 0.0 and not p.dead:
		if wi == 0:
			shift_cd = 0.6
			_float(p.x + p.w / 2, p.y - 10, "SHIFT dormido: recupera el 1.er fragmento", Color(0.75, 0.63, 1), 13)
		else:
			var nd := 1 - dim
			var blocked := false
			for q in level.plats:
				if q.k == "phase" and int(q.ph) == nd and ov(p, q):
					blocked = true
			if blocked:
				Aether.sfx("clang", 0.4, 1.5)
				_float(p.x + p.w / 2, p.y - 10, "¡BLOQUEADO!", Color(1, 0.33, 0.44), 14)
			else:
				dim = nd
				shift_cd = 0.22
				Aether.sfx("shift", 0.7)
				_burst(p.x + p.w / 2, p.y + p.h / 2, Color(0.82, 0.44, 1) if dim else Color(0.2, 0.89, 1), 16, 180, 0, 0.4)
	# zonas: viento, gravedad baja, agua, arena
	var gmul := 1.0
	var wfx := 0.0
	var wfy := 0.0
	var water = null
	var sand := false
	for z in level.zones:
		if ov(p, z):
			match z.k:
				"lowgrav":
					gmul = 0.42
				"wind":
					wfx += float(z.get("fx", 0))
					wfy += float(z.get("fy", 0))
				"water":
					if p.y + p.h * 0.45 > z.y:
						water = z
						wfx += float(z.get("fx", 0))
				"sand":
					sand = true
	p.gmul = gmul
	p.wfx = wfx
	p.wfy = wfy
	p.water = water
	p.sand = sand
	if sand and p.onGround:
		p.sinkT = float(p.get("sinkT", 0.0)) + dt
		if p.sinkT > 2.4:
			p.sinkT = 0.0
			_float(p.x + p.w / 2, p.y - 10, "¡LA ARENA TE TRAGÓ!", Color(1, 0.76, 0.29), 14)
			_hazard_respawn(12)
			return
	elif not sand:
		p.sinkT = 0.0
	var dir := Input.get_axis("left", "right")
	dir = 0.0 if abs(dir) < 0.3 else signf(dir)
	invert_t = max(0.0, invert_t - dt)
	if invert_t > 0.0:
		dir = -dir
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
	if p.hook != null:
		_update_hook(dt, dir)
	elif p.dashT > 0.0:
		p.dashT -= dt
		p.vx = p.face * DASH
		p.vy = 0.0
		if p.dashT <= 0.0:
			p.vx = p.face * MOVE
	else:
		var atk_slow := 0.35 if (p.atkT > 0.0 and p.onGround) else 1.0
		var accel := 2600.0 if p.onGround else 1800.0
		if WD.get("ice", false) and p.onGround:
			accel = 700.0
		if not ctrl:
			p.vx = move_toward(p.vx, 0.0, 600.0 * dt)
		else:
			var mul := 0.72 if water != null else (0.45 if (sand and p.onGround) else 1.0)
			p.vx = move_toward(p.vx, dir * MOVE * atk_slow * mul, (1400.0 if water != null else accel) * dt)
		p.vx += wfx * dt
		if water != null:
			if ctrl and p.buf > 0.0:
				p.buf = 0.0
				var surf: bool = p.y < water.y + 14
				p.vy = -JUMP * 0.98 if surf else -330.0
				p.jumps = 1
				p.noCut = true
				Aether.sfx("jump" if surf else "dj", 0.35, 1.0 if surf else 0.8)
			p.vy = min(p.vy + 520.0 * dt, 150.0)
			if p.vy < -420 and p.y > water.y + 30:
				p.vy = -420.0
		elif ctrl and p.buf > 0.0:
			var anc = _near_anchor() if (not p.onGround and p.coyote <= 0.0) else null
			if anc != null:
				_attach_hook(anc)
			elif p.coyote > 0.0:
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
		if wfy != 0.0:
			p.noCut = true
			p.vy += wfy * dt
			if p.vy < -420:
				p.vy = -420.0
		var gr: float = GRAV * float(p.get("gmul", 1.0))
		if water != null:
			gr = 0.0
		if p.vy >= 0.0 and wfy == 0.0:
			p.noCut = false
		if not Input.is_action_pressed("jump") and p.vy < 0.0 and not p.noCut:
			gr *= 2.3
		if Input.is_action_pressed("jump") and abs(p.vy) < 90.0:
			gr *= 0.55
		if p.vy > 0.0:
			gr *= 1.12
		if water == null:
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

func _near_anchor():
	var best = null
	var bd := 160.0
	if time < float(p.get("hookCD", 0.0)):
		return null
	for a in level.anchors:
		if is_same(a, p.get("lastHook")) and time < float(p.get("hookCD2", 0.0)):
			continue
		var d := Vector2(a.x - (p.x + p.w / 2), a.y - (p.y + p.h / 2)).length()
		if d < bd:
			bd = d
			best = a
	return best

func _attach_hook(a: Dictionary) -> void:
	var cx: float = p.x + p.w / 2
	var cy: float = p.y + p.h / 2
	var dx: float = cx - a.x
	var dy: float = cy - a.y
	var length: float = clamp(Vector2(dx, dy).length(), 70.0, 140.0)
	var ang := atan2(dx, dy)
	var tv: float = p.vx * cos(ang) - p.vy * sin(ang)
	p.hook = {"a": a, "len": length, "ang": ang, "av": clamp(tv / length, -6.0, 6.0)}
	p.buf = 0.0
	p.dashT = 0.0
	p.jumps = 1
	Aether.sfx("lever", 0.5, 1.6)
	_burst(a.x, a.y, Color(1, 0.83, 0.3), 10, 120, 0, 0.4)

func _update_hook(dt: float, dir: float) -> void:
	var h: Dictionary = p.hook
	var gr := GRAV * 0.9
	h.av += (-(gr / h.len) * sin(h.ang) + dir * 3.2) * dt
	h.av *= (1.0 - 0.15 * dt)
	h.av = clamp(h.av, -7.0, 7.0)
	h.ang += h.av * dt
	var cx: float = h.a.x + sin(h.ang) * h.len
	var cy: float = h.a.y + cos(h.ang) * h.len
	p.vx = cos(h.ang) * h.len * h.av
	p.vy = -sin(h.ang) * h.len * h.av
	p.x = cx - p.w / 2
	p.y = cy - p.h / 2
	p.onGround = false
	p.ground = null
	p.wall = 0
	if dir != 0.0:
		p.face = int(dir)
	elif abs(p.vx) > 40:
		p.face = int(signf(p.vx))
	if _press("jump"):
		p.lastHook = h.a
		p.hookCD = time + 0.15
		p.hookCD2 = time + 0.6
		p.buf = 0.0
		p.hook = null
		p.vy = min(p.vy, 0.0) - 300.0
		p.vx *= 1.15
		p.jumps = 1
		p.noCut = true
		Aether.sfx("jump", 0.5, 1.2)

func _add_time(v: float) -> void:
	if slow_t <= 0.0:
		p.time = min(100.0, p.time + v)

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
		elif land.k == "break" and land.st == 0:
			land.st = 1
			land.t = 0.45
			Aether.sfx("crumble", 0.3, 1.6)
		elif land.k == "solid" and not land.get("conv", 0):
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
	for q in level.plates:
		if not q.get("on", false) and not q.get("boss", false) and ov(p, {"x": q.x, "y": q.y - 6, "w": q.w, "h": q.h + 6}):
			q.on = true
			Aether.sfx("lever", 0.6)
			_float(q.x + q.w / 2, q.y - 20, "¡PUERTA ABIERTA!", Color(0.6, 1, 0.69), 14)
	_update_gates()
	var rl = level.get("relic")
	if rl is Dictionary and not rl.is_empty() and not rl.get("taken", false) and abs(p.x + p.w / 2 - rl.x) < 16 and abs(p.y + p.h / 2 - rl.y) < 30:
		rl.taken = true
		score += 1000
		p.time = 100.0
		Aether.sfx("relic", 0.8)
		Aether.flash(Color(1, 0.86, 0.47), 0.25)
		_burst(rl.x, rl.y, Color(1, 0.88, 0.5), 30, 220, 0, 0.8)
		_float(rl.x, rl.y - 20, "¡RELOJ DE ARENA SECRETO!", Color(1, 0.83, 0.3), 20)
	_update_chases()
	level_time += get_process_delta_time()
	var rf = level.get("rift")
	if mode == "historia" and rf is Dictionary and not rf.is_empty() and ov(p, rf):
		_enter_rift()
	for gm in level.gems:
		if gm.taken:
			continue
		if p.x < gm.x + 9 and p.x + p.w > gm.x - 9 and p.y < gm.y + 9 and p.y + p.h > gm.y - 9:
			gm.taken = true
			score += 100
			_add_time(3)
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
		dim = 0
		if _story_on():
			story.set_meta("boss_name", str(WD.get("boss", {}).get("name", "")))
			story.say(CrStory.data().bossl[wi], true)
		Aether.music("final" if wi >= 6 else "boss")
		Aether.sfx("roar", 0.8)
		shake = 8.0

func _spawn_foe(id: String, x: float, y: float) -> Dictionary:
	var d: Dictionary = data().enemy.get(id, {"b": "walker", "anim": "opossum", "w": 32, "h": 22, "hp": 2, "face": -1})
	var air: bool = d.b in ["flyer", "diver", "ghost", "dropper", "bob"]
	var e := {"id": id, "d": d, "b": d.b, "x": x, "y": (y if air else GY - float(d.h)), "w": float(d.w), "h": float(d.h), "hp": float(d.hp), "hit": 0.0, "t": randf() * 5.0,
		"dir": -1, "minX": x - 140.0, "maxX": x + 140.0 - float(d.w), "cd": 1.0 + randf(), "dead": false, "st": ("buried" if d.b == "riser" else 0), "x0": x, "y0": y, "fire": 0.0, "alert": 1.0, "vy": 0.0, "vx": 0.0, "kx": 0.0, "air": false}
	level.enemies.append(e)
	_burst(x + e.w / 2, e.y + e.h / 2, Color(1, 0.4, 0.3), 12, 160, 0, 0.4)
	return e

func _update_gates() -> void:
	for z in level.get("seals", []):
		if z.st == 0 and p.x + p.w > z.x1 and p.x + p.w < z.bar - 4:
			z.st = 1
			z.plate.on = false
			z.live = []
			for f in z.foes:
				z.live.append(_spawn_foe(f.id, f.x, f.y))
			_banner("¡EMBOSCADA!")
			Aether.sfx("alert", 0.5)
			shake = max(shake, 6.0)
		if z.st != 1:
			continue
		var left := 0
		for e in z.live:
			if not e.dead and (e.y > level.deathY or abs(e.x - z.bar) > 1400):
				e.dead = true
			if not e.dead:
				left += 1
		if left == 0:
			z.st = 2
			z.plate.on = true
			score += 600
			for i in 5:
				level.gems.append({"x": z.bar - 200 + i * 40, "y": 420 - sin(i / 4.0 * PI) * 50, "taken": false, "ph": float(i)})
			_banner("¡PASO ABIERTO!")
			Aether.sfx("relic", 0.5)
	for t in level.get("trials", []):
		if t.st == 0 and p.x > t.x1 + 70 and p.x + p.w < t.x2 - 40 and p.y > GY - 420:
			t.st = 1
			t.wave = 0
			t.t = 0.9
			t.live = []
			for q in t.plates:
				q.on = false
			_banner("CÁMARA DEL DESAFÍO")
			Aether.sfx("alert", 0.6)
			shake = max(shake, 8.0)
		if t.st != 1:
			continue
		var alive := false
		for e in t.live:
			if not e.dead:
				alive = true
		if alive:
			continue
		t.t -= get_process_delta_time()
		if t.t > 0.0:
			continue
		if t.wave < t.waves.size():
			for w in t.waves[t.wave]:
				t.live.append(_spawn_foe(w.id, w.x, w.get("y0", w.y) if w.b in ["flyer", "diver", "ghost"] else w.y))
			t.wave += 1
			t.t = 1.1
		else:
			t.st = 2
			for q in t.plates:
				q.on = true
			p.hp = min(p.maxHp, p.hp + 25.0)
			hp_changed.emit(p.hp, p.maxHp)
			score += 1500
			_banner("¡DESAFÍO SUPERADO!")
			Aether.sfx("win", 0.5)

const CHASE_LOOK := {1: [Color(0.16, 0.04, 0.24), Color(0.69, 0.44, 1), "LA SOMBRA TE PERSIGUE"], 6: [Color(0.47, 0.08, 0), Color(1, 0.48, 0.19), "EL FUEGO TE PERSIGUE"],
	11: [Color(0.08, 0, 0.16), Color(1, 0.42, 0.84), "EL VACÍO TE PERSIGUE"], 13: [Color(0.12, 0.12, 0.2), Color(0.56, 0.71, 1), "EL CASTILLO SE DERRUMBA"], 17: [Color(0.08, 0.12, 0.27), Color(0.75, 0.9, 1), "LA TORMENTA TE PERSIGUE"]}

func _update_chases() -> void:
	var dt := get_process_delta_time()
	for c in level.get("chases", []):
		if c.st == 0 and not p.dead and p.x > c.x0 and p.x < c.x1 - 200:
			c.st = 1
			c.wx = c.x0 - 260
			c.sp = 200.0
			_banner("¡CORRE! " + str(CHASE_LOOK.get(wi, CHASE_LOOK[1])[2]))
			Aether.sfx("roar", 0.7, 0.7)
			shake = max(shake, 8.0)
		if c.st != 1:
			continue
		c.sp = min(255.0, c.sp + dt * 22.0)
		c.wx += c.sp * dt
		if abs(c.wx - p.x) < 300:
			shake = max(shake, 2.0)
		if p.x < c.wx and p.inv <= 0.0:
			if diff_idx >= 1:
				p.hp = 0.0
				hp_changed.emit(0.0, p.maxHp)
				_kill()
			else:
				_hurt(25, c.wx - 100)
				p.x = c.wx + 30
		if c.wx >= c.x1:
			c.st = 2
			Aether.sfx("relic", 0.5)
			_float(p.x + p.w / 2, p.y - 30, "¡A SALVO!", Color(0.24, 0.96, 0.63), 20)

func _stage_clear() -> void:
	if state != "playing":
		return
	state = "clear"
	state_t = 3.0
	var gl: Dictionary = level.goal
	if not gl.is_empty():
		var hgt: float = (gl.y + gl.h) - (p.y + p.h)
		var bonus := 5000 if hgt > 50 else (2000 if hgt > 25 else 500)
		var txt := "¡SALTO PERFECTO!" if bonus == 5000 else ("¡GRAN SALTO!" if bonus == 2000 else "¡META!")
		score += bonus
		_float(p.x + p.w / 2, p.y - 40, "%s +%d" % [txt, bonus], Color(1, 0.83, 0.3), 22)
	if mode == "historia" and wi == 0 and act == 0:
		Aether.achievements.unlock("cr_primeros")
	if mode == "historia" and act == 2:
		Aether.achievements.unlock("cr_guardian1")
		var bs: Array = Aether.save.get_value("cr_guardianes", [])
		if not wi in bs:
			bs.append(wi)
			Aether.save.set_value("cr_guardianes", bs)
		if bs.size() >= 18:
			Aether.achievements.unlock("cr_guardian18")
	if lives == LIVES_BY[diff_idx] and attempt == 1 and LIVES_BY[diff_idx] < 99:
		Aether.achievements.unlock("cr_perfecto")
	if lives == LIVES_BY[diff_idx] and attempt == 1:
		_float(p.x + p.w / 2, p.y - 70, "¡PERFECTO! ★★★", Color(1, 0.95, 0.5), 22)
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
			_hit_boss(db, true)
			_pogo()
	for q in projs.duplicate():
		if ov(hb, {"x": q.x - q.hw, "y": q.y - q.hh, "w": q.hw * 2, "h": q.hh * 2}):
			projs.erase(q)
			score += 10
			Aether.sfx("clang", 0.5)
			_float(q.x, q.y - 10, "PARRY", Color(0.2, 0.89, 1), 15)
	for l in level.levers:
		if not l.get("on", false) and ov(hb, l):
			l.on = true
			Aether.sfx("lever")
			_float(l.x + l.w / 2, l.y - 14, "¡PALANCA!", Color(0.6, 1, 0.69), 16)
			var all_on := true
			for v in level.levers:
				if not v.get("on", false):
					all_on = false
			if all_on and not boss.is_empty() and boss.type == 2 and not boss.dying:
				boss.vulnT = 5.5
				shake = 12.0
				Aether.sfx("shield")
				_float(boss.x + boss.w / 2, boss.y - 24, "¡ESCUDO ROTO!", Color(0.2, 0.89, 1), 24)
	if not boss.is_empty() and not boss.dying and not boss.done and boss_intro <= 0.0 and not p.hitSet.has("boss") and ov(hb, boss):
		_hit_boss(hb)

func _hit_enemies(hb: Dictionary) -> bool:
	var hit := false
	for e in level.enemies:
		if not e.dead and not p.hitSet.has(e) and ov(hb, e) and not (e.b == "ghost" and dim == 0) and not (e.b == "riser" and str(e.get("st", "")) == "buried") and not (e.b in ["dormant", "revive"]) and not (e.b == "burrower" and str(e.get("st", "")) in ["under", "tele"]):
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
	if e.hp > 0.01 and e.b == "rammer" and str(e.get("st", "")) == "aim":
		e.st = "stun"
		e.tt = 0.6
	if e.hp <= 0.01 and str(e.get("v", "")) == "reviver" and not e.get("revived", false):
		if dim == 1:
			_float(e.x + e.w / 2, e.y - 14, "¡DESTRUIDO!", Color(0.85, 0.63, 1), 13)
		else:
			e.revived = true
			e.b0 = "riser"
			e.b = "revive"
			e.tt = 2.2
			e.hp = float(e.d.get("hp", 2))
			e.gy = e.y + e.h
			_float(e.x + e.w / 2, e.y - 14, "SE RECOMPONE…", Color(0.91, 0.86, 0.75), 13)
			return
	if e.hp <= 0.01 and str(e.get("v", "")) == "splitter" and not e.get("mini", false):
		for sgn in [-1, 1]:
			var m: Dictionary = e.duplicate()
			m.merge({"dead": false, "mini": true, "v": "mini", "b": "walker", "hp": 1.0, "w": 20.0, "h": 14.0, "x": e.x + e.w / 2 - 10 + sgn * 8, "y": e.y + e.h - 14, "dir": sgn, "minX": e.x - 120, "maxX": e.x + 120, "kx": sgn * 180.0, "hit": 0.2}, true)
			level.enemies.append(m)
			p.hitSet.append(m)
	if e.hp <= 0.01:
		e.dead = true
		_add_time(8)
		score += 50
		Aether.sfx("kill", 0.6)
		_burst(e.x + e.w / 2, e.y + e.h / 2, Color(0.9, 0.9, 1), 16, 160, 100, 0.5, 3)
		_float(e.x + e.w / 2, e.y - 8, "+50", Color(1, 0.9, 0.4), 16)
		if randf() < 0.05:
			level.cherries.append({"x": e.x + e.w / 2, "y": e.y + e.h - 14, "taken": false, "ph": 0.0})

# ---------------- enemigos ----------------
func _shoot(e: Dictionary, tx: float, ty: float, kind := "") -> void:
	var D: Dictionary = DIFFS[diff_idx]
	if kind == "":
		kind = str(e.d.get("shot", "orb"))
	var cx: float = e.x + e.w / 2
	var cy: float = e.y + e.h / 2
	var d := Vector2(tx - cx, ty - cy)
	var l: float = max(1.0, d.length())
	var sp: float = 210.0 * D.spd
	match kind:
		"spore":
			projs.append({"x": cx, "y": e.y + 6, "vx": clamp(d.x, -260.0, 260.0), "vy": -320.0, "grav": 700.0, "hw": 6.0, "hh": 6.0, "type": "spore", "dmg": 12.0, "life": 3.0})
		"wormball":
			projs.append({"x": cx + e.dir * 14, "y": cy - 2, "vx": e.dir * 200.0 * D.spd, "vy": 0.0, "hw": 7.0, "hh": 5.0, "type": "wormball", "dmg": 14.0, "life": 3.0})
		"bolt":
			projs.append({"x": cx + e.dir * 14, "y": e.y + 8, "vx": e.dir * 300.0 * D.spd, "vy": 0.0, "hw": 6.0, "hh": 4.0, "type": "bolt", "dmg": 12.0, "life": 3.0})
		_:
			projs.append({"x": cx, "y": cy, "vx": d.x / l * sp, "vy": d.y / l * sp, "hw": 5.0, "hh": 5.0, "type": "orb", "dmg": 12.0, "life": 4.0})
	if str(e.get("v", "")) == "spread" and projs.size() > 0:
		var q: Dictionary = projs[projs.size() - 1]
		var vq := Vector2(q.vx, q.vy)
		for da in [-0.32, 0.32]:
			var q2: Dictionary = q.duplicate()
			var r2 := vq.rotated(da)
			q2.vx = r2.x
			q2.vy = r2.y
			projs.append(q2)

## Comportamientos nuevos de foes.js que todavía usan el más parecido.
const B_MAP := {"rammer": "chaser", "brute": "chaser", "burrower": "chaser", "dormant": "chaser", "book": "ghost", "sniper": "shooter", "dropper": "flyer", "pulse": "bob", "splitter": "walker", "spread": "shooter"}

func _update_enemies(dt: float) -> void:
	var D: Dictionary = DIFFS[diff_idx]
	var pcx: float = p.x + p.w / 2
	var pcy: float = p.y + p.h / 2
	for e in level.enemies:
		if e.dead:
			continue
		e.hit = max(0.0, e.hit - dt)
		e.t += dt
		if e.alert > 0.0:
			e.alert -= dt
		if abs(e.x - cam.x - VW / 2) > 900:
			continue
		var cx: float = e.x + e.w / 2
		var dx: float = pcx - cx
		var dy: float = pcy - (e.y + e.h / 2)
		var adx: float = abs(dx)
		var d: Dictionary = e.d
		if e.kx != 0.0:
			var nx: float = e.x + e.kx * dt
			if _ground_below(nx + e.w if e.kx > 0 else nx, e.y + e.h, 14) != null or e.air:
				e.x = nx
			e.kx *= max(0.0, 1.0 - 9.0 * dt)
			if abs(e.kx) < 8:
				e.kx = 0.0
		if e.b in CrFoes.OWN:
			for k in ["tt", "run", "cd"]:
				if not e.has(k) or e[k] == null:
					e[k] = 0.0
			CrFoes.update(self, e, dt, D, pcx, pcy)
			if not p.dead and ov(p, e) and not (e.b in ["dormant", "revive"]) and not (e.b == "burrower" and str(e.get("st", "")) in ["under", "tele"]):
				_hurt(15.0, e.x + e.w / 2)
			continue
		if str(e.get("v", "")) == "pulse":
			CrFoes.pulse(self, e, dt, D, pcx, pcy)
		var b: String = B_MAP.get(e.b, e.b)
		match b:
			"walker":
				if e.hit <= 0.0:
					e.x += e.dir * float(d.get("spd", 70)) * D.spd * dt
				if e.x < e.minX:
					e.x = e.minX
					e.dir = 1
				if e.x > e.maxX:
					e.x = e.maxX
					e.dir = -1
			"chaser", "bomber", "riser", "shield":
				if b == "riser" and str(e.get("st", "")) == "buried":
					if adx < 150 and abs(dy) < 80:
						e.st = "rising"
						e.rise = 0.0
						Aether.sfx("bones", 0.6)
					continue
				if b == "riser" and str(e.get("st", "")) == "rising":
					e.rise = float(e.get("rise", 0.0)) + dt
					if e.rise > 0.8:
						e.st = "walk"
					continue
				var sees: bool = adx < (260 if b == "bomber" else 230) and abs(dy) < 70
				if sees and not e.get("saw", false):
					e.saw = true
					e.alert = 0.6
					if b == "chaser":
						Aether.sfx("roar", 0.35, 1.3)
				if not sees:
					e.saw = false
				var sp: float = float(d.get("spd", 60))
				var target: int = e.dir
				if sees:
					target = 1 if dx > 0 else -1
				if b == "chaser" and sees and e.alert <= 0.0:
					sp = float(d.get("run", 240))
				if b == "bomber" and sees:
					sp = -float(d.get("spd", 60)) if adx < 90 else 0.0
					e.cd -= dt
					if e.cd <= 0.0 and e.alert <= 0.0:
						e.cd = 2.2 / D.aggr
						var T := 0.9
						projs.append({"x": cx, "y": e.y + 4, "vx": (pcx - cx) / T, "vy": -(0.5 * 800 * T) + (pcy - e.y) / T * 0.3, "grav": 800.0, "hw": 6.0, "hh": 6.0, "type": "bomb", "dmg": 16.0, "life": 2.0})
				e.dir = target
				if e.hit <= 0.0 and e.alert <= 0.0 and sp != 0.0:
					var nx2: float = e.x + e.dir * sp * D.spd * dt
					var fx_: float = nx2 + e.w + 2 if e.dir > 0 else nx2 - 2
					if _ground_below(fx_, e.y + e.h, 14) != null:
						e.x = nx2
					elif not sees:
						e.dir *= -1
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
					var nx3: float = e.x + e.vx * dt
					var gnd = _ground_below(nx3 + e.w / 2, ny + e.h, 16) if e.vy > 0 else null
					if gnd != null and e.y + e.h <= gnd.y + 4:
						e.y = gnd.y - e.h
						e.air = false
						e.vy = 0.0
					else:
						e.y = ny
						if _ground_below(nx3 + e.w / 2, e.y + e.h, 400) != null or e.vy < 0:
							e.x = nx3
					if e.y > level.deathY:
						e.dead = true
			"shooter":
				e.dir = 1 if dx > 0 else -1
				if e.fire > 0.0:
					e.fire -= dt
				if not d.get("still", false) and e.fire <= 0.0 and adx > 120:
					var nx4: float = e.x + e.dir * float(d.get("spd", 30)) * dt
					var fx4: float = nx4 + e.w + 2 if e.dir > 0 else nx4 - 2
					if _ground_below(fx4, e.y + e.h, 14) != null and nx4 > e.minX - 60 and nx4 < e.maxX + 60:
						e.x = nx4
				e.cd -= dt
				if e.cd <= 0.0 and adx < 400 and abs(dy) < 150 and not p.dead:
					e.cd = randf_range(1.8, 2.6) / D.aggr
					e.fire = 0.5
					_shoot(e, pcx, pcy)
					Aether.sfx("shoot", 0.3, 1.3)
			"flyer":
				var ox: float = e.x
				e.x = e.x0 + sin(e.t * 1.2) * 60.0
				e.y = e.y0 + sin(e.t * 2.3) * 18.0
				e.dir = 1 if e.x >= ox else -1
				e.cd -= dt
				if e.cd <= 0.0 and Vector2(dx, dy).length() < 400 and not p.dead and d.has("shot"):
					e.cd = randf_range(2.2, 3.2) / D.aggr
					_shoot(e, pcx, pcy)
					Aether.sfx("shoot", 0.25, 1.5)
			"diver":
				var stt: String = str(e.get("st", ""))
				if stt == "" or stt == "0":
					e.st = "hover"
					stt = "hover"
				if stt == "hover":
					e.x = lerp(float(e.x), e.x0 + sin(e.t) * 40.0, dt * 2.0)
					e.y = lerp(float(e.y), e.y0 + sin(e.t * 2) * 12.0, dt * 2.0)
					e.dir = 1 if dx > 0 else -1
					e.cd -= dt
					if e.cd <= 0.0 and adx < 240 and dy > -20 and dy < 260 and not p.dead:
						e.st = "tele"
						e.tt = 0.45
						e.alert = 0.45
				elif stt == "tele":
					e.tt -= dt
					e.x += sin(e.t * 60) * 0.6
					if e.tt <= 0.0:
						e.st = "dive"
						e.tt = 0.9
						var dd: float = max(1.0, Vector2(dx, dy).length())
						e.vx = dx / dd * 380.0 * D.spd
						e.vy = dy / dd * 380.0 * D.spd
						e.dir = 1 if dx > 0 else -1
						Aether.sfx("dash", 0.3, 1.6)
				elif stt == "dive":
					e.tt -= dt
					e.x += e.vx * dt
					e.y += e.vy * dt
					if e.tt <= 0.0 or _ground_below(e.x + e.w / 2, e.y + e.h, 6) != null:
						e.st = "back"
				elif stt == "back":
					e.x = lerp(float(e.x), float(e.x0), dt * 1.5)
					e.y = lerp(float(e.y), float(e.y0), dt * 1.5)
					if abs(e.y - e.y0) < 6:
						e.st = "hover"
						e.cd = randf_range(1.2, 2.2)
			"bob":
				e.y = e.y0 + sin(e.t * 1.4) * 34.0
				e.x = e.x0 + sin(e.t * 0.6) * 20.0
				e.dir = 1 if dx > 0 else -1
			"ghost":
				e.dir = 1 if dx > 0 else -1
				var dl: float = Vector2(dx, dy).length()
				if dl < 320:
					e.x += dx / max(1.0, dl) * 50.0 * D.spd * dt
					e.y += dy / max(1.0, dl) * 40.0 * D.spd * dt
				e.y += sin(e.t * 2) * 10.0 * dt
				if e.b == "ghost" and dim == 0:
					continue
		if not p.dead and ov(p, e) and not (b == "riser" and str(e.get("st", "")) != "walk"):
			_hurt(12.0 if b in ["flyer", "diver"] else 15.0, e.x + e.w / 2)

func _update_projs(dt: float) -> void:
	for q in projs.duplicate():
		q.life -= dt
		if q.type == "clock" and not boss.is_empty():
			var dd := Vector2(p.x + p.w / 2 - q.x, p.y + p.h / 2 - q.y).normalized()
			q.vx += dd.x * 300 * dt
			q.vy += dd.y * 300 * dt
			var vv := Vector2(q.vx, q.vy)
			if vv.length() > 260:
				vv = vv.normalized() * 260
				q.vx = vv.x
				q.vy = vv.y
		if q.has("grav"):
			q.vy += q.grav * dt
		q.x += q.vx * dt
		q.y += q.vy * dt
		var rem: bool = q.life <= 0.0
		if q.type in ["bolt", "wormball", "spore", "bomb"]:
			for s in level.plats:
				if s.k == "solid" and ov({"x": q.x - q.hw, "y": q.y - q.hh, "w": q.hw * 2, "h": q.hh * 2}, s):
					rem = true
					_burst(q.x, q.y, Color(1, 0.7, 0.4), 6, 100, 200, 0.3)
					break
		var rr := {"x": q.x - q.hw, "y": q.y - q.hh, "w": q.hw * 2, "h": q.hh * 2}
		if not rem and not p.dead and ov(rr, p):
			if _hurt(q.dmg, q.x):
				rem = true
		if rem:
			projs.erase(q)
	var A: Dictionary = level.arena
	for w in warns.duplicate():
		w.t -= dt
		if w.t <= 0.0 and not A.is_empty():
			match str(w.get("kind", "")):
				"sand":
					projs.append({"x": w.x, "y": A.floor - 560, "vx": 0.0, "vy": 150.0, "grav": 1000.0, "hw": 10.0, "hh": 10.0, "type": "sandblock", "dmg": 15.0, "life": 3.0})
				"feather":
					projs.append({"x": w.x, "y": A.floor - 560, "vx": randf_range(-30, 30), "vy": 420.0, "hw": 4.0, "hh": 10.0, "type": "feather", "dmg": 12.0, "life": 3.0})
				"ice":
					projs.append({"x": w.x, "y": A.floor - 540, "vx": 0.0, "vy": 200.0, "grav": 1200.0, "hw": 6.0, "hh": 12.0, "type": "icicle", "dmg": 15.0, "life": 3.0})
				_:
					projs.append({"x": w.x, "y": A.floor - 560, "vx": 0.0, "vy": 150.0, "grav": 900.0, "hw": 9.0, "hh": 9.0, "type": "fire", "dmg": 15.0, "life": 3.0})
			warns.erase(w)
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
func _boss_type() -> int:
	return int(WD.get("boss", {}).get("type", 0))

func _boss_art() -> String:
	var skin = WD.get("boss", {}).get("skin")
	if skin is String and skin != "":
		return skin
	return BOSS_ART.get(_boss_type(), "hdb_demon")

func _spawn_boss() -> void:
	var A: Dictionary = level.arena
	var D: Dictionary = DIFFS[diff_idx]
	var bt := _boss_type()
	boss = CrBosses.spawn(bt, A)
	boss.skin = WD.get("boss", {}).get("skin")
	boss.merge({"type": bt, "vx": 0.0, "vy": 0.0, "t": 0.0, "face": -1, "anim": 0.0, "hit": 0.0, "dying": false, "done": false, "dieT": 0.0}, false)
	boss.max = round(BOSS_HP[min(bt, BOSS_HP.size() - 1)] * D.boss)
	boss.hp = boss.max
	for l in level.levers:
		l.on = false
	for e in level.enemies:
		if e.x > A.x1 - 300:
			e.dead = true
	_boss_proxy.activate(str(WD.get("boss", {}).get("name", "GUARDIÁN")), boss.max)

func _hit_boss(hb: Dictionary, from_above := false) -> void:
	p.hitSet.append("boss")
	var b := boss
	var rule: float = CrBosses.hit_rule(self, b, from_above)
	if rule == -2.0:
		Aether.sfx("ghost", 0.6)
		_float(b.x + b.w / 2, b.y - 10, "ESPECTRAL (usa SHIFT)", Color(0.75, 0.91, 1))
		return
	if rule == 0.0:
		Aether.sfx("clang", 0.7)
		_float(b.x + b.w / 2, b.y - 10, "ESCUDO" if b.type in [2, 9] else "INMUNE", Color(0.2, 0.89, 1))
		return
	if rule < 0.0:
		Aether.sfx("clang", 0.8)
		p.vx = -p.face * 260.0
		_float(b.x + b.w / 2, b.y - 10, "¡BLOQUEO!", Color.WHITE)
		return
	if from_above:
		if float(b.get("pogoCD", 0.0)) > 0.0:
			return
		b.pogoCD = 0.75
		b.pogoN = (int(b.get("pogoN", 0)) if float(b.get("pogoT", 0.0)) > 0.0 else 0) + 1
		b.pogoT = 2.6
		if b.pogoN >= 3 and rule < 1.6:
			_boss_shake()
			return
		rule *= 0.6 if rule >= 1.6 else 0.4
	var dmg: float = (1.6 if p.atkN == 2 else 1.0) * rule
	if rule >= 1.6:
		_float(b.x + b.w / 2, b.y - 14, "¡CRÍTICO!", Color(1, 0.83, 0.3), 18)
		hit_stop = 0.1
		shake = max(shake, 9.0)
	elif rule <= 0.4:
		_float(b.x + b.w / 2, b.y - 10, "DURO", Color(0.66, 0.7, 0.78), 13)
		Aether.sfx("clang", 0.35, 1.3)
	boss.hp -= dmg
	boss.hit = 0.12
	score += 25
	hit_stop = max(hit_stop, 0.06)
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

func _boss_shake() -> void:
	var b := boss
	var bcx: float = b.x + b.w / 2
	var dir: float = signf(p.x + p.w / 2 - bcx)
	if dir == 0.0:
		dir = 1.0
	b.pogoN = 0
	b.pogoCD = 1.2
	shake = max(shake, 12.0)
	Aether.sfx("roar", 0.7, 0.8)
	_hurt(12, bcx)
	p.vy = -640.0
	p.vx = dir * 420.0
	p.hook = null
	_float(bcx, b.y - 18, "¡TE SACUDE!", Color(1, 0.54, 0.48), 18)

func _update_boss(dt: float) -> void:
	if boss.is_empty() or boss.done:
		return
	var D: Dictionary = DIFFS[diff_idx]
	var A: Dictionary = level.arena
	var b := boss
	b.hit = max(0.0, b.hit - dt)
	b.anim += dt
	if float(b.get("pogoCD", 0.0)) > 0.0:
		b.pogoCD -= dt
	if float(b.get("pogoT", 0.0)) > 0.0:
		b.pogoT -= dt
	if b.dying:
		b.dieT -= dt
		if randf() < 0.25:
			_burst(b.x + randf() * b.w, b.y + randf() * b.h, Color(0.9, 0.95, 0.8), 10, 160, 100, 0.6, 3)
			shake = max(shake, 5.0)
			Aether.sfx("boom", 0.4)
		if int(b.type) in [1, 3, 6, 10, 11]:
			b.y = min(A.floor - b.h, b.y + 120 * dt)
		if b.dieT <= 0.0:
			b.done = true
			_burst(b.x + b.w / 2, b.y + b.h / 2, Color.WHITE, 50, 380, 100, 1.2, 3)
			if _story_on():
				state = "story"
				var after := func() -> void:
					state = "playing"
					_stage_clear()
				var cut_id: String = {7: "mid", 10: "veil", 17: "late", 11: "ending"}.get(wi, "")
				story.say(CrStory.data().fragl[wi], true, func() -> void:
					if cut_id != "":
						story.play_cut(cut_id, after)
					else:
						after.call())
			else:
				_stage_clear()
		return
	if boss_intro > 0.0:
		if story and story.busy():
			boss_intro = max(boss_intro, 0.6)
			return
		boss_intro -= dt
		if boss_intro <= 0.0:
			hint_txt = Aether.t(str(WD.get("boss", {}).get("hint", "")))
			hint_t = 3.0
		return
	b.t += dt
	var pcx: float = p.x + p.w / 2
	var bcx: float = b.x + b.w / 2
	var ag: float = D.aggr * (1.2 if b.hp <= b.max / 2 else 1.0)
	if int(b.type) != 0:
		var contact: bool = CrBosses.update(self, b, dt, A, ag, pcx, p.y + p.h / 2, bcx)
		if contact and not p.dead and ov(p, b) and int(b.type) != 7:
			_hurt(20.0, bcx)
		return
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
	var vsz := get_viewport_rect().size
	VH = 420.0 if arena_lock else 270.0
	VW = round(vsz.x / vsz.y * VH / 2.0) * 2.0
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
	_camera.zoom = _camera.zoom.lerp(Vector2(z, z), 1.0 if snap else min(1.0, dt * 4.0))
	var sh := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 0.4
	_camera.position = cam + sh
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
	var tx := Aether.tex("tx%d" % wi)
	var ed := Aether.tex("ed%d" % wi)
	var wcol := Color.from_string(str(WD.get("c", "#7dea5a")), Color(0.5, 0.9, 0.4))
	# zonas
	for z in level.zones:
		var zr := Rect2(z.x, z.y, z.w, z.h)
		match z.k:
			"water":
				draw_rect(zr, Color(0.2, 0.5, 0.8, 0.35))
				draw_rect(Rect2(z.x, z.y, z.w, 2), Color(0.8, 0.95, 1, 0.7))
			"wind":
				for i in 6:
					var yy: float = z.y + fmod(i * 53.0 + (time * 300.0 if z.fy != 0 else 0.0), z.h)
					var xx: float = z.x + fmod(i * 97.0 + (time * -float(z.fx) * 0.3 if z.fx != 0 else 0.0), z.w)
					draw_line(Vector2(xx, yy), Vector2(xx + (20.0 if z.fx != 0 else 0.0), yy + (0.0 if z.fx != 0 else 20.0)), Color(1, 1, 1, 0.35), 1.5)
			"lowgrav":
				draw_rect(zr, Color(0.6, 0.5, 1, 0.08))
			"sand":
				draw_rect(zr, Color(0.9, 0.75, 0.4, 0.3))
	# decorado pintado
	for dco in level.decor:
		if dco.x < cam.x - 200 or dco.x > cam.x + VW + 200:
			continue
		var sway: float = sin(time * 1.3 + float(dco.get("ph", 0.0))) * 0.6
		_sheet_frame(str(dco.k), int(time * 8 + float(dco.get("ph", 0.0))), Vector2(dco.x + sway, dco.y), dco.get("flip", false))
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
					var em: Dictionary = Aether.sheet("ed0")
					var gy: float = float(em.get("gy", 9))
					var eh: float = ed.get_height() / 3.0
					draw_texture_rect_region(ed, Rect2(s.x, s.y - gy, s.w, eh), Rect2(s.x * 3.0, 0, s.w * 3.0, ed.get_height()))
				else:
					draw_rect(Rect2(s.x, s.y, s.w, 5), Color(0.45, 0.8, 0.3))
				draw_rect(Rect2(s.x, s.y + r.size.y - 30, s.w, 30), Color(0, 0, 0, 0.25))
				if s.get("conv", 0) != 0:
					for i in int(s.w / 20):
						var cxp: float = s.x + fmod(i * 20.0 + time * 60.0 * float(s.conv), s.w)
						draw_line(Vector2(cxp, s.y + 3), Vector2(cxp + 6 * float(s.conv), s.y + 3), Color(1, 0.9, 0.4, 0.8), 2)
			"move":
				draw_rect(r, Color(0.55, 0.42, 0.3))
				draw_rect(Rect2(s.x, s.y, s.w, 4), wcol)
			"break":
				if s.st < 2 or s.oy < 400:
					var shake_x: float = randf_range(-1, 1) if s.st == 1 else 0.0
					var br := Rect2(s.x + shake_x, s.y + s.oy, s.w, 16)
					draw_rect(br, Color(0.45, 0.33, 0.28, 1.0 if s.st < 2 else 0.6))
					draw_rect(Rect2(br.position, Vector2(s.w, 3)), wcol.darkened(0.2))
					for i in int(s.w / 16):
						draw_line(Vector2(s.x + i * 16 + 8, s.y + s.oy + 4), Vector2(s.x + i * 16 + 12, s.y + s.oy + 12), Color(0, 0, 0, 0.4), 1)
			"phase":
				var on: bool = int(s.ph) == dim
				var pc := Color(0.2, 0.89, 1) if int(s.ph) == 0 else Color(0.82, 0.44, 1)
				if on:
					draw_rect(r, Color(pc.r, pc.g, pc.b, 0.55))
					draw_rect(r, pc, false, 2)
				else:
					draw_rect(r, Color(pc.r, pc.g, pc.b, 0.12))
					draw_rect(r, Color(pc.r, pc.g, pc.b, 0.35), false, 1)
			"laser":
				var lc := Color(1, 0.2, 0.3, 0.9) if s.get("on", true) else (Color(1, 0.6, 0.6, 0.5) if s.get("warn", false) else Color(1, 0.3, 0.3, 0.15))
				draw_rect(Rect2(s.x, s.y + 2, s.w, 4), lc)
				draw_rect(Rect2(s.x - 4, s.y - 2, 6, 12), Color(0.4, 0.4, 0.5))
				draw_rect(Rect2(s.x + s.w - 2, s.y - 2, 6, 12), Color(0.4, 0.4, 0.5))
			"door":
				var op: float = float(s.get("open", 0.0))
				var dh: float = s.h * (1.0 - op)
				if dh > 1:
					draw_rect(Rect2(s.x, s.y + s.h - dh, s.w, dh), Color(0.3, 0.28, 0.35))
					draw_rect(Rect2(s.x, s.y + s.h - dh, s.w, dh), Color(1, 0.45, 0.35, 0.8) if s.get("trial", false) else wcol, false, 2)
			"bounce":
				var sq: float = clamp(float(s.sq) / 0.3, 0.0, 1.0)
				draw_rect(Rect2(s.x + 4, s.y + 4 + sq * 5, s.w - 8, s.h - 4 - sq * 5), Color(1, 0.45, 0.65))
				draw_rect(Rect2(s.x, s.y + sq * 5, s.w, 5), Color(1, 0.8, 0.9))
	for l in level.lavaStrips:
		draw_rect(Rect2(l.x, l.y, l.w, 300), Color(0.9, 0.3, 0.05))
		draw_rect(Rect2(l.x, l.y, l.w, 4), Color(1, 0.8, 0.3))
	for q in level.plates:
		draw_rect(Rect2(q.x, q.y + (3 if q.get("on", false) else 0), q.w, q.h), Color(0.6, 1, 0.69) if q.get("on", false) else Color(0.9, 0.7, 0.3))
	for h in level.hazards:
		if h.k == "icicle":
			draw_colored_polygon(PackedVector2Array([Vector2(h.x, h.y), Vector2(h.x + 12, h.y), Vector2(h.x + 6, h.y + 18)]), Color(0.8, 0.94, 1, 0.9 if int(h.get("st", 0)) != 3 else 0.0))
		elif h.k == "jet":
			draw_rect(Rect2(h.x, GY - 6, h.w, 6), Color(0.3, 0.25, 0.25))
			if h.get("warn", false):
				draw_rect(Rect2(h.x + 4, GY - 14, h.w - 8, 8), Color(1, 0.6, 0.2, 0.5))
			if h.get("on", false):
				draw_rect(Rect2(h.x + 3, h.y, h.w - 6, h.h), Color(1, 0.55, 0.15, 0.55))
		elif h.k == "spike":
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
	for w in warns:
		var a2: float = 0.4 + 0.4 * sin(time * 30)
		draw_rect(Rect2(w.x - 12, level.arena.get("floor", GY) - 3, 24, 3), Color(1, 0.24, 0.35, a2))
		draw_line(Vector2(w.x, level.arena.get("floor", GY) - 3), Vector2(w.x, level.arena.get("floor", GY) - 40), Color(1, 0.24, 0.35, a2 * 0.5), 2)
	for q in projs:
		match str(q.type):
			"laser":
				draw_rect(Rect2(q.x - q.hw, q.y - q.hh, q.hw * 2, q.hh * 2), Color(1, 0.3, 0.35))
				draw_rect(Rect2(q.x - q.hw, q.y - 1, q.hw * 2, 2), Color(1, 0.9, 0.9))
			"fire", "hfire":
				draw_circle(Vector2(q.x, q.y), q.hw + 3, Color(1, 0.45, 0.1, 0.4))
				draw_circle(Vector2(q.x, q.y), q.hw * 0.7, Color(1, 0.85, 0.3))
			"bubble":
				draw_arc(Vector2(q.x, q.y), q.hw, 0, TAU, 16, Color(0.75, 0.96, 1), 2)
			"clock":
				draw_circle(Vector2(q.x, q.y), q.hw, Color(1, 0.85, 0.4))
				draw_line(Vector2(q.x, q.y), Vector2(q.x + cos(time * 6) * 6, q.y + sin(time * 6) * 6), Color(0.2, 0.15, 0.1), 2)
			"ring":
				draw_arc(Vector2(q.x, q.y), q.hw, 0, TAU, 20, Color(1, 1, 0.9), 3)
			"feather", "icicle", "sandblock":
				draw_rect(Rect2(q.x - q.hw, q.y - q.hh, q.hw * 2, q.hh * 2), Color(0.95, 0.95, 1) if q.type != "sandblock" else Color(0.85, 0.7, 0.4))
			_:
				draw_circle(Vector2(q.x, q.y), q.hw + 2, Color(1, 0.5, 0.9, 0.35))
				draw_circle(Vector2(q.x, q.y), q.hw * 0.8, Color(1, 0.75, 1))
	for l in level.levers:
		draw_rect(Rect2(l.x, l.y + l.h - 8, l.w, 8), Color(0.35, 0.3, 0.3))
		var ang: float = -0.6 if l.get("on", false) else 0.6
		draw_line(Vector2(l.x + l.w / 2, l.y + l.h - 6), Vector2(l.x + l.w / 2 + sin(ang) * 22, l.y + l.h - 6 - cos(ang) * 22), Color(0.6, 1, 0.69) if l.get("on", false) else Color(1, 0.7, 0.3), 4)
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
	var rf = level.get("rift")
	if rf is Dictionary and not rf.is_empty():
		var c2 := Vector2(rf.x + rf.w / 2, rf.y + rf.h / 2)
		for k in 3:
			draw_arc(c2, 14 + k * 6 + sin(time * 3 + k) * 2, 0, TAU, 24, Color(0.78, 0.47, 1, 0.7 - k * 0.2), 3)
		draw_circle(c2, 10, Color(0.9, 0.7, 1, 0.5 + sin(time * 5) * 0.2))
	for a in level.anchors:
		var near: bool = p.hook == null and not p.onGround and Vector2(a.x - (p.x + p.w / 2), a.y - (p.y + p.h / 2)).length() < 160
		draw_arc(Vector2(a.x, a.y), 9, 0, TAU, 18, Color(1, 0.83, 0.3), 3)
		if near:
			draw_arc(Vector2(a.x, a.y), 14 + sin(time * 8) * 2, 0, TAU, 18, Color(1, 0.95, 0.6, 0.6), 2)
	if p.hook != null:
		draw_line(Vector2(p.hook.a.x, p.hook.a.y), Vector2(p.x + p.w / 2, p.y + p.h / 2), Color(1, 0.9, 0.6), 2)
	var rl = level.get("relic")
	if rl is Dictionary and not rl.is_empty() and not rl.get("taken", false):
		var ry: float = rl.y + sin(time * 2) * 3
		draw_colored_polygon(PackedVector2Array([Vector2(rl.x - 7, ry - 10), Vector2(rl.x + 7, ry - 10), Vector2(rl.x, ry)]), Color(1, 0.85, 0.4))
		draw_colored_polygon(PackedVector2Array([Vector2(rl.x - 7, ry + 10), Vector2(rl.x + 7, ry + 10), Vector2(rl.x, ry)]), Color(1, 0.85, 0.4))
		draw_circle(Vector2(rl.x, ry), 16, Color(1, 0.85, 0.4, 0.15 + sin(time * 4) * 0.08))
	for c in level.get("chases", []):
		if c.st == 1:
			var lk: Array = CHASE_LOOK.get(wi, CHASE_LOOK[1])
			var c0: Color = lk[0]
			draw_rect(Rect2(c.wx - 600, cam.y - 20, 600, VH + 40), Color(c0.r, c0.g, c0.b, 0.95))
			for i in 8:
				var a3 := 0.85 - i * 0.1
				draw_rect(Rect2(c.wx + i * 4, cam.y - 20, 4, VH + 40), Color(c0.r, c0.g, c0.b, a3))
			var c1: Color = lk[1]
			var yy0: float = floor(cam.y / 14.0) * 14.0
			for k in int(VH / 14) + 3:
				draw_rect(Rect2(c.wx + sin(time * 9 + k) * 6, yy0 + k * 14, 3, 9), Color(c1.r, c1.g, c1.b, 0.7))
	if not p.dead:
		var tt := Aether.tex("TicHD")
		var tm: Dictionary = Aether.sheet("TicHD")
		if tt and not tm.is_empty():
			var tn: int = int(tm.get("n", 1))
			var tfw: float = float(tm.fw)
			var tfh: float = float(tm.fh)
			var tf: int = int(time * 12) % tn
			var sc: float = 0.25
			var dst := Rect2(tic.x - float(tm.get("ax", tfw / 2)) * sc * tic.face, tic.y + sin(time * 3) * 1.5 - float(tm.get("ay", tfh / 2)) * sc, tfw * sc * tic.face, tfh * sc)
			draw_texture_rect_region(tt, dst, Rect2(tf * tfw, 0, tfw, tfh))
		draw_circle(Vector2(tic.x, tic.y), 14, Color(1, 0.78, 0.43, 0.12))
	if slow_t > 0.0:
		draw_rect(Rect2(cam.x - 10, cam.y - 10, VW + 20, VH + 20), Color(0.45, 0.75, 1, 0.1))
	# vidas y poder del tiempo (debajo de la vida)
	var hx := cam.x + 14
	var hy := cam.y + 46
	if LIVES_BY[diff_idx] < 99:
		for i in LIVES_BY[diff_idx]:
			var full: bool = i < lives
			draw_circle(Vector2(hx + i * 14, hy), 5, Color(1, 0.3, 0.4) if full else Color(0.3, 0.3, 0.35))
	draw_rect(Rect2(hx - 5, hy + 10, 80, 5), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(hx - 5, hy + 10, 80 * p.get("time", 0.0) / 100.0, 5), Color(0.5, 0.88, 1) if p.get("time", 0.0) >= 100.0 else Color(0.3, 0.55, 0.9))
	if dim == 1:
		draw_rect(Rect2(cam.x - 10, cam.y - 10, VW + 20, VH + 20), Color(0.5, 0.2, 0.7, 0.12))
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
	var dens: float = float(m.get("d", 1.0))
	var src := Rect2(f * fw * dens, 0, fw * dens, fh * dens)
	var w := fw * scale_k
	var h := fh * scale_k
	var x := pos.x - (fw - ax if flip else ax) * scale_k
	var dst := Rect2(x, pos.y - ay * scale_k, w, h)
	if flip:
		dst = Rect2(x + w, dst.position.y, -w, h)
	draw_texture_rect_region(t, dst, src, mod)

func _draw_enemy(e: Dictionary) -> void:
	var d: Dictionary = e.d
	if e.b in ["revive"] or (e.b == "burrower" and str(e.get("st", "")) in ["under", "tele"]):
		draw_rect(Rect2(e.x, float(e.get("gy", e.y + e.h)) - 3, e.w, 3), Color(0.55, 0.43, 0.25, 0.8))
		return
	if float(e.get("pq", 0.0)) > 0.0 or float(e.get("pr", 0.0)) > 0.0:
		draw_circle(Vector2(e.x + e.w / 2, e.y + e.h / 2), 66 if float(e.get("pr", 0.0)) > 0.0 else 30 + sin(time * 30) * 6, Color(0.6, 0.9, 1, 0.25))
	if e.b == "riser" and str(e.get("st", "")) == "buried":
		draw_rect(Rect2(e.x, e.y + e.h - 3, e.w, 3), Color(0.3, 0.25, 0.2, 0.7))
		return
	var key: String = d.anim
	if e.b == "brute" and str(e.get("st", "")) in ["wind", "hit"] and d.has("atk"):
		key = d.atk
	if e.b == "jumper" and e.air:
		key = d.get("jump", key)
	var fr := int(e.t * 10)
	var flip: bool = (e.dir > 0) == (d.face < 0)
	var mod := Color(3, 3, 3) if e.hit > 0.0 else Color.WHITE
	if e.b == "ghost" and dim == 0:
		mod.a = 0.3
	if e.alert > 0.0:
		draw_string(_font, Vector2(e.x + e.w / 2 - 4, e.y - 6), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.3, 0.3))
	var sq := 1.0 + (0.12 if e.hit > 0.0 else 0.0)
	_sheet_frame(key, fr, Vector2(e.x + e.w / 2, e.y + e.h + 2 + float(d.get("oy", 0))), flip, sq, mod)

func _draw_boss() -> void:
	var b := boss
	if int(b.type) == 7:
		var kk: String = "KH_dash" if b.st == "dash" else ("KH_jump" if b.st == "jump" else ("KH_atk2" if b.st == "clocks" else ("KH_run" if abs(float(b.get("vx", 0.0))) > 10 else "KH_idle")))
		var mod7: Color = Color(3, 3, 3) if b.hit > 0.0 else Color(0.75, 0.45, 1.0)
		var m7: Dictionary = Aether.sheet(kk)
		var t7 := Aether.tex(kk)
		if t7:
			var n7: int = int(m7.get("n", 1))
			var fw7: float = float(m7.fw)
			var fh7: float = float(m7.fh)
			var fr7: int = int(time * 14) % n7
			var w7 := fw7 * 0.27
			var h7 := fh7 * 0.27
			var bx7: float = b.x + b.w / 2 - float(m7.ax) * 0.27 * b.face
			var r7 := Rect2(bx7, b.y + b.h + 2 - float(m7.ay) * 0.27, w7 * b.face, h7)
			draw_texture_rect_region(t7, r7, Rect2(fr7 * fw7, 0, fw7, fh7), mod7)
		return
	var art := _boss_art()
	var t := Aether.tex(art)
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
	var bm: Dictionary = Aether.sheet(art)
	var w: float = float(bm.get("fw", 136)) * sx
	var h: float = float(bm.get("fh", 120)) * sy * breathe
	var base := Vector2(b.x + b.w / 2, b.y + b.h + 2)
	draw_circle(Vector2(base.x, b.y + b.h + 2 if b.st != "air" else level.arena.floor + 2), b.w * 0.45, Color(0, 0, 0, 0.25))
	if t:
		var r := Rect2(base.x - w / 2, base.y - h, w, h)
		var sv = WD.get("boss", {}).get("sfl", false)
		var sfl: bool = bool(sv) if typeof(sv) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT] else false
		if (b.face > 0) != sfl:
			r = Rect2(base.x + w / 2, base.y - h, -w, h)
		var dn: float = float(bm.get("d", 1.0))
		var bn: int = int(bm.get("n", 1))
		var bf: int = int(time * 9) % bn if bn > 1 else 0
		var fwp: float = float(bm.get("fw", t.get_width())) * dn
		draw_texture_rect_region(t, r, Rect2(bf * fwp, 0, fwp, float(bm.get("fh", t.get_height())) * dn), mod)
		if (int(b.type) == 2 and b.get("vulnT", 0.0) <= 0.0) or (int(b.type) == 9 and b.get("vulnT", 0.0) <= 0.0):
			draw_arc(Vector2(base.x, base.y - h * 0.5), max(w, h) * 0.55, 0, TAU, 40, Color(0.3, 0.85, 1, 0.45 + sin(time * 4) * 0.15), 3)
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
	var gap_air: bool = not p.onGround and p.vy > -80 and _ground_below(p.x + p.w / 2 + (120.0 if want_right else -120.0), p.y + p.h, 300) == null
	if (gap_air or (gap and randf() < 0.05)) and p.dashCD <= 0.0 and p.jumps >= 2:
		Input.action_press("dash")
	else:
		Input.action_release("dash")

## Guardianes voladores (provisional hasta traducir cada uno): flotan, disparan
## ráfagas y bajan en picado; tras el picado quedan aturdidos (momento débil).
func _update_flying_boss(dt: float, b: Dictionary, A: Dictionary, ag: float, pcx: float) -> void:
	var pcy: float = p.y + p.h / 2
	b.face = -1 if pcx < b.x + b.w / 2 else 1
	match b.st:
		"idle":
			var tx: float = clamp(pcx - b.w / 2 + sin(b.anim * 0.8) * 180.0, A.x1 + 20, A.x2 - b.w - 20)
			var ty: float = A.floor - 290 + sin(b.anim * 1.7) * 30.0
			b.x = lerp(float(b.x), tx, min(1.0, dt * 1.6))
			b.y = lerp(float(b.y), ty, min(1.0, dt * 1.6))
			if b.t > 1.3 / ag:
				b.st = "fire"
				b.t = 0.0
				b.shots = 0
		"fire":
			if b.t > 0.32:
				b.t = 0.0
				b.shots += 1
				var c := Vector2(b.x + b.w / 2, b.y + b.h * 0.6)
				var d := (Vector2(pcx, pcy) - c).normalized()
				for a in [-0.25, 0.0, 0.25]:
					var v := d.rotated(a) * 230.0 * ag
					projs.append({"x": c.x, "y": c.y, "vx": v.x, "vy": v.y, "hw": 6.0, "hh": 6.0, "type": "orb", "dmg": 14.0, "life": 4.0})
				Aether.sfx("shoot", 0.5)
				if b.shots >= 3:
					b.st = "aim"
					b.t = 0.0
		"aim":
			b.x += sin(b.anim * 50.0) * 0.8
			if b.t > 0.7:
				b.st = "dive"
				b.t = 0.0
				var dv := (Vector2(pcx, A.floor - 20) - Vector2(b.x + b.w / 2, b.y + b.h / 2)).normalized()
				b.vx = dv.x * 520.0 * ag
				b.vy = dv.y * 520.0 * ag
				Aether.sfx("dash", 0.6, 0.7)
		"dive":
			b.x += b.vx * dt
			b.y += b.vy * dt
			b.x = clamp(b.x, A.x1, A.x2 - b.w)
			if b.y + b.h >= A.floor:
				b.y = A.floor - b.h
				b.st = "stun"
				b.t = 0.0
				shake = 14.0
				Aether.sfx("stomp")
				waves.append({"x": b.x + b.w / 2 - 50, "y": A.floor, "dir": -1.0, "spd": 300.0 * ag})
				waves.append({"x": b.x + b.w / 2 + 50, "y": A.floor, "dir": 1.0, "spd": 300.0 * ag})
		"stun":
			if b.t > 2.0 / sqrt(ag):
				b.st = "idle"
				b.t = 0.0

# ---------------- modos: Torre, Boss Rush, Grietas, Reto diario ----------------
func start_mode(m: String) -> void:
	mode = m
	score = 0
	match m:
		"torre":
			tower = {"floor": 0, "v": randi() % 2, "hp": -1.0}
			_tower_floor()
		"rush":
			rush = {"i": 0, "hp": -1.0}
			_rush_next()
		"diario":
			var d := int(Time.get_unix_time_from_system() / 86400.0)
			var fl: int = 1 + d % 9
			daily = {"d": d, "deaths": 0}
			start_stage(0, -1, "torre_v%d_%d" % [d % 2, fl])
			lives = 99
			_banner("RETO DIARIO · La misma fase para todos hoy")

func _tower_floor() -> void:
	tower.floor += 1
	var f: int = (int(tower.floor) - 1) % 40 + 1
	var hp_keep: float = tower.hp
	start_stage(0, -1, "torre_v%d_%d" % [tower.v, f])
	var k: float = 1.0 + tower.floor * 0.07
	for e in level.enemies:
		e.hp = ceil(e.hp * k)
	if hp_keep > 0.0:
		p.hp = min(p.maxHp, hp_keep + 25.0)
		hp_changed.emit(p.hp, p.maxHp)
	lives = 1
	var boss_floor: bool = int(tower.floor) % 10 == 0
	_banner("TORRE DEL TIEMPO · %sPISO %d · %s" % ["¡GUARDIÁN! · " if boss_floor else "", tower.floor, WD.name])

func _rush_next() -> void:
	var order: Array = data().order
	if rush.i >= order.size():
		_banner("¡BOSS RUSH COMPLETADO!")
		Aether.save.set_value("cr_rush", order.size())
		state = "victory"
		state_t = 0.0
		return
	var hp_keep: float = rush.hp
	start_stage(2, int(order[rush.i]))
	var A: Dictionary = level.arena
	p.x = A.x1 + 100
	p.y = A.floor - PH
	p.respawn = Vector2(p.x, p.y)
	p.safe = p.respawn
	if hp_keep > 0.0:
		p.hp = min(p.maxHp, hp_keep + 30.0)
		hp_changed.emit(p.hp, p.maxHp)
	lives = 1
	_update_camera(0.0, true)
	_banner("BOSS RUSH · %d / %d" % [rush.i + 1, order.size()])

func _mode_clear() -> void:
	match mode:
		"torre":
			tower.hp = p.hp
			score += 500 + int(tower.floor) * 100
			if int(tower.floor) >= 10:
				Aether.achievements.unlock("cr_torre10")
			if int(tower.floor) >= 25:
				Aether.achievements.unlock("cr_torre25")
			if int(tower.floor) > int(Aether.save.get_value("cr_torre", 0)):
				Aether.save.set_value("cr_torre", int(tower.floor))
			_tower_floor()
		"rush":
			rush.i += 1
			rush.hp = p.hp
			if int(rush.i) >= 6:
				Aether.achievements.unlock("cr_rush6")
			if int(rush.i) >= 18:
				Aether.achievements.unlock("cr_rush18")
			if int(rush.i) > int(Aether.save.get_value("cr_rush", 0)):
				Aether.save.set_value("cr_rush", int(rush.i))
			_rush_next()
		"grieta":
			_leave_rift(true)
		"diario":
			var t: float = level_time + int(daily.get("deaths", 0)) * 5.0
			var key := "cr_diario_%d" % int(daily.d)
			var prev: float = float(Aether.save.get_value(key, 0.0))
			var first: bool = prev == 0.0
			Aether.achievements.unlock("cr_diario")
			if first or t < prev:
				Aether.save.set_value(key, t)
			_banner("RETO DIARIO · %.1f s%s" % [t, " · ¡NUEVO RÉCORD!" if (first or t < prev) else ""])
			state = "victory"
			state_t = 0.0

func _mode_over() -> void:
	match mode:
		"torre":
			_banner("FIN DE LA TORRE · PISO %d (récord %d)" % [tower.floor, int(Aether.save.get_value("cr_torre", 0))])
		"rush":
			_banner("FIN DEL BOSS RUSH · %d guardianes" % rush.i)
	state = "victory"
	state_t = 0.0
	p.dead = true
	p.deadT = 99.0

func _enter_rift() -> void:
	rift_ret = {"level": level, "p": p.duplicate(), "act": act, "wi": wi, "score": score, "dim": dim}
	Aether.sfx("portal", 0.8)
	Aether.flash(Color(0.78, 0.47, 1), 0.5)
	var w := wi
	mode = "grieta"
	start_stage(1, -1, "grieta_%d" % w)
	for s in level.plats:
		if s.get("float", false) and s.w >= 48:
			var x: float = s.x + 14
			while x < s.x + s.w - 10:
				level.gems.append({"x": x, "y": s.y - 26, "taken": false, "ph": randf() * 6.0})
				x += 30
	for e in level.enemies:
		e.hp = max(1.0, e.hp - 1)
	level.rift = {}
	score = rift_ret.score
	lives = 99
	_banner("GRIETA DEL TIEMPO · ¡recoge todo lo que puedas!")

func _leave_rift(won: bool) -> void:
	var got := 0
	for g in level.gems:
		if g.taken:
			got += 1
	var R := rift_ret
	mode = "historia"
	wi = R.wi
	act = R.act
	WD = data().worlds[wi]
	level = R.level
	p = R.p
	p.dead = false
	p.inv = 1.5
	dim = R.dim
	level.rift = {}
	state = "playing"
	_bg.texture = Aether.tex("pbg%d" % wi)
	if won:
		var sec: Array = Aether.save.get_value("cr_grietas", [])
		if not wi in sec:
			sec.append(wi)
			Aether.save.set_value("cr_grietas", sec)
		score += got * 100
		Aether.achievements.unlock("cr_grieta1")
		_banner("¡GRIETA SUPERADA! · %d fragmentos" % got)
		Aether.sfx("relic", 0.7)
	else:
		score = R.score
		_banner("La grieta te expulsa…")
	hp_changed.emit(p.hp, p.maxHp)
	_update_camera(0.0, true)
