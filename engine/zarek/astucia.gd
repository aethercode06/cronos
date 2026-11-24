class_name ZarekAstucia
extends Node
## Tanda 3: engañar a Damián y una casa que reacciona (todo con su porqué, un consejo la primera vez y en el DIARIO):
## - LA POLAROID DE DAMIÁN: con ella fotografía a sus víctimas. Su flash, de cerca y de frente, le ciega unos
##   segundos (3 fotos). Está en la galería de servicio, donde cuelga a la gente. Se dispara con el botón BENGALA.
## - ENCERRARLE: con el llavero del padre (el reloj de pie) se puede echar la llave a una puerta con él dentro.
##   La aporrea y al final la revienta, pero te da tiempo.
## - LUCES COMO CEBO: Damián ve una luz que no estaba encendida desde lejos y va a mirar (ZarekSupervivencia).
## - ESCONDITES NUEVOS: tras las cortinas de las ventanas, dentro del montaplatos y en la bañera de agua sucia.
## - LOS TELÉFONOS: hay dos en la casa unidos por una línea interior. Desde uno se hace sonar el otro y Damián va
##   a ver quién llama. A veces la madre hace sonar el que tienes cerca: descuelga antes de que él venga.
## - LA CASA MIRA: las muñecas tienen los ojos de la madre (si una te mira de frente, su furia sube; dales la vuelta),
##   detrás de los espejos tapados y de algunos retratos hay cosas escritas (pistas… y sustos).
## - EL CUARTO DE DAMIÁN: su mechero (velas sin cerillas), pilas y un mapa dibujado a mano de dónde lo esconde todo.

var j: Node  # ZarekJuego
var m: ZarekMansion

var items: Array = []           # {pos, kind, node, taken}
var polaroid := false
var fotos := 0
var mechero := false
var mapa := false

var telefonos: Array = []       # {pos, node, snd, sonando}
var _t_llamada := 0.0           # espera para volver a marcar
var _t_madre_llama := 0.0       # la madre hace sonar un teléfono cerca
var munecas: Array = []         # {node, mira, fuera_t, girada}
var espejos: Array = []         # {pos, tela, hecho, frente}
var retratos: Array = []        # {pos, hecho, nota}
var encierros: Array = []       # {d, t}
var _t := 0.0

func preparar(mansion: ZarekMansion) -> void:
	m = mansion
	ZarekTerror._rng.seed = m.partida_seed + 4242
	var rng := RandomNumberGenerator.new()
	rng.seed = m.partida_seed + 77
	# la Polaroid, donde cuelga a sus víctimas; si no hay sitio, en su cuarto o en el estudio
	for nombre in ["Galería de servicio", "Cuarto de Damián", "Estudio del padre"]:
		if _poner("polaroid", nombre):
			break
	# el botín de su cuarto: el mechero, pilas y el mapa dibujado a mano
	for k in ["mechero", "pilas", "mapa"]:
		_poner(k, "Cuarto de Damián")
	_telefonos()
	_munecas()
	_espejos()
	_retratos(rng)
	_escondites()
	_t_madre_llama = rng.randf_range(240.0, 420.0)

func _poner(kind: String, sala: String) -> bool:
	var r := m._sala_por_nombre(sala)
	if r.is_empty():
		return false
	var p := ZarekTerror._sitio_libre(m, r, 0.5)
	if p == Vector3.INF:
		return false
	items.append({"pos": p, "kind": kind, "node": _modelo(kind, p), "taken": false})
	return true

