class_name CrPowers
## Poderes de Kael (traducción de abilities.js con el equilibrio de hard.js) y sus efectos de Blender.
## Cada poder se gana al vencer al guardián del mundo con su mismo índice (como en el juego web).

const ABIL := ["carga", "parada", "fantasma", "sismo", "iman", "triple", "corazon", "planeo", "ojo", "luz", "rebobinar"]

static func has_ab(g, k: String) -> bool:
	if g.all_powers:
		return true
	var i: int = ABIL.find(k)
	if i < 0:
		return false
	var bs: Array = Aether.save.get_value("cr_guardianes", [])
	return i in bs

## Antes de la física de Kael.
static func pre(g, dt: float) -> Dictionary:
	var p: Dictionary = g.p
	if not p.has("_ab"):
		p._ab = true
		p.gst = 100.0
		p.guardT = 9.0
		p.lastHurt = -9.0
		p.chargeT = 0.0
		p.glideT = 0.0
		if has_ab(g, "corazon"):
			p.maxHp += 20.0
			p.hp += 20.0
	var guard_held: bool = Input.is_action_pressed("guard")
	var guard_pressed: bool = g._press("guard")
	if float(p.get("guardBreak", 0.0)) > 0.0:
		p.guardBreak -= dt
	var can_guard: bool = p.stun <= 0.0 and p.dashT <= 0.0 and p.get("hook") == null and float(p.get("guardBreak", 0.0)) <= 0.0 and not p.get("plunge", false)
	# picado sísmico: GUARDIA en el aire
	if guard_pressed and not p.onGround and has_ab(g, "sismo") and p.get("hook") == null and p.dashT <= 0.0:
		p.plunge = true
		p.guard = false
		p.vy = 300.0
		Aether.sfx("dash", 0.5, 0.7)
	else:
		p.guard = guard_held and can_guard and p.onGround
	if guard_pressed:
		p.guardT = 0.0
	else:
		p.guardT += dt
	# triple salto
	if has_ab(g, "triple") and g._press("jump") and not p.onGround and p.coyote <= 0.0 and p.wall == 0 and p.get("hook") == null and p.jumps >= 2 and not p.get("triple", false) and p.dashT <= 0.0:
		p.triple = true
		p.vy = -CrGame.JUMP * 0.62
		p.sq = 1.16
		g._pressed["jump"] = false
		p.noCut = false
		Aether.sfx("jump", 0.5, 1.25)
		g._burst(p.x + p.w / 2, p.y + p.h, Color(1, 0.91, 0.63), 12, 140, 0, 0.4, 2)
		g._fx_sheet("impacto", p.x + p.w / 2, p.y + p.h, 46.0, false, 40.0)
	# golpe cargado: mantener ESPADA y soltar
	var held: bool = Input.is_action_pressed("attack") and not p.guard
	if has_ab(g, "carga") and held:
		p.chargeT += dt
		if p.chargeT > 0.3 and int(p.get("chargeFx", 0)) == 0:
			p.chargeFx = g._vfx.spawn("carga", 0, 0, 62.0, false, 22.0, -1, p, Vector2(0, -2))
		if p.chargeT > 0.6 and not p.get("chargeReady", false):
			p.chargeReady = true
			Aether.sfx("relic", 0.3, 2.0)
			g._fx_sheet("impacto", p.x + p.w / 2, p.y + p.h * 0.45, 52.0, false, 40.0)
	elif p.chargeT > 0.0:
		if p.get("chargeReady", false):
			_release(g)
		p.chargeT = 0.0
		p.chargeReady = false
	if not held or p.chargeT <= 0.0:
		_stop_charge_fx(g)
	if p.guard:
		g._pressed["attack"] = false
		g._pressed["dash"] = false
		p.chargeT = 0.0
	return {"x0": p.x, "wasDash": p.dashT > 0.0, "atk0": p.atkT}

