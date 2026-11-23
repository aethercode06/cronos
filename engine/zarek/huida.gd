class_name ZarekHuida
extends Node
## La noche de Sofía: sobrevivir sola y salir de la finca Varela.
##
## Historia: Sofía toma un atajo de noche por el bosque de Valdeoscuro; dos ruedas revientan con los clavos que
## siembra Damián y le roban la rueda de repuesto y el gato. Sin cobertura, va a pedir ayuda a la única casa con luz
## (el cebo) y recibe un golpe en la nuca. El juego empieza cuando despierta encadenada por el tobillo en el cuarto de
## huéspedes, cerrado por fuera (la «celda»): primero hay que soltarse y salir del cuarto; el portón de la finca ya
## está cerrado con cadena. Damián caza para alimentar a su madre, Elena, poseída por
## Zarek desde 1987 y encadenada en la capilla del sótano.
##
## La madre manda en la casa aunque esté encadenada (poltergeist): lanza objetos, cierra y abre puertas, quita
## tablones, apaga luces y la linterna, cambia de sitio lo que buscas, toca la caja de música. Su FURIA sube con los
## errores (ruido en el sótano, correr, romper cosas, que Damián te atrape, gritar de miedo, entrar en su capilla) y
## baja si eres sigilosa; al 100 % rompe las cadenas y se convierte en la segunda cazadora (rápida, sin forcejeo,
## solo la luz la frena). Se la puede quemar en su capilla con gasolina y una bengala.
##
## Rejugable: tres salidas (la camioneta de Damián, tu coche, escalar el muro) y cada noche una está bloqueada; los
## objetos que se necesitan dependen de las salidas abiertas, y el poltergeist cambia cosas de sitio.

const SALIDAS := ["camioneta", "coche", "muro"]
const NOMBRE_SALIDA := {"camioneta": "la camioneta de Damián (en la cochera)", "coche": "tu coche (al otro lado del portón)",
	"muro": "el muro de piedra (cuerda y garfio)"}
const BLOQUEO := {
	"camioneta": "Le ha arrancado los cables del motor a hachazos. Esta camioneta no arrancará esta noche.",
	"coche": "Ha rajado las cuatro ruedas de mi coche. Por aquí no saldré.",
	"muro": "Ha clavado alambre de espino en todo lo alto del muro. Imposible trepar."}
## Objetos de la casa que pide cada salida (las llaves de la camioneta se recogen en el cuarto de Damián).
## Las tres cuestan lo mismo (3 pasos), cada una a su manera; el bot vio que con una sola cuerda se escapaba en 1 minuto.
const PIDE := {"camioneta": ["llave", "gasolina", "bateria"], "coche": ["cizalla", "rueda", "gato"], "muro": ["cuerda", "garfio"]}
const CORTAR := 3.0
const ROCIAR := 2.0
const RUEDA := 5.0
const TREPAR := 6.0
const ARRANCAR := 4.0

var j: Node  # ZarekJuego
var m: ZarekMansion
var salida_cerrada := ""
var tiene := {}               # objetos de la noche cogidos (y "llaves_camioneta")
var gasolina_usada := false
var porton_abierto := false
var porton_cerrado := false   # se cierra al entrar en la casa

# la madre
var madre: ZarekElena
var madre_suelta := false
var madre_muerta := false
var furia := 0.0              # 0-100: a 100 rompe las cadenas
var capilla_rociada := false
var capilla_pos := Vector3.INF
var _t_grito := 0.0
var _t_poltergeist := 45.0
var _t_luz_madre := 0.0
var _t_aviso := 0.0
var _silencio_ruido := 0.0    # el ruido de lo que tira ella no la enfada a ella misma
var _aviso_furia := 0
var movidos := 0
## La madre te ha mordido (si escapas con ella viva, el final es «Hambre»; el fuego lo cura).
var mordida := false
## Donde Damián cuelga a quien atrapa: el matadero del sótano, junto a la capilla.
var matadero_pos := Vector3.INF
var fisicos: Array = []

# acciones que se mantienen pulsadas
var hold_kind := ""
var hold_t := 0.0

var cochera_pos := Vector3.INF
var muro_pos := Vector3.INF

# la celda del principio: el cuarto de huéspedes
const SALA_CELDA := "Cuarto de huéspedes"
const CADENA := 1.7          # lo que da de sí la cadena del tobillo
const ARGOLLA := 3.0
const CERRADURA := 4.0
var en_celda := false
var encadenada := false
var tiene_clavo := false
var ancla := Vector3.INF
var clavo_pos := Vector3.INF
var celda_puertas: Array = []
var _clavo: Node3D
var _cadena_vis: Node3D
var _t_celda := 0.0
var _susto_puerta := false

## La salida bloqueada de la noche (con semilla 0, la de las pruebas, siempre el coche).
static func salida_bloqueada(seed: int) -> String:
	if seed == 0:
		return "coche"
	# hash de la semilla: reparto parejo entre las tres (con el generador sembrado salía casi siempre la misma)
	return SALIDAS[absi(hash(str(seed) + "salida")) % 3]

## Objetos de la casa que hacen falta esta noche.
static func objetos(seed: int) -> Array:
	var c := salida_bloqueada(seed)
	var o := []
	for s in SALIDAS:
		if s != c:
			o.append_array(PIDE[s])
	return o

