class_name CrBosses
extends RefCounted
## Los 12 guardianes de Chronos traducidos de logic.js (tipos 0-7) y ext.js (8-11).
## Los mundos 13-18 usan estos mismos tipos con su propio dibujo (skin).

static func spawn(t: int, A: Dictionary) -> Dictionary:
	var cx: float = (A.x1 + A.x2) / 2.0
	var f: float = A.floor
	match t:
		0: return {"w": 116.0, "h": 92.0, "x": A.x2 - 260, "y": f - 92, "st": "idle"}
		1: return {"w": 104.0, "h": 84.0, "x": A.x2 - 170, "y": f - 300, "st": "move", "side": 1, "cycle": 0, "shots": 0, "aimY": 0.0}
		2: return {"w": 64.0, "h": 112.0, "x": cx - 32, "y": f - 112, "st": "stand", "cd": 2.0, "atk": 0, "vulnT": 0.0, "throwA": 0.0}
		3: return {"w": 72.0, "h": 56.0, "x": A.x2 - 220, "y": f - 300, "st": "hover", "cd": 1.5, "volleys": 0}
		4: return {"w": 52.0, "h": 100.0, "x": A.x2 - 200, "y": f - 100, "st": "walk", "cd": 2.0, "guardCD": 4.0, "summoned": false}
		5: return {"w": 120.0, "h": 64.0, "x": A.x2 - 220, "y": f - 64, "st": "idle", "cd": 1.2, "moves": 0}
		6: return {"w": 130.0, "h": 150.0, "x": cx - 55, "y": f - 360, "st": "fly", "cd": 1.5, "shots": 0}
		7: return {"w": 30.0, "h": 62.0, "x": A.x2 - 160, "y": f - 62, "st": "idle", "cd": 1.2, "moves": 0, "shiftT": 6.0}
		8: return {"w": 150.0, "h": 96.0, "x": A.x2 + 60, "y": f - 260, "st": "wait", "cd": 1.0, "side": 1, "n": 0, "ty": 0.0}
		9: return {"w": 140.0, "h": 120.0, "x": cx + 120, "y": f - 120, "st": "idle", "cd": 1.6, "n": 0, "vulnT": 0.0, "side": 1}
		10: return {"w": 70.0, "h": 120.0, "x": cx - 35, "y": f - 330, "st": "float", "cd": 1.5, "n": 0, "invCD": 9.0}
	return {"w": 170.0, "h": 150.0, "x": cx - 85, "y": f - 345, "st": "float", "cd": 2.0, "n": 0, "summoned": false}

## Multiplicador de daño según el momento débil de cada guardián (bossfix.js):
## 0 = inmune o escudo, -1 = bloqueo, -2 = espectral (solo en la dimensión violeta).
static func hit_rule(g, b: Dictionary, from_above: bool) -> float:
	var t: int = b.type
	var st: String = str(b.st)
	var behind: bool = (g.p.x + g.p.w / 2 - (b.x + b.w / 2)) * b.face < 0
	var skin = b.get("skin")
	if t == 2 and b.get("vulnT", 0.0) <= 0.0:
		return 0.0
	if t == 4 and st == "guard" and not behind and not from_above:
		return -1.0
	if skin == "boss_stag" and g.dim != 1:
		return -2.0
	match t:
		0: return 1.7 if (st == "idle" and b.t < 0.8) else (0.3 if st == "air" else 1.0)
		1: return 1.8 if st == "down" else 0.3
		2: return 1.3 if b.vulnT > 0.0 else 0.8
		3: return 1.8 if st == "stun" else 0.4
		4: return 1.4 if behind else (0.4 if st == "windup" else 0.7)
		5: return 1.8 if st == "stagger" else (0.3 if st == "charge" else 0.6)
		6: return 1.8 if st == "rest" else 0.3
		7: return 1.7 if st == "recover" else 0.6
		8:
			if skin == "boss_king":
				return (2.0 if behind else 1.0) if st == "stuck" else (0.5 if st == "spit" else 0.0)
			return 1.8 if st == "stuck" else (0.6 if st == "spit" else 0.0)
		9: return 1.7 if b.vulnT > 0.0 else 0.0
		10: return 1.8 if st == "stun" else 0.3
	return 1.8 if st == "tired" else 0.3

