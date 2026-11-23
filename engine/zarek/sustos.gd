class_name ZarekSustos
extends Node
## Sustos de la historia, una sola vez cada uno y ligados a lo que se cuenta:
## - al llegar: Damián mira desde una ventana del primer piso con un farol y desaparece;
## - en el vestíbulo: se ríe arriba y se le oye caminar por el piso de encima;
## - al bajar al sótano por primera vez: la madre gime muy cerca y arrastra las cadenas;
## - en el matadero: alguien está cortando carne… y se calla;
## - en la capilla: la madre habla desde la oscuridad de la celda;
## - en el cuarto de Damián: oyes que vuelve, pasos que suben y un portazo;
## - al empezar cada persecución, un golpe de música (como mucho cada 30 s).

var j: Node  # ZarekJuego
var hechos := {}
var _ventana: Node3D
var _luz_ventana: OmniLight3D
var _t_ventana := 0.0
var _mirada := 0.0
var _t_susto := 0.0
var _estado_antes := -1

func setup(juego: Node) -> void:
	j = juego

func _process(delta: float) -> void:
	if j == null or j.player == null or not (j.state in ["juego", "ritual"]):
		return
	var pp: Vector3 = j.player.global_position
	var m: ZarekMansion = j.mansion
	_t_susto -= delta
	# persecución: golpe de música al empezar
	var est: int = j.elena.state
	if est == ZarekElena.S.CHASE and _estado_antes != ZarekElena.S.CHASE and _t_susto <= 0.0:
		_t_susto = 30.0
		_golpe(2.0)
	_estado_antes = est
	_llegada(pp, m, delta)
	if not m.inside_house(pp) and pp.y > -0.5:
		return
	var r := m.room_at(pp)
	var nombre := String(m.rooms[r].name) if r >= 0 else ""
	if nombre.begins_with("Vestíbulo") and not hechos.has("vestibulo") and j.entered:
		hechos["vestibulo"] = true
		_vestibulo()
	if pp.y < -1.0 and not hechos.has("sotano"):
		hechos["sotano"] = true
		_sotano(m)
	if nombre == "Galería de servicio" and not hechos.has("matadero"):
		hechos["matadero"] = true
		_matadero(pp)
	if nombre == "Capilla de la madre" and not hechos.has("capilla"):
		hechos["capilla"] = true
		_capilla(m)
	if nombre == "Cuarto de Damián" and not hechos.has("cuarto"):
		hechos["cuarto"] = true
		_cuarto(m, r)

func _golpe(db := 0.0) -> void:
	if ZarekSonido.hay("susto"):
		var p: AudioStreamPlayer = j._player_snd(ZarekSonido.uno("susto"), db)
		p.play()
		p.finished.connect(p.queue_free)

# ---------------- llegada: la figura en la ventana ----------------
func _llegada(pp: Vector3, m: ZarekMansion, delta: float) -> void:
	if hechos.has("ventana") or j.entered:
		if is_instance_valid(_ventana) and _ventana.visible:
			_quitar_ventana()
		return
	var puerta: Vector3 = m.front_door
	if _ventana == null:
		if Vector2(pp.x - puerta.x, pp.z - puerta.z).length() > 34.0:
			return
		# ventana del primer piso en la fachada de la puerta, la más cercana a ella
		var hc := m.house_rect.get_center()
		var hacia := Vector3(puerta.x - hc.x, 0, puerta.z - hc.y).normalized()
		var mejor := {}
		var bd := 1e9
		for v in m.ventanas_info:
			var c: Vector3 = v.c
			if m.level_of(c.y + 0.3) != 1 or (v.inward as Vector3).dot(hacia) > -0.6:
				continue
			var d := Vector2(c.x - puerta.x, c.z - puerta.z).length()
			if d < bd and d > 6.5:
				bd = d
				mejor = v
		if mejor.is_empty():
			hechos["ventana"] = true
			return
		var inward: Vector3 = mejor.inward
		var c2: Vector3 = mejor.c
		_ventana = ZarekElena.new()
		_ventana.only_visual = true
		add_child(_ventana)
		_ventana.global_position = Vector3(c2.x, m.lvl_y(1), c2.z) + inward * 0.45
		_ventana.look_at(_ventana.global_position - inward, Vector3.UP)
		_luz_ventana = OmniLight3D.new()
		_luz_ventana.light_color = Color(1.0, 0.55, 0.25)
		_luz_ventana.light_energy = 6.0
		_luz_ventana.omni_range = 5.5
		add_child(_luz_ventana)
		# el farol detrás de él: se le ve recortado contra la luz de la ventana
		_luz_ventana.global_position = _ventana.global_position + inward * 1.6 + Vector3(0, 1.5, 0)
		_t_ventana = 14.0
	if not _ventana.visible:
		return
	_t_ventana -= delta
	var mira: bool = j._in_view(_ventana.global_position + Vector3(0, 1.6, 0)) if j.player.camera else false
	if mira:
		_mirada += delta
	if _mirada > 1.4 or _t_ventana <= 0.0:
		hechos["ventana"] = true
		if _mirada > 1.4:
			j.sound_at("damian_gruñe", _ventana.global_position + Vector3(0, 1.6, 0), 0.0)
			j.message("Había alguien en la ventana del primer piso…\nMe estaba mirando.", 3.5)
			j.sanity = maxf(0.0, j.sanity - 8.0)
		_quitar_ventana()