func preparar(mansion: ZarekMansion) -> void:
	m = mansion
	salida_cerrada = salida_bloqueada(m.partida_seed)
	var cap := m._sala_por_nombre("Capilla de la madre")
	if not cap.is_empty():
		var rc: Rect2 = cap.rect
		capilla_pos = Vector3(rc.get_center().x, float(cap.y), rc.position.y + rc.size.y - 6.0)
	cochera_pos = m.cell_to_world("exterior", 61.0, 41.5)
	var mt := m._sala_por_nombre("Galería de servicio")
	if not mt.is_empty():
		ZarekTerror._rng.seed = m.partida_seed + 99
		matadero_pos = ZarekTerror._sitio_libre(m, mt, 0.5)
		if matadero_pos == Vector3.INF:
			var rc2: Rect2 = mt.rect
			matadero_pos = Vector3(rc2.get_center().x, float(mt.y), rc2.get_center().y)
		matadero_pos += Vector3(0, 0.05, 0)
	if matadero_pos == Vector3.INF:
		matadero_pos = m.start_pos
	# un punto del muro oeste, entre el cementerio y el huerto, con la hiedra más espesa
	muro_pos = m.cell_to_world("exterior", 20.0, 50.0) + Vector3(0.9, 0, 0)
	_marca_muro()
	_preparar_celda()
	for n in m.find_children("*", "RigidBody3D", true, false):
		if n is ZarekObjetoFisico and (n as RigidBody3D).mass < 9.0:
			fisicos.append(n)

## Una cuerda vieja de hiedra y piedras caídas donde se puede trepar (o el alambre de espino, si está bloqueado).
func _marca_muro() -> void:
	var n := Node3D.new()
	n.position = muro_pos
	m.add_child(n)
	var piedra: Material = m._mat.piedra
	for k in 4:
		var b := m.box(Vector3(0.5, 0.3, 0.4), Vector3(0.3 + k * 0.25, 0.15, -1.2 + k * 0.8), piedra, false, n, false)
		b.rotation.y = k * 0.7
	if salida_cerrada == "muro":
		for k in 12:
			var e := m.cyl(0.006, 0.006, 1.3, Vector3(-0.9, 2.5, -6.0 + k), m._mat.metal, n, 4)
			e.rotation.x = PI * 0.5
			e.rotation.z = 0.3 * (k % 2 * 2 - 1)

## Que todo objeto de la noche se pueda alcanzar andando (el bot encontró objetos encerrados entre los trasteros
## del ático): si el camino no llega, se mueve al punto alcanzable más cercano de la misma sala.
var _verificados := false
func _verificar_objetos() -> void:
	_verificados = true
	var desde: Vector3 = j.respawn_pos
	var movidos_v := 0
	for s in m.seals:
		var sp: Vector3 = s.pos
		var p := m.path(desde, sp)
		var fin: Vector3 = p[p.size() - 1] if p.size() > 0 else desde
		if fin.distance_to(sp) <= 1.4:
			continue
		# primero, el punto alcanzable más cercano si es de la misma sala; si no, otro punto de esa sala que sí se
		# alcance; si tampoco, se queda donde está (nunca a una sala donde no tiene sentido)
		var nuevo := Vector3.INF
		var rid := m.room_at(sp)
		if m.room_at(fin) == rid:
			nuevo = fin
		elif rid >= 0:
			var rc: Rect2 = m.rooms[rid].rect
			for k in 30:
				var q := Vector3(randf_range(rc.position.x + 0.6, rc.end.x - 0.6), sp.y, randf_range(rc.position.y + 0.6, rc.end.y - 0.6))
				var p2 := m.path(desde, q)
				if p2.size() > 0 and p2[p2.size() - 1].distance_to(q) < 1.0:
					nuevo = p2[p2.size() - 1]
					break
		if nuevo == Vector3.INF:
			continue
		s.pos = nuevo
		(s.node as Node3D).global_position = nuevo + Vector3(0, 0.02, 0)
		movidos_v += 1
	if movidos_v > 0:
		print("ZAREK objetos inalcanzables recolocados: %d" % movidos_v)

# ---------------- la celda del principio ----------------
## Colchón en el suelo, una argolla en la pared con la cadena al tobillo y un clavo suelto al alcance de la mano.
func _preparar_celda() -> void:
	var r := m._sala_por_nombre(SALA_CELDA)
	if r.is_empty():
		return
	ZarekTerror._rng.seed = 4711
	ancla = ZarekTerror._sitio_libre(m, r, 1.2)
	if ancla == Vector3.INF:
		var rc: Rect2 = r.rect
		ancla = Vector3(rc.get_center().x, float(r.y), rc.get_center().y)
	var rc2: Rect2 = r.rect
	var n := Node3D.new()
	n.position = ancla
	m._house.add_child(n)
	# colchón manchado
	m.box(Vector3(0.9, 0.16, 1.9), Vector3(0, 0.08, 0), m._plain(Color(0.42, 0.36, 0.28), 0.95), false, n, false)
	m.box(Vector3(0.5, 0.1, 0.35), Vector3(0, 0.2, -0.7), m._plain(Color(0.5, 0.45, 0.38), 0.95), false, n, false)
	ZarekGore._charco(m, ancla + Vector3(0.25, 0, 0.2), 0.5)
	# argolla en el suelo y la cadena hasta el colchón
	m.cyl(0.08, 0.1, 0.05, Vector3(0.7, 0.025, 0.8), m._mat.hierro, n, 10)
	_cadena_vis = Node3D.new()
	n.add_child(_cadena_vis)
	for k in 9:
		var e := m.cyl(0.014, 0.014, 0.07, Vector3(0.7 - k * 0.075, 0.03, 0.8 - k * 0.06), m._mat.hierro, _cadena_vis, 5)
		e.rotation = Vector3(PI * 0.5, 0.0, (k % 2) * PI * 0.5)
	# el clavo, en el suelo junto al rodapié
	clavo_pos = ancla + Vector3(-1.1, 0.0, 0.6)
	if not rc2.has_point(Vector2(clavo_pos.x, clavo_pos.z)):
		clavo_pos = ancla + Vector3(1.0, 0.0, -0.6)
	_clavo = Node3D.new()
	_clavo.position = clavo_pos
	m._house.add_child(_clavo)
	var cl := m.cyl(0.004, 0.004, 0.11, Vector3(0, 0.006, 0), m._mat.hierro, _clavo, 5)
	cl.rotation.z = PI * 0.5
	m.cyl(0.009, 0.009, 0.004, Vector3(0.055, 0.006, 0), m._mat.hierro, _clavo, 6).rotation.z = PI * 0.5
	for d in m.doors:
		if int(r.id) in (d.get("ids", []) as Array):
			celda_puertas.append(d)

