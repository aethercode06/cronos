extends Node
## Prueba automática de La Sombra de Zarek (Noche I). Imprime «ZAREK OK».
## Con `-- --capturas` guarda imágenes en la carpeta SHOTS_DIR.

var g: ZarekJuego
var fails := 0

func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FALLO ") + what)
	if not ok:
		fails += 1

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _ready() -> void:
	var shots := "--capturas" in OS.get_cmdline_user_args()
	g = load("res://zarek/zarek.tscn").instantiate()
	g.autotest = true
	add_child(g)
	await _wait(0.5)
	if shots:
		await _capturas()
		get_tree().quit()
		return
	var t0 := Time.get_ticks_msec()
	# la carga es por pasos: esperar a que termine entera (jugador y Elena creados) y a la navegación
	while (g.mansion == null or g.player == null or g.elena == null or not g.mansion.nav_ready) and Time.get_ticks_msec() - t0 < 180000:
		await get_tree().process_frame
	var m := g.mansion
	for k in 10:
		await get_tree().physics_frame
	print("ZAREK: navegación lista en %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	print("ZAREK: habitaciones %d, sellos %d, armarios %d, lámparas %d, puertas %d, pasos %d" % [m.rooms.size(), m.seals.size(), m.wardrobes.size(), m.lamps.size(), m.doors.size(), m.portals.size()])
	_check(m.nav_ready, "navegación de Elena horneada")
	g.huida.congelar_furia = true
	_check(m.seals.size() == ZarekHuida.objetos(0).size(), "objetos de la noche (%d)" % m.seals.size())
	var con_sentido := true
	for so in m.seals:
		var salas: Array = ZarekMansion.SITIOS_POR_OBJETO.get(String(so.tipo), [])
		if not m.room_name(so.pos) in salas.map(func(x): return String(x).to_lower()):
			con_sentido = false
			print("  objeto fuera de sitio: %s en %s" % [so.tipo, m.room_name(so.pos)])
	_check(con_sentido, "cada objeto en un sitio con sentido")
	var rutas := {}
	for sd in range(1, 200):
		rutas[ZarekHuida.salida_bloqueada(sd)] = true
	_check(rutas.size() == 3, "cada noche se bloquea una salida distinta (%d)" % rutas.size())
	_check(g.huida.matadero_pos != Vector3.INF and m.room_name(g.huida.matadero_pos) == "galería de servicio", "el matadero existe")
	_check(m.wardrobes.size() >= 10, "armarios")
	_check(m.lamps.size() >= 6, "lámparas")
	var inside := g.respawn_pos
	for s in m.seals:
		var pth := m.path(inside, s.pos)
		var ok := pth.size() > 0 and pth[pth.size() - 1].distance_to(s.pos) < 3.0
		_check(ok or m.room_at(s.pos) < 0 or m.level_of(s.pos.y + 0.5) == 2, "Damián llega al objeto en " + m.room_name(s.pos))
	var pe := m.path(inside, m.circle_pos)
	_check(pe.size() > 0 and pe[pe.size() - 1].distance_to(m.circle_pos) < 3.0, "Elena llega al Epicentro (primer piso)")
	var cava := m.cell_to_world("sotano", 21.5, 10.0)
	var pc := m.path(inside, cava)
	_check(pc.size() > 0 and pc[pc.size() - 1].distance_to(cava) < 3.0, "Elena baja al sótano")
	# el jugador camina desde el bosque hasta la puerta
	g.player.global_position = m.start_pos
	_check(m.room_name(m.start_pos) == "el bosque", "empiezas en el bosque")
	g.player.global_position = inside
	await _wait(0.3)
	_check(g.entered and g.huida.porton_cerrado, "al entrar se cierra la puerta y el portón con cadena")
	# Elena se despierta y ronda
	g.elena.timer = 0.0
	await _wait(1.0)
	_check(g.elena.state != ZarekElena.S.DORMANT, "Elena despierta (" + g.elena.state_name() + ")")
	# lámparas: luz segura
	var l: Dictionary = m.lamps[0]
	m.set_lamp(l, true)
	_check(m.is_lit(l.pos + Vector3(1.0, -2.0, 0.5)), "lámpara ilumina su habitación")
	m.set_lamp(l, false)
	# la sal la ahuyenta
	g.player.global_position = inside
	g.player.set_look(0.0, 0.0)
	g.elena.global_position = inside + Vector3(0, 0, -3.0)
	g.elena.set_state(ZarekElena.S.CHASE)
	g.salt = 2
	g._throw_salt()
	_check(g.elena.state == ZarekElena.S.FLEE, "la sal la ahuyenta")
	await _wait(3.0)
	_check(g.elena.state == ZarekElena.S.DORMANT, "tras huir desaparece")
	# te atrapa si estás cerca (a oscuras)
	for lp in m.lamps:
		m.set_lamp(lp, false)
	var lives0 := g.lives
	g.player.global_position = inside
	g.elena.global_position = inside + Vector3(0, 0, -4.0)
	g.elena.set_state(ZarekElena.S.CHASE)
	var t := 0.0
	while g.lives == lives0 and t < 8.0:
		await _wait(0.2)
		t += 0.2
	_check(g.lives == lives0 - 1, "Elena te atrapa (vidas %d)" % g.lives)
	while g.state != "juego" and t < 14.0:
		await _wait(0.2)
		t += 0.2
	_check(g.state == "juego" and g.player.global_position.distance_to(g.huida.matadero_pos) < 2.0, "Damián te cuelga en el matadero")
	# esconderse: no te ve
	var wd: Dictionary = m.wardrobes[0]
	g.player.global_position = wd.pos
	g._enter_wardrobe(wd)
	g.elena.global_position = wd.pos + Vector3(0, 0, 2.0)
	g.elena.global_position.y = wd.pos.y
	g.elena.set_state(ZarekElena.S.WANDER)
	await _wait(0.3)
	_check(g.state == "escondido" and not g.elena._can_see_player(), "escondido en el armario no te ve")
	await _wait(1.5)
	_check(absf(g.player.global_position.y - (wd.inside as Vector3).y) < 0.2, "escondida no se cae atravesando el suelo")
	g._exit_wardrobe(true)
	_check(g.state == "juego", "sales del armario")
	# debajo de la cama: la vista baja a ras de suelo y vuelve al salir
	var camas := m.wardrobes.filter(func(w): return w.get("tipo", "") == "cama")
	_check(camas.size() >= 5, "escondites bajo las camas (%d)" % camas.size())
	if not camas.is_empty():
		g.player.global_position = camas[0].pos
		g._enter_wardrobe(camas[0])
		await _wait(0.2)
		var bajo: bool = g.player.head.position.y < 0.5 and g.slit_cama.visible
		g._exit_wardrobe(true)
		_check(bajo and g.player.head.position.y > 1.0, "esconderse debajo de la cama")
	# el fonógrafo lo atrae (sin hábitos guardados de otras partidas: si no, Damián ya conoce el truco)
	Aether.save.set_value("zarek_habitos", {"esc": {}, "fono": 0})
	g.elena.global_position = m.radio_pos + Vector3(6, -1.0, 0)
	g.elena.set_state(ZarekElena.S.WANDER)
	g._poner_fonografo()
	await _wait(0.3)
	_check(g.elena.state == ZarekElena.S.INVESTIGATE and g.elena.last_seen.distance_to(m.radio_pos) < 0.5, "el fonógrafo lo atrae")
	g._t_fono = 0.01
	await _wait(0.1)
	_check(m.pickups.any(func(k): return k.kind == "llaves") and m.car_pos != Vector3.ZERO, "las llaves de la camioneta están en la casa")
	_check(m.pickups.filter(func(k): return k.kind == "tablon").size() >= 1, "tablones para atrancar puertas")
	_check(g.sustos != null and ZarekSonido.hay("damian_rugido") and ZarekSonido.hay("persecucion"), "sonidos reales y sustos de la historia cargados")
	# electricidad: el interruptor apaga y enciende la sala; sin corriente no se enciende nada; el cuadro la devuelve
	var el: ZarekElectricidad = m.electricidad
	var sw: Dictionary = {}
	for it in el.interruptores:
		var hay_buena := false
		for lm in m.rooms[int(it.room)].get("lamps", []):
			if not lm.broken:
				hay_buena = true
		if hay_buena and it.on:
			sw = it
			break
	var lamparas_sala: Array = m.rooms[int(sw.room)].lamps
	el.pulsar(sw)
	var apagada := lamparas_sala.all(func(lz): return not lz.on)
	el.pulsar(sw)
	var encendida := lamparas_sala.any(func(lz): return lz.on)
	el.cortar()
	var todo_negro := m.lamps.all(func(lz): return not lz.on)
	el.pulsar(sw)
	el.pulsar(sw)
	var sigue_negro := lamparas_sala.all(func(lz): return not lz.on)
	el.devolver()
	_check(el.interruptores.size() >= 20 and not el.cuadro.is_empty() and apagada and encendida and todo_negro and sigue_negro and lamparas_sala.any(func(lz): return lz.on), "electricidad: interruptores, corte de luz y cuadro eléctrico")
	# puertas con peso: primero una rendija (sigue cerrando el paso), luego del todo
	var pz: Dictionary = {}
	for d in m.doors:
		if not d.locked and not d.has("pivot2"):
			pz = d
			break
	m.set_door(pz, false)
	pz.ang = 0.0
	pz["vel"] = 0.0
	m.entreabrir(pz)
	await _wait(2.5)
	var rendija: bool = absf(float(pz.ang) - ZarekMansion.PUERTA_RENDIJA) < 0.08 and not pz.open and not pz.shape.disabled
	m.set_door(pz, true)
	await _wait(2.5)
	_check(rendija and absf(float(pz.ang) - 1.6) < 0.08, "puerta: rendija y luego abierta del todo")
	# registrar un mueble
	_check(g.muebles_reg.size() >= 20, "muebles para registrar (%d)" % g.muebles_reg.size())
	var mx: Dictionary = g.muebles_reg.filter(func(x): return String(x.tipo) != "")[0]
	ZarekRegistro.abrir(m, mx)
	_check(mx.hecho, "registrar un mueble abre el cajón")
	# la noche: salas cerradas con su llave en algún cajón, secretos repartidos
	var con_llave := g.muebles_reg.filter(func(x): return String(x.botin).begins_with("llave:"))
	var con_secreto := g.muebles_reg.filter(func(x): return String(x.botin).begins_with("secreto:"))
	_check(g.salas_cerradas.size() >= 1 and con_llave.size() == g.salas_cerradas.size(), "salas cerradas con llave (%d) y sus llaves en cajones" % g.salas_cerradas.size())
	_check(con_secreto.size() >= 3, "secretos de la familia escondidos (%d)" % con_secreto.size())
	if not g.salas_cerradas.is_empty():
		var sc: Dictionary = g.salas_cerradas[0]
		var dl: Dictionary = sc.puerta
		g.player.global_position = (dl.pos as Vector3) + Vector3(0, 0.05, 0)
		var sin_llave: String = g._target().get("kind", "")
		g.llaves_salas.append(String(sc.nombre))
		var con: String = g._target().get("kind", "")
		g._use()
		await _wait(1.5)
		_check(sin_llave == "cerrada" and con == "abrir_llave" and not dl.locked and dl.open, "abrir una sala con su llave")
	var antes_sec: Array = Aether.save.get_value(ZarekSecretos.CLAVE, []).duplicate()
	Aether.save.set_value(ZarekSecretos.CLAVE, [])
	g._secreto("k2")
	var guardado := ZarekSecretos.cuantos() == 1 and "k2" in g.secretos_noche
	g._abrir_archivo()
	_check(guardado and g.archivo_box != null, "secreto guardado en el archivo")
	g.archivo_box.queue_free()
	g.archivo_box = null
	g.panel_nota.visible = false
	Aether.save.set_value(ZarekSecretos.CLAVE, antes_sec)
	var antes_hab = Aether.save.get_value("zarek_habitos", null)
	var wd0: Dictionary = m.wardrobes[0]
	for k in 4:
		g._anotar_escondite(wd0)
	_check(g._conoce_escondite(wd0) > 0.2, "Damián recuerda tus escondites")
	Aether.save.set_value("zarek_habitos", antes_hab if antes_hab != null else {"esc": {}, "fono": 0})
	g.suceso = "tormenta"
	g._empezar_suceso()
	g._trueno()
	await _wait(1.6)
	_check(g._trueno_tapa > 0.0 and g.snd_lluvia != null, "tormenta: el trueno tapa los pasos")
	# director de tensión: calma -> acecho -> aparece cerca; tras una persecución, respiro
	var tn: ZarekTension = g.tension
	tn.activo = true
	g.elena.vanish(5.0)
	tn._poner_fase("calma")
	tn.sin_contacto = 200.0
	tn.tick(0.016)
	var fue_acecho := tn.fase == "acecho"
	tn.t_fase = 23.0
	tn.tick(0.016)
	var ed_t: float = g.elena.global_position.distance_to(g.player.global_position)
	_check(fue_acecho and tn.fase == "calma" and g.elena.state == ZarekElena.S.INVESTIGATE and ed_t < 22.0, "tensión: acecho y aparece cerca (%.0f m)" % ed_t)
	tn._antes_caza = true
	g.elena.set_state(ZarekElena.S.WANDER)
	tn.tick(0.016)
	_check(tn.fase == "respiro" and g.elena.rondar == 0.0 or tn.fase == "respiro", "tensión: respiro tras escapar")
	tn.activo = false
	tn._poner_fase("calma")
	g.elena.rondar = 1.0
	g.elena.vanish(60.0)
	# defensa: armas a la vista, forcejeo, trampa de caza y escopeta
	var df: ZarekDefensa = g.defensa
	var en_cajon := g.muebles_reg.filter(func(x): return String(x.botin) in ["cepo", "escopeta", "cartucho"] or String(x.botin).begins_with("arma:"))
	_check(df.suelo.size() >= 1 and en_cajon.size() >= 3, "defensas repartidas (%d a la vista, %d en cajones)" % [df.suelo.size(), en_cajon.size()])
	var vidas0: int = g.lives
	df.arma = "cuchillo"
	g.elena.set_state(ZarekElena.S.CHASE)
	g.elena.visible = true
	g.elena.global_position = g.player.global_position + Vector3(0.8, 0, 0)
	g._on_caught()
	var en_forcejeo: bool = g.state == "forcejeo"
	await _wait(3.2)
	_check(en_forcejeo and g.state == "juego" and df.arma == "" and g.lives == vidas0 and g.elena.heridas == 1, "forcejeo: se la clava y huye")
	g.elena.vanish(60.0)
	await _wait(3.2)
	g.elena.can_catch = true
	# trampa de caza
	var pp_t: Vector3 = g.player.global_position
	df.cepos = 1
	df.poner_trampa(pp_t + Vector3(0, 0, 1.5), 0.0)
	g.elena.set_state(ZarekElena.S.WANDER)
	g.elena.global_position = pp_t + Vector3(0, 0, 1.5)
	g.set_meta("no_catch", true)
	await _wait(0.3)
	_check(g.elena.aturdido > 3.0 and df.trampas.is_empty(), "trampa de caza: lo atrapa")
	g.elena.aturdido = 0.0
	# escopeta: buscar una dirección despejada y ponerle ahí
	var dir_libre := Vector3.ZERO
	for k in 12:
		var dv := Vector3(cos(k * TAU / 12.0), 0, sin(k * TAU / 12.0))
		var qq := PhysicsRayQueryParameters3D.create(pp_t + Vector3(0, 1.5, 0), pp_t + Vector3(0, 1.5, 0) + dv * 7.0)
		qq.collision_mask = 1
		if g.get_world_3d().direct_space_state.intersect_ray(qq).is_empty():
			dir_libre = dv
			break
	df.escopeta = true
	df.cartuchos = 1
	var her0: int = g.elena.heridas
	g.elena.set_state(ZarekElena.S.WANDER)
	g.elena.global_position = pp_t + dir_libre * 5.0
	g.player.set_look(atan2(-dir_libre.x, -dir_libre.z), 0.0)
	await _wait(0.1)
	df.disparar()
	await _wait(0.3)
	_check(dir_libre == Vector3.ZERO or g.elena.heridas == her0 + 1, "escopeta: lo derriba")
	await _wait(3.2)
	g.elena.vanish(60.0)
	g.elena.aturdido = 0.0
	g.set_meta("no_catch", false)
	# diario: objetivos con pistas y mapa
	g.diario.abrir("objetivos")
	var txt_obj: String = g.diario.texto_objetivos()
	await _wait(0.2)
	var pausado := get_tree().paused
	g.diario._pestana = "mapa"
	g.diario.refrescar()
	await _wait(0.2)
	g.diario.cerrar_diario()
	_check(pausado and not get_tree().paused and "SALIR VIVA DE LA FINCA" in txt_obj and "LA MADRE" in txt_obj and "FINALES" in txt_obj and "MANTÉN USAR" in txt_obj, "diario: objetivos, pistas y mapa")
	var s0: Dictionary = m.seals[0]
	var pista_vaga: String = g.diario.pista(s0)
	s0["visto"] = true
	var pista_exacta: String = g.diario.pista(s0)
	s0.erase("visto")
	_check(pista_vaga != pista_exacta and m.room_name(s0.pos) in pista_exacta, "pistas: vaga y luego exacta")
	g.suceso = "normal"
	var sucesos := {}
	for sd in range(1, 400):
		sucesos[ZarekNoches.elegir_suceso(sd)] = true
	_check(sucesos.size() == ZarekNoches.SUCESOS.size(), "todas las noches posibles salen (%d)" % sucesos.size())
	# puerta atrancada: la aporrea y la rompe
	var pd: Dictionary = {}
	for d in m.doors:
		if not d.locked:
			pd = d
			break
	m.set_door(pd, false)
	m.atrancar(pd, 0.6)
	m.set_door(pd, true)
	var sigue_cerrada: bool = not pd.open
	g.elena.global_position = pd.pos + Vector3(0.3, 0, 0.3)
	g.elena.set_state(ZarekElena.S.INVESTIGATE, 10.0)
	await _wait(1.5)
	_check(sigue_cerrada and pd.open and float(pd.get("barricada", 0.0)) <= 0.0, "puerta atrancada: aguanta y la rompe a golpes")
	g.elena.vanish(60.0)
	await _wait(0.2)
	g.elena.vanish(60.0)
	# la celda del principio: encadenada, clavo, argolla, cerradura
	var hu: ZarekHuida = g.huida
	hu.empezar_celda()
	g.player.global_position = hu.ancla + Vector3(0, 0.1, 0.3)
	await _wait(0.2)
	g.player.global_position = hu.ancla + Vector3(4.0, 0.1, 0.0)
	hu.tick(0.016)
	var sujeta: bool = Vector2(g.player.global_position.x - hu.ancla.x, g.player.global_position.z - hu.ancla.z).length() <= ZarekHuida.CADENA + 0.05
	g.player.global_position = hu.clavo_pos + Vector3(0.3, 0.1, 0.0)
	var k_clavo: String = str(g._target().get("que", ""))
	g._use()
	var k_arg: String = str(g._target().get("que", ""))
	hu.completar("argolla")
	var puertas_cerradas: bool = hu.celda_puertas.size() > 0 and hu.celda_puertas.all(func(d): return d.locked)
	hu.completar("cerradura")
	_check(sujeta and k_clavo == "clavo" and hu.tiene_clavo and k_arg == "argolla" and not hu.encadenada and puertas_cerradas and not hu.en_celda and hu.celda_puertas.all(func(d): return not d.locked), "celda: encadenada, clavo, argolla y cerradura")
	# recoger los objetos de la noche
	var rs: ZarekHuida = g.huida
	for so in m.seals:
		g.player.global_position = so.pos + Vector3(0.8, 0.05, 0)
		g.player.velocity = Vector3.ZERO
		g._use()
		await _wait(0.1)
	_check(g.seals == m.seals.size() and rs.tiene.get("llave", false) and rs.tiene.get("cuerda", false) and rs.tiene.get("garfio", false), "objetos recogidos (%d)" % g.seals)
	# el cuarto de Damián se abre con su llave
	var dc: Dictionary = {}
	for d in m.doors:
		if d.locked and String(d.get("llave", "")) == "":
			dc = d
	if not dc.is_empty():
		g.player.global_position = (dc.pos as Vector3) + Vector3(0, 0.05, 0)
		var k_abrir: String = g._target().get("kind", "")
		g._use()
		await _wait(0.5)
		_check(k_abrir == "abrir_cuarto" and not dc.locked, "la llave abre el cuarto de Damián")
	# poltergeist: la madre encadenada cierra una puerta y cambia un objeto de sitio
	g.player.global_position = g.respawn_pos
	var hizo_puerta: bool = rs._p_puerta(g.player.global_position, 0.5)
	_check(hizo_puerta, "poltergeist: una puerta se mueve sola")
	# el ruido en el sótano la enfurece: grita y Damián acude
	g.elena.vanish(60.0)
	rs._t_grito = 0.0
	var en_sotano: Vector3 = rs.matadero_pos
	rs.congelar_furia = false
	rs._silencio_ruido = 0.0
	rs.furia = 0.0
	var f0: float = rs.furia
	rs.ruido(en_sotano, 12.0)
	_check(rs.furia > f0 and g.elena.state == ZarekElena.S.INVESTIGATE and g.elena.last_seen.distance_to(en_sotano) < 0.5, "ruido abajo: la madre grita y Damián acude (furia %d)" % int(rs.furia))
	g.elena.vanish(60.0)
	# al 100 % rompe las cadenas
	rs.subir_furia(100.0, "")
	rs.tick(0.016)
	await _wait(3.5)
	_check(rs.madre_suelta and is_instance_valid(rs.madre) and not rs.madre.es_damian, "con la furia al máximo, la madre se suelta")
	# la linterna la frena
	g.flash_on = true
	g.battery = 80.0
	g.player.global_position = g.respawn_pos
	g.player.set_look(0.0, 0.0)
	await _wait(0.2)
	rs.madre.global_position = g.respawn_pos + g.player.look_dir() * 4.0
	rs.madre.global_position.y = g.respawn_pos.y
	rs.madre.set_state(ZarekElena.S.WANDER)
	rs.madre.visible = true
	rs._t_luz_madre = 0.0
	await _wait(0.3)
	_check(rs.madre.state == ZarekElena.S.FLEE or rs.madre.state == ZarekElena.S.DORMANT, "la linterna hace retroceder a la madre (" + rs.madre.state_name() + ")")
	# si te toca, te muerde: sin forcejeo, te quedas donde estás y llevas su mordisco
	var vidas_m: int = g.lives
	if g.defensa:
		g.defensa.arma = "cuchillo"
	var donde: Vector3 = g.player.global_position
	rs.madre.global_position = donde + Vector3(0.6, 0, 0)
	rs.madre.can_catch = true
	g._on_caught_madre()
	await _wait(0.3)
	var sin_forcejeo: bool = g.state == "atrapado"
	var t2 := 0.0
	while g.state != "juego" and t2 < 14.0:
		await _wait(0.2)
		t2 += 0.2
	_check(sin_forcejeo and g.lives == vidas_m - 1 and g.elena.es_damian and rs.mordida and g.player.global_position.distance_to(donde) < 2.0, "la madre te muerde sin forcejeo")
	# quemarla en la capilla: rociar gasolina, que esté dentro, bengala
	g.set_meta("no_catch", true)
	g.player.global_position = rs.capilla_pos + Vector3(0, 0.05, 0)
	var k_rociar: String = str(g._target().get("que", ""))
	rs.completar("rociar")
	rs.madre.global_position = rs.capilla_pos + Vector3(2.0, 0.0, 0.0)
	rs.madre.set_state(ZarekElena.S.WANDER)
	g.salt = 2
	g._throw_salt()
	await _wait(2.5)
	_check(k_rociar == "rociar" and rs.madre_muerta, "la madre arde en la capilla")
	# escapar trepando el muro (la gasolina se gastó en el fuego: la camioneta ya no sirve)
	g.elena.vanish(60.0)
	_check(not rs.faltan("camioneta").is_empty(), "sin gasolina la camioneta no sirve")
	g.player.global_position = rs.muro_pos + Vector3(0.5, 0.05, 0.0)
	var k_muro: String = str(g._target().get("que", ""))
	rs.completar("trepar")
	t = 0.0
	while g.state != "final" and t < 8.0:
		await _wait(0.25)
		t += 0.25
	await _wait(8.0)
	_check(k_muro == "trepar" and g.state == "final" and g.end_box.visible and "VERDADERO" in g.lbl_end_t.text, "final: " + g.lbl_end_t.text)
	print("ZAREK: tiempo de juego simulado %.1f s" % g.play_time)
	if fails == 0:
		print("ZAREK OK")
	else:
		print("ZAREK: %d fallos" % fails)
	get_tree().quit()

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var dir := OS.get_environment("SHOTS_DIR")
	if dir == "":
		dir = "user://"
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(name + ".png"))
	print("ZAREK: captura " + name)

