extends Node
## Vídeo de juego de La Sombra de Zarek (para enseñar cómo se juega). Se graba con el Movie Maker de Godot:
##   godot --path . --write-movie parte1.avi --fixed-fps 30 --resolution 960x540 res://tests/zarek_gameplay.tscn -- --parte 1
## Partes: 1 = llegar, la casa, una puerta y un cajón con un secreto · 2 = un objeto de la trampa, aparece Damián,
## huida y escondite · 3 = forcejeo con el cuchillo y, sin arma, el hachazo.

var g
var m
var parte := 1

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--parte" and i + 1 < args.size():
			parte = int(args[i + 1])
	g = load("res://zarek/zarek.tscn").instantiate()
	g.shots = true
	add_child(g)
	for k in 6000:
		if g.mansion != null and g.player != null and g.elena != null and g.state == "juego" and g.mansion.nav_ready:
			break
		await get_tree().process_frame
	m = g.mansion
	g.tension.activo = false
	g.elena.vanish(9999.0)
	g._black_target = 0.0
	g.black.color.a = 0.0
	g.flash_on = true
	await _espera(0.5)
	match parte:
		1: await _parte1()
		2: await _parte2()
		3: await _parte3()
	await _fundido()
	get_tree().quit()

func _espera(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _fundido() -> void:
	g._black_target = 1.0
	await _espera(1.2)

## Gira la vista poco a poco hasta (yaw, pitch) en `t` segundos.
func _mirar(yaw: float, pitch: float, t: float) -> void:
	var y0: float = g.player._yaw
	var p0: float = g.player._pitch
	var n := int(t * 30.0)
	for i in n:
		var k := float(i + 1) / float(n)
		k = k * k * (3.0 - 2.0 * k)
		g.player.set_look(lerp_angle(y0, yaw, k), lerpf(p0, pitch, k))
		await get_tree().process_frame

func _yaw_hacia(desde: Vector3, hacia: Vector3) -> float:
	var d := hacia - desde
	return atan2(-d.x, -d.z)

func _andar(t: float, correr := false) -> void:
	g.player.move_override = Vector2(0, -1)
	g.player.run_override = correr
	await _espera(t)
	g.player.move_override = Vector2.ZERO
	g.player.run_override = false

func _poner(p: Vector3, yaw: float, pitch := 0.0) -> void:
	g.player.global_position = p
	g.player.velocity = Vector3.ZERO
	g.player.set_look(yaw, pitch)

# ---------------- parte 1 ----------------
func _parte1() -> void:
	# llegando a la mansión de noche
	var hr: Rect2 = m.house_rect
	var centro := Vector3(hr.get_center().x, m.front_door.y, hr.get_center().y)
	var fuera: Vector3 = m.front_door - centro
	fuera.y = 0.0
	fuera = fuera.normalized()
	var ini: Vector3 = m.front_door + fuera * 11.0
	_poner(ini, _yaw_hacia(ini, m.front_door), 0.12)
	g.message("Valdeoscuro, 3:00 de la madrugada.", 3.0)
	await _andar(4.5)
	# dentro: el vestíbulo
	var v: Vector3 = m.cell_to_world("baja", 9.0, 11.4)
	_poner(v, 0.0, 0.05)
	g.entered = true
	g.sound_behind("portazo", 3.0, 4.0)
	g.player.shake(10.0)
	g.message("La puerta se cerró detrás de mí.\nYa no hay vuelta atrás.", 3.0)
	await _espera(1.5)
	await _mirar(0.9, 0.12, 2.5)
	await _mirar(-0.7, 0.0, 2.5)
	await _andar(2.0)
	# una puerta: primero una rendija y luego del todo
	var pd: Dictionary = {}
	var mejor := 1e9
	for d in m.doors:
		if d.locked or d.has("pivot2") or int(d.get("level", 0)) != 0:
			continue
		var dist: float = (d.pos as Vector3).distance_to(g.player.global_position)
		if dist < mejor:
			mejor = dist
			pd = d
	if not pd.is_empty():
		m.set_door(pd, false, true)
		pd.ang = 0.0
		pd["vel"] = 0.0
		(pd.pivot as Node3D).rotation.y = pd.base
		var nrm := Vector3(0, 0, 1) if pd.get("horiz", true) else Vector3(1, 0, 0)
		var lado := (pd.pos as Vector3) + nrm * 1.7
		if m.room_at(lado) < 0:
			lado = (pd.pos as Vector3) - nrm * 1.7
		await _espera(0.2)
		_poner(lado + Vector3(0, 0.05, 0), _yaw_hacia(lado, pd.pos), 0.0)
		await _espera(1.0)
		g._mover_puerta(pd)
		await _espera(2.2)
		g._mover_puerta(pd)
		await _espera(1.5)
		await _andar(1.8)
	# un cajón: dentro, un secreto de la familia
	var cajon: Dictionary = {}
	mejor = 1e9
	for x in g.muebles_reg:
		if String(x.tipo) != "cajon" or m.level_of((x.pos as Vector3).y + 0.5) != 0:
			continue
		var dist2: float = (x.pos as Vector3).distance_to(g.player.global_position)
		if dist2 < mejor:
			mejor = dist2
			cajon = x
	if not cajon.is_empty():
		var cp: Vector3 = cajon.pos
		var fw := Vector3(cajon.nodo.global_transform.basis.z.x, 0, cajon.nodo.global_transform.basis.z.z).normalized()
		var pp := cp + fw * 1.3
		if m.room_at(pp) < 0:
			pp = cp - fw * 1.3
		_poner(Vector3(pp.x, cp.y + 0.05, pp.z), _yaw_hacia(pp, cp), -0.5)
		await _espera(1.0)
		g.bar_rit.visible = true
		for i in 33:
			g.bar_rit.value = float(i) / 33.0 * 100.0
			await get_tree().process_frame
		g.bar_rit.visible = false
		ZarekRegistro.abrir(m, cajon)
		g.sound_at("cajon_abrir", cp + Vector3(0, 0.6, 0), -4.0)
		await _espera(0.6)
		g._secreto("f7")
		await _espera(4.5)
		g.panel_nota.visible = false
		await _espera(0.5)

# ---------------- parte 2 ----------------
func _parte2() -> void:
	# un objeto de la trampa sobre su velador
	var s: Dictionary = {}
	for so in m.seals:
		if m.inside_house(so.pos):
			s = so
			break
	if s.is_empty():
		s = m.seals[0]
	var sp: Vector3 = s.pos
	var pp := sp + Vector3(1.8, 0.05, 0)
	if m.room_at(pp) < 0:
		pp = sp + Vector3(-1.8, 0.05, 0)
	_poner(pp, _yaw_hacia(pp, sp), -0.35)
	await _espera(1.5)
	g._take_seal(s)
	await _espera(3.5)
	# el pasillo: algo se acerca
	var pas: Dictionary = m._sala_por_nombre("Pasillo principal")
	var rc: Rect2 = pas.rect
	var largo_x := rc.size.x > rc.size.y
	var a := Vector3(rc.position.x + 2.0, float(pas.y) + 0.05, rc.get_center().y) if largo_x else Vector3(rc.get_center().x, float(pas.y) + 0.05, rc.position.y + 2.0)
	var b := Vector3(rc.end.x - 2.0, float(pas.y), rc.get_center().y) if largo_x else Vector3(rc.get_center().x, float(pas.y), rc.end.y - 2.0)
	if a.distance_to(b) > 22.0:
		b = a + (b - a).normalized() * 18.0
	_poner(a, _yaw_hacia(a, b), 0.0)
	g.sound_at("damian_paso", b + Vector3(0, 1, 0), -6.0)
	await _espera(1.2)
	g.sound_at("damian_gruñe", b + Vector3(0, 1.5, 0), -2.0)
	m.flicker_lamp(m.lamps[0], 1.0)
	await _espera(1.5)
	g.message("Está cerca. Lo noto.", 1.8)
	g.elena.global_position = b
	g.elena.visible = true
	g.elena.set_state(ZarekElena.S.WANDER)
	g.elena.path.clear()
	g.elena.look_at(Vector3(a.x, b.y, a.z), Vector3.UP)
	g.set_meta("no_catch", true)
	await _espera(1.2)
	g.elena.set_state(ZarekElena.S.CHASE)
	g.sound_at("damian_rugido", b + Vector3(0, 1.6, 0), 4.0)
	await _espera(1.0)
	# huir: media vuelta y correr
	await _mirar(_yaw_hacia(b, a), 0.0, 0.4)
	await _andar(3.0, true)
	# escondida en un armario: contener la respiración mientras pasa
	var wd: Dictionary = {}
	var mejor := 1e9
	for w in m.wardrobes:
		if String(w.get("tipo", "")) == "cama":
			continue
		var dd: float = (w.pos as Vector3).distance_to(g.player.global_position)
		if dd < mejor and absf((w.pos as Vector3).y - g.player.global_position.y) < 2.0:
			mejor = dd
			wd = w
	if not wd.is_empty():
		g._enter_wardrobe(wd)
		g.elena.vanish(9999.0)
		await _espera(1.5)
		var fuera: Vector3 = wd.pos
		var mira := -Vector3(sin(float(wd.yaw)), 0, cos(float(wd.yaw)))
		g.elena.global_position = fuera + mira * 5.0
		g.elena.visible = true
		g.elena.set_state(ZarekElena.S.SEARCH, 30.0)
		g.elena.path.assign(m.path(g.elena.global_position, fuera + mira * 1.6))
		g.sound_at("damian_olfatea", g.elena.global_position + Vector3(0, 1.6, 0), 0.0)
		g.barra_aliento.visible = true
		for i in 150:
			g.aliento = maxf(0.15, g.aliento - 1.0 / 150.0 * 0.8)
			g.barra_aliento.value = g.aliento
			await get_tree().process_frame
		g.message("Se quedó mirando… y se fue.", 2.5)
		g.elena.set_state(ZarekElena.S.WANDER)
		g.elena.path.assign(m.path(g.elena.global_position, g.elena.global_position + mira * 10.0))
		await _espera(3.0)
		g.barra_aliento.visible = false
		g._exit_wardrobe(true)
		await _espera(1.0)

# ---------------- parte 3 ----------------
func _parte3() -> void:
	var v: Vector3 = m.cell_to_world("baja", 9.0, 11.4)
	_poner(v, PI, 0.0)
	g.defensa.arma = "cuchillo"
	g.message("Cojo el cuchillo de la cocina. Si me atrapa, puedo defenderme… una vez.", 3.0)
	await _espera(2.5)
	var e: ZarekElena = g.elena
	var delante: Vector3 = v - Vector3(sin(PI), 0, cos(PI)) * 6.0
	e.global_position = delante
	e.visible = true
	e.set_state(ZarekElena.S.CHASE)
	g.sound_at("damian_rugido", delante + Vector3(0, 1.6, 0), 4.0)
	# espera a que la atrape y machaca USAR en el forcejeo
	for k in 300:
		if g.state == "forcejeo":
			break
		await get_tree().process_frame
	for k in 90:
		if g.state != "forcejeo":
			break
		if k % 5 == 0:
			Input.action_press("usar")
		elif k % 5 == 2:
			Input.action_release("usar")
		await get_tree().process_frame
	Input.action_release("usar")
	await _espera(4.0)
	# sin arma: el hachazo
	e.vanish(9999.0)
	await _espera(1.0)
	var detras: Vector3 = g.player.global_position + g.player.look_dir() * -4.0
	if m.room_at(detras) < 0:
		detras = g.player.global_position + g.player.look_dir() * 4.0
	e.global_position = detras
	e.visible = true
	e.can_catch = true
	e.set_state(ZarekElena.S.CHASE)
	g.sound_at("damian_paso", detras + Vector3(0, 1, 0), 2.0)
	await _espera(0.6)
	await _mirar(_yaw_hacia(g.player.global_position, detras), 0.05, 0.5)
	for k in 240:
		if g.state == "atrapado":
			break
		await get_tree().process_frame
	await _espera(2.6)
