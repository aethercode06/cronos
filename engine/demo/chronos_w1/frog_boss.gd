extends AetherBoss
## Gran Sapo Ancestral — primer jefe de Chronos rehecho en Aether Engine.
## Un solo dibujo pintado cobra vida con la malla deformable:
## respira, se agacha antes de saltar, infla la panza para cubrirse,
## abre la boca, lanza la lengua, escupe burbujas, entra en furia y se
## desploma al ser derrotado.

var art: DeformSprite
var tongue: Line2D
var tip: Sprite2D
var shadow: Sprite2D
var floor_y := 0.0
var P := {"squash": 1.0, "lean": 0.0, "belly": 0.0, "head": 0.0, "jaw": 0.0, "wobble": 0.0}
var T := {"squash": 1.0, "lean": 0.0, "belly": 0.0, "head": 0.0, "jaw": 0.0, "wobble": 0.0}
var _time := 0.0
var _airborne := false
var _leap := false
var _tongue_len := 0.0
var _tongue_hit := false
var _spit_n := 0
var _hits_window: Array[float] = []
var _next := 0
var _steam := 0.0
var _die_t := 0.0
var _die_boom := 0.0

const ART_SCALE := 0.95

func _ready() -> void:
	boss_name = "GRAN SAPO ANCESTRAL"
	max_hp = 48.0
	contact_damage = 18.0
	body_size = Vector2(300, 250)
	super._ready()
	shadow = Sprite2D.new()
	shadow.texture = FX.soft()
	shadow.modulate = Color(0, 0, 0, 0.45)
	shadow.scale = Vector2(6.5, 1.2)
	shadow.top_level = true
	shadow.z_index = -1
	add_child(shadow)
	art = DeformSprite.new()
	add_child(art)
	art.setup(Aether.tex("hdb_frog"), ART_SCALE, 0.985)
	art.set_p("belly_center", Vector2(0.52, 0.66))
	art.set_p("mouth_y", 0.43)
	art.set_p("breath", 1.0)
	tongue = Line2D.new()
	tongue.width = 22.0
	tongue.default_color = Color(1.25, 0.45, 0.55)
	tongue.begin_cap_mode = Line2D.LINE_CAP_ROUND
	tongue.end_cap_mode = Line2D.LINE_CAP_ROUND
	tongue.z_index = 2
	tongue.visible = false
	add_child(tongue)
	tip = Sprite2D.new()
	tip.texture = FX.dot()
	tip.modulate = Color(1.6, 0.6, 0.7)
	tip.scale = Vector2.ONE * 0.9
	tip.visible = false
	add_child(tip)
	floor_y = global_position.y

func _process(delta: float) -> void:
	_time += delta
	# los parámetros persiguen a sus objetivos: el movimiento siempre es suave
	for k in P:
		var sp := 14.0 if k == "squash" else 9.0
		P[k] = lerp(P[k], T[k], 1.0 - exp(-delta * sp))
		art.set_p(k, P[k])
	art.set_p("time_s", _time)
	art.set_p("flash", _flash)
	art.set_p("tint", Color(1.25, 0.75, 0.7) if fury else (Color(0.75, 0.85, 1.05) if guard else Color(1, 1, 1)))
	art.scale.x = -face          # el dibujo mira a la derecha
	shadow.global_position = Vector2(global_position.x, floor_y + 4)
	var hgt: float = clamp((floor_y - global_position.y) / 900.0, 0.0, 1.0)
	shadow.scale = Vector2(6.5 * (1.0 - hgt * 0.6), 1.2 * (1.0 - hgt * 0.6))
	shadow.modulate.a = 0.45 * (1.0 - hgt * 0.5)
	if fury and not dying:
		_steam -= delta
		if _steam <= 0:
			_steam = 0.12
			FX.burst(get_parent(), global_position + Vector2(randf_range(-110, 110), -230), Color(1.8, 0.6, 0.4, 0.5), 2, 120, 0.7, 22, -200, 30, Vector2.UP)

func _relax() -> void:
	T.squash = 1.0; T.lean = 0.0; T.belly = 0.0; T.head = 0.0; T.jaw = 0.0; T.wobble = 0.0