func _modelo(kind: String, p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = p
	n.set_meta("dyn", true)
	m._house.add_child(n)
	match kind:
		"polaroid":
			if m.objeto_real("s_polaroid", n, Vector3.ZERO, randf() * TAU) == null:
				m.box(Vector3(0.15, 0.1, 0.11), Vector3(0, 0.05, 0), m._plain(Color(0.85, 0.82, 0.75), 0.6), false, n, false)
			# fotos tiradas alrededor (marco blanco)
			for k in 3:
				var f := m.box(Vector3(0.088, 0.002, 0.107), Vector3(randf_range(-0.3, 0.3), 0.002 + k * 0.001, randf_range(-0.3, 0.3)), m._plain(Color(0.9, 0.88, 0.82), 0.8), false, n, false)
				f.rotation.y = randf() * TAU
		"mechero":
			if m.objeto_real("s_mechero", n, Vector3(0, 0, PI * 0.5), randf() * TAU) == null:
				m.box(Vector3(0.04, 0.06, 0.014), Vector3(0, 0.03, 0), m._mat.metal, false, n, false)
		"pilas":
			m.objeto_real("s_pila", n, Vector3.ZERO, randf() * TAU)
		"mapa":
			# hoja de cuaderno doblada con un plano a lápiz
			var hoja := m.box(Vector3(0.3, 0.003, 0.21), Vector3(0, 0.002, 0), m._plain(Color(0.86, 0.82, 0.7), 0.95), false, n, false)
			hoja.rotation.y = randf() * TAU
			for k in 5:
				var linea := m.box(Vector3(randf_range(0.08, 0.2), 0.0015, 0.004), Vector3(randf_range(-0.07, 0.07), 0.002, randf_range(-0.06, 0.06)), m._plain(Color(0.25, 0.22, 0.2), 0.9), false, hoja, false)
				linea.rotation.y = randf() * PI
	return n

# ---------------- los teléfonos ----------------
func _telefonos() -> void:
	for nombre in ["Vestíbulo y gran escalera", "Estudio del padre", "Cocina", "Salón con chimenea"]:
		if telefonos.size() >= 2:
			break
		var r := m._sala_por_nombre(nombre)
		if r.is_empty():
			continue
		var p := ZarekTerror._sitio_libre(m, r, 0.6)
		if p == Vector3.INF:
			continue
		var n := Node3D.new()
		n.position = p
		n.set_meta("dyn", true)
		m._house.add_child(n)
		var alto := 0.55
		if m._prop("side_table_01", Vector3.ZERO, randf() * TAU, 1.0, true, n) != null:
			alto = 0.551
		var tel := Node3D.new()
		tel.position = Vector3(0, alto, 0)
		n.add_child(tel)
		if m.objeto_real("s_telefono", tel, Vector3.ZERO, randf() * TAU) == null:
			m.box(Vector3(0.22, 0.12, 0.2), Vector3(0, 0.06, 0), m._mat.oscuro, false, tel, false)
		var s := AudioStreamPlayer3D.new()
		s.position = Vector3(0, alto + 0.1, 0)
		s.unit_size = 6.0
		s.max_distance = 45.0
		s.volume_db = 2.0
		n.add_child(s)
		telefonos.append({"pos": p, "node": n, "snd": s, "sonando": 0.0, "sala": nombre})

## Hace sonar un teléfono «seg» segundos; Damián lo oye desde casi toda la planta y va a ver.
func sonar(tel: Dictionary, seg: float) -> void:
	tel.sonando = seg
	_timbre(tel)
	var e: ZarekElena = j.elena
	if e.visible and e.state != ZarekElena.S.DORMANT and e.state != ZarekElena.S.CHASE:
		e.last_seen = (tel.pos as Vector3)
		e.set_state(ZarekElena.S.INVESTIGATE, seg + 10.0)

func _timbre(tel: Dictionary) -> void:
	var s: AudioStreamPlayer3D = tel.snd
	if ZarekSonido.hay("telefono"):
		s.stream = ZarekSonido.uno("telefono")
	else:
		s.stream = AetherSynth.make("campana")
	s.play()

func _telefonos_tick(delta: float, pp: Vector3) -> void:
	_t_llamada -= delta
	for tel in telefonos:
		if float(tel.sonando) > 0.0:
			tel.sonando = float(tel.sonando) - delta
			var s: AudioStreamPlayer3D = tel.snd
			if not s.playing and float(tel.sonando) > 0.5:
				_timbre(tel)
			if float(tel.sonando) <= 0.0:
				s.stop()
	# la madre hace sonar el teléfono que tienes cerca (si estás en la planta y no escondida)
	_t_madre_llama -= delta
	if _t_madre_llama <= 0.0 and j.state == "juego" and not j.huida.encadenada:
		_t_madre_llama = randf_range(260.0, 480.0)
		for tel in telefonos:
			if (tel.pos as Vector3).distance_to(pp) < 14.0 and absf((tel.pos as Vector3).y - pp.y) < 2.0:
				sonar(tel, 14.0)
				j.message("¡El teléfono! Está sonando… y él lo va a oír.", 2.5)
				j._consejo("telefono_madre", "A veces la madre hace sonar el teléfono que tienes cerca para que Damián venga. Descuélgalo (USAR) para que pare… o aléjate.")
				break

# ---------------- las muñecas: los ojos de la madre ----------------
func _munecas() -> void:
	for nd in m.munecas:
		if is_instance_valid(nd):
			munecas.append({"node": nd, "fuera": 0.0, "girada": false, "mira": false})

func _munecas_tick(delta: float, pp: Vector3) -> void:
	var cam_dir: Vector3 = j.player.look_dir()
	for mu in munecas:
		var nd: Node3D = mu.node
		if not is_instance_valid(nd):
			continue
		var to := nd.global_position - pp
		var d := Vector2(to.x, to.z).length()
		if d > 9.0 or absf(to.y) > 2.5:
			mu.fuera = 0.0
			continue
		var vista := cam_dir.normalized().dot(to.normalized()) > 0.55
		if not vista:
			mu.fuera = float(mu.fuera) + delta
			# cuando no la miras, se gira hacia ti (una sola vez hasta que la vuelvas a girar)
			if float(mu.get("vuelta", 0.0)) > 0.0:
				mu["vuelta"] = float(mu.vuelta) - delta
			elif float(mu.fuera) > 2.5 and not bool(mu.mira) and d < 7.0:
				mu.mira = true
				var yaw := atan2(pp.x - nd.global_position.x, pp.z - nd.global_position.z)
				nd.rotation.y = yaw
				j.sound_at("crujido", nd.global_position + Vector3(0, 0.3, 0), -14.0)
		else:
			if bool(mu.mira) and float(mu.fuera) > 0.0 and not bool(mu.get("susto", false)):
				mu["susto"] = true
				j.sanity = maxf(0.0, j.sanity - 4.0)
				j.message("La muñeca… estaba mirando hacia el otro lado.", 2.2)
				j._consejo("muneca", "Las muñecas de esta casa tienen los ojos de la madre: mientras una te mire de frente, su furia sube. Dales la vuelta (USAR) para que miren a la pared.")
			mu.fuera = 0.0
		# mirándote de frente y cerca: la madre te ve
		if bool(mu.mira) and d < 4.0 and m.room_at(nd.global_position + Vector3(0, 0.3, 0)) == m.room_at(pp):
			j.huida.subir_furia(0.2 * delta, "muneca")
			mu["mirando"] = float(mu.get("mirando", 0.0)) + delta
			# al rato pierde el interés y vuelve a su sitio
			if float(mu.mirando) > 45.0:
				mu.mira = false
				mu["mirando"] = 0.0
				mu["susto"] = false
				nd.rotation.y += PI

# ---------------- espejos tapados y retratos: lo que esconden ----------------
func _espejos() -> void:
	for c in m._house.get_children():
		var nd := c as Node3D
		if nd == null or nd.scene_file_path == "" or not nd.scene_file_path.get_file().contains("mirror"):
			continue
		for h in nd.get_children():
			if h is MeshInstance3D and (h as MeshInstance3D).material_override != null and h.get_class() == "MeshInstance3D" and (h as MeshInstance3D).mesh is ArrayMesh:
				espejos.append({"pos": (h as MeshInstance3D).global_position, "tela": h, "hecho": false})
				break

func _retratos(rng: RandomNumberGenerator) -> void:
	for c in m._house.get_children():
		var nd := c as Node3D
		if nd == null or nd.scene_file_path == "":
			continue
		var f := nd.scene_file_path.get_file()
		if not (f.contains("picture_frame") or f.contains("portrait")):
			continue
		var ab := m._caja_mallas(nd)
		var cen := ab.get_center()
		var id := m.room_at(Vector3(cen.x, ab.position.y - 0.5, cen.z))
		if id < 0 or ab.size.y < 0.3:
			continue
		retratos.append({"pos": Vector3(cen.x, float(m.rooms[id].y), cen.z), "alto": cen.y, "hecho": false, "nota": ""})
	retratos.shuffle()
	# detrás de uno está escrita la fecha de la caja fuerte (la boda de los padres)
	if not retratos.is_empty() and j.inter:
		retratos[0].nota = "fecha"

# ---------------- escondites nuevos ----------------
func _escondites() -> void:
	# tras las cortinas largas de las ventanas (salones, comedor, dormitorios; no en el sótano)
	var n_cort := 0
	for w in m.ventanas_info:
		if n_cort >= 8 or w.get("tapiada", false):
			continue
		var c: Vector3 = w.c
		var inward: Vector3 = w.inward
		if inward == Vector3.ZERO or m.level_of(c.y + 0.3) < 0:
			continue
		var id := m.room_at(c + inward * 1.2 + Vector3(0, 0.5, 0))
		if id < 0 or not (String(m.rooms[id].type) in ["salon", "dormitorio", "comedor", "biblioteca", "estudio"]):
			continue
		var fuera := c + inward * 1.25
		if m.wardrobe_near(fuera, 1.5).size() > 0:
			continue
		m.wardrobes.append({"pos": fuera, "inside": c + inward * (float(w.thick) * 0.5 + 0.32), "yaw": atan2(inward.x, inward.z), "tipo": "cortina"})
		n_cort += 1
	# dentro del montaplatos (encogida, entre la despensa y el cuarto de plancha)
	for mp in m.montaplatos:
		var p: Vector3 = mp
		m.wardrobes.append({"pos": p + Vector3(-0.8, 0, 0), "inside": p + Vector3(0.12, 0.9, 0), "yaw": -PI * 0.5, "tipo": "montaplatos"})
	# en la bañera de agua sucia
	for c in m._house.get_children():
		var nd := c as Node3D
		if nd == null or nd.scene_file_path == "" or not (nd.scene_file_path.get_file().contains("bathtub") or nd.scene_file_path.get_file().contains("bathtube")):
			continue
		var ab := m._caja_mallas(nd)
		var cen := ab.get_center()
		var id := m.room_at(Vector3(cen.x, ab.position.y + 0.3, cen.z))
		if id < 0:
			continue
		var rc: Rect2 = m.rooms[id].rect
		var hacia := Vector3(rc.get_center().x - cen.x, 0, rc.get_center().y - cen.z)
		if absf(hacia.x) * (ab.size.z) > absf(hacia.z) * (ab.size.x):
			hacia = Vector3(signf(hacia.x), 0, 0)
		else:
			hacia = Vector3(0, 0, signf(hacia.z))
		var lado := absf(hacia.x) * ab.size.x * 0.5 + absf(hacia.z) * ab.size.z * 0.5
		m.wardrobes.append({"pos": Vector3(cen.x, ab.position.y, cen.z) + hacia * (lado + 0.55), "inside": Vector3(cen.x, ab.position.y + 0.12, cen.z),
			"yaw": atan2(-hacia.x, -hacia.z) + PI, "tipo": "bañera"})

# ---------------- qué se puede hacer aquí ----------------
func objetivo(pp: Vector3) -> Dictionary:
	var fw: Vector3 = j.player.forward()
	for it in items:
		if not it.taken and Vector2(pp.x - it.pos.x, pp.z - it.pos.z).length() < 1.4 and absf(pp.y - (it.pos as Vector3).y) < 1.6:
			return {"kind": "ast", "que": "coger", "obj": it, "text": "USAR: coger " + {"polaroid": "la cámara Polaroid", "mechero": "el mechero", "pilas": "las pilas", "mapa": "el papel doblado"}.get(String(it.kind), "eso")}
	for tel in telefonos:
		if Vector2(pp.x - tel.pos.x, pp.z - tel.pos.z).length() < 1.5 and absf(pp.y - (tel.pos as Vector3).y) < 1.6:
			if float(tel.sonando) > 0.0:
				return {"kind": "ast", "que": "descolgar", "obj": tel, "text": "USAR: descolgar el teléfono"}
			if _t_llamada > 0.0:
				return {"kind": "nada", "text": "El teléfono. La línea interior hace clic… hay que esperar un poco."}
			return {"kind": "ast", "que": "llamar", "obj": tel, "text": "USAR: marcar el otro teléfono de la casa (sonará allí)"}
	# echarle la llave con él dentro
	if j.inter.llavero:
		var d: Dictionary = m.door_near(pp + fw * 0.6, 1.7)
		if not d.is_empty() and not d.open and not d.locked and float(d.get("barricada", 0.0)) <= 0.0 and _damian_al_otro_lado(d, pp):
			return {"kind": "ast", "que": "encerrar", "obj": d, "text": "USAR: ¡echarle la llave! (está dentro)"}
	for mu in munecas:
		var nd: Node3D = mu.node
		if is_instance_valid(nd) and bool(mu.mira) and Vector2(pp.x - nd.global_position.x, pp.z - nd.global_position.z).length() < 1.5 and absf(pp.y - nd.global_position.y) < 2.0:
			return {"kind": "ast", "que": "muneca", "obj": mu, "text": "USAR: girar la muñeca hacia la pared"}
	for es in espejos:
		if not es.hecho and is_instance_valid(es.tela) and Vector2(pp.x - es.pos.x, pp.z - es.pos.z).length() < 1.5 and absf(pp.y - (es.pos as Vector3).y) < 2.2:
			return {"kind": "ast", "que": "espejo", "obj": es, "text": "USAR: quitar la tela del espejo"}
	for rt in retratos:
		if not rt.hecho and Vector2(pp.x - rt.pos.x, pp.z - rt.pos.z).length() < 1.3 and absf(pp.y - (rt.pos as Vector3).y) < 1.0:
			var to := Vector3(rt.pos.x - pp.x, 0, rt.pos.z - pp.z).normalized()
			if fw.dot(to) > 0.5:
				return {"kind": "ast", "que": "retrato", "obj": rt, "text": "USAR: mirar detrás del retrato", "debil": true}
	return {}

func _damian_al_otro_lado(d: Dictionary, pp: Vector3) -> bool:
	var e: ZarekElena = j.elena
	if not e.visible or e.state == ZarekElena.S.DORMANT or not e.es_damian:
		return false
	var mio := m.room_at(pp)
	var suyo := m.room_at(e.global_position)
	if suyo < 0 or suyo == mio or e.global_position.distance_to(d.pos) > 14.0:
		return false
	return suyo in (d.get("ids", []) as Array)

func usar(t: Dictionary) -> void:
	var pp: Vector3 = j.player.global_position
	match String(t.que):
		"coger":
			var it: Dictionary = t.obj
			if it.kind in ["polaroid", "mechero"] and not j.sup.cabe():
				return
			it.taken = true
			j._a_la_mano(it.node)
			match String(it.kind):
				"polaroid":
					polaroid = true
					fotos = 3
					j.message("Su cámara Polaroid. Con esto fotografía a… No quiero pensarlo.\nQuedan 3 fotos: el flash de cerca le ciega (botón BENGALA).", 4.0)
					j._consejo("polaroid", "La Polaroid de Damián: si está cerca y delante de ti, el botón BENGALA dispara el flash y le ciega unos segundos. Solo quedan 3 fotos.")
				"mechero":
					mechero = true
					j.message("Su mechero de gasolina. Con él enciendo las velas sin gastar cerillas.", 3.0)
				"pilas":
					j.battery = 100.0
					j.message("Pilas nuevas, todavía en su blíster. La linterna, al máximo.", 2.5)
				"mapa":
					mapa = true
					for s in m.seals:
						if not s.taken:
							s["revelado"] = true
					j.message("Un plano de la finca a lápiz, con su letra: dónde ha escondido cada cosa.\nLo apunto todo en el DIARIO.", 4.0)
					if j.diario:
						j.diario.tick(0.0, true)
		"descolgar":
			var tel: Dictionary = t.obj
			tel.sonando = 0.0
			(tel.snd as AudioStreamPlayer3D).stop()
			j.sound_at("pomo", tel.pos + Vector3(0, 0.6, 0), -8.0)
			j.message("Descuelgo. Al otro lado solo se oye una respiración lenta… y cadenas.", 3.0)
			j.sanity = maxf(0.0, j.sanity - 5.0)
		"llamar":
			var otro: Dictionary = {}
			for tel in telefonos:
				if tel != t.obj:
					otro = tel
			if otro.is_empty():
				j.message("No hay tono. La línea interior está muerta.", 2.0)
				return
			_t_llamada = 75.0
			j.sound_at("pomo", (t.obj.pos as Vector3) + Vector3(0, 0.6, 0), -10.0)
			sonar(otro, 16.0)
			j.message("Marco la línea interior. Allí, en «%s», empieza a sonar el otro teléfono.\nÉl irá a ver quién llama." % String(otro.sala), 3.5)
			j._consejo("telefono", "Los dos teléfonos de la casa están unidos: desde uno haces sonar el otro y Damián va hacia allí. Úsalo para alejarle de donde quieres ir.")
		"encerrar":
			var d: Dictionary = t.obj
			d["barricada"] = 22.0
			d["encerrado"] = true
			encierros.append({"d": d, "t": 45.0})
			j.sound_at("llaves", (d.pos as Vector3) + Vector3(0, 1.1, 0), -2.0)
			j.message("¡Clic! Le he echado la llave con él dentro. La cerradura es vieja: no aguantará mucho.", 3.0)
			j._consejo("encerrar", "Con el llavero del padre puedes echarle la llave a una puerta cuando Damián está al otro lado. La aporreará hasta reventarla: aprovecha ese tiempo.")
		"muneca":
			var mu: Dictionary = t.obj
			var nd: Node3D = mu.node
			nd.rotation.y += PI
			mu.mira = false
			mu.fuera = 0.0
			mu["susto"] = false
			mu["vuelta"] = 60.0  # tarda en volver a girarse
			j.sound_at("crujido", nd.global_position, -12.0)
			j.message("Le doy la vuelta. Mira a la pared.", 1.8)
		"espejo":
			var es: Dictionary = t.obj
			es.hecho = true
			var tela: Node3D = es.tela
			var tw := tela.create_tween()
			tw.tween_property(tela, "position:y", tela.position.y - 1.4, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_callback(tela.queue_free)
			j.sound_at("impacto_tela", es.pos, -6.0)
			var pista: String = j.huida.pista_de_nota()
			if pista != "" or randf() < 0.5:
				j.message(("Alguien escribió en el cristal con el dedo…\n" + pista.replace("Entre las hojas hay un papelito con la letra de Damián: ", "")) if pista != "" else "En el cristal, escrito con el dedo y algo oscuro: «ELLA TE VE».", 4.0)
			else:
				# susto: algo detrás de ti en el reflejo
				j.sound_behind("susto", 0.0, 0.5)
				j.sanity = maxf(0.0, j.sanity - 10.0)
				j.player.shake(6.0)
				j.message("En el espejo… detrás de mí había alguien.\nMe giro: no hay nadie.", 3.0)
				j.huida.subir_furia(4.0, "espejo")
			j._consejo("espejo", "Los espejos están tapados porque la madre no soporta verse. Detrás a veces hay pistas escritas… y a veces algo que no quieres ver.")
		"retrato":
			var rt: Dictionary = t.obj
			rt.hecho = true
			j.sound_at("impacto_madera", rt.pos + Vector3(0, 1.4, 0), -10.0)
			if String(rt.nota) == "fecha" and j.inter:
				j.message("Detrás del retrato, a lápiz: «Nuestra boda, %d de %s». La fecha de los padres." % [j.inter.fecha_dia, ZarekInteraccion.MESES[j.inter.fecha_mes - 1]], 4.0)
			else:
				var pista: String = j.huida.pista_de_nota()
				if pista != "":
					j.message(pista.replace("Entre las hojas hay", "Detrás del marco hay"), 4.0)
				elif randf() < 0.35:
					j.sound_at("susto", rt.pos + Vector3(0, 1.4, 0), -6.0)
					j.sanity = maxf(0.0, j.sanity - 4.0)
					j.message("Al moverlo, cientos de cucarachas salen corriendo por la pared.", 2.5)
				else:
					j.message("Detrás del retrato solo hay polvo y una mancha más clara en el papel.", 2.0)

## El botón BENGALA con la Polaroid: si Damián (o la madre) está cerca y delante, el flash le ciega.
func disparar_foto() -> bool:
	if not polaroid or fotos <= 0:
		return false
	var pp: Vector3 = j.player.global_position
	var fw: Vector3 = j.player.look_dir()
	fw.y = 0
	var objetivo_n: ZarekElena = null
	for e in [j.elena, j.huida.madre if j.huida.madre_suelta else null]:
		if e == null or not is_instance_valid(e) or not e.visible or e.state == ZarekElena.S.DORMANT:
			continue
		var to: Vector3 = (e as Node3D).global_position - pp
		to.y = 0
		if to.length() < 8.0 and fw.normalized().dot(to.normalized()) > 0.5:
			objetivo_n = e
			break
	if objetivo_n == null:
		return false
	fotos -= 1
	Aether.flash(Color(1, 1, 1), 0.35)
	j.sound_at("camara" if ZarekSonido.hay("camara") else "interruptor", pp + Vector3(0, 1.5, 0), 2.0)
	j.oir_ruido(pp, 5.0)
	if objetivo_n == j.elena:
		objetivo_n.aturdir(3.5, "dolor")
		j.message("¡FLASH! Se tapa los ojos y ruge, ciego. ¡Corre! (quedan %d fotos)" % fotos, 2.5)
	else:
		objetivo_n.repel(pp)
		j.message("¡FLASH! La luz la quema: se arrastra lejos chillando. (quedan %d fotos)" % fotos, 2.5)
	if fotos == 0:
		polaroid = false
		j.message("La cámara escupe la última foto: es él, con los ojos cerrados. Ya no quedan.", 3.0)
	return true

# ---------------- cada fotograma ----------------
func tick(delta: float) -> void:
	if m == null:
		return
	_t += delta
	var pp: Vector3 = j.player.global_position
	_telefonos_tick(delta, pp)
	_munecas_tick(delta, pp)
	# encierros: al final revienta la cerradura
	for en in encierros.duplicate():
		en.t = float(en.t) - delta
		var d: Dictionary = en.d
		if float(en.t) <= 0.0 or float(d.get("barricada", 0.0)) <= 0.0:
			encierros.erase(en)
			d.erase("encerrado")
			if float(d.get("barricada", 0.0)) > 0.0:
				m.desatrancar(d)
				m.set_door(d, true, true)
				j.sound_at("madera_rota" if ZarekSonido.hay("madera_rota") else "portazo", (d.pos as Vector3) + Vector3(0, 1.0, 0), 4.0)
				j.player.shake(8.0)
			if pp.distance_to(d.pos) < 25.0:
				j.message("Un crujido de madera: ha reventado la cerradura. Está fuera.", 2.5)
