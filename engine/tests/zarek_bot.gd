extends Node
## Bot que juega partidas enteras de La Sombra de Zarek para ver qué le falta al juego.
## Juega como una persona razonable: se suelta de la celda, explora siguiendo las pistas del diario, busca los objetos
## de la salida más fácil, se esconde cuando le persiguen, vuelve a salir y escapa. Mide tiempos, capturas, furia,
## sustos, persecuciones, atascos y el final. Imprime una línea «BOT {json}» por partida y «BOT FIN».
## Uso: godot --headless --path engine --fixed-fps 60 res://tests/zarek_bot.tscn -- partidas=4 dif=1 escala=4

var g: ZarekJuego
var P := {}
var r := {}            # métricas de la partida actual
var _t := 0.0
var _vistas: Dictionary = {}
var _ultimo_avance := 0.0
var _escondido_t := 0.0
var _t0_partida := 0.0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if "=" in a:
			P[a.get_slice("=", 0)] = a.get_slice("=", 1)
	var n := int(P.get("partidas", "3"))
	Engine.time_scale = float(P.get("escala", "4"))
	for i in n:
		await _partida(i)
	print("BOT FIN")
	get_tree().quit()

func _esperar(seg: float) -> void:
	var fin := _t + seg
	while _t < fin:
		await get_tree().physics_frame

func _physics_process(delta: float) -> void:
	_t += delta

func _partida(i: int) -> void:
	g = load("res://zarek/zarek.tscn").instantiate()
	g.set_meta("bot", true)
	add_child(g)
	var t0 := Time.get_ticks_msec()
	while (g.mansion == null or g.player == null or g.elena == null or g.huida == null or not g.mansion.nav_ready) and Time.get_ticks_msec() - t0 < 240000:
		await get_tree().process_frame
	while g.state != "titulo" and g.title_box and not g.title_box.visible and Time.get_ticks_msec() - t0 < 240000:
		await get_tree().process_frame
	var m := g.mansion
	var hu := g.huida
	_vistas.clear()
	r = {"partida": i, "semilla": m.partida_seed, "noche": "", "bloqueada": hu.salida_cerrada, "objetos": [], "salas_objetos": [],
		"t_celda": -1.0, "t_objetos": {}, "capturas_damian": 0, "mordiscos": 0, "persecuciones": 0, "t_escondida": 0.0,
		"furia_max": 0.0, "madre_suelta_t": -1.0, "poltergeist": 0, "atascos": 0, "salida": "", "final": "", "t_total": 0.0,
		"salas_visitadas": 0, "cordura_min": 100.0, "sin_avance_max": 0.0, "notas": 0, "secretos": 0}
	for s in m.seals:
		r.objetos.append(String(s.tipo))
		r.salas_objetos.append(m.room_name(s.pos))
	var dif := int(P.get("dif", "1"))
	g._jugar(dif)
	r.noche = g.suceso
	# la intro (con la escala de tiempo, unos segundos)
	while g.state == "intro":
		await get_tree().physics_frame
	var empezo := _t
	_t0_partida = _t
	_ultimo_avance = _t
	var cuentas_polt := 0
	var chase_antes := false
	var limite := float(P.get("limite", "1200"))
	while g.state != "final" and g.state != "muerte" and _t - empezo < limite:
		await _paso(hu, m)
		r.furia_max = maxf(r.furia_max, hu.furia)
		r.cordura_min = minf(r.cordura_min, g.sanity)
		if hu.madre_suelta and r.madre_suelta_t < 0.0:
			r.madre_suelta_t = snappedf(_t - empezo, 1.0)
		var ch: bool = g.elena.state == ZarekElena.S.CHASE
		if ch and not chase_antes:
			r.persecuciones += 1
		chase_antes = ch
		r.sin_avance_max = maxf(r.sin_avance_max, _t - _ultimo_avance)
		if hu.has_meta("polt"):
			cuentas_polt = int(hu.get_meta("polt"))
	r.poltergeist = cuentas_polt
	r.capturas_damian = g.deaths - int(r.mordiscos)
	r.t_total = snappedf(_t - empezo, 1.0)
	r.final = g.lbl_end_t.text if g.state in ["final", "muerte"] else "SIN TERMINAR (%s)" % g.state
	r.salas_visitadas = g._salas_vistas.size()
	r.notas = g.notas_leidas
	r.secretos = g.secretos_noche.size()
	r.t_escondida = snappedf(r.t_escondida, 1.0)
	r.furia_max = snappedf(r.furia_max, 1.0)
	r.sin_avance_max = snappedf(r.sin_avance_max, 1.0)
	print("BOT " + JSON.stringify(r))
	await _esperar(2.0)
	get_tree().paused = false
	g.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