## El primer susto, con guion: mientras sigues encerrada, Damián sube, se para delante de la puerta, prueba el
## pomo, respira… y se va. Así sabes desde el primer minuto quién hay en la casa y que no debe oírte.
func _pasa_por_la_puerta() -> void:
	if celda_puertas.is_empty():
		return
	var d: Dictionary = celda_puertas[0]
	var dp: Vector3 = d.pos
	var fuera := dp + (dp - ancla).normalized() * 2.5
	fuera.y = dp.y
	var desde := fuera + (dp - ancla).normalized().cross(Vector3.UP) * 9.0
	j.message("Pasos. Pesados. Suben por la escalera…", 3.0)
	for k in 7:
		if not en_celda:
			return
		j.sound_at("damian_paso", desde.lerp(fuera, k / 6.0) + Vector3(0, 0.1, 0), -2.0 + k)
		await get_tree().create_timer(0.75).timeout
	j.sound_at("damian_resp", fuera + Vector3(0, 1.7, 0), 2.0)
	await get_tree().create_timer(1.6).timeout
	j.sound_at("pomo_cerrado", dp + Vector3(0, 1.0, 0), 4.0)
	j.player.shake(2.0)
	j.message("Se ha parado delante de la puerta. Ha probado el pomo.\nNo respires.", 3.5)
	j.sanity = maxf(0.0, j.sanity - 10.0)
	await get_tree().create_timer(3.0).timeout
	j.sound_at("damian_olfatea", fuera + Vector3(0, 1.6, 0), 0.0)
	await get_tree().create_timer(2.5).timeout
	for k in 6:
		j.sound_at("damian_paso", fuera.lerp(desde, k / 5.0) + Vector3(0, 0.1, 0), 2.0 - k)
		await get_tree().create_timer(0.8).timeout
	if en_celda:
		j.message("Se aleja. Ahora. Tengo que soltarme ahora.", 2.5)

## Empieza la partida aquí: encadenada y con las puertas del cuarto cerradas por fuera.
func empezar_celda() -> void:
	if ancla == Vector3.INF:
		return
	en_celda = true
	encadenada = true
	for d in celda_puertas:
		m.set_door(d, false, true)
		d.locked = true
		d["celda"] = true

# ---------------- el portón ----------------
## Al entrar en la casa: una cadena y un candado cierran el portón (las hojas giran y ya no se puede pasar).
func cerrar_porton() -> void:
	if porton_cerrado or m.porton_hojas.is_empty():
		return
	porton_cerrado = true
	for h in m.porton_hojas:
		var tw := (h as Node3D).create_tween()
		tw.tween_property(h, "rotation:y", 0.0, 1.4).set_trans(Tween.TRANS_QUAD)
	_porton_bloqueo = m.box(Vector3(m.porton_ancho, 3.0, 0.4), m.porton_pos + Vector3(0, 1.5, 0), m._mat.metal, true, m)
	_porton_bloqueo.visible = false
	_porton_cadena = Node3D.new()
	_porton_cadena.position = m.porton_pos
	m.add_child(_porton_cadena)
	for k in 10:
		var e := m.cyl(0.015, 0.015, 0.07, Vector3(-0.3 + k * 0.065, 1.35 + sin(k * 0.6) * 0.04, 0.06), m._mat.hierro, _porton_cadena, 5)
		e.rotation.z = PI * 0.5 + (k % 2) * 0.6
	if m._prop("candado_viejo", Vector3(0.0, 1.22, 0.1), 0.0, 2.4, false, _porton_cadena) == null:
		m.box(Vector3(0.1, 0.12, 0.05), Vector3(0, 1.22, 0.1), m._mat.laton_viejo, false, _porton_cadena)
	ZarekSonido.en(m, "cadenas", m.porton_pos + Vector3(0, 1.3, 0), 2.0, 120.0)
var _porton_bloqueo: MeshInstance3D
var _porton_cadena: Node3D

func abrir_porton() -> void:
	porton_abierto = true
	if _porton_cadena:
		_porton_cadena.queue_free()
	if _porton_bloqueo:
		_porton_bloqueo.queue_free()
	for h in m.porton_hojas:
		var tw := (h as Node3D).create_tween()
		tw.tween_property(h, "rotation:y", float((h as Node3D).get_meta("abierta", 1.9)), 1.6)
	ZarekSonido.en(m, "puerta_crujido", m.porton_pos + Vector3(0, 1.3, 0), 4.0, 60.0, 0.6)

