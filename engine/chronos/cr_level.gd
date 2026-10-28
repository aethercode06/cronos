class_name CrLevel
extends RefCounted
## Chronos en Aether Engine — generador de fases (traducción de buildStage de
## data.js + tramos de levels.js). Misma semilla y mismas medidas que el juego web.

const GY := 480.0
const PH := 48.0
const ENEMY := {
	"opossum": {"b": "walker", "anim": "opossum", "w": 32, "h": 22, "hp": 2, "face": -1, "spd": 70},
	"frog": {"b": "jumper", "anim": "frog_idle", "jump": "frog_jump", "w": 28, "h": 24, "hp": 2, "face": -1},
	"eagle": {"b": "flyer", "anim": "eagle", "w": 30, "h": 30, "hp": 1, "face": -1, "shot": "orb"},
}
const WORLD0 := {
	"name": "JUNGLA FLOTANTE", "g": ["opossum", "opossum", "frog"], "a": ["eagle"],
	"pool": ["spring", "bouncefield", "pits", "movepits", "mover", "elevator", "climb"], "sig": ["spring", "pits", "spikes"],
	"boss": "GRAN SAPO ANCESTRAL", "hint": "¡Salta las ondas de choque!",
}
const RATE := {"flat": 0, "gap": 1, "spring": 1, "stairs": 2, "mover": 2, "elevator": 2, "spikes": 2, "bouncefield": 2, "wallclimb": 3,
	"pits": 2.5, "movepits": 3, "climb": 2.5}

var L := {}
var _v := 0
var wi := 0
var act := 0
var diff := 1
var g := 0.0

# ---------------- azar con semilla (igual que seeded() del juego web) ----------------
func _seed(s: int) -> void:
	_v = s % 2147483647
	if _v <= 0:
		_v += 2147483646

func r() -> float:
	_v = (_v * 16807) % 2147483647
	return float(_v - 1) / 2147483646.0

func pick(a: Array):
	return a[int(floor(r() * a.size()))]

# ---------------- piezas ----------------
func solid(x: float, y: float, w: float, h: float, extra := {}) -> Dictionary:
	var s := {"k": "solid", "x": x, "y": y, "w": round(w / 16.0) * 16.0, "h": h}
	s.merge(extra, true)
	L.plats.append(s)
	return s

func G(x: float, w: float, top := 0.0) -> Dictionary:
	var t: float = top if top != 0.0 else GY
	return solid(x, t, w, (GY - top if top != 0.0 else 0.0) + 176.0, {"ground": true})

func P(x: float, y: float, w: float) -> Dictionary:
	return solid(x, y, max(32.0, w), 16.0, {"float": true})

func pillar(x: float, y1: float, y2: float, w := 24.0) -> Dictionary:
	return solid(x, y1, w, y2 - y1, {"ground": true, "pillar": true})

func M(x: float, y: float, w: float, bx: float, by: float, spd: float) -> void:
	L.plats.append({"k": "move", "x": x, "y": y, "w": max(32.0, round(w / 32.0) * 32.0), "h": 16.0, "ax": x, "ay": y, "bx": bx, "by": by, "spd": spd, "t": r() * 6.0, "dx": 0.0, "dy": 0.0})

func SPRING(x: float, y := GY) -> void:
	L.plats.append({"k": "bounce", "x": x - 20.0, "y": y - 12.0, "w": 40.0, "h": 14.0, "sq": 0.0})

func SPK(x: float, w: float, y := GY) -> void:
	L.hazards.append({"k": "spike", "x": x, "y": y - 12.0, "w": w, "h": 12.0})

func gem(x: float, y: float) -> void:
	L.gems.append({"x": x, "y": y, "taken": false, "ph": r() * 6.0})

func row(x: float, y: float, c: int, dx: float) -> void:
	for i in c:
		gem(x + i * dx, y)

func arc(x: float, y: float, c: int, dx: float, hgt := 30.0) -> void:
	for i in c:
		gem(x + i * dx, y - sin(float(i) / max(1, c - 1) * PI) * hgt)

func CH(x: float, y: float) -> void:
	L.cherries.append({"x": x, "y": y, "taken": false, "ph": r() * 6.0})