## Un paso de decisión del bot.
func _paso(hu: ZarekHuida, m: ZarekMansion) -> void:
	var pp := g.player.global_position
	var e := g.elena
	# mordiscos (para separarlos de las capturas de Damián)
	if hu.mordida and r.mordiscos == 0:
		r.mordiscos = 1
	if g.state in ["atrapado", "forcejeo", "intro"]:
		await get_tree().physics_frame
		return
	# escondida: esperar a que se vaya
	if not g.hidden_in.is_empty():
		r.t_escondida += get_physics_process_delta_time() * Engine.time_scale
		_escondido_t += get_physics_process_delta_time() * Engine.time_scale
		var peligro: bool = (e.state == ZarekElena.S.CHASE or e.state == ZarekElena.S.SEARCH) and e.global_position.distance_to(pp) < 12.0
		if (not peligro and _escondido_t > 6.0) or _escondido_t > 45.0:
			g._exit_wardrobe(true)
			_escondido_t = 0.0
		await get_tree().physics_frame
		return
	# celda del principio
	if hu.encadenada:
		if not hu.tiene_clavo:
			await _ir(hu.clavo_pos, false)
			g._use()
		else:
			await _mantener(hu.ARGOLLA, 2.0)
			hu.completar("argolla")
		_avance()
		return
	if hu.en_celda:
		var d: Dictionary = hu.celda_puertas[0] if not hu.celda_puertas.is_empty() else {}
		if not d.is_empty():
			await _ir(d.pos, false)
		await _mantener(hu.CERRADURA, 5.0)
		hu.completar("cerradura")
		r.t_celda = snappedf(_t - _t0_partida, 1.0)
		_avance()
		return
	# peligro: Damián o la madre persiguiendo cerca → correr al escondite más cercano
	var cazador: ZarekElena = null
	var de := e.global_position.distance_to(pp)
	if e.visible and e.state != ZarekElena.S.DORMANT and absf(e.global_position.y - pp.y) < 2.0 \
			and ((e.state == ZarekElena.S.CHASE and de < 14.0) or (de < 8.0 and g._in_view(e.global_position + Vector3(0, 1.5, 0)))):
		cazador = e
	if hu.madre_suelta and is_instance_valid(hu.madre) and hu.madre.visible and hu.madre.state == ZarekElena.S.CHASE and hu.madre.global_position.distance_to(pp) < 14.0:
		cazador = hu.madre
	if cazador:
		var mejor: Dictionary = {}
		var md := 1e9
		for w in m.wardrobes:
			var dd := (w.pos as Vector3).distance_to(pp)
			if absf((w.pos as Vector3).y - pp.y) < 2.0 and dd < md and (w.pos as Vector3).distance_to(cazador.global_position) > dd:
				md = dd
				mejor = w
		if not mejor.is_empty() and md < 25.0:
			await _ir(mejor.pos, true, 0.9)
			if g.state == "juego":
				g._enter_wardrobe(mejor)
				_escondido_t = 0.0
			return
	# ¿qué salida? la abierta a la que le falta menos
	var salida := ""
	var falta_min := 99
	for s in ZarekHuida.SALIDAS:
		if s == hu.salida_cerrada:
			continue
		var f := hu.faltan(s).size()
		if f < falta_min:
			falta_min = f
			salida = s
	if salida == "":
		await get_tree().physics_frame
		return
	if falta_min == 0 or (salida == "coche" and hu.faltan("coche").size() == 1 and not hu.porton_abierto and hu.tiene.get("rueda", false) and hu.tiene.get("gato", false)):
		await _salir(salida, hu, m)
		return
	# objeto que falta para esa salida: si sé dónde está, voy; si no, exploro según la pista
	var necesarios: Array = ZarekHuida.PIDE[salida]
	for s in m.seals:
		if s.taken or not (String(s.tipo) in necesarios):
			continue
		if s.get("visto", false) or s.get("revelado", false):
			await _ir(s.pos, false, 1.0)
			if (s.pos as Vector3).distance_to(g.player.global_position) < 1.8 and g.state == "juego":
				g._use()
				if s.taken:
					r.t_objetos[String(s.tipo)] = snappedf(_t - _t0_partida, 1.0)
					_avance()
			return
	# las llaves de la camioneta, en el cuarto de Damián (con su llave)
	if salida == "camioneta" and hu.tiene.get("llave", false) and not hu.tiene.get("llaves_camioneta", false):
		for k in m.pickups:
			if k.kind == "llaves" and not k.taken:
				var dc := _puerta_cuarto(m)
				if not dc.is_empty() and dc.locked:
					await _ir(dc.pos, false, 1.2)
					g._use()
				await _ir(k.pos, false, 1.0)
				g._use()
				if hu.tiene.get("llaves_camioneta", false):
					r.t_objetos["llaves_camioneta"] = snappedf(_t - _t0_partida, 1.0)
					_avance()
				return
	# explorar: una sala de la planta y el tipo que dice la pista que aún no haya visto
	await _explorar(necesarios, m)

func _puerta_cuarto(m: ZarekMansion) -> Dictionary:
	for d in m.doors:
		if d.locked and String(d.get("llave", "")) == "" and not d.has("celda"):
			return d
	return {}