func _face_player() -> void:
	var pl = Aether.player
	if pl:
		face = sign(pl.global_position.x - global_position.x)
		if face == 0: face = 1

func _speed() -> float:
	return 1.35 if fury else 1.0

func _boss_tick(delta: float) -> void:
	var pl = Aether.player
	if not _airborne:
		velocity.y = 0
	# gravedad y aterrizaje
	if _airborne:
		velocity.y += 4200.0 * delta
		position += velocity * delta
		if arena.size.x > 0:
			position.x = clamp(position.x, arena.position.x + 170, arena.end.x - 170)
		if _leap and velocity.y > 0 and pl:
			position.x = lerp(position.x, pl.global_position.x, 1.0 - exp(-delta * 3.0))
		T.squash = 1.25 if velocity.y < 0 else 1.1
		T.lean = 0.0
		if global_position.y >= floor_y and velocity.y > 0:
			global_position.y = floor_y
			_airborne = false
			_land()
		return
	match state:
		"intro":
			# rugido de presentación
			T.belly = 1.0 if state_t > 0.4 else 0.0
			T.jaw = 1.0 if state_t > 0.6 else 0.0
			T.wobble = 0.5 if state_t > 0.6 else 0.0
			if state_t > 0.6 and state_t - delta <= 0.6:
				Aether.sfx("roar", 1.0, 0.7)
				Aether.shake(18, 0.05)
				FX.ring(get_parent(), global_position + Vector2(face * 120, -170), Color(1.4, 1.3, 0.8, 0.8), 400, 0.6)
			if state_t > 1.8:
				_relax(); set_state("idle")
		"idle":
			_relax()
			_face_player()
			if state_t > (0.55 if fury else 0.9):
				_pick()
		"hop_prep":
			T.squash = 0.72; T.lean = 0.12; T.wobble = 0.15
			if state_t > 0.36 / _speed():
				_jump(false)
		"leap_prep":
			T.squash = 0.6; T.lean = -0.08; T.belly = 0.35; T.wobble = 0.3
			if state_t > 0.6 / _speed():
				_jump(true)
		"tongue_prep":
			# echa la cabeza atrás, infla la panza y abre la boca: aviso claro
			T.head = -0.5; T.belly = 0.6; T.jaw = 0.5; T.squash = 0.92
			if state_t > 0.55 / _speed():
				set_state("tongue")
				_tongue_len = 0.0
				_tongue_hit = false
				tongue.visible = true
				tip.visible = true
				Aether.sfx("dash", 0.9, 0.6)
		"tongue":
			T.head = 0.6; T.jaw = 1.0; T.belly = 0.0; T.squash = 1.0
			var ext: float = min(1.0, state_t / 0.16)
			var ret: float = clamp((state_t - 0.75) / 0.25, 0.0, 1.0)
			_tongue_len = 760.0 * ext * (1.0 - ret)
			_update_tongue()
			weak = state_t > 0.3 and state_t < 0.75   # lengua estirada: momento débil
			if state_t > 1.0:
				tongue.visible = false; tip.visible = false; weak = false
				set_state("idle")
		"spit_prep":
			T.belly = 0.9; T.jaw = 0.3; T.head = -0.2
			if state_t > 0.45:
				set_state("spit")
				_spit_n = 5 if fury else 3
		"spit":
			T.jaw = 1.0; T.head = 0.35; T.belly = 0.2
			if fmod(state_t, 0.22) < delta and _spit_n > 0:
				_spit_n -= 1
				_bubble()
			if _spit_n <= 0 and state_t > 0.5:
				set_state("idle")
		"guard":
			# se cubre: se hincha y se endurece como una roca
			T.belly = 1.0; T.squash = 0.86; T.head = -0.3; T.jaw = 0.0; T.wobble = 0.05
			guard = true
			if state_t > 1.1:
				guard = false
				set_state("counter")
		"counter":
			T.belly = -0.2; T.jaw = 1.0; T.squash = 1.08
			if state_t < delta * 1.5:
				Aether.sfx("roar", 0.8, 1.1)
				Aether.shake(14, 0.04)
				FX.ring(get_parent(), global_position + Vector2(0, -130), Color(1.2, 1.6, 1.0, 0.9), 420, 0.4)
				if pl and abs(pl.global_position.x - global_position.x) < 380:
					pl.take_damage(14, global_position.x)
			if state_t > 0.45:
				set_state("idle")
		"tired":
			# tras el gran salto se queda aturdido: ¡ataca!
			weak = true
			T.squash = 0.82; T.belly = -0.3; T.jaw = 0.6; T.head = 0.2; T.wobble = 0.08
			if fmod(state_t, 0.4) < delta:
				FX.float_text(get_parent(), global_position + Vector2(randf_range(-60, 60), -280), "✦", Color(2.0, 1.8, 0.6), 30)
			if state_t > (1.6 if fury else 2.3):
				weak = false
				set_state("idle")
		"hurt":
			if state_t > 0.25:
				set_state("idle")