# ---------------- cada fotograma ----------------
func tick(delta: float) -> void:
	if j == null or m == null:
		return
	if not _verificados and m.nav_ready:
		_verificar_objetos()
	var pp: Vector3 = j.player.global_position
	_silencio_ruido = maxf(0.0, _silencio_ruido - delta)
	if en_celda:
		_t_celda += delta
		if not _susto_puerta and _t_celda > 16.0 and j.state == "juego":
			_susto_puerta = true
			_pasa_por_la_puerta()
	if encadenada:
		var off := Vector2(pp.x - ancla.x, pp.z - ancla.z)
		if off.length() > CADENA:
			var lim := Vector2(ancla.x, ancla.z) + off.normalized() * CADENA
			j.player.global_position = Vector3(lim.x, pp.y, lim.y)
			j.player.velocity = Vector3.ZERO
			if randf() < 0.05:
				j.sound_at("cadenas", ancla + Vector3(0, 0.2, 0), -12.0)
	_t_grito -= delta
	_t_aviso -= delta
	if not madre_suelta and not madre_muerta:
		_furia_tick(delta, pp)
		if j.entered:
			_t_poltergeist -= delta
			if _t_poltergeist <= 0.0:
				_t_poltergeist = lerpf(60.0, 14.0, furia / 100.0) * randf_range(0.7, 1.3)
				poltergeist()
	elif madre_suelta and not madre_muerta and is_instance_valid(madre):
		_madre_tick(delta, pp)
	if _carrera and not (j.elena.state in [ZarekElena.S.CHASE, ZarekElena.S.INVESTIGATE, ZarekElena.S.SEARCH]):
		_carrera = false
		# suelta sigue moviendo cosas, más a menudo
		_t_poltergeist -= delta
		if _t_poltergeist <= 0.0:
			_t_poltergeist = randf_range(16.0, 30.0)
			poltergeist()
	_hold_tick(delta, pp)

func _furia_tick(delta: float, pp: Vector3) -> void:
	var cap := m._sala_por_nombre("Capilla de la madre")
	var en_capilla: bool = not cap.is_empty() and m.room_at(pp) == int(cap.id)
	if en_capilla:
		# en su capilla te ve: con la linterna encendida, mucho más
		subir_furia(delta * (4.0 if j.flash_on and j.battery > 0.0 else 1.2), "")
	elif m.level_of(pp.y + 0.5) == -1:
		subir_furia(delta * 0.15, "")
	elif j.hidden_in.is_empty() and not j.player.running:
		furia = maxf(0.0, furia - delta * 0.3)
	if furia >= 100.0:
		soltar_madre()

## Un error de Sofía enfurece a la madre. Avisa al cruzar el 50 % y el 80 %.
## Solo para la prueba automática: la furia no cambia (para probar cada cosa por separado).
var congelar_furia := false
func subir_furia(cuanto: float, motivo: String) -> void:
	if madre_suelta or madre_muerta or congelar_furia:
		return
	var antes := furia
	furia = clampf(furia + cuanto, 0.0, 100.0)
	if furia >= 100.0:
		soltar_madre()
		return
	if motivo != "" and cuanto >= 8.0:
		j.message(motivo, 2.8)
	if antes < 50.0 and furia >= 50.0 and _aviso_furia < 1:
		_aviso_furia = 1
		ZarekSonido.en(m, "cadenas", capilla_pos + Vector3(0, 1.0, 0), 4.0, 70.0)
		j.message("Abajo, las cadenas tiemblan. Está furiosa.\n(Furia de la madre: %d %%)" % int(furia), 3.5)
		j._consejo("furia", "La FURIA de la madre sube con tus errores: ruido en el sótano, correr, romper cosas, que Damián te atrape, gritar de miedo o entrar en su capilla. Baja si eres sigilosa. Al 100 % rompe las cadenas. Mírala en el DIARIO.")
	elif antes < 80.0 and furia >= 80.0 and _aviso_furia < 2:
		_aviso_furia = 2
		ZarekSonido.en(m, "grito", capilla_pos + Vector3(0, 1.5, 0), 4.0, 90.0, 0.7)
		j.player.shake(6.0)
		j.message("Un alarido hace temblar la casa entera.\nLas cadenas están a punto de ceder. (Furia: %d %%)" % int(furia), 3.5)

## Ruido de Sofía: en el sótano la enfurece (y si es fuerte, grita y Damián acude); fuera, un poco.
func ruido(pos: Vector3, fuerza: float) -> void:
	# antes de empezar (al cargar, los objetos caen a su sitio y algunos se rompen) no cuenta nada
	if m == null or j == null or not (j.state in ["juego", "escondido"]):
		return
	if madre_suelta and is_instance_valid(madre) and not madre_muerta:
		madre.hear(pos, fuerza * 1.3)
		return
	if madre_muerta or _silencio_ruido > 0.0:
		return
	if fuerza >= 13.0:
		subir_furia(5.0, "")  # algo roto, un portazo, un disparo: lo oye toda la casa
	if m.level_of(pos.y + 0.5) != -1:
		subir_furia(fuerza * 0.025, "")
		return
	var d := pos.distance_to(capilla_pos) if capilla_pos != Vector3.INF else 20.0
	subir_furia(fuerza * 0.12 * clampf(1.6 - d / 25.0, 0.3, 1.6), "")
	if fuerza >= 7.0 and _t_grito <= 0.0:
		_t_grito = 25.0
		grito(pos)

## La madre grita: Damián acude al sitio.
func grito(pos: Vector3) -> void:
	var desde := capilla_pos if capilla_pos != Vector3.INF else pos
	ZarekSonido.en(m, "grito", desde + Vector3(0, 1.5, 0), 6.0, 60.0, 0.7)
	j.player.shake(5.0)
	if j.elena.state == ZarekElena.S.DORMANT:
		j.elena.wake_far()
	j.elena.last_seen = pos
	j.elena.set_state(ZarekElena.S.INVESTIGATE, 14.0)
	if _t_aviso <= 0.0:
		_t_aviso = 60.0
		j.message("Un alarido sube del sótano.\nElla me ha oído… y Damián sabe dónde estoy.", 3.5)