static func _warn(g, x: float, t: float, kind := "") -> void:
	g.warns.append({"x": x, "t": t, "kind": kind})

static func _wave(g, x: float, dir: float, spd: float, col := Color(0.78, 0.63, 0.44)) -> void:
	g.waves.append({"x": x, "y": g.level.arena.floor, "dir": dir, "spd": spd, "col": col})

static func _proj(g, x: float, y: float, vx: float, vy: float, hw: float, hh: float, type: String, dmg: float, life: float, grav := 0.0) -> Dictionary:
	var q := {"x": x, "y": y, "vx": vx, "vy": vy, "hw": hw, "hh": hh, "type": type, "dmg": dmg, "life": life}
	if grav != 0.0:
		q.grav = grav
	g.projs.append(q)
	return q

## Devuelve si el contacto con el jefe hace daño.
static func update(g, b: Dictionary, dt: float, A: Dictionary, ag: float, pcx: float, pcy: float, bcx: float) -> bool:
	var D: Dictionary = CrGame.DIFFS[g.diff_idx]
	var di: int = g.diff_idx
	var contact := true
	match int(b.type):
		1:
			b.face = -1 if b.side > 0 else 1
			if b.st == "move":
				var tx: float = A.x2 - b.w - 40 if b.side > 0 else A.x1 + 40
				var want: float = clamp(pcy, A.floor - 300, A.floor - 20)
				var ty: float = clamp(want - b.h * 0.5, A.floor - 340, A.floor - b.h - 10)
				b.x = lerp(float(b.x), tx, min(1.0, dt * 2.5))
				b.y = lerp(float(b.y), ty, min(1.0, dt * 2.5))
				if b.t > 1.4 / ag:
					b.st = "aim"
					b.t = 0.0
					b.aimY = want
					Aether.sfx("alert", 0.45)
			elif b.st == "aim":
				if b.t > 0.6 / sqrt(ag):
					b.st = "fire"
					b.t = 0.22
					b.shots = 0
			elif b.st == "fire":
				if b.t >= 0.22:
					b.t = 0.0
					b.shots += 1
					_proj(g, bcx - b.side * 50, b.aimY, -b.side * 560 * ag, 0, 26, 4, "laser", 14, 4)
					Aether.sfx("shoot", 0.6)
					if b.shots >= (4 if di >= 2 else 3):
						b.cycle += 1
						b.st = "drop" if b.cycle % 2 == 0 else "move"
						b.t = 0.0
			elif b.st == "drop":
				b.y = min(A.floor - b.h, b.y + 520 * dt)
				if b.y >= A.floor - b.h:
					b.st = "down"
					b.t = 0.0
					g.shake = 12.0
					Aether.sfx("stomp")
			elif b.st == "down":
				contact = false
				if b.t > 2.4 / sqrt(ag):
					b.st = "move"
					b.t = 0.0
					b.side *= -1
		2:
			b.face = -1 if pcx < bcx else 1
			contact = b.vulnT <= 0.0
			if b.vulnT > 0.0:
				b.vulnT -= dt
				if b.vulnT <= 0.0:
					for l in g.level.levers:
						l.on = false
					Aether.sfx("shield", 0.6, 0.7)
					g._float(bcx, b.y - 24, "ESCUDO RESTAURADO", Color(1, 0.56, 0.23), 20)
			b.throwA = max(0.0, b.throwA - dt)
			b.cd -= dt
			if b.cd <= 0.0:
				b.atk += 1
				b.cd = (2.6 if b.vulnT > 0.0 else 1.8) / ag
				b.throwA = 0.6
				if b.atk % 3 == 0:
					var cnt := 5 if di >= 2 else 4
					for i in cnt:
						_warn(g, pcx if i == 0 else randf_range(A.x1 + 40, A.x2 - 40), 0.9 + i * 0.15)
					Aether.sfx("alert", 0.6)
					g.shake = max(g.shake, 6.0)
				else:
					var sx: float = bcx + b.face * 40
					var sy: float = b.y + 30
					var tg := [[pcx, pcy]]
					if di > 0 and b.hp <= b.max / 2:
						tg.append([pcx - 120, pcy])
						tg.append([pcx + 120, pcy])
					for t in tg:
						_proj(g, sx, sy, (t[0] - sx), (t[1] - sy - 0.5 * 900.0), 9, 9, "fire", 15, 4, 900.0)
					Aether.sfx("fire", 0.7)
		3:
			b.face = -1 if pcx < bcx else 1
			if b.st == "hover":
				var tx3: float = clamp(pcx - b.w / 2 + sin(b.t * 0.8) * 160, A.x1 + 20, A.x2 - b.w - 20)
				var ty3: float = A.floor - 290 + sin(b.t * 2) * 20
				b.x = lerp(float(b.x), tx3, dt * 1.6)
				b.y = lerp(float(b.y), ty3, dt * 2.0)
				b.cd -= dt
				if b.cd <= 0.0:
					b.cd = 1.3 / ag
					b.volleys += 1
					Aether.sfx("shoot", 0.5, 0.7)
					var n := 5 if di >= 2 else 3
					for i in n:
						var a: float = atan2(pcy - (b.y + b.h / 2), pcx - bcx) + (i - (n - 1) / 2.0) * 0.25
						_proj(g, bcx, b.y + b.h / 2, cos(a) * 230 * D.spd, sin(a) * 230 * D.spd, 7, 7, "eyeball", 12, 4)
					if b.volleys >= 3:
						b.volleys = 0
						b.st = "tele"
						b.t = 0.0
						Aether.sfx("alert", 0.6)
			elif b.st == "tele":
				b.x += sin(b.t * 70) * 1.2
				if b.t > 0.6:
					b.st = "dive"
					b.t = 0.0
					var dv := Vector2(pcx - bcx, pcy - (b.y + b.h / 2)).normalized()
					b.vx = dv.x * 560 * ag
					b.vy = dv.y * 560 * ag
					Aether.sfx("dash", 0.8, 0.7)
			elif b.st == "dive":
				b.x += b.vx * dt
				b.y += b.vy * dt
				b.x = clamp(b.x, A.x1, A.x2 - b.w)
				if b.y + b.h >= A.floor or b.t > 1.1:
					b.y = min(b.y, A.floor - b.h)
					b.st = "stun"
					b.t = 0.0
					g.shake = 10.0
					Aether.sfx("stomp")
			elif b.st == "stun":
				contact = false
				if b.t > 1.4:
					b.st = "hover"
					b.t = 0.0
					b.cd = 1.0
		4:
			if b.st != "slash" and b.st != "windup":
				b.face = -1 if pcx < bcx else 1
			b.guardCD -= dt
			if not b.summoned and b.hp < b.max * 0.6:
				b.summoned = true
				for sx in [A.x1 + 120, A.x2 - 140]:
					var e: Dictionary = g._spawn_foe("gskel", sx, A.floor - 44)
					e.st = "rising"
				Aether.sfx("bones", 0.8)
				g._float(bcx, b.y - 20, "¡LEVANTAOS!", Color(0.75, 0.44, 1), 22)
			if b.st == "walk":
				var adx: float = abs(pcx - bcx)
				if adx > 70:
					b.x += b.face * 75 * ag * dt
				b.x = clamp(b.x, A.x1 + 10, A.x2 - b.w - 10)
				b.cd -= dt
				if adx < 120 and b.cd <= 0.0:
					b.st = "windup"
					b.t = 0.0
					Aether.sfx("alert", 0.4)
				elif b.guardCD <= 0.0:
					b.st = "guard"
					b.t = 0.0
					b.guardCD = 5.0 / ag
					Aether.sfx("clang", 0.4, 0.7)
			elif b.st == "windup":
				if b.t > 0.45 / sqrt(ag):
					b.st = "slash"
					b.t = 0.0
					Aether.sfx("swing", 1.0, 0.7)
			elif b.st == "slash":
				if b.t > 0.08 and b.t < 0.3 and not g.p.dead and CrGame.ov(g.p, {"x": (b.x + b.w - 10 if b.face > 0 else b.x - 110), "y": b.y + 10, "w": 120.0, "h": 90.0}):
					g._hurt(22, bcx)
				if b.t > 0.55:
					b.st = "walk"
					b.cd = 1.2 / ag
			elif b.st == "guard":
				if b.t > 1.8:
					b.st = "walk"
					b.cd = 0.4
		5:
			if b.st == "idle":
				b.face = -1 if pcx < bcx else 1
				b.cd -= dt
				if b.cd <= 0.0:
					b.moves += 1
					b.st = "leapT" if b.moves % 3 == 0 else "roar"
					b.t = 0.0
			elif b.st == "roar":
				if b.t < 0.05:
					Aether.sfx("roar", 0.8, 0.6)
					g.shake = 6.0
				if b.t > 0.6 / sqrt(ag):
					b.st = "charge"
					b.t = 0.0
					b.vx = b.face * 520 * ag
			elif b.st == "charge":
				b.x += b.vx * dt
				if b.x <= A.x1 + 4 or b.x + b.w >= A.x2 - 4:
					b.x = clamp(b.x, A.x1 + 4, A.x2 - b.w - 4)
					b.st = "stagger"
					b.t = 0.0
					g.shake = 16.0
					Aether.sfx("stomp")
					Aether.sfx("ice", 0.8)
					var cnt5 := 6 if di >= 2 else 4
					for i in cnt5:
						_warn(g, pcx if i == 0 else randf_range(A.x1 + 40, A.x2 - 40), 0.5 + i * 0.18, "ice")
			elif b.st == "stagger":
				contact = false
				if b.t > 1.3:
					b.st = "idle"
					b.cd = 0.8 / ag
			elif b.st == "leapT":
				b.face = -1 if pcx < bcx else 1
				if b.t > 0.4:
					b.st = "leap"
					b.t = 0.0
					var tx5: float = clamp(pcx - b.w / 2, A.x1 + 10, A.x2 - b.w - 10)
					b.vx = (tx5 - b.x) / 0.9
					b.vy = -820.0
					Aether.sfx("jump", 0.8, 0.5)
			elif b.st == "leap":
				b.vy += 1800 * dt
				b.x += b.vx * dt
				b.y += b.vy * dt
				b.x = clamp(b.x, A.x1 + 4, A.x2 - b.w - 4)
				if b.vy > 0 and b.y + b.h >= A.floor:
					b.y = A.floor - b.h
					b.st = "idle"
					b.cd = 1.0 / ag
					g.shake = 12.0
					Aether.sfx("stomp")
					_wave(g, bcx - 60, -1, 300 * ag, Color(0.8, 0.94, 1))
					_wave(g, bcx + 60, 1, 300 * ag, Color(0.8, 0.94, 1))
		6:
			if b.st == "fly":
				b.face = -1 if pcx < bcx else 1
				var tx6: float = clamp(pcx - b.w / 2 - b.face * 160, A.x1 + 10, A.x2 - b.w - 10)
				var ty6: float = A.floor - 330 + sin(b.t * 1.6) * 24
				b.x = lerp(float(b.x), tx6, dt * 1.2)
				b.y = lerp(float(b.y), ty6, dt * 1.6)
				b.cd -= dt
				if b.cd <= 0.0:
					b.cd = 1.4 / ag
					b.shots += 1
					var sx6: float = bcx + b.face * 40
					var sy6: float = b.y + 40
					var dv6 := Vector2(pcx - sx6, pcy - sy6).normalized()
					_proj(g, sx6, sy6, dv6.x * 260 * D.spd, dv6.y * 260 * D.spd, 10, 6, "hfire", 15, 4)
					Aether.sfx("fire", 0.6, 0.8)
					if b.shots >= 3:
						b.shots = 0
						b.st = "breathT"
						b.t = 0.0
						Aether.sfx("roar", 0.9, 0.5)
			elif b.st == "breathT":
				b.face = -1 if pcx < bcx else 1
				b.y = lerp(float(b.y), A.floor - 230, dt * 2)
				if b.t > 0.7:
					b.st = "breath"
					b.t = 0.0
					Aether.sfx("fire", 1.0, 0.5)
			elif b.st == "breath":
				var bx_: float = b.x - 190 if b.face < 0 else b.x + b.w
				for i in 2:
					g.parts.append({"x": (b.x + 10 if b.face < 0 else b.x + b.w - 10), "y": b.y + 60, "vx": b.face * randf_range(250, 420), "vy": randf_range(40, 200), "life": 0.55, "max": 0.55, "c": (Color(0.25, 0.88, 1) if randf() < 0.5 else Color(0.63, 0.97, 1)), "s": 4.0, "g": 100.0})
				if not g.p.dead and CrGame.ov(g.p, {"x": bx_, "y": b.y + 50, "w": 190.0, "h": 160.0}):
					g._hurt(16, bcx)
				if b.t > 1.3:
					b.st = "land"
					b.t = 0.0
			elif b.st == "land":
				b.y = min(A.floor - b.h, b.y + 300 * dt)
				if b.y >= A.floor - b.h:
					b.st = "rest"
					b.t = 0.0
					g.shake = 10.0
					Aether.sfx("stomp")
			elif b.st == "rest":
				contact = false
				if b.t > 2.2 / sqrt(ag):
					b.st = "fly"
					b.t = 0.0
					b.cd = 0.8
		7:
			contact = _kael_dark(g, b, dt, A, ag, pcx, bcx)
		8:
			contact = _leviathan(g, b, dt, A, ag, pcx, pcy, bcx, D)
		9:
			b.face = -1 if pcx < bcx else 1
			if b.vulnT > 0.0:
				b.vulnT -= dt
				if b.vulnT <= 0.0:
					Aether.sfx("shield", 0.6, 0.7)
					for q in g.level.plates:
						if q.get("boss", false):
							q.on = false
			var pl_on := 0
			var pl_n := 0
			for q in g.level.plates:
				if q.get("boss", false):
					pl_n += 1
					if CrGame.ov(g.p, {"x": q.x, "y": q.y - 8, "w": q.w, "h": q.h + 8}):
						q.on = true
					if q.get("on", false):
						pl_on += 1
			if pl_n > 0 and pl_on == pl_n and b.vulnT <= 0.0:
				b.vulnT = 5.0
				g._float(bcx, b.y - 24, "¡ESCUDO ROTO!", Color(0.2, 0.89, 1), 24)
				Aether.sfx("shield")
				g.shake = 12.0
			b.cd -= dt
			if b.st == "idle" and b.cd <= 0.0:
				b.n += 1
				b.cd = (2.4 if b.vulnT > 0.0 else 1.7) / ag
				var m: int = b.n % 4
				if m == 1:
					_wave(g, bcx - 60, -1, 320 * ag, Color(1, 0.85, 0.56))
					_wave(g, bcx + 60, 1, 320 * ag, Color(1, 0.85, 0.56))
					Aether.sfx("stomp")
					g.shake = 10.0
				elif m == 2:
					for i in (6 if di >= 2 else 4):
						_warn(g, pcx if i == 0 else randf_range(A.x1 + 40, A.x2 - 40), 0.8 + i * 0.16, "sand")
					Aether.sfx("alert", 0.6)
				elif m == 3:
					b.beamY = clamp(pcy, A.floor - 200, A.floor - 20)
					b.st = "beamT"
					b.t = 0.0
					Aether.sfx("alert", 0.7)
				else:
					b.st = "tp"
					b.t = 0.0
			elif b.st == "beamT":
				if b.t > 0.7 / sqrt(ag):
					b.st = "idle"
					for i in 3:
						_proj(g, bcx + b.face * 40, b.beamY, b.face * (520 + i * 60) * ag, 0, 26, 4, "laser", 14, 3)
					Aether.sfx("shoot", 0.7, 0.7)
			elif b.st == "tp":
				if b.t > 0.4 and not b.get("tpd", false):
					b.tpd = true
					var mid: float = (A.x1 + A.x2) / 2
					b.x = mid - 220 if bcx > mid else mid + 80
					Aether.sfx("shift", 0.7, 0.6)
				if b.t > 0.8:
					b.tpd = false
					b.st = "idle"
					b.cd = 0.6
			contact = b.st != "tp"
		10:
			contact = _seraph(g, b, dt, A, ag, pcx, bcx, D)
		_:
			contact = _devourer(g, b, dt, A, ag, pcx, pcy, bcx)
	return contact