func _pick() -> void:
	var pl = Aether.player
	var dist: float = abs(pl.global_position.x - global_position.x) if pl else 400.0
	var plan := ["hop", "tongue", "hop", "spit", "leap", "tongue"]
	if fury:
		plan = ["leap", "tongue", "hop", "spit", "hop", "leap", "tongue"]
	var a: String = plan[_next % plan.size()]
	_next += 1
	if a == "tongue" and dist > 700:
		a = "hop"
	set_state(a + "_prep")

func _jump(big: bool) -> void:
	_face_player()
	_airborne = true
	_leap = big
	var pl = Aether.player
	var dx: float = (pl.global_position.x - global_position.x) if pl else 0.0
	if big:
		velocity = Vector2(0, -2500)
		Aether.sfx("jump", 1.0, 0.5)
	else:
		velocity = Vector2(clamp(dx * 1.1, -700, 700), -1500)
		Aether.sfx("jump", 0.9, 0.7)
	FX.burst(get_parent(), Vector2(global_position.x, floor_y), Color(0.9, 0.85, 0.7, 0.7), 18, 380, 0.45, 18, 400, 60, Vector2.UP)
	set_state("air")

func _land() -> void:
	T.squash = 0.55; T.wobble = 0.6
	P.squash = 0.55
	Aether.sfx("stomp", 1.0, 0.7 if _leap else 0.9)
	Aether.sfx("boom", 0.6 if _leap else 0.35)
	Aether.shake(26 if _leap else 14, 0.06 if _leap else 0.03)
	var c := Vector2(global_position.x, floor_y)
	FX.burst(get_parent(), c, Color(0.95, 0.9, 0.75, 0.8), 34 if _leap else 20, 620, 0.55, 22, 500, 80, Vector2.UP)
	FX.ring(get_parent(), c + Vector2(0, -20), Color(1.6, 1.4, 0.9, 0.8), 360 if _leap else 220, 0.35)
	var n := 2 if (_leap or fury) else 1
	for dir in ([-1.0, 1.0] if n == 2 else [face]):
		_wave(dir, 1.25 if _leap else 1.0)
	if _leap:
		set_state("tired")
		FX.float_text(get_parent(), global_position + Vector2(0, -320), "¡ATURDIDO!", Color(2.0, 1.8, 0.5), 30)
	else:
		set_state("idle")

func _wave(dir: float, k: float) -> void:
	var w := AetherHazard.new()
	w.kind = "wave"
	w.position = Vector2(global_position.x + dir * 150, floor_y)
	w.vel = Vector2(dir * 640 * k * _speed(), 0)
	w.damage = 16
	w.life = 2.2
	w.col = Color(1.7, 1.4, 0.7) if not fury else Color(2.0, 0.8, 0.5)
	get_parent().add_child(w)

func _bubble() -> void:
	var pl = Aether.player
	var mouth := global_position + Vector2(face * 150, -200)
	var target_x: float = pl.global_position.x if pl else mouth.x + face * 400
	var b := AetherHazard.new()
	b.kind = "bubble"
	b.position = mouth
	b.gravity = 1800
	var t := 0.9
	b.vel = Vector2((target_x - mouth.x) / t + randf_range(-120, 120), -700)
	b.floor_y = floor_y - 10
	b.radius = 26
	b.damage = 14
	b.col = Color(0.8, 1.8, 0.6)
	get_parent().add_child(b)
	Aether.sfx("bounce", 0.6, 1.4)