## Después de la física de Kael.
static func post(g, dt: float, st: Dictionary) -> void:
	var p: Dictionary = g.p
	if p.guard and p.onGround:
		p.x = st.x0 + (p.x - st.x0) * 0.2
	if not p.guard:
		p.gst = min(100.0, float(p.gst) + dt * 28.0)
	if float(p.get("blockT", 0.0)) > 0.0:
		p.blockT -= dt
	if p.get("plunge", false):
		p.vy = 980.0
		p.vx = 0.0
		if p.onGround:
			p.plunge = false
			_seismic(g)
	if float(p.get("slamT", 0.0)) > 0.0:
		p.slamT -= dt
	if p.onGround:
		p.triple = false
		p.glideT = 0.0
	# planeo (0,8 s por salto)
	p.gliding = has_ab(g, "planeo") and not p.onGround and Input.is_action_pressed("jump") and p.vy > 0.0 and p.wall == 0 and p.get("hook") == null and not p.get("plunge", false) and p.dashT <= 0.0 and p.glideT < 0.8
	if p.gliding:
		p.glideT += dt
		p.vy = min(p.vy, 75.0)
		if randf() < 0.3:
			g.parts.append({"x": p.x + p.w / 2 - p.face * 14, "y": p.y + randf_range(14, 30), "vx": -p.face * 30.0, "vy": randf_range(0, 20), "life": 0.5, "max": 0.5, "c": Color(1, 0.91, 0.63), "s": 1.0, "g": 0.0})
	# dash fantasma: atraviesa y daña
	if p.dashT > 0.0 and not st.wasDash:
		p.hitSet = []
	if p.dashT > 0.0 and has_ab(g, "fantasma"):
		if g._hit_enemies({"x": p.x - 6, "y": p.y, "w": p.w + 12, "h": p.h}):
			g.hit_stop = max(g.hit_stop, 0.03)
	# espada de luz: el tercer golpe lanza una media luna
	if has_ab(g, "luz") and p.atkT > 0.0 and st.atk0 <= 0.0 and p.atkN == 2:
		fire_wave(g, 1.4, 0.5, 0.85, "media_luna")
	# imán
	if has_ab(g, "iman"):
		var px: float = p.x + p.w / 2
		var py: float = p.y + p.h / 2
		for gm in g.level.gems:
			if not gm.taken:
				var d := Vector2(px - gm.x, py - gm.y)
				if d.length() < 230.0 and d.length() > 1.0:
					var v := d.normalized() * 380.0 * dt
					gm.x += v.x
					gm.y += v.y
		for c in g.level.cherries:
			if not c.taken:
				var d2 := Vector2(px - c.x, py - c.y)
				if d2.length() < 200.0 and d2.length() > 1.0:
					var v2 := d2.normalized() * 300.0 * dt
					c.x += v2.x
					c.y += v2.y
	# corazón de cristal: cura 1,2/s tras 8 s sin golpes, hasta la mitad
	if has_ab(g, "corazon") and g.time - float(p.lastHurt) > 8.0 and p.hp < p.maxHp * 0.5:
		p.hp = min(p.maxHp * 0.5, p.hp + 1.2 * dt)
		g.hp_changed.emit(p.hp, p.maxHp)
	if float(p.get("releaseT", 0.0)) > 0.0:
		p.releaseT -= dt

static func _stop_charge_fx(g) -> void:
	var p: Dictionary = g.p
	if int(p.get("chargeFx", 0)) != 0:
		g._vfx.stop(int(p.chargeFx))
		p.chargeFx = 0

static func _release(g) -> void:
	var p: Dictionary = g.p
	p.releaseT = 0.28
	p.chargeReady = false
	_stop_charge_fx(g)
	fire_wave(g, 3.0, 1.0, 1.25, "onda_luz")
	Aether.sfx("swing", 0.8, 0.7)
	Aether.sfx("relic", 0.4, 1.4)
	g.shake = max(g.shake, 4.0)
	g.hit_stop = max(g.hit_stop, 0.05)

## Onda de luz amiga que atraviesa enemigos (golpe cargado y espada de luz).
static func fire_wave(g, dmg: float, life: float, scale: float, fx: String) -> void:
	var p: Dictionary = g.p
	var x: float = p.x + p.w / 2 + p.face * 26.0
	var y: float = p.y + 26.0
	var q := {"type": "lightwave", "friendly": true, "x": x, "y": y, "vx": p.face * 560.0, "vy": 0.0, "life": life,
		"hw": 14.0 * scale, "hh": 24.0 * scale, "dmg": 0.0, "fdmg": dmg, "hit": []}
	g._vfx.spawn(fx, x, y, 70.0 * scale, p.face < 0, 30.0, -1, q)
	g.projs.append(q)
	g._fx_sheet("impacto", x, y, 40.0 * scale, p.face < 0, 40.0)

## Proyectiles amigos: dañan enemigos y jefe. Devuelve si hay que quitarlo.
static func friendly(g, q: Dictionary) -> bool:
	var r := {"x": q.x - q.hw, "y": q.y - q.hh, "w": q.hw * 2, "h": q.hh * 2}
	var hit := false
	var p: Dictionary = g.p
	var keep: Array = p.hitSet
	for e in g.level.enemies:
		if not e.dead and not q.hit.has(e) and g.ov(r, e) and not (e.b == "ghost" and g.dim == 0):
			q.hit.append(e)
			var n: int = max(1, roundi(float(q.fdmg)))
			for i in n:
				if e.dead:
					break
				p.hitSet = []
				g._damage_enemy(e, r)
			hit = true
	var b: Dictionary = g.boss
	if not b.is_empty() and not b.dying and not b.done and g.boss_intro <= 0.0 and not q.hit.has("boss") and g.ov(r, b):
		q.hit.append("boss")
		p.hitSet = []
		g._hit_boss(r)
		hit = true
	p.hitSet = keep
	return q.type != "lightwave" and hit