func _explorar(necesarios: Array, m: ZarekMansion) -> void:
	var pp := g.player.global_position
	var candidatas: Array = []
	for s in m.seals:
		if s.taken or not (String(s.tipo) in necesarios):
			continue
		var rid := m.room_at(s.pos)
		var lv := m.level_of((s.pos as Vector3).y + 0.5)
		var tipo := String(m.rooms[rid].type) if rid >= 0 else ""
		for rr in m.rooms:
			if int(rr.level) == lv and String(rr.type) == tipo and not _vistas.has(rr.id) and rr.type != "jardin":
				candidatas.append(rr)
	if candidatas.is_empty():
		# todo lo que encaja ya visto: cualquier sala no vista
		for rr in m.rooms:
			if not _vistas.has(rr.id) and rr.type != "jardin":
				candidatas.append(rr)
	if candidatas.is_empty():
		_vistas.clear()
		await get_tree().physics_frame
		return
	candidatas.sort_custom(func(a, b): return _centro(a).distance_to(pp) < _centro(b).distance_to(pp))
	var sala: Dictionary = candidatas[0]
	_vistas[sala.id] = true
	await _ir(_centro(sala), false, 1.5)
	# mirar alrededor
	for k in 8:
		g.player.set_look(k * TAU / 8.0, -0.1)
		await _esperar(0.25)

func _centro(rr: Dictionary) -> Vector3:
	var rc: Rect2 = rr.rect
	var p := Vector3(rc.get_center().x, float(rr.y), rc.get_center().y)
	return g.mansion.random_floor(p, 0.0, -1, int(rr.level)) if g.mansion.room_at(p) != int(rr.id) else p

func _salir(s: String, hu: ZarekHuida, m: ZarekMansion) -> void:
	if s == "coche" and not hu.porton_abierto:
		await _ir(m.porton_pos + Vector3(0, 0, -1.5), false, 2.0)
		await _mantener(hu.CORTAR, 14.0)
		hu.completar("porton")
	var dest: Vector3 = hu._pos_salida(s)
	await _ir(dest, false, 2.5)
	r.salida = s
	match s:
		"camioneta":
			g._escapar("camioneta")
		"coche":
			await _mantener(hu.RUEDA, 10.0)
			hu.completar("rueda")
		"muro":
			await _mantener(hu.TREPAR, 8.0)
			hu.completar("trepar")
	while g.state == "final" and not g.end_box.visible:
		await get_tree().physics_frame

## Mantener una acción: tiempo quieto haciendo ruido (como mantener USAR).
func _mantener(seg: float, ruido: float) -> void:
	var fin := _t + seg
	while _t < fin and g.state == "juego":
		g.oir_ruido(g.player.global_position, ruido)
		await _esperar(0.7)

func _avance() -> void:
	_ultimo_avance = _t

## Caminar (o correr) hasta un punto siguiendo la navegación; hace el ruido de los pasos.
func _ir(dest: Vector3, correr: bool, cerca := 0.8) -> void:
	var m := g.mansion
	var pp := g.player.global_position
	var camino: Array[Vector3] = m.path(pp, dest)
	if camino.is_empty() or camino[camino.size() - 1].distance_to(dest) > 3.0:
		# fuera de la casa o sin camino: por la puerta principal y luego en línea recta
		if m.inside_house(pp) and not m.inside_house(dest):
			var por: Array[Vector3] = m.path(pp, m.front_door + Vector3(0, 0, -1.5))
			camino = por
			camino.append(m.front_door + Vector3(0, 0, 2.0))
			camino.append(dest)
		else:
			camino = [dest]
	var vel := 4.6 if correr else 2.1
	var paso_t := 0.0
	var inicio := _t
	var ultima := pp
	var quieto := 0.0
	for wp in camino:
		while g.state == "juego" and g.hidden_in.is_empty():
			var p := g.player.global_position
			var to := wp - p
			if Vector2(to.x, to.z).length() < 0.35 and absf(to.y) < 0.8:
				break
			if g.player.global_position.distance_to(dest) < cerca:
				return
			var dt := get_physics_process_delta_time() * Engine.time_scale
			var st := to.normalized() * vel * dt
			if st.length() > to.length():
				st = to
			g.player.altura_fija = true  # el bot lleva la posición: sin gravedad ni choques (sigue la navegación)
			g.player.global_position = p + st
			g.player.velocity = Vector3.ZERO
			g.player.running = correr
			if Vector2(st.x, st.z).length() > 0.001:
				g.player.set_look(atan2(-st.x, -st.z), -0.05)
			paso_t += dt
			if paso_t > (0.33 if correr else 0.55):
				paso_t = 0.0
				g._on_step(12.0 if correr else 3.5)
			await get_tree().physics_frame
			# atascos: sin moverse en 6 s
			if g.player.global_position.distance_to(ultima) < 0.05:
				quieto += dt
				if quieto > 6.0:
					r.atascos += 1
					return
			else:
				quieto = 0.0
				ultima = g.player.global_position
			if _t - inicio > 90.0:
				r.atascos += 1
				return
			# si empieza una persecución cerca, cortar para decidir
			if not correr and g.elena.state == ZarekElena.S.CHASE and g.elena.global_position.distance_to(g.player.global_position) < 12.0:
				g.player.running = false
				return
	g.player.running = false
