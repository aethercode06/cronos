class_name CrFoes
extends RefCounted
## Comportamientos propios de los enemigos (foes.js y bestiary.js del juego web):
## embestida, francotirador, el que suelta cosas, el que va bajo la arena,
## el disfrazado, el que se recompone, libros que persiguen, brutos y medusas.

const OWN := ["rammer", "sniper", "dropper", "burrower", "dormant", "revive", "book", "brute"]

static func update(g, e: Dictionary, dt: float, D: Dictionary, pcx: float, pcy: float) -> void:
	var cx: float = e.x + e.w / 2
	var dx: float = pcx - cx
	var dy: float = pcy - (e.y + e.h / 2)
	var adx: float = abs(dx)
	var d: Dictionary = e.d
	var st: String = str(e.get("st", ""))
	match str(e.b):
		"rammer":
			if st == "walk" or st == "" or st == "0":
				e.st = "walk"
				if e.hit <= 0.0:
					var nx: float = e.x + e.dir * float(d.get("spd", 70)) * D.spd * dt
					var fx: float = nx + e.w + 2 if e.dir > 0 else nx - 2
					if g._ground_below(fx, e.y + e.h, 14) != null and nx > e.minX and nx < e.maxX:
						e.x = nx
					else:
						e.dir *= -1
				e.cd -= dt
				if adx < 320 and abs(dy) < 60 and e.cd <= 0.0 and not g.p.dead:
					e.dir = 1 if dx > 0 else -1
					e.st = "aim"
					e.tt = 0.65 / max(0.7, D.aggr)
					e.alert = e.tt
					Aether.sfx("roar", 0.35, 1.4)
			elif st == "aim":
				e.tt -= dt
				if e.tt <= 0.0:
					e.st = "run"
					e.run = 0.0
					Aether.sfx("dash", 0.35, 1.2)
			elif st == "run":
				var sp: float = (480.0 if g.wi == 5 else 400.0) * D.spd
				var nx2: float = e.x + e.dir * sp * dt
				var fx2: float = nx2 + e.w + 2 if e.dir > 0 else nx2 - 2
				e.run += sp * dt
				var wall := false
				for s in g.level.plats:
					if s.k == "solid" and not s.get("float", false) and CrGame.ov({"x": nx2, "y": e.y + 2, "w": e.w, "h": e.h - 6}, s):
						wall = true
						break
				if g._ground_below(fx2, e.y + e.h, 14) == null or wall or e.run > (520.0 if g.wi == 5 else 380.0):
					e.st = "stun"
					e.tt = 1.1
					if wall:
						g.shake = max(g.shake, 4.0)
						Aether.sfx("stomp", 0.4)
				else:
					e.x = nx2
			elif st == "stun":
				e.tt -= dt
				if e.tt <= 0.0:
					e.st = "walk"
					e.cd = 1.2
		"sniper":
			e.dir = 1 if dx > 0 else -1
			if st != "aim":
				e.cd -= dt
				if e.cd <= 0.0 and Vector2(dx, dy).length() < 540 and not g.p.dead:
					e.st = "aim"
					e.tt = 1.15 / max(0.7, D.aggr)
					Aether.sfx("alert", 0.3, 1.4)
			else:
				e.tt -= dt
				if e.tt > 0.35:
					e.tx = pcx
					e.ty = pcy
				if e.tt <= 0.0:
					var o := Vector2(cx + e.dir * 10, e.y + 8)
					var v: Vector2 = (Vector2(e.tx, e.ty) - o).normalized() * 720.0 * D.spd
					g.projs.append({"x": o.x, "y": o.y, "vx": v.x, "vy": v.y, "hw": 6.0, "hh": 4.0, "type": "bolt", "dmg": 14.0, "life": 2.0})
					Aether.sfx("shoot", 0.45, 0.8)
					e.st = "idle"
					e.cd = randf_range(2.0, 2.8) / D.aggr
		"dropper":
			if st != "drop":
				var tx: float = clamp(pcx, e.x0 - 260, e.x0 + 260) - e.w / 2
				e.x += clamp(tx - e.x, -1.0, 1.0) * 95.0 * D.spd * dt
				e.y = e.y0 + sin(e.t * 2) * 8.0
				e.dir = 1 if dx > 0 else -1
				e.cd -= dt
				if e.cd <= 0.0 and adx < 24 and pcy > e.y and not g.p.dead:
					e.st = "drop"
					e.tt = 0.55
					e.alert = 0.55
			else:
				e.tt -= dt
				if e.tt <= 0.0:
					var kind: String = "icicle" if g.wi in [5, 14] else ("sandblock" if g.wi == 9 else "orb")
					g.projs.append({"x": cx, "y": e.y + e.h, "vx": 0.0, "vy": 60.0, "grav": 900.0, "hw": (9.0 if kind == "sandblock" else 5.0), "hh": 8.0, "type": kind, "dmg": 14.0, "life": 3.0})
					Aether.sfx("ice" if kind == "icicle" else "swing", 0.4)
					e.st = "hover"
					e.cd = randf_range(1.8, 2.6) / D.aggr
		"burrower":
			if not e.has("gy"):
				e.gy = e.y + e.h
			if st == "under" or st == "" or st == "0":
				e.st = "under"
				e.y = e.gy + 60
				e.dir = 1 if dx > 0 else -1
				var nx3: float = e.x + e.dir * 105.0 * D.spd * dt
				if g._ground_below(nx3 + e.w / 2, e.gy, 8) != null and nx3 > e.minX - 200 and nx3 < e.maxX + 200:
					e.x = nx3
				if randf() < 0.35:
					g.parts.append({"x": cx + randf_range(-8, 8), "y": e.gy - 2, "vx": randf_range(-30, 30), "vy": randf_range(-90, -30), "life": 0.4, "max": 0.4, "c": Color(0.88, 0.69, 0.38), "s": 2.0, "g": 400.0})
				e.cd -= dt
				if e.cd <= 0.0 and adx < 26 and abs(pcy - e.gy) < 90 and not g.p.dead:
					e.st = "tele"
					e.tt = 0.6
					Aether.sfx("crumble", 0.45)
			elif st == "tele":
				e.tt -= dt
				if e.tt <= 0.0:
					e.st = "up"
					e.y = e.gy - e.h
					e.vy = -420.0
					g.shake = max(g.shake, 4.0)
					Aether.sfx("stomp", 0.5)
			elif st == "up":
				e.vy += 1400.0 * dt
				e.y += e.vy * dt
				if e.y + e.h >= e.gy:
					e.y = e.gy - e.h
					e.st = "surface"
					e.tt = 2.6
			elif st == "surface":
				e.tt -= dt
				e.dir = 1 if dx > 0 else -1
				if e.tt <= 0.0:
					e.st = "under"
					e.cd = 1.4
		"dormant":
			if adx < 115 and abs(dy) < 90:
				e.b = str(e.get("b0", "walker"))
				e.st = 0
				e.cd = 0.2
				e.alert = 0.4
				g._burst(cx, e.y + e.h / 2, Color(0.75, 0.44, 0.63), 18, 200, 300, 0.6, 3)
				Aether.sfx("crumble", 0.5)
				if e.b == "shooter":
					for vx in [-150.0, 0.0, 150.0]:
						g.projs.append({"x": cx, "y": e.y + 6, "vx": vx * D.spd, "vy": -330.0, "grav": 700.0, "hw": 6.0, "hh": 6.0, "type": "spore", "dmg": 12.0, "life": 3.0})
		"revive":
			e.tt -= dt
			e.y = e.gy + 80
			if e.tt <= 0.0:
				e.b = "riser"
				e.st = "buried"
				e.y = e.gy - e.h
		"book":
			if st == "idle" or st == "" or st == "0":
				e.st = "idle"
				e.x = e.x0 + sin(e.t * 1.3) * 20
				e.y = e.y0 + sin(e.t * 2.6) * 10
				if Vector2(dx, dy).length() < 300 and not g.p.dead:
					e.st = "chase"
					e.tt = 4.0
					e.vx = 0.0
					e.vy = 0.0
					Aether.sfx("swing", 0.3, 1.6)
			elif st == "chase":
				var n := Vector2(dx, dy).normalized()
				e.vx += n.x * 300 * dt
				e.vy += n.y * 300 * dt
				var vv := Vector2(e.vx, e.vy)
				var mx: float = 150.0 * D.spd
				if vv.length() > mx:
					vv = vv.normalized() * mx
					e.vx = vv.x
					e.vy = vv.y
				e.x += e.vx * dt
				e.y += e.vy * dt + sin(e.t * 14) * 0.6
				e.dir = 1 if e.vx > 0 else -1
				e.tt -= dt
				if e.tt <= 0.0 or Vector2(e.x - e.x0, e.y - e.y0).length() > 700:
					e.st = "rest"
					e.tt = 1.2
			elif st == "rest":
				e.tt -= dt
				e.vx *= 0.95
				e.vy *= 0.95
				e.x += e.vx * dt
				e.y += e.vy * dt
				if e.tt <= 0.0:
					e.st = "chase"
					e.tt = 3.0
		"brute":
			if st == "" or st == "0":
				e.st = "walk"
				st = "walk"
			e.cd -= dt
			var reach: float = float(d.get("reach", 46))
			if st == "walk":
				var sees: bool = adx < 260 and abs(dy) < 80 and not g.p.dead
				if sees:
					e.dir = 1 if dx > 0 else -1
				if sees and adx < reach + 10 and e.cd <= 0.0:
					e.st = "wind"
					e.tt = 0.5 / max(0.8, D.aggr)
					e.alert = e.tt
					Aether.sfx("swing", 0.3, 0.7)
				elif e.hit <= 0.0:
					var nx4: float = e.x + e.dir * float(d.get("spd", 50)) * D.spd * dt
					var fx4: float = nx4 + e.w + 2 if e.dir > 0 else nx4 - 2
					if g._ground_below(fx4, e.y + e.h, 14) != null and (sees or (nx4 > e.minX and nx4 < e.maxX)):
						e.x = nx4
					elif not sees:
						e.dir *= -1
			elif st == "wind":
				e.tt -= dt
				if e.hit > 0.1:
					e.st = "walk"
					e.cd = 0.8
				elif e.tt <= 0.0:
					e.st = "hit"
					e.tt = 0.32
					Aether.sfx("stomp", 0.45)
					g.shake = max(g.shake, 3.0)
			elif st == "hit":
				e.tt -= dt
				if not e.get("dmgDone", false) and not g.p.dead and CrGame.ov(g.p, {"x": (e.x + e.w - 6 if e.dir > 0 else e.x - reach + 6), "y": e.y - 6, "w": reach, "h": e.h + 8}):
					e.dmgDone = true
					g._hurt(18, cx)
				if e.tt <= 0.0:
					e.st = "walk"
					e.cd = 1.5 / D.aggr
					e.dmgDone = false

## Medusas que brillan antes de soltar una descarga.
static func pulse(g, e: Dictionary, dt: float, D: Dictionary, pcx: float, pcy: float) -> void:
	var dist := Vector2(pcx - (e.x + e.w / 2), pcy - (e.y + e.h / 2)).length()
	e.pc = float(e.get("pc", 1.5 + randf() * 2.0)) - dt
	if e.pc <= 0.0 and float(e.get("pq", 0.0)) <= 0.0 and dist < 260:
		e.pq = 0.8
		Aether.sfx("alert", 0.2, 1.8)
	if float(e.get("pq", 0.0)) > 0.0:
		e.pq -= dt
		if e.pq <= 0.0:
			e.pq = 0.0
			e.pc = 3.4 / D.aggr
			e.pr = 0.35
			Aether.sfx("shield", 0.4, 1.5)
			if dist < 66 and not g.p.dead:
				g._hurt(12, e.x + e.w / 2)
	if float(e.get("pr", 0.0)) > 0.0:
		e.pr = max(0.0, e.pr - dt)
