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
	var m := g.mansion
	var t0 := Time.get_ticks_msec()
	while not m.nav_ready and Time.get_ticks_msec() - t0 < 120000:
		await get_tree().process_frame
	print("ZAREK: navegación lista en %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	print("ZAREK: habitaciones %d, sellos %d, armarios %d, lámparas %d, puertas %d, pasos %d" % [m.rooms.size(), m.seals.size(), m.wardrobes.size(), m.lamps.size(), m.doors.size(), m.portals.size()])
	_check(m.nav_ready, "navegación de Elena horneada")
	_check(m.seals.size() == 4, "4 sellos")
	_check(m.wardrobes.size() >= 10, "armarios")
	_check(m.lamps.size() >= 6, "lámparas")
	var inside := g.respawn_pos
	for s in m.seals:
		var pth := m.path(inside, s.pos)
		var ok := pth.size() > 0 and pth[pth.size() - 1].distance_to(s.pos) < 3.0
		_check(ok or m.room_at(s.pos) < 0, "Elena llega al sello en " + m.room_name(s.pos))
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
	_check(g.entered, "al entrar se cierra la puerta (evento)")
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
	_check(g.state == "juego", "despiertas en el vestíbulo")
	# esconderse: no te ve
	var wd: Dictionary = m.wardrobes[0]
	g.player.global_position = wd.pos
	g._enter_wardrobe(wd)
	g.elena.global_position = wd.pos + Vector3(0, 0, 2.0)
	g.elena.global_position.y = wd.pos.y
	g.elena.set_state(ZarekElena.S.WANDER)
	await _wait(0.3)
	_check(g.state == "escondido" and not g.elena._can_see_player(), "escondido en el armario no te ve")
	g._exit_wardrobe(true)
	_check(g.state == "juego", "sales del armario")
	g.elena.vanish(60.0)
	# recoger los 4 sellos
	for s in m.seals:
		g.player.global_position = s.pos + Vector3(0.8, 0.05, 0)
		await _wait(0.1)
		g._use()
	_check(g.seals == 4, "4 sellos recogidos")
	var unlocked := true
	for d in m.doors:
		if d.locked:
			unlocked = false
	_check(unlocked, "la puerta del Epicentro se abre")
	# ritual
	g.set_meta("no_catch", true)
	g.elena.vanish(60.0)
	g.player.global_position = m.circle_pos
	g.state = "ritual"
	t = 0.0
	while g.state != "final" and t < 16.0:
		await _wait(0.25)
		t += 0.25
	_check(g.state == "final", "ritual completado: Zarek expulsado")
	await _wait(9.0)
	_check(g.end_box.visible, "pantalla final")
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