# ---------------- poltergeist ----------------
## La casa es suya: algo pasa cerca de ti. Cuanta más furia, más fuerte.
func poltergeist() -> void:
	var pp: Vector3 = j.player.global_position
	if not m.inside_house(pp) or j.state != "juego":
		return
	var f := furia / 100.0 if not madre_suelta else 1.0
	var opciones := ["lanzar", "lanzar", "puerta", "luces", "linterna", "musica", "latido"]
	if f > 0.35:
		opciones.append_array(["mover", "tablones", "puerta"])
	opciones.shuffle()
	for o in opciones:
		if call("_p_" + o, pp, f):
			set_meta("polt", int(get_meta("polt", 0)) + 1)
			return

func _p_lanzar(pp: Vector3, f: float) -> bool:
	var cand: Array = []
	for b in fisicos:
		if not is_instance_valid(b):
			continue
		var rb := b as RigidBody3D
		var d := rb.global_position.distance_to(pp)
		if d > 2.0 and d < 9.0 and absf(rb.global_position.y - pp.y) < 2.5 and j._in_view(rb.global_position):
			cand.append(rb)
	if cand.is_empty():
		return false
	var rb: RigidBody3D = cand[randi() % cand.size()]
	_silencio_ruido = 3.0
	rb.sleeping = false
	var hacia := (pp + Vector3(randf_range(-1.5, 1.5), 1.0, randf_range(-1.5, 1.5)) - rb.global_position).normalized()
	rb.apply_central_impulse((hacia * lerpf(4.0, 9.0, f) + Vector3(0, 2.5, 0)) * rb.mass)
	rb.apply_torque_impulse(Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * rb.mass * 2.0)
	j.sanity = maxf(0.0, j.sanity - 6.0)
	j.player.shake(3.0)
	j.message(["¡Algo ha salido volando hacia mí!", "Nadie lo ha tocado. Se ha movido solo.", "Lo ha tirado ella. Desde el sótano."][randi() % 3], 2.2)
	# el golpe se oye: Damián viene a mirar
	get_tree().create_timer(0.6).timeout.connect(func(): if is_instance_valid(rb): j.elena.hear(rb.global_position, 14.0))
	return true

func _p_puerta(pp: Vector3, _f: float) -> bool:
	var cerca: Array = []
	for d in m.doors:
		var dp: Vector3 = d.pos
		if dp.distance_to(pp) < 10.0 and absf(dp.y - pp.y) < 2.5 and not d.locked and float(d.get("barricada", 0.0)) <= 0.0:
			cerca.append(d)
	if cerca.is_empty():
		return false
	var d: Dictionary = cerca[randi() % cerca.size()]
	m.set_door(d, not d.open, true)
	d.snd.stream = ZarekSonido.uno("portazo" if not d.open else "puerta_crujido")
	d.snd.play()
	j.player.shake(5.0 if not d.open else 1.5)
	j.sanity = maxf(0.0, j.sanity - 4.0)
	_silencio_ruido = 2.0
	if not d.open:
		j.elena.hear(d.pos, 12.0)
	return true

func _p_tablones(pp: Vector3, _f: float) -> bool:
	for d in m.doors:
		if float(d.get("barricada", 0.0)) > 0.0 and (d.pos as Vector3).distance_to(pp) < 25.0:
			m.desatrancar(d)
			m.set_door(d, true, true)
			d.snd.stream = ZarekSonido.uno("madera_rota" if ZarekSonido.hay("madera_rota") else "portazo")
			d.snd.play()
			j.message("Un crujido de madera… Ha arrancado los tablones de una puerta.", 3.0)
			return true
	return false

func _p_luces(pp: Vector3, _f: float) -> bool:
	var rid := m.room_at(pp)
	if rid < 0:
		return false
	var hubo := false
	for l in m.lamps:
		if l.on and m.room_at(l.pos) == rid:
			m.flicker_lamp(l, 1.2)
			var ll: Dictionary = l
			get_tree().create_timer(1.2).timeout.connect(func(): m.set_lamp(ll, false))
			hubo = true
	if hubo:
		j.message("Las luces de la sala se apagan una a una.", 2.2)
		j.sanity = maxf(0.0, j.sanity - 5.0)
	return hubo

func _p_linterna(_pp: Vector3, f: float) -> bool:
	if not j.flash_on or j.battery <= 0.0:
		return false
	j.flash_on = false
	j._click()
	j.message("La linterna se apaga sola.", 1.8)
	j.sanity = maxf(0.0, j.sanity - 4.0)
	get_tree().create_timer(lerpf(1.2, 3.0, f)).timeout.connect(func():
		if j.state == "juego" and j.hidden_in.is_empty():
			j.flash_on = true
			j._click())
	return true

func _p_musica(pp: Vector3, _f: float) -> bool:
	if j.snd_box and not j.snd_box.playing and m.musicbox_pos.distance_to(pp) < 35.0:
		j.snd_box.play()
		j.message("Una caja de música ha empezado a sonar sola.", 2.5)
		return true
	j.sound_at("piano", pp + Vector3(randf_range(-8, 8), 0.5, randf_range(-8, 8)), -4.0)
	return true

func _p_latido(pp: Vector3, _f: float) -> bool:
	ZarekSonido.en(m, "latido", pp + Vector3(0, -1.5, 0), -4.0, 12.0, 0.8)
	j.sanity = maxf(0.0, j.sanity - 4.0)
	j.message(["Bajo el suelo, algo late. Como un corazón enorme.", "Oigo una nana… dentro de mi cabeza.", "Me está mirando. No sé desde dónde, pero me mira."][randi() % 3], 2.6)
	return true