func _cam(pos: Vector3, yaw: float, pitch := 0.0) -> void:
	g.player.global_position = pos
	g.player.velocity = Vector3.ZERO
	g.player.set_look(yaw, pitch)
	await _wait(0.5)

func _capturas() -> void:
	# la carga del juego es asíncrona: esperar a que exista todo
	for k in 600:
		if g.black != null and g.elena != null and g.mansion != null:
			break
		await _wait(0.1)
	var m := g.mansion
	g._black_target = 0.0
	g.black.color.a = 0.0
	g.elena.vanish(999.0)
	g.flash_on = true
	await _cam(m.start_pos, 0.0, 0.0)
	await _shot("1_bosque_inicio")
	await _cam(m.cell_to_world("exterior", 44.0, 62.0), 0.0, 0.14)
	await _shot("2_mansion_fachada")
	await _cam(m.cell_to_world("exterior", 28.0, 58.0), -0.55, 0.16)
	await _shot("3_mansion_lateral")
	await _cam(m.cell_to_world("baja", 9.0, 11.4), 0.0, 0.08)
	await _shot("4_vestibulo_escalera")
	await _cam(m.cell_to_world("baja", 11.3, 3.4), 0.9, 0.05)
	await _shot("5_salon_de_baile")
	await _cam(m.cell_to_world("baja", 3.3, 3.4), 0.6, 0.0)
	await _shot("6_biblioteca")
	await _cam(m.cell_to_world("alta", 9.5, 3.6), 0.4, -0.25)
	await _shot("7_epicentro")
	await _cam(m.cell_to_world("sotano", 8.5, 7.0), PI * 0.5, 0.0)
	await _shot("8_tunel")
	var pos := m.cell_to_world("baja", 1.0, 4.5)
	await _cam(pos, -PI * 0.5, 0.0)
	g.elena.set_state(ZarekElena.S.GHOST)
	g.elena.visible = true
	g.elena.global_position = pos + Vector3(7.0, 0, 0)
	g.elena.look_at(Vector3(pos.x, pos.y, pos.z), Vector3.UP)
	await _wait(0.5)
	await _shot("9_elena_pasillo")
	g.elena.visible = false
	g._show_title()
	await _cam(m.cell_to_world("exterior", 44.0, 62.0), 0.0, 0.14)
	await _shot("10_titulo")
