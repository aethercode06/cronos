class_name ZarekTension
extends Node
## Director del miedo (como el «medidor de amenaza» de Alien: Isolation): el terror no viene de que Damián esté
## siempre encima, sino del ritmo. Tres fases:
## - CALMA: la casa respira; Damián ronda por su cuenta.
## - ACECHO: tras un rato sin verle, la casa avisa de que se acerca (pasos arriba, una puerta, luces que
##   tiemblan, un gruñido al otro lado de la pared…) y al final aparece cerca, buscándote.
## - RESPIRO: tras una persecución o mucho rato con él encima, se aleja de verdad (se oye irse) y te deja
##   explorar un rato. Así la tensión sube y baja y cada encuentro pesa.

var j: Node  # ZarekJuego
var amenaza := 0.0
var fase := "calma"
var t_fase := 0.0
var sin_contacto := 0.0
var _alta := 0.0
var _antes_caza := false
var _t_aviso := 0.0
var _dur_respiro := 50.0
var _se_fue := false
var activo := true

func _poner_fase(f: String) -> void:
	fase = f
	t_fase = 0.0
	_t_aviso = randf_range(2.0, 4.0)
	_se_fue = false
	if f == "respiro":
		_dur_respiro = randf_range(40.0, 70.0) - j.seals * 4.0
	print("ZAREK tensión: ", f)

func tick(delta: float) -> void:
	if not activo or j.elena == null or not j.entered or not (j.state in ["juego", "escondido"]):
		return
	var e: ZarekElena = j.elena
	var p: Vector3 = j.player.global_position
	var cerca := e.visible and e.state != ZarekElena.S.DORMANT
	var d: float = e.global_position.distance_to(p) if cerca else 99.0
	var caza := e.state == ZarekElena.S.CHASE
	# medidor de amenaza: sube rápido con él cerca o persiguiendo, baja despacio
	var objetivo := 1.0 if caza else (clampf(1.0 - d / 14.0, 0.0, 1.0) * 0.8 if d < 14.0 else 0.0)
	if objetivo > amenaza:
		amenaza = lerpf(amenaza, objetivo, minf(1.0, delta * 1.5))
	else:
		amenaza = maxf(0.0, amenaza - delta * 0.025)
	if d < 18.0:
		sin_contacto = 0.0
	else:
		sin_contacto += delta
	t_fase += delta
	var escapo: bool = _antes_caza and not caza and j.state != "atrapado"
	_antes_caza = caza
	match fase:
		"calma":
			e.rondar = 1.0
			_alta = _alta + delta if amenaza > 0.7 else maxf(0.0, _alta - delta * 0.5)
			if escapo or _alta > 22.0:
				_poner_fase("respiro")
			elif sin_contacto > lerpf(95.0, 50.0, j.seals / 4.0):
				_poner_fase("acecho")
		"acecho":
			e.rondar = 1.2
			if d < 16.0 or caza:
				_poner_fase("calma")
				return
			_t_aviso -= delta
			if _t_aviso <= 0.0:
				_t_aviso = randf_range(4.0, 7.0)
				_aviso(p, t_fase / 22.0)
			if t_fase > 22.0:
				_aparecer_cerca(e, p)
				sin_contacto = 0.0
				_poner_fase("calma")
		"respiro":
			e.rondar = 0.0
			if caza:
				return
			# en cuanto le pierdes de vista se marcha (y se le oye irse)
			if not _se_fue and t_fase > 4.0 and (d > 20.0 or not e.sees_player) and e.state in [ZarekElena.S.WANDER, ZarekElena.S.SEARCH, ZarekElena.S.INVESTIGATE, ZarekElena.S.DORMANT]:
				_se_fue = true
				j.sound_at("portazo", p + Vector3(randf_range(-14, 14), 1.0, randf_range(-14, 14)), -6.0)
				e.vanish(_dur_respiro)
			if t_fase > _dur_respiro:
				amenaza = 0.3
				_alta = 0.0
				sin_contacto = 35.0
				_poner_fase("calma")

## Avisos de que se acerca, cada vez más cerca y más claros (fuerza 0-1).
func _aviso(p: Vector3, fuerza: float) -> void:
	var dist := lerpf(14.0, 6.0, clampf(fuerza, 0.0, 1.0))
	var ang := randf() * TAU
	var donde := p + Vector3(cos(ang) * dist, 1.0, sin(ang) * dist)
	match randi() % 5:
		0:
			j._footsteps_above()
		1:
			j.sound_at("damian_gruñe", donde, lerpf(-12.0, -2.0, fuerza))
		2:
			j.sound_at("puerta_crujido", donde, -4.0)
		3:
			var rid: int = j.mansion.room_at(p)
			for l in j.mansion.lamps:
				if l.on and j.mansion.room_at(l.pos) == rid:
					j.mansion.flicker_lamp(l, 1.4)
		4:
			j.sound_at("damian_paso", donde, lerpf(-10.0, 0.0, fuerza))
	if fuerza > 0.6:
		j.message("Está cerca. Lo noto.", 1.6)

## Aparece en una sala cercana (no en la tuya) y viene a buscarte a donde estás.
func _aparecer_cerca(e: ZarekElena, p: Vector3) -> void:
	var rid: int = j.mansion.room_at(p)
	var mejor := Vector3.INF
	for i in 25:
		var q: Vector3 = j.mansion.random_floor(p, 9.0, rid, j.mansion.level_of(p.y + 0.3))
		if q.distance_to(p) < 20.0 and absf(q.y - p.y) < 2.0:
			mejor = q
			break
	if mejor == Vector3.INF:
		return
	if e.state == ZarekElena.S.DORMANT or e.global_position.distance_to(p) > 20.0:
		e.global_position = mejor
	e.set_state(ZarekElena.S.INVESTIGATE, 15.0)
	e.last_seen = p + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	e.path = []
	j.sound_at("damian_rugido", mejor + Vector3(0, 1.5, 0), -4.0)