static func _kael_dark(g, b: Dictionary, dt: float, A: Dictionary, ag: float, pcx: float, bcx: float) -> bool:
	var contact := true
	b.shiftT -= dt
	if b.shiftT <= 0.0:
		b.shiftT = 7.0 / ag
		g.dim = 1 - g.dim
		Aether.sfx("shift", 0.8, 0.7)
		g._float(bcx, b.y - 20, "¡SHIFT!", Color(0.82, 0.44, 1), 20)
	match String(b.st):
		"idle":
			b.face = -1 if pcx < bcx else 1
			b.cd -= dt
			if abs(pcx - bcx) > 160:
				b.x += b.face * 120 * dt
			if b.cd <= 0.0:
				b.moves += 1
				var m: int = b.moves % 4
				b.st = "jumpT" if m == 2 else ("clocks" if m == 3 else "dashT")
				b.t = 0.0
		"dashT":
			b.face = -1 if pcx < bcx else 1
			if b.t > 0.4 / sqrt(ag):
				b.st = "dash"
				b.t = 0.0
				b.vx = b.face * 820 * ag
				Aether.sfx("dash", 0.9, 0.8)
		"dash":
			b.x += b.vx * dt
			if not g.p.dead and CrGame.ov(g.p, {"x": b.x - 20, "y": b.y, "w": b.w + 40, "h": b.h}):
				g._hurt(20, bcx)
			if b.t > 0.32 or b.x <= A.x1 + 4 or b.x + b.w >= A.x2 - 4:
				b.x = clamp(b.x, A.x1 + 4, A.x2 - b.w - 4)
				b.st = "recover"
				b.t = 0.0
		"jumpT":
			if b.t > 0.3:
				b.st = "jump"
				b.t = 0.0
				b.vy = -900.0
				b.vx = (pcx - bcx) / 0.8
				Aether.sfx("jump", 0.8, 0.7)
		"jump":
			b.vy += 1800 * dt
			b.x += b.vx * dt
			b.y += b.vy * dt
			b.x = clamp(b.x, A.x1 + 4, A.x2 - b.w - 4)
			if b.vy > 0 and b.t > 0.35:
				b.vx = 0.0
				b.vy = max(b.vy, 900.0)
			if b.y + b.h >= A.floor:
				b.y = A.floor - b.h
				b.st = "recover"
				b.t = 0.0
				g.shake = 10.0
				Aether.sfx("stomp")
				_wave(g, bcx - 30, -1, 320 * ag, Color(0.82, 0.44, 1))
				_wave(g, bcx + 30, 1, 320 * ag, Color(0.82, 0.44, 1))
		"clocks":
			if b.t > 0.3 and not b.get("thrown", false):
				b.thrown = true
				var n := 4 if g.diff_idx >= 2 else 3
				for i in n:
					_proj(g, bcx, b.y + 10, (i - (n - 1) / 2.0) * 140, -260, 8, 8, "clock", 14, 3.5)
				Aether.sfx("slow", 0.5, 1.5)
			if b.t > 0.8:
				b.thrown = false
				b.st = "recover"
				b.t = 0.0
		"recover":
			contact = false
			if b.t > 0.9 / sqrt(ag):
				b.st = "idle"
				b.cd = 0.5
	return contact