## Cambia de sitio un objeto que necesitas (y que ya habías visto): «no está donde lo vi».
func _p_mover(pp: Vector3, _f: float) -> bool:
	if movidos >= 2:
		return false
	for s in m.seals:
		if s.taken or String(s.tipo) == "rueda" or (s.pos as Vector3).distance_to(pp) < 14.0:
			continue
		# a otra sala donde también tenga sentido (de su lista), lejos de ti y alcanzable andando
		var nueva := Vector3.INF
		var salas: Array = (ZarekMansion.SITIOS_POR_OBJETO.get(String(s.tipo), []) as Array).duplicate()
		salas.shuffle()
		for nombre in salas:
			var r := m._sala_por_nombre(nombre)
			if r.is_empty() or int(r.id) == m.room_at(s.pos):
				continue
			var q := ZarekTerror._sitio_libre(m, r, 0.6)
			if q == Vector3.INF or q.distance_to(pp) < 10.0:
				continue
			var cam := m.path(j.respawn_pos, q)
			if cam.size() > 0 and cam[cam.size() - 1].distance_to(q) < 1.4:
				nueva = q
				break
		if nueva == Vector3.INF:
			continue
		var visto: bool = s.get("visto", false) or s.get("revelado", false)
		s.pos = nueva
		(s.node as Node3D).global_position = nueva + Vector3(0, 0.02, 0)
		s.erase("visto")
		s.erase("revelado")
		movidos += 1
		if visto:
			j.message("Algo ha cambiado en la casa… %s ya no está donde lo vi." % ZarekMansion.NOMBRE_OBJETO.get(String(s.tipo), "un objeto"), 3.5)
		return true
	return false

# ---------------- la madre suelta ----------------
## Rompe las cadenas: sale de la capilla, corta la luz y empieza a cazar.
func soltar_madre() -> void:
	if madre_suelta or madre_muerta:
		return
	madre_suelta = true
	furia = 100.0
	madre = ZarekElena.new()
	madre.forzar_elena = true
	madre.teme_luz = true
	madre.name = "Madre"
	j.add_child(madre)
	madre.setup(m, j.player)
	madre.rapidez = [1.05, 1.18, 1.3][j.dif]
	madre.aggro = 3
	madre.caught.connect(j._on_caught_madre)
	madre.global_position = capilla_pos if capilla_pos != Vector3.INF else m.random_floor()
	madre.set_state(ZarekElena.S.WANDER)
	ZarekSonido.en(m, "cadenas", madre.global_position + Vector3(0, 1.0, 0), 6.0, 40.0)
	ZarekSonido.en(m, "grito", madre.global_position + Vector3(0, 1.5, 0), 8.0, 80.0, 0.6)
	j.player.shake(16.0)
	Aether.flash(Color(0.5, 0, 0), 0.5)
	j.message("Un estruendo de cadenas en el sótano.\nLA MADRE SE HA SOLTADO. Solo la luz la detiene.", 5.0)
	j._corte_luz(2.5)
	j._consejo("madre_suelta", "La madre es más rápida que Damián, anda a oscuras y si te toca pierdes una vida sin poder forcejear. Su debilidad es la luz: enfócala con la linterna, quédate en salas iluminadas, lánzale bengalas y devuelve la luz en el cuadro eléctrico.")

func _madre_tick(delta: float, pp: Vector3) -> void:
	madre.player_hidden = j.elena.player_hidden
	madre.flashlight_on = j.flash_on
	# la linterna la frena: si la enfocas de cerca, chilla y retrocede
	_t_luz_madre -= delta
	if madre.visible and madre.state != ZarekElena.S.FLEE and _t_luz_madre <= 0.0 and j.flash_on and j.battery > 0.0 and j.hidden_in.is_empty():
		var cam: Camera3D = j.player.camera
		var to: Vector3 = madre.global_position + Vector3(0, 1.3, 0) - cam.global_position
		var mira: Vector3 = j.player.look_dir()
		if to.length() < 9.0 and to.normalized().dot(mira) > 0.93 and j._in_view(madre.global_position + Vector3(0, 1.3, 0)):
			_t_luz_madre = 1.5
			madre.repel(pp)
			ZarekSonido.en(m, "grito", madre.global_position + Vector3(0, 1.5, 0), 2.0, 30.0, 1.3)
			j.battery = maxf(0.0, j.battery - 2.0)
	# Damián le tiene miedo: si se cruzan, él se aparta
	if j.elena.visible and j.elena.state != ZarekElena.S.DORMANT and madre.visible and j.elena.global_position.distance_to(madre.global_position) < 5.0:
		ZarekSonido.en(m, "damian_gruñe", j.elena.global_position + Vector3(0, 1.6, 0), -2.0, 25.0, 0.8)
		j.elena.vanish(15.0)

## Fuego en la capilla: rociada de gasolina y con la madre dentro (encadenada o atraída), la bengala la quema.
func bengala(pp: Vector3) -> bool:
	if madre_muerta or not capilla_rociada:
		return false
	var cap := m._sala_por_nombre("Capilla de la madre")
	if cap.is_empty() or m.room_at(pp) != int(cap.id):
		return false
	var dentro := not madre_suelta or (is_instance_valid(madre) and m.room_at(madre.global_position) == int(cap.id))
	if not dentro:
		j.message("La capilla está empapada de gasolina… pero ella no está dentro.\nTengo que atraerla hasta aquí.", 3.0)
		return true
	_quemar(cap)
	return true