func _update_tongue() -> void:
	var start := Vector2(face * 140, -170)
	var end := start + Vector2(face * _tongue_len, 18)
	tongue.clear_points()
	for i in 8:
		var f := i / 7.0
		var p := start.lerp(end, f)
		p.y += sin(f * PI) * 26.0 * (1.0 - min(1.0, state_t * 3.0))
		tongue.add_point(p)
	tip.position = end
	var pl = Aether.player
	if pl and not _tongue_hit and not pl.dead:
		var tip_g := global_position + end
		if pl.hurt_rect().grow(16).has_point(tip_g):
			_tongue_hit = true
			pl.take_damage(20, global_position.x)

func _on_hurt(crit: bool) -> void:
	T.wobble = 0.6
	P.head = -0.5
	if not crit:
		# si le golpeas de frente sin pausa, se cubre
		var now := Time.get_ticks_msec() / 1000.0
		_hits_window.append(now)
		while _hits_window.size() > 0 and now - _hits_window[0] > 1.2:
			_hits_window.pop_front()
		if _hits_window.size() >= 3 and state in ["idle", "hop_prep", "spit_prep", "hurt"]:
			_hits_window.clear()
			set_state("guard")
			Aether.sfx("shield", 1.0, 0.7)
			FX.float_text(get_parent(), global_position + Vector2(0, -300), "¡SE CUBRE!", Color(0.8, 1.0, 1.4), 28)

func _on_blocked() -> void:
	T.wobble = 0.3

func _on_fury() -> void:
	Aether.sfx("roar", 1.0, 0.6)
	Aether.flash(Color(1.0, 0.3, 0.2), 0.35)
	Aether.shake(20, 0.06)
	FX.float_text(get_parent(), global_position + Vector2(0, -340), "¡FURIA!", Color(2.4, 0.6, 0.4), 44)
	FX.ring(get_parent(), global_position + Vector2(0, -150), Color(2.2, 0.6, 0.4, 0.9), 520, 0.6)

func _on_defeat_start() -> void:
	tongue.visible = false
	tip.visible = false
	_airborne = false
	global_position.y = floor_y
	_die_t = 0.0

func _dying_tick(delta: float) -> void:
	_die_t += delta
	if _die_t < 0.5:
		# se estira hacia arriba con la boca abierta (último grito)
		T.squash = 1.3; T.jaw = 1.0; T.belly = 0.6; T.wobble = 0.8
	elif _die_t < 2.2:
		# se desinfla y se desploma
		T.squash = 0.45; T.jaw = 0.4; T.belly = -0.6; T.wobble = 0.25; T.lean = -0.25 * face
		art.modulate.a = 1.0 - clamp((_die_t - 1.4) / 0.8, 0.0, 1.0)
	_flash = 0.6 if fmod(_die_t, 0.16) < 0.08 else 0.0
	_die_boom -= delta
	if _die_boom <= 0 and _die_t < 2.0:
		_die_boom = 0.18
		var p := global_position + Vector2(randf_range(-150, 150), randf_range(-260, -40))
		FX.burst(get_parent(), p, Color(2.6, 2.0, 1.2), 20, 560, 0.5, 14, 300)
		FX.glow(get_parent(), p, Color(2.0, 1.5, 0.8, 0.8), 150, 0.3)
		Aether.sfx("boom", 0.5, randf_range(0.8, 1.2))
		Aether.shake(8, 0.0)
	if _die_t >= 2.2 and _die_t - delta < 2.2:
		var c := global_position + Vector2(0, -150)
		FX.burst(get_parent(), c, Color(3.0, 2.6, 1.4), 80, 900, 0.9, 18, 200)
		FX.ring(get_parent(), c, Color(2.6, 2.2, 1.2, 1.0), 900, 0.7)
		Aether.flash(Color(1, 0.95, 0.8), 0.8)
		Aether.sfx("win", 1.0)
		visible = false
		finish_defeat()