func E(slot: String, x: float, y: float, rng := 100.0) -> Dictionary:
	var id: String = pick(WORLD0.a if slot == "a" else WORLD0.g)
	var d: Dictionary = ENEMY[id]
	var h: float = d.h
	var e := {"id": id, "d": d, "b": d.b, "x": x, "y": (y if slot == "a" else y - h), "w": float(d.w), "h": h,
		"hp": float(d.hp) + (1.0 if act > 0 and d.hp > 2 else 0.0), "hit": 0.0, "t": r() * 5.0, "dir": -1, "minX": x - rng / 2.0, "maxX": x + rng / 2.0 - d.w,
		"cd": 1.0 + r() * 2.0, "dead": false, "x0": x, "y0": y, "alert": 0.0, "vy": 0.0, "vx": 0.0, "air": false, "kx": 0.0}
	L.enemies.append(e)
	return e

func hint(x: float, k: String) -> void:
	L.hints.append({"x": x, "k": k, "shown": false})

func check(x: float, y := GY - 40.0) -> void:
	L.checks.append({"x": x, "y": y, "w": 24.0, "h": 40.0, "on": false})

# ---------------- tramos ----------------
func chunk(k: String, x: float) -> float:
	match k:
		"flat":
			G(x, 512)
			if r() < 0.6:
				G(x + 40 + floor(r() * 3) * 16, 80 + floor(r() * 3) * 16, GY - 32)
			E("g", x + 300, GY, 220)
			if r() < 0.5 + (0.3 if diff >= 2 else 0.0):
				E("a", x + 200, 330, 0)
			arc(x + 160, 440, 5, 40, 40)
			return 512
		"mover":
			G(x, 128); M(x + 150, 430, 96, x + 330, 430, 1.2); G(x + 480, 128); arc(x + 170, 390, 5, 50, 30); E("a", x + 330, 300)
			return 608
		"elevator":
			G(x, 192); M(x + 40, 466, 96, x + 40, 286, 1.0); G(x + 160, 192, 300); G(x + 352, 224); row(x + 190, 270, 3, 45); E("g", x + 450, GY, 120)
			return 576
		"spring":
			G(x, 512); SPRING(x + 140); P(x + 210, 230, 176); row(x + 240, 200, 4, 40); E("g", x + 400, GY, 160)
			return 512
		"spikes":
			G(x, 576); SPK(x + 190, 96); SPK(x + 400, 64); arc(x + 190, 410, 3, 40, 20); E("g", x + 330, GY, 80); hint(x + 100, "spikes")
			return 576
		"bouncefield":
			G(x, 128); P(x + 176, 440, 48); SPRING(x + 200, 440); P(x + 352, 440, 48); SPRING(x + 376, 440); P(x + 230, 220, 112); G(x + 528, 128); row(x + 250, 190, 3, 35)
			return 656
		"pits":
			G(x, 128)
			var cx := x + 128
			var n := 3 + (1 if g > 0.45 else 0)
			for i in n:
				var gap: float = round(135 + r() * 30 + 105 * g)
				var w: float = round(88 - 32 * g)
				var y: float = 440 - (i % 2) * round(40 + 40 * g)
				P(cx + gap, y, w); gem(cx + gap / 2, y - 50)
				if i % 2 == 1 and g > 0.15:
					E("a", cx + gap + w / 2, y - 120)
				cx += gap + w
			var end: float = round(130 + 60 * g)
			G(cx + end, 160)
			return cx + end + 160 - x
		"movepits":
			G(x, 128)
			var sp := 0.9 + 0.5 * g
			M(x + 170, 430, 80, x + 370, 430, sp); M(x + 480, 400, 80, x + 480, 270, sp)
			arc(x + 190, 390, 4, 50, 30); gem(x + 520, 240)
			if g > 0.15:
				E("a", x + 420, 300)
			G(x + 650, 128)
			return 778
		"climb":
			G(x, 448)
			P(x + 60, 400, 112); P(x + 220, 320, 112); P(x + 60, 240, 112); P(x + 220, 160, 112); P(x + 380, 112, 176)
			pillar(x + 430, 150, 480, 24)
			E("g", x + 270, 320, 90)
			if g > 0.3:
				E("a", x + 150, 190)
			row(x + 400, 80, 4, 36); gem(x + 115, 210)
			G(x + 448, 192)
			return 640
		"wallclimb":
			G(x, 288); pillar(x + 192, 200, 396, 24); G(x + 288, 192, 200); G(x + 480, 224)
			row(x + 310, 170, 4, 40); hint(x + 60, "wallclimb"); E("g", x + 600, GY, 120)
			return 704
	return 0