func _quemar(cap: Dictionary) -> void:
	madre_muerta = true
	var rc: Rect2 = cap.rect
	var c := Vector3(rc.get_center().x, float(cap.y), rc.get_center().y)
	for k in 6:
		var fl := OmniLight3D.new()
		fl.light_color = Color(1.0, 0.45, 0.15)
		fl.light_energy = 3.0
		fl.omni_range = 9.0
		fl.position = c + Vector3(randf_range(-6, 6), 1.0, randf_range(-5, 5))
		fl.set_meta("vela", true)
		fl.set_meta("e", 3.0)
		m._house.add_child(fl)
		m.fires.append(fl)
	ZarekSonido.en(m, "grito", capilla_pos + Vector3(0, 1.5, 0), 10.0, 90.0, 0.55)
	j.player.shake(20.0)
	Aether.flash(Color(1.0, 0.5, 0.1), 0.8)
	if is_instance_valid(madre):
		madre.can_catch = false
		madre.set_state(ZarekElena.S.FLEE, 2.0)
		var mm := madre
		get_tree().create_timer(2.0).timeout.connect(func(): if is_instance_valid(mm): mm.queue_free())
	j.message("¡La capilla arde! Ella grita… y bajo la casa, el latido se para.\nZarek ha muerto con ella. Ahora Damián no tiene nada que perder.", 5.5)
	j.elena.aggro += 2
	j.elena.wake_far()
	j.elena.hear(j.player.global_position, 999.0)

## Al leer una nota, a veces aparece un papelito de Damián que dice dónde guarda algo que necesitas (leer sirve).
func pista_de_nota() -> String:
	if randf() > 0.6:
		return ""
	var cand: Array = []
	for s in m.seals:
		if not s.taken and not s.get("visto", false) and not s.get("revelado", false):
			cand.append(s)
	if cand.is_empty():
		return ""
	var s: Dictionary = cand[randi() % cand.size()]
	s["revelado"] = true
	return "Entre las hojas hay un papelito con la letra de Damián: «%s → %s». (Apuntado en el DIARIO)" % [
		String(ZarekMansion.NOMBRE_OBJETO.get(String(s.tipo), "eso")).get_slice(" ", 1), m.room_name(s.pos)]

# ---------------- objetivos al alcance ----------------
## Lo que se puede hacer aquí (para la indicación en pantalla y USAR).
func objetivo(pp: Vector3) -> Dictionary:
	if encadenada:
		if not tiene_clavo and Vector2(pp.x - clavo_pos.x, pp.z - clavo_pos.z).length() < 1.4:
			return {"kind": "celda", "que": "clavo", "text": "USAR: coger el clavo del suelo"}
		if tiene_clavo:
			return {"kind": "hold", "que": "argolla", "text": "MANTÉN USAR: forzar el candado de la argolla con el clavo"}
		return {"kind": "nada", "text": "Una cadena del tobillo a una argolla del suelo. El candado es viejo… si tuviera algo fino y duro."}
	if en_celda:
		for d in celda_puertas:
			if (d.pos as Vector3).distance_to(pp) < 2.0:
				return {"kind": "hold", "que": "cerradura", "text": "MANTÉN USAR: forzar la cerradura con el clavo (hace ruido)"}
	if not madre_muerta and not capilla_rociada and tiene.get("gasolina", false) and not gasolina_usada and capilla_pos != Vector3.INF \
			and pp.distance_to(capilla_pos) < 3.5:
		return {"kind": "hold", "que": "rociar", "text": "MANTÉN USAR: rociar la capilla con gasolina (no podré usarla en la camioneta)"}
	# el portón (camino de tu coche)
	if porton_cerrado and not porton_abierto and Vector2(pp.x - m.porton_pos.x, pp.z - m.porton_pos.z).length() < 3.0:
		if salida_cerrada == "coche":
			return {"kind": "nada", "text": "Una cadena gruesa y un candado. Al otro lado está mi coche… con las cuatro ruedas rajadas."}
		if tiene.get("cizalla", false):
			return {"kind": "hold", "que": "porton", "text": "MANTÉN USAR: cortar la cadena del portón (se oirá en toda la finca)"}
		return {"kind": "nada", "text": "Cerrado con una cadena gruesa. Necesito una cizalla."}
	for s in SALIDAS:
		var sp := _pos_salida(s)
		if sp == Vector3.INF or Vector2(pp.x - sp.x, pp.z - sp.z).length() > 3.2 or absf(pp.y - sp.y) > 2.0:
			continue
		if s == salida_cerrada:
			return {"kind": "nada", "text": BLOQUEO[s]}
		var falta := faltan(s)
		if not falta.is_empty():
			return {"kind": "nada", "text": "Para salir por aquí me falta: " + ", ".join(falta) + "."}
		match s:
			"coche":
				return {"kind": "hold", "que": "rueda", "text": "MANTÉN USAR: cambiar la rueda y huir (tarda y hace ruido)"}
			"muro":
				return {"kind": "hold", "que": "trepar", "text": "MANTÉN USAR: atar el garfio, lanzarlo y trepar el muro (tarda y hace ruido)"}
		return {"kind": "hold", "que": "arrancar", "text": "MANTÉN USAR: arrancar la camioneta (el motor tose… y se oye en toda la finca)"}
	return {}

func _pos_salida(s: String) -> Vector3:
	match s:
		"camioneta":
			return cochera_pos
		"coche":
			return m.car_pos
		"muro":
			return muro_pos
	return Vector3.INF

## Lo que falta para usar una salida (texto para el jugador).
func faltan(s: String) -> Array[String]:
	var f: Array[String] = []
	match s:
		"camioneta":
			if not tiene.get("llaves_camioneta", false):
				f.append("sus llaves (en el cuarto de Damián)")
			if not tiene.get("gasolina", false) or gasolina_usada:
				f.append("gasolina")
			if not tiene.get("bateria", false):
				f.append("la batería (se la ha quitado)")
		"coche":
			if not porton_abierto:
				f.append("abrir el portón (cizalla)" if not tiene.get("cizalla", false) else "cortar la cadena del portón")
			if not tiene.get("rueda", false):
				f.append("una rueda de repuesto")
			if not tiene.get("gato", false):
				f.append("un gato")
		"muro":
			if not tiene.get("cuerda", false):
				f.append("una cuerda")
			if not tiene.get("garfio", false):
				f.append("un garfio")
	return f