static func _leviathan(g, b: Dictionary, dt: float, A: Dictionary, ag: float, pcx: float, pcy: float, bcx: float, D: Dictionary) -> bool:
	var contact := true
	match String(b.st):
		"wait":
			contact = false
			b.cd -= dt
			if b.cd <= 0.0:
				b.n += 1
				var m: int = b.n % 3
				b.st = "biteT" if m == 0 else ("lungeT" if m == 1 else "spitIn")
				b.t = 0.0
				b.ty = clamp(pcy - b.h / 2, A.floor - 300, A.floor - b.h)
				b.side = 1 if randf() < 0.5 else -1
		"lungeT":
			contact = false
			b.x = A.x2 + 40 if b.side > 0 else A.x1 - b.w - 40
			b.y = b.ty
			b.face = -b.side
			if b.t > 0.75 / sqrt(ag):
				b.st = "lunge"
				b.t = 0.0
				b.vx = -b.side * 620 * ag
				Aether.sfx("roar", 0.7, 0.7)
		"lunge":
			b.x += b.vx * dt
			if (b.vx < 0 and b.x + b.w < A.x1 - 60) or (b.vx > 0 and b.x > A.x2 + 60):
				b.st = "wait"
				b.cd = 0.5 / ag
		"spitIn":
			var tx: float = A.x2 - b.w - 20 if b.side > 0 else A.x1 + 20
			b.face = -1 if b.side > 0 else 1
			b.x = lerp(float(b.x), tx, dt * 3)
			b.y = lerp(float(b.y), A.floor - 300, dt * 3)
			if b.t > 0.8:
				b.st = "spit"
				b.t = 0.0
				b.shots = 0
		"spit":
			b.face = -1 if pcx < bcx else 1
			if b.t > 0.45:
				b.t = 0.0
				b.shots = int(b.get("shots", 0)) + 1
				var sx: float = bcx + b.face * 60
				var sy: float = b.y + 40
				for i in [-1, 0, 1]:
					var a: float = atan2(pcy - sy, pcx - sx) + i * 0.3
					_proj(g, sx, sy, cos(a) * 200 * D.spd, sin(a) * 200 * D.spd, 7, 7, "bubble", 12, 4)
				Aether.sfx("bounce", 0.5, 0.6)
			if int(b.get("shots", 0)) >= 3:
				b.st = "leave"
				b.t = 0.0
		"leave":
			b.x += (1 if b.side > 0 else -1) * 500 * dt
			if b.t > 0.8:
				b.st = "wait"
				b.cd = 0.4
		"biteT":
			contact = false
			var tx8: float = clamp(pcx - b.w / 2, A.x1 + 10, A.x2 - b.w - 10)
			b.x = lerp(float(b.x), tx8, dt * 4)
			b.y = lerp(float(b.y), A.floor - 430, dt * 4)
			b.face = -1
			if b.t > 1.0 / sqrt(ag):
				b.st = "bite"
				b.t = 0.0
				b.vy = 300.0
				Aether.sfx("roar", 0.9, 0.5)
		"bite":
			b.vy += 2600 * dt
			b.y += b.vy * dt
			if b.y + b.h >= A.floor:
				b.y = A.floor - b.h
				b.st = "stuck"
				b.t = 0.0
				g.shake = 18.0
				Aether.sfx("stomp")
				_wave(g, bcx - 70, -1, 300 * ag, Color(0.8, 0.94, 1))
				_wave(g, bcx + 70, 1, 300 * ag, Color(0.8, 0.94, 1))
		"stuck":
			contact = false
			if b.t > 2.4 / sqrt(ag):
				b.st = "leave"
				b.side = 1 if pcx < bcx else -1
				b.t = 0.0
				b.y -= 4
	return contact

