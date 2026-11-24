extends Node
## Diagnóstico: una jugadora normal (sale de la celda y recorre la casa andando de sala en sala, sin esconderse)
## y un registro de lo que hace Damián: estado, distancia, si la ve, fases del director de tensión, sustos.
## Uso: godot --headless --path engine res://tests/zarek_diag.tscn -- minutos=10 escala=4 semilla=0
var g: ZarekJuego
var P := {}
var _t := 0.0

func _physics_process(delta: float) -> void:
	_t += delta

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if "=" in a:
			P[a.get_slice("=", 0)] = a.get_slice("=", 1)
	Engine.time_scale = float(P.get("escala", "4"))
	g = load("res://zarek/zarek.tscn").instantiate()
	g.set_meta("diag", true)
	add_child(g)
	var t0 := Time.get_ticks_msec()
	while (g.mansion == null or not g.mansion.nav_ready or g.huida == null) and Time.get_ticks_msec() - t0 < 300000:
		await get_tree().process_frame
	while g.title_box and not g.title_box.visible:
		await get_tree().process_frame
	Aether.save.set_value("zarek_tutorial_hecho", true)
	g._jugar(1)
	while g.state == "intro":
		g._saltar_intro = true
		await get_tree().physics_frame
	var hu := g.huida
	var m := g.mansion
	var e := g.elena
	print("DIAG noche=", g.suceso, " elena=", e.state_name(), " pos=", e.global_position)
	# la jugadora tarda lo que tardaría una persona en soltarse (unos 60 s)
	var empezo := _t
	while _t - empezo < 60.0:
		await get_tree().physics_frame
	hu.tiene_clavo = true
	hu.completar("argolla")
	hu.completar("cerradura")
	print("DIAG libre en t=60")
	var minutos := float(P.get("minutos", "10"))
	var destino := Vector3.INF
	var ruta: Array[Vector3] = []
	var log_t := 0.0
	var cerca_t := 0.0
	var ve_t := 0.0
	var caza_t := 0.0
	var n_caza := 0
	var antes_caza := false
	var estados := {}
	var min_d := 999.0
	var vel := 1.6  # andar
	var t_ruta := 0.0
	var en_pantalla_t := 0.0
	var visto_veces := 0
	var antes_vis := false
	while _t - empezo < 60.0 + minutos * 60.0 and g.state in ["juego", "escondido", "atrapado", "forcejeo"]:
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time() * Engine.time_scale
		if g.state != "juego":
			continue
		var pp := g.player.global_position
		t_ruta += dt
		if ruta.is_empty() or t_ruta > 40.0:
			t_ruta = 0.0
			destino = m.random_floor(pp, 8.0, -1, m.level_of(pp.y + 0.3) if randf() < 0.7 else -99)
			ruta = m.path(pp, destino)
		if not ruta.is_empty():
			var q: Vector3 = ruta[0]
			var to := Vector3(q.x - pp.x, 0, q.z - pp.z)
			if to.length() < 0.4:
				ruta.remove_at(0)
				if not ruta.is_empty() and absf(ruta[0].y - pp.y) > 1.0:
					g.player.global_position = ruta[0]
			else:
				g.player.global_position = Vector3(pp.x, q.y if absf(q.y - pp.y) < 1.2 else pp.y, pp.z) + to.normalized() * minf(to.length(), vel * dt)
				g.player._yaw = atan2(-to.x, -to.z)
		var d := e.global_position.distance_to(pp) if e.visible else 999.0
		min_d = minf(min_d, d)
		var st := e.state_name()
		estados[st] = float(estados.get(st, 0.0)) + dt
		if d < 12.0: cerca_t += dt
		# ¿lo tiene en pantalla? (delante, a menos de 20 m y sin nada en medio)
		var vis := false
		if e.visible and d < 20.0 and absf(e.global_position.y - pp.y) < 2.5:
			var to_e := (e.global_position - pp).normalized()
			if g.player.look_dir().normalized().dot(to_e) > 0.7:
				var q := PhysicsRayQueryParameters3D.create(pp + Vector3(0, 1.5, 0), e.global_position + Vector3(0, 1.5, 0), 1)
				vis = e.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
		if vis: en_pantalla_t += dt
		if vis and not antes_vis: visto_veces += 1
		antes_vis = vis
		if e.sees_player: ve_t += dt
		var caza := e.state == ZarekElena.S.CHASE
		if caza: caza_t += dt
		if caza and not antes_caza:
			n_caza += 1
			print("DIAG t=%d PERSECUCIÓN %d (d=%.1f)" % [_t - empezo, n_caza, d])
		antes_caza = caza
		log_t -= dt
		if log_t <= 0.0:
			log_t = 20.0
			print("DIAG t=%d sala=%s damian=%s d=%.1f vis=%s ve=%s fase=%s amenaza=%.2f rondar=%.1f" % [_t - empezo, m.room_name(pp), st, d, e.visible, e.sees_player, g.tension.fase if g.tension else "-", g.tension.amenaza if g.tension else 0.0, e.rondar])
	print("DIAG RESUMEN cerca12m=%ds ve=%ds caza=%ds persecuciones=%d en_pantalla=%ds veces_visto=%d min_d=%.1f capturas=%d encuentros=%s estados=%s estado_final=%s" % [cerca_t, ve_t, caza_t, n_caza, en_pantalla_t, visto_veces, min_d, g.deaths, str(g.enc.hechos), str(estados), g.state])
	get_tree().quit()