func empezar_hold(que: String) -> void:
	hold_kind = que
	hold_t = 0.0
	if que in ["arrancar", "rueda", "trepar"] and not _carrera:
		_carrera_final(que)

## El último paso de cualquier salida se oye en toda la finca: Damián sale corriendo de la casa a por ti (y la madre,
## si está suelta). Una carrera: o terminas antes de que llegue, o te atrapa (y vuelves a empezar ese paso).
var _carrera := false
func _carrera_final(que: String) -> void:
	_carrera = true
	var pp: Vector3 = j.player.global_position
	var e: ZarekElena = j.elena
	e.aturdido = 0.0
	e.can_catch = true
	var salida_casa: Vector3 = m.front_door + Vector3(0, 0, 2.0)
	if pp.distance_to(salida_casa) < 14.0 or m.inside_house(pp):
		salida_casa = m.random_floor(pp, 16.0)
	e.global_position = salida_casa
	e.visible = true
	e.aggro = maxi(e.aggro, 4)
	e.last_seen = pp
	e.set_state(ZarekElena.S.CHASE)
	ZarekSonido.en(m, "damian_rugido", salida_casa + Vector3(0, 1.7, 0), 8.0, 80.0)
	j.player.shake(6.0)
	j.message({"arrancar": "¡El motor tose! Un rugido en la casa: viene corriendo.\n¡NO SUELTES! ¡ARRANCA!", "rueda": "Cada golpe de la llave de cruz retumba en el bosque. Le oigo correr hacia aquí.\n¡NO SUELTES!",
		"trepar": "El garfio choca contra la piedra. Le oigo venir a la carrera.\n¡SUBE!"}.get(que, ""), 3.0)
	if madre_suelta and is_instance_valid(madre):
		madre.last_seen = pp
		madre.set_state(ZarekElena.S.CHASE)

func _hold_tick(delta: float, pp: Vector3) -> void:
	if hold_kind == "":
		return
	var t := objetivo(pp)
	if not Input.is_action_pressed("usar") or str(t.get("que", "")) != hold_kind or j.state != "juego":
		hold_kind = ""
		j.bar_rit.visible = false
		return
	hold_t += delta
	var dur := {"rociar": ROCIAR, "porton": CORTAR, "rueda": RUEDA, "trepar": TREPAR, "argolla": ARGOLLA, "cerradura": CERRADURA, "arrancar": ARRANCAR}.get(hold_kind, 2.0) as float
	j.bar_rit.visible = true
	j.bar_rit.value = hold_t / dur * 100.0
	if fmod(hold_t, 0.7) < delta:
		j.oir_ruido(pp, {"rociar": 3.0, "porton": 14.0, "rueda": 10.0, "trepar": 8.0, "argolla": 2.0, "cerradura": 5.0, "arrancar": 14.0}.get(hold_kind, 6.0))
		j.sound_at({"rociar": "chapoteo", "porton": "cadenas", "rueda": "impacto_metal", "trepar": "crujido", "argolla": "cadenas", "cerradura": "pomo_cerrado", "arrancar": "coche_puerta"}.get(hold_kind, "golpe_madera"), pp + j.player.forward() * 0.8, -6.0)
	if hold_t >= dur:
		var k := hold_kind
		hold_kind = ""
		j.bar_rit.visible = false
		completar(k)

func completar(que: String) -> void:
	match que:
		"clavo":
			tiene_clavo = true
			if _clavo:
				j._a_la_mano(_clavo)
			j.message("Un clavo largo y oxidado. Puede servir para forzar el candado.", 3.0)
		"argolla":
			encadenada = false
			if _cadena_vis:
				_cadena_vis.queue_free()
			j.sound_at("cadenas", ancla + Vector3(0, 0.3, 0), -4.0)
			j.message("¡Clic! El candado se abre. Tengo el tobillo en carne viva, pero soy libre.\nAhora la puerta… cerrada por fuera.", 4.0)
		"cerradura":
			en_celda = false
			for d in celda_puertas:
				d.locked = false
				d.erase("celda")
			if not celda_puertas.is_empty():
				var dd: Dictionary = celda_puertas[0]
				var mejor := 1e9
				for d in celda_puertas:
					var dist := (d.pos as Vector3).distance_to(j.player.global_position)
					if dist < mejor:
						mejor = dist
						dd = d
				m.entreabrir(dd)
			j.message("La cerradura cede… con un chasquido que se oye en toda la casa.\nAbajo, alguien se ha levantado. Tengo que salir de aquí. En silencio.", 4.5)
			# el ruido le despierta: ya no duerme los 75 s (el bot escapaba antes de que se levantara)
			if j.elena.state == ZarekElena.S.DORMANT:
				j.elena.timer = minf(j.elena.timer, 8.0)
			j._consejo("salir", "Busca una forma de salir de la finca: mira el DIARIO (arriba a la derecha). Cada noche hay una salida bloqueada.")
		"rociar":
			capilla_rociada = true
			gasolina_usada = true
			j.message("La capilla apesta a gasolina. Ahora necesito que ella esté dentro…\ny lanzar una bengala (botón BENGALA).", 4.5)
		"porton":
			abrir_porton()
			j.message("¡La cadena cede! El portón está abierto. Mi coche está ahí fuera.", 3.0)
			j.elena.hear(j.player.global_position, 999.0)
		"rueda":
			j._escapar("coche")
		"arrancar":
			j._escapar("camioneta")
		"trepar":
			j._escapar("muro")