static func _seraph(g, b: Dictionary, dt: float, A: Dictionary, ag: float, pcx: float, bcx: float, D: Dictionary) -> bool:
	var contact := true
	b.invCD -= dt
	if b.invCD <= 0.0:
		b.invCD = 14.0 / ag
		g.invert_t = 6.0
		Aether.flash(Color.WHITE, 0.3)
		Aether.sfx("shift", 1.0, 0.5)
		g._float(bcx, b.y - 20, "¡EL CIELO SE INVIERTE!", Color(0.75, 0.9, 1), 20)
	match String(b.st):
		"float":
			b.face = -1 if pcx < bcx else 1
			var tx: float = clamp(pcx - b.w / 2 + sin(b.t * 0.7) * 200, A.x1 + 20, A.x2 - b.w - 20)
			var ty: float = A.floor - 290 + sin(b.t * 1.8) * 16
			b.x = lerp(float(b.x), tx, dt * 1.2)
			b.y = lerp(float(b.y), ty, dt * 1.6)
			b.cd -= dt
			if b.cd <= 0.0:
				b.n += 1
				b.cd = 1.5 / ag
				var m: int = b.n % 3
				if m == 1:
					for s in [-1, 1]:
						var q := _proj(g, bcx, b.y + 50, s * 420 * D.spd, 40 * s, 10, 10, "ring", 14, 3.2)
						q.back = false
				elif m == 2:
					for i in (7 if g.diff_idx >= 2 else 5):
						_warn(g, randf_range(A.x1 + 30, A.x2 - 30), 0.6 + i * 0.12, "feather")
					if randf() < 0.5:
						_warn(g, pcx, 0.7, "feather")
					Aether.sfx("alert", 0.5)
				else:
					b.st = "diveT"
					b.t = 0.0
					Aether.sfx("alert", 0.7, 1.3)
		"diveT":
			b.x += sin(b.t * 60) * 1.4
			if b.t > 0.55 / sqrt(ag):
				b.st = "dive"
				b.t = 0.0
				b.tx = clamp(pcx - b.w / 2, A.x1 + 10, A.x2 - b.w - 10)
				Aether.sfx("dash", 0.9, 0.7)
		"dive":
			b.x = lerp(float(b.x), float(b.tx), dt * 8)
			b.y += 900 * ag * dt
			if b.y + b.h >= A.floor:
				b.y = A.floor - b.h
				b.st = "stun"
				b.t = 0.0
				g.shake = 14.0
				Aether.sfx("stomp")
				_wave(g, bcx - 40, -1, 280 * ag, Color.WHITE)
				_wave(g, bcx + 40, 1, 280 * ag, Color.WHITE)
		"stun":
			contact = false
			if b.t > 1.9:
				b.st = "float"
				b.t = 0.0
				b.cd = 1.0
	for q in g.projs:
		if q.type == "ring":
			if 3.2 - q.life > 0.8:
				q.back = true
			if q.get("back", false):
				var d := Vector2(bcx - q.x, b.y + 50 - q.y)
				var l: float = max(1.0, d.length())
				q.vx += d.x / l * 1200 * dt
				q.vy += d.y / l * 1200 * dt
				var v := Vector2(q.vx, q.vy)
				if v.length() > 480:
					v = v.normalized() * 480
					q.vx = v.x
					q.vy = v.y
				if l < 30:
					q.life = 0.0
	return contact