func _quitar_ventana() -> void:
	if is_instance_valid(_ventana):
		_ventana.visible = false
		_ventana.queue_free()
	if is_instance_valid(_luz_ventana):
		_luz_ventana.queue_free()

# ---------------- dentro de la casa ----------------
func _vestibulo() -> void:
	await get_tree().create_timer(6.0).timeout
	if not is_inside_tree():
		return
	j.sound_at("risa", j.player.global_position + Vector3(randf_range(-3, 3), 4.5, randf_range(-3, 3)), 2.0)
	await get_tree().create_timer(1.5).timeout
	j._footsteps_above()

func _sotano(m: ZarekMansion) -> void:
	var r := m._sala_por_nombre("Capilla de la madre")
	if r.is_empty():
		return
	var rc: Rect2 = r.rect
	var c := Vector3(rc.get_center().x, float(r.y) + 1.2, rc.end.y - 2.0)
	ZarekSonido.en(self, "madre_gime", c, 10.0, 60.0, 0.95)
	j.sound_at("tintineo", c + Vector3(0, -0.8, 0), 6.0)
	await get_tree().create_timer(2.5).timeout
	if is_inside_tree():
		j.message("Hay alguien más aquí abajo.\nY no es él.", 3.0)

func _matadero(pp: Vector3) -> void:
	ZarekSonido.en(self, "carne", pp + Vector3(4, 1, 2), 6.0, 25.0)
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return
	_golpe(-2.0)
	j.message("Huele a carne podrida…\nEsto no es de cerdo.", 3.5)
	j.sanity = maxf(0.0, j.sanity - 10.0)

func _capilla(m: ZarekMansion) -> void:
	var r := m._sala_por_nombre("Capilla de la madre")
	var rc: Rect2 = r.rect
	var c := Vector3(rc.get_center().x, float(r.y) + 1.4, rc.end.y - 1.5)
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	ZarekSonido.en(self, "madre_gime", c, 12.0, 40.0, 1.0)
	j.sound_at("tintineo", c + Vector3(0.6, -1.0, 0), 8.0)
	for l in m.lamps:
		m.flicker_lamp(l, 2.0)
	await get_tree().create_timer(2.2).timeout
	if not is_inside_tree():
		return
	_golpe(0.0)
	j.message("Desde la oscuridad de la celda, una voz de mujer:\n«Sofía… hija de Inés… acércate a los barrotes…»", 5.0)
	j.sanity = maxf(0.0, j.sanity - 12.0)

func _cuarto(m: ZarekMansion, r: int) -> void:
	await get_tree().create_timer(8.0).timeout
	if not is_inside_tree() or j.state != "juego":
		return
	# vuelve a su cuarto: pasos que suben por la escalera y un portazo en el pasillo
	j.message("Pasos en la escalera…\nVuelve a su cuarto.", 3.0)
	var pp: Vector3 = j.player.global_position
	for i in 5:
		j.sound_at("damian_paso", pp + Vector3(6.0 - i * 0.8, -1.0 + i * 0.25, 4.0), 4.0)
		await get_tree().create_timer(0.7).timeout
		if not is_inside_tree():
			return
	j.sound_at("damian_gruñe", pp + Vector3(3.0, 1.2, 3.0), 4.0)
	var e: ZarekElena = j.elena
	if j.autotest:
		return  # en la prueba automática no se despierta a Damián por guion
	if e.state in [ZarekElena.S.DORMANT, ZarekElena.S.WANDER]:
		if e.state == ZarekElena.S.DORMANT:
			e.wake_far()
		e.last_seen = pp
		e.set_state(ZarekElena.S.INVESTIGATE, 14.0)
		e.path = m.path(e.global_position, pp)
