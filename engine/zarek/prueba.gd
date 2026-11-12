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
	print("ZAREK: mansión %dx%d, sellos %d, armarios %d, lámparas %d, puertas %d" % [m.w, m.h, m.seals.size(), m.wardrobes.size(), m.lamps.size(), m.doors.size()])
	_check(m.seals.size() == 4, "4 sellos")
	_check(m.wardrobes.size() >= 5, "armarios")
	_check(m.lamps.size() == 7, "7 lámparas")
	for s in m.seals:
		_check(m.path(m.start_pos, s.pos).size() > 0, "camino al sello " + str(s.cell) + " (" + m.room_name(s.pos) + ")")
	_check(m.path(m.start_pos, m.circle_pos).size() > 0, "camino al Epicentro")
	# Elena se despierta y ronda
	g.elena.timer = 0.0
	await _wait(1.0)
	_check(g.elena.state != ZarekElena.S.DORMANT, "Elena despierta (" + g.elena.state_name() + ")")
	# lámparas: luz segura
	var l: Dictionary = m.lamps[0]
	m.set_lamp(l, true)
	_check(m.is_lit(m.to_world(l.cell)), "lámpara ilumina su habitación")
	m.set_lamp(l, false)
	# la sal la ahuyenta
	g.player.global_position = m.start_pos
	g.player.set_look(0.0, 0.0)
	g.elena.global_position = m.start_pos + Vector3(0, 0, -3.0)
	g.elena.set_state(ZarekElena.S.CHASE)
	g.salt = 2
	g._throw_salt()
	_check(g.elena.state == ZarekElena.S.FLEE, "la sal la ahuyenta")
	await _wait(3.0)
	_check(g.elena.state == ZarekElena.S.DORMANT, "tras huir desaparece")
	# te atrapa si estás cerca
	var lives0 := g.lives
	g.player.global_position = m.start_pos
	g.elena.global_position = m.start_pos + Vector3(0, 0, -4.0)
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
	g.elena.set_state(ZarekElena.S.WANDER)
	await _wait(0.3)
	_check(g.state == "escondido" and not g.elena._can_see_player(), "escondido en el armario no te ve")
	g._exit_wardrobe(true)
	_check(g.state == "juego", "sales del armario")
	g.elena.vanish(60.0)
	# recoger los 4 sellos
	for s in m.seals:
		g.player.global_position = s.pos + Vector3(0.8, 0, 0)
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

func _capturas() -> void:
	var m := g.mansion
	g._black_target = 0.0
	g.black.color.a = 0.0
	g.elena.vanish(999.0)
	# 1: vestíbulo con la linterna
	g.player.global_position = m.start_pos
	g.player.set_look(0.0, -0.05)
	await _wait(1.0)
	await _shot("1_vestibulo")
	# 2: Elena en el haz de la linterna
	g.elena.set_state(ZarekElena.S.GHOST)
	g.elena.visible = true
	g.player.set_look(-PI * 0.5, -0.05)
	g.elena.global_position = m.start_pos + Vector3(7.0, 0, 0.4)
	g.elena.look_at(Vector3(m.start_pos.x, 0, m.start_pos.z), Vector3.UP)
	await _wait(0.6)
	await _shot("2_elena")
	g.elena.global_position = m.start_pos + Vector3(1.9, 0, 0.15)
	g.elena.look_at(Vector3(m.start_pos.x, 0, m.start_pos.z), Vector3.UP)
	await _wait(0.4)
	await _shot("3_elena_cerca")
	g.elena.visible = false
	# 4: habitación con lámpara encendida
	var l: Dictionary = m.lamps[0]
	m.set_lamp(l, true)
	g.player.global_position = m.to_world(l.cell) + Vector3(0, 0, 3.5)
	g.player.set_look(0.0, 0.0)
	await _wait(0.6)
	await _shot("4_lampara")
	# 5: sello
	var s: Dictionary = m.seals[1]
	g.player.global_position = s.pos + Vector3(0, 0, 2.5)
	g.player.set_look(0.0, -0.25)
	await _wait(0.6)
	await _shot("5_sello")
	# 6: Epicentro
	for d in m.doors:
		if d.locked:
			d.locked = false
			m.set_door(d, true)
	g.player.global_position = m.circle_pos + Vector3(0, 0, 4.0)
	g.player.set_look(0.0, -0.3)
	await _wait(1.0)
	await _shot("6_epicentro")
	# 7: armario
	var wd: Dictionary = m.wardrobes[0]
	g.player.global_position = wd.pos + (wd.pos - wd.inside).normalized() * 1.5
	g.player.set_look(wd.yaw + PI, 0.0)
	await _wait(0.5)
	await _shot("7_armario")
	# 8: título
	g._show_title()
	await _wait(0.8)
	await _shot("8_titulo")