static func _devourer(g, b: Dictionary, dt: float, A: Dictionary, ag: float, pcx: float, pcy: float, bcx: float) -> bool:
	var contact := true
	b.face = -1 if pcx < bcx else 1
	match String(b.st):
		"float":
			var tx: float = clamp(pcx - b.w / 2, A.x1 + 40, A.x2 - b.w - 40)
			var ty: float = A.floor - 345 + sin(b.t * 1.3) * 14
			b.x = lerp(float(b.x), tx, dt * 0.8)
			b.y = lerp(float(b.y), ty, dt * 2)
			b.cd -= dt
			if b.cd <= 0.0:
				b.n += 1
				b.cd = 1.6 / ag
				var m: int = b.n % 5
				if m == 1:
					_wave(g, A.x1 + 20, 1, 330 * ag, Color(0.82, 0.44, 1))
					_wave(g, A.x2 - 20, -1, 330 * ag, Color(0.82, 0.44, 1))
					Aether.sfx("stomp")
					g.shake = 10.0
				elif m == 2:
					for i in 3:
						_proj(g, bcx, clamp(pcy, A.floor - 220, A.floor - 20) - 40 + i * 40, b.face * (380 + i * 70) * ag, 0, 26, 4, "laser", 14, 4)
					Aether.sfx("shoot", 0.8, 0.6)
				elif m == 3:
					for i in (6 if g.diff_idx >= 2 else 4):
						_warn(g, pcx if i == 0 else randf_range(A.x1 + 40, A.x2 - 40), 0.8 + i * 0.15)
					Aether.sfx("alert", 0.6)
				elif m == 4:
					var n := 4 if g.diff_idx >= 2 else 3
					for i in n:
						_proj(g, bcx, b.y + b.h - 20, (i - (n - 1) / 2.0) * 160, -200, 8, 8, "clock", 14, 3.5)
					Aether.sfx("slow", 0.6, 1.4)
				else:
					b.st = "tiredT"
					b.t = 0.0
					Aether.sfx("roar", 1.0, 0.4)
					g._float(bcx, b.y + b.h + 10, "¡SE AGOTA!", Color(1, 0.83, 0.3), 20)
			if not b.summoned and b.hp < b.max * 0.5:
				b.summoned = true
				for sx in [A.x1 + 140, A.x2 - 160]:
					g._spawn_foe("voidling", sx, A.floor)
				g._float(bcx, b.y - 20, "¡SOMBRAS, DEVORADLO!", Color(0.82, 0.44, 1), 20)
		"tiredT":
			b.y = min(A.floor - b.h, b.y + 260 * dt)
			if b.y >= A.floor - b.h:
				b.st = "tired"
				b.t = 0.0
				g.shake = 14.0
				Aether.sfx("stomp")
		"tired":
			contact = false
			if b.t > 2.8 / sqrt(ag):
				b.st = "float"
				b.t = 0.0
				b.cd = 1.0
	return contact