# ---------------- fase completa ----------------
func build(p_wi: int, p_act: int, p_diff: int) -> Dictionary:
	wi = p_wi
	act = p_act
	diff = p_diff
	g = act * 0.07
	L = {"plats": [], "enemies": [], "gems": [], "cherries": [], "checks": [], "hazards": [], "hints": [], "goal": {}, "arena": {},
		"top": 0.0, "bottom": 540.0, "deathY": 720.0, "start": Vector2(70, GY - PH), "width": 0.0}
	_seed(1000 + wi * 97 + act * 31 + 7)
	var x := 0.0
	if act == 0:
		# MUNDO 1-1: tutorial diseñado a mano
		G(0, 576); row(200, 440, 4, 40); hint(40, "move")
		G(704, 512); E("g", 960, GY, 220); arc(760, 400, 3, 40, 20); hint(620, "sword")
		G(1216, 288, 400); row(1240, 370, 3, 40)
		G(1504, 256, 300); row(1530, 270, 4, 40); hint(1150, "doublejump")
		G(1760, 640); check(1800)
		SPRING(1960); P(2020, 236, 176); row(2045, 205, 4, 38); CH(2180, 205); hint(1880, "spring")
		P(2100, 120, 64); E("a", 2260, 330)
		G(2400, 160); M(2600, 430, 96, 2780, 430, 1.1); arc(2610, 380, 5, 50, 30); hint(2420, "mover")
		G(2960, 384); E("g", 3150, GY, 200)
		check(3000)
		G(3632, 512); arc(3380, 380, 5, 50, 70); hint(3200, "dash")
		SPK(3880, 96); arc(3870, 420, 3, 40, 10); hint(3700, "spikes"); E("g", 4050, GY, 80)
		var wc := 4144.0
		G(wc, 288); pillar(wc + 192, 200, 396, 24); G(wc + 288, 192, 200); G(wc + 480, 224); row(wc + 310, 170, 4, 40); hint(wc + 40, "wallclimb")
		check(wc + 500)
		var st := wc + 704
		P(st + 80, 420, 96); P(st + 230, 360, 96); P(st + 380, 300, 128); P(st + 560, 360, 96); P(st + 700, 420, 96); row(st + 400, 270, 3, 40); E("a", st + 420, 220)
		G(st + 840, 640); E("g", st + 1100, GY, 200); CH(st + 900, 440)
		x = st + 1480
		G(x, 448)
		L.goal = {"x": x + 260, "y": GY - 64, "w": 40.0, "h": 64.0}
		row(x + 80, 440, 3, 40)
		x += 448
		L.width = x
		return L
	G(0, 352)
	x = 352
	var n: int = min(WORLD0.pool.size() * 2, 12 if act == 0 else (14 if act == 1 else 7))
	var seq: Array = []
	var sig: Array = WORLD0.sig.duplicate()
	sig.append("wallclimb")
	if act == 1:
		sig.append(pick(WORLD0.pool))
		sig.append(pick(WORLD0.pool))
	if act == 2:
		sig.resize(min(sig.size(), 2))
	for s in sig:
		seq.append(s)
	while seq.size() < n:
		var c: String = pick(WORLD0.pool)
		if seq[seq.size() - 1] != c:
			seq.append(c)
	var cnt := {}
	var uniq: Array = []
	for s in seq:
		cnt[s] = cnt.get(s, 0) + 1
		if cnt[s] <= 2:
			uniq.append(s)
	while uniq.size() < n:
		var c2: String = pick(WORLD0.pool)
		if cnt.get(c2, 0) < 2:
			cnt[c2] = cnt.get(c2, 0) + 1
			uniq.append(c2)
	var keyed: Array = []
	for s in uniq:
		keyed.append([s, float(RATE.get(s, 1)) + r() * 1.6 + act * 0.3])
	keyed.sort_custom(func(a, b): return a[1] < b[1])
	seq = []
	for k in keyed:
		seq.append(k[0])
	for i in range(1, seq.size()):
		if seq[i] == seq[i - 1]:
			for j in range(i + 1, seq.size()):
				if seq[j] != seq[i]:
					var t = seq[i]
					seq[i] = seq[j]
					seq[j] = t
					break
	seq.push_front("flat")
	for i in seq.size():
		if i > 0 and i % 2 == 0:
			check(x + 40)
		x += chunk(seq[i], x)
		if i == int(seq.size() / 3.0) or i == int(seq.size() * 2 / 3.0):
			CH(x - 60, 440)
	L.seq = seq
	if act < 2:
		G(x, 448)
		L.goal = {"x": x + 260, "y": GY - 64, "w": 40.0, "h": 64.0}
		row(x + 80, 440, 3, 40)
		x += 448
		L.width = x
	else:
		check(x + 40)
		CH(x + 120, 440)
		var ax := x + 160
		G(x, 160 + 960 + 260)
		L.arena = {"x1": ax, "x2": ax + 960, "floor": GY}
		L.width = ax + 960 + 200
	return L