static func _seismic(g) -> void:
	var p: Dictionary = g.p
	var x: float = p.x + p.w / 2
	var y: float = p.y + p.h
	p.slamT = 0.3
	g.shake = max(g.shake, 10.0)
	g.hit_stop = max(g.hit_stop, 0.08)
	Aether.sfx("boom", 0.6, 1.2)
	Aether.sfx("stomp", 0.7)
	g._fx_sheet("sismo", x, y - 26.0, 230.0, false, 30.0)
	g._burst(x, y - 4, Color(1, 0.69, 0.25), 20, 260, 500, 0.6, 2)
	var box := {"x": x - 95, "y": y - 50, "w": 190, "h": 60}
	p.hitSet = []
	p.atkN = 2
	g._hit_enemies(box)
	var b: Dictionary = g.boss
	if not b.is_empty() and not b.dying and g.boss_intro <= 0.0 and g.ov(box, b):
		g._hit_boss(box, true)

static func front_of(g, src_x: float) -> bool:
	var p: Dictionary = g.p
	return (src_x - (p.x + p.w / 2)) * p.face > -8.0

## Bloqueo con GUARDIA; la parada perfecta (con el poder) no gasta escudo y contraataca.
static func block(g, dmg: float, src_x: float, proj = null) -> bool:
	var p: Dictionary = g.p
	var perfect: bool = has_ab(g, "parada") and float(p.guardT) < 0.22
	var sx: float = p.x + p.w / 2 + p.face * 16.0
	var sy: float = p.y + 26.0
	p.blockT = 0.22
	p.inv = max(p.inv, 0.3)
	if perfect:
		g.hit_stop = max(g.hit_stop, 0.16)
		Aether.sfx("shield", 0.7, 1.3)
		Aether.sfx("clang", 0.6, 1.5)
		g._fx_sheet("parada", sx, sy, 78.0, false, 32.0)
		g._float(sx, p.y - 14, "¡PARADA!", Color(0.75, 0.96, 1), 16)
		p.gst = min(100.0, float(p.gst) + 20.0)
		if proj is Dictionary:
			proj.friendly = true
			proj.vx = -proj.vx * 1.2
			proj.vy = -abs(proj.vy) * 0.3
			proj.fdmg = 2.0
			proj.hit = []
		else:
			var best = null
			var bd := 90.0
			for e in g.level.enemies:
				if not e.dead:
					var d: float = abs(e.x + e.w / 2 - sx)
					if d < bd and abs(e.y + e.h / 2 - sy) < 70.0:
						bd = d
						best = e
			if best != null:
				p.hitSet = []
				p.atkN = 2
				g._damage_enemy(best, {"x": best.x, "y": best.y, "w": best.w, "h": best.h})
		return true
	p.gst -= dmg * 2.4
	p.vx = -p.face * 200.0
	Aether.sfx("clang", 0.6)
	g._fx_sheet("impacto", sx, sy, 40.0, p.face < 0, 40.0)
	if p.gst <= 0.0:
		p.gst = 0.0
		p.guardBreak = 1.4
		p.guard = false
		Aether.sfx("crumble", 0.6)
		g._float(sx, p.y - 14, "¡GUARDIA ROTA!", Color(1, 0.54, 0.35), 15)
		p.inv = 0.0
		return false
	return true

## Segunda Oportunidad: una vez por fase el tiempo retrocede al caer derrotado.
static func try_rewind(g) -> bool:
	var p: Dictionary = g.p
	if not has_ab(g, "rebobinar") or p.get("rewindUsed", false):
		return false
	p.rewindUsed = true
	p.hp = p.maxHp * 0.25
	p.inv = 1.6
	p.stun = 0.0
	g.hp_changed.emit(p.hp, p.maxHp)
	g._vfx.spawn("rebobinar", p.x + p.w / 2, p.y + p.h / 2, 120.0, false, 24.0, 1)
	g._float(p.x + p.w / 2, p.y - 20, "¡SEGUNDA OPORTUNIDAD!", Color(0.5, 0.91, 1), 18)
	Aether.sfx("relic", 0.8, 0.7)
	Aether.slowmo(0.35, 0.8)
	Aether.flash(Color(0.6, 0.9, 1), 0.35)
	return true

## Hoja de Kael según el poder en uso ("" si ninguno).
static func kael_anim(g) -> Array:
	var p: Dictionary = g.p
	if p.get("plunge", false):
		return ["KH_plunge", 18.0, true]
	if float(p.get("slamT", 0.0)) > 0.0:
		return ["KH_slam", 20.0, false]
	if float(p.get("blockT", 0.0)) > 0.0:
		return ["KH_guardHit", 14.0, false]
	if p.get("guard", false):
		return ["KH_guard", 10.0, true]
	if float(p.get("releaseT", 0.0)) > 0.0:
		return ["KH_release", 10.0, false]
	if float(p.get("chargeT", 0.0)) > 0.3:
		return ["KH_charge", 10.0, true]
	if p.get("gliding", false):
		return ["KH_glide", 12.0, true]
	return []
