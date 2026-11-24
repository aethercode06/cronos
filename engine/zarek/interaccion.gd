class_name ZarekInteraccion
extends Node
## Más cosas que hacer con las manos, todas con su porqué en la historia (y distintas cada noche):
## PUZLES
## - La caja fuerte del padre (estudio): la combinación es el día y el mes en que la madre bajó por primera vez a la
##   cueva (lo dice el diario del padre; la fecha está en el diario de la madre, distinta cada noche). Dentro, su
##   escopeta con dos cartuchos.
## - El reloj de pie del vestíbulo: se paró a las tres la noche del hacha, pero alguien ha movido las agujas. Puesto
##   otra vez a las tres, se abre la caja del péndulo: el llavero del padre (abre las salas cerradas con llave).
## - El piano: con la partitura de la nana leída, tocarla calma a la madre (furia −40)… y Damián lo oye.
## - Los fusibles del sótano: Damián los quitó (a su madre le gusta la oscuridad). Puestos en el cuadro, el sótano
##   tiene luz y la madre se enfada la mitad con tu ruido allí.
## FABRICAR
## - Cóctel incendiario (botella + trapo + la gasolina): se lanza con BENGALA; quema a la madre donde esté, o aparta
##   a Damián. Gasta la gasolina (la camioneta ya no sirve).
## - Latas con cordel (despensa): colgadas en una puerta, suenan cuando alguien la cruza.
## - Palanca: arranca las tablas de una ventana tapiada de la planta baja y abre un atajo al jardín.
## SIGILO Y DISTRACCIONES
## - Escuchar detrás de una puerta cerrada (quieta junto a ella un momento).
## - Mirar por la cerradura (agachada + USAR en una puerta cerrada).
## - Un grifo abierto tapa tus pasos cerca durante medio minuto (aunque el primer ruido le atrae).

var j: Node  # ZarekJuego
var m: ZarekMansion
var rng := RandomNumberGenerator.new()

# inventario de lo nuevo
var botellas := 0
var trapos := 0
var latas := 0
var palanca := false
var fusibles := false
var cocteles := 0
var llavero := false
var nana_leida := false
var items: Array = []          # {pos, kind, node, taken}

# puzles
var fecha_dia := 12
var fecha_mes := 3
var caja_pos := Vector3.INF
var caja_abierta := false
var reloj_pos := Vector3.INF
var reloj_nodo: Node3D
var reloj_hora := 7
var reloj_abierto := false
var piano_pos := Vector3.INF
var fusibles_puestos := false
var _nana_cd := 0.0

# sigilo
var _grifo_hasta := 0.0
var _grifo_pos := Vector3.INF
var _t := 0.0
var _escucha_t := 0.0
var _escucha_puerta: Dictionary = {}
var _escuchadas := {}
var _latas_puertas: Array = []   # {d, nodo}
var _cerradura_cam: Camera3D
var _cerradura_capa: CanvasLayer

# acciones mantenidas
var hold_kind := ""
var hold_t := 0.0
var hold_obj = null

const MESES := ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
const SITIOS := {
	"botella": ["Cava de vinos", "Cocina", "Despensa", "Comedor formal", "Antecocina"],
	"trapo": ["Cuarto de plancha", "Sala de costura", "Cuarto de servicio", "Baño"],
	"latas": ["Despensa", "Cocina", "Antecocina"],
	"palanca": ["Sala de calderas", "Salida a la cochera", "Cuarto de servicio", "Galería de servicio"],
	"fusibles": ["Cuarto de servicio", "Guardarropa", "Despensa", "Cocina", "Estudio del padre"]}
const CUANTOS := {"botella": 2, "trapo": 1, "latas": 1, "palanca": 1, "fusibles": 1}
const NOMBRE := {"botella": "una botella vacía", "trapo": "un trapo", "latas": "unas latas con cordel", "palanca": "una palanca", "fusibles": "los fusibles del sótano"}

func preparar(mansion: ZarekMansion) -> void:
	m = mansion
	rng.seed = m.partida_seed + 2024
	# la fecha de la caja fuerte: cada noche, otra
	fecha_dia = rng.randi_range(1, 28)
	fecha_mes = rng.randi_range(1, 12)
	reloj_hora = [4, 5, 6, 7, 8, 9, 10, 11][rng.randi_range(0, 7)]
	_notas()
	_objetos()
	_caja_fuerte()
	_reloj()
	for x in j.muebles_reg:
		if String(x.ruido) == "piano":
			piano_pos = x.pos
	# Damián se llevó los fusibles del sótano: abajo, a oscuras
	if m.electricidad:
		m.electricidad.sin_fusibles = true
		m.electricidad.devolver()

## Las notas que dan la combinación: el padre dice qué fecha es; el diario de la madre la lleva en el título.
func _notas() -> void:
	for n in m.notas:
		var t := String(n.titulo)
		if t.begins_with("Diario de la madre"):
			n.titulo = "Diario de la madre · %d de %s de 1986" % [fecha_dia, MESES[fecha_mes - 1]]
			n.texto = "Hoy he bajado por primera vez a la cueva. " + String(n.texto)
		elif t.begins_with("Diario del padre"):
			n.texto = String(n.texto) + "\nHe cambiado la combinación de la caja fuerte: el día y el mes en que ella bajó por primera vez a esa maldita cueva. Que nunca se me olvide por qué."
		elif t.begins_with("Partitura"):
			n["nana"] = true
		elif t.begins_with("Reloj de pie"):
			n.texto = "Se paró a las tres en punto la noche del hacha, en 1987. Pero alguien ha movido las agujas: ahora marcan las %d.\nEn el polvo del cristal, con el dedo: «A LAS TRES SE ABRE»." % reloj_hora

# ---------------- objetos sueltos ----------------
func _objetos() -> void:
	ZarekTerror._rng.seed = m.partida_seed + 777
	for kind in CUANTOS:
		var salas: Array = (SITIOS[kind] as Array).duplicate()
		for i in range(salas.size() - 1, 0, -1):
			var k := rng.randi_range(0, i)
			var t0 = salas[i]
			salas[i] = salas[k]
			salas[k] = t0
		var puestos := 0
		for nombre in salas:
			if puestos >= int(CUANTOS[kind]):
				break
			var r := m._sala_por_nombre(nombre)
			if r.is_empty():
				continue
			var p := ZarekTerror._sitio_libre(m, r, 0.5)
			if p == Vector3.INF:
				continue
			items.append({"pos": p, "kind": kind, "node": _modelo(kind, p), "taken": false})
			puestos += 1

func _modelo(kind: String, p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = p
	m._house.add_child(n)
	var real := {"botella": ["s_botella", Vector3(0, 0, PI * 0.5)], "trapo": ["s_trapo", Vector3(PI * 0.5, 0, 0)],
		"latas": ["s_latas", Vector3.ZERO], "palanca": ["s_palanca", Vector3.ZERO], "fusibles": ["s_fusible", Vector3(PI * 0.5, 0, 0)]}
	if real.has(kind):
		var r: Array = real[kind]
		if m.objeto_real(String(r[0]), n, r[1], randf() * TAU) != null:
			if kind == "latas":
				# un puñado de latas oxidadas atadas con cordel
				m.objeto_real("s_latas2", n, Vector3(PI * 0.5, 0, 0), randf() * TAU, Vector3(0.13, 0, 0.04))
				m.objeto_real("s_latas", n, Vector3(0, 0, PI * 0.5), randf() * TAU, Vector3(-0.12, 0, 0.06))
			return n
	var vidrio := m._plain(Color(0.2, 0.3, 0.22, 0.8), 0.1, 0.1)
	match kind:
		"botella":
			m.cyl(0.035, 0.035, 0.2, Vector3(0, 0.1, 0), vidrio, n, 10)
			m.cyl(0.012, 0.03, 0.08, Vector3(0, 0.24, 0), vidrio, n, 8)
		"trapo":
			var t := m.box(Vector3(0.35, 0.03, 0.3), Vector3(0, 0.015, 0), m._mat.sabana, false, n, false)
			t.rotation.y = 0.4
		"latas":
			for k in 4:
				m.cyl(0.035, 0.035, 0.1, Vector3(-0.1 + k * 0.07, 0.05, 0.02 * (k % 2)), m._mat.metal, n, 10)
			m.box(Vector3(0.3, 0.004, 0.004), Vector3(0, 0.1, 0), m._plain(Color(0.6, 0.55, 0.4), 0.9), false, n, false)
		"palanca":
			var b := m.box(Vector3(0.7, 0.025, 0.025), Vector3(0, 0.02, 0), m._mat.hierro, false, n, false)
			b.rotation.y = 0.3
			m.box(Vector3(0.06, 0.02, 0.04), Vector3(0.33, 0.04, 0.1), m._mat.hierro, false, n, false)
		"fusibles":
			m.box(Vector3(0.2, 0.06, 0.12), Vector3(0, 0.03, 0), m._plain(Color(0.35, 0.25, 0.15), 0.8), false, n, false)
			for k in 3:
				m.cyl(0.018, 0.018, 0.05, Vector3(-0.06 + k * 0.06, 0.08, 0), m._plain(Color(0.9, 0.88, 0.8), 0.4), n, 8)
	return n

# ---------------- la caja fuerte y el reloj ----------------
func _caja_fuerte() -> void:
	var r := m._sala_por_nombre("Estudio del padre")
	if r.is_empty():
		return
	ZarekTerror._rng.seed = m.partida_seed + 31
	# contra una pared, de cara a la sala (una caja fuerte de 300 kg no está en medio del estudio)
	var sp := ZarekTerror._sitio_pared(m, r, 0.6)
	var p := Vector3.INF
	var giro := 0.0
	if sp.is_empty():
		p = ZarekTerror._sitio_libre(m, r, 0.6)
	else:
		p = sp[0]
		giro = sp[1]
	if p == Vector3.INF:
		return
	caja_pos = p
	var n := Node3D.new()
	n.position = p
	n.rotation.y = giro
	m._house.add_child(n)
	var acero := m._plain(Color(0.12, 0.13, 0.12), 0.45, 0.7)
	var cuerpo := m.box(Vector3(0.6, 0.8, 0.55), Vector3(0, 0.4, 0), acero, true, n)
	if m.objeto_real("s_caja_fuerte", n, Vector3.ZERO, 0.0) != null:
		cuerpo.visible = false  # solo queda el choque: se ve la caja fuerte antigua de verdad
		return
	for s in [-1.0, 1.0]:
		var dial := m.cyl(0.06, 0.06, 0.03, Vector3(s * 0.0, 0.5, 0.29 * s), m._mat.laton_viejo, n, 16)
		dial.rotation.x = PI * 0.5
		m.box(Vector3(0.04, 0.12, 0.03), Vector3(0.18 * s, 0.38, 0.29 * s), m._mat.laton_viejo, false, n, false)

func _reloj() -> void:
	for n in m.notas:
		if String(n.titulo).begins_with("Reloj de pie"):
			reloj_pos = n.pos
			reloj_nodo = n.nodo
			return

# ---------------- cada fotograma ----------------
func tick(delta: float) -> void:
	if m == null:
		return
	_t += delta
	_nana_cd -= delta
	var pp: Vector3 = j.player.global_position
	_escuchar(delta, pp)
	_latas_tick()
	_avisos(pp)
	_hold_tick(delta, pp)

## La primera vez que te acercas a cada cosa, un consejo claro (una sola vez por jugador).
func _avisos(pp: Vector3) -> void:
	if j.state != "juego":
		return
	if caja_pos != Vector3.INF and not caja_abierta and pp.distance_to(caja_pos) < 3.0:
		j._consejo("caja", "La caja fuerte del padre: 4 cifras, el día y el mes de una fecha (por ejemplo 0703 = 7 de marzo). Las notas de la casa dicen qué fecha usó.")
	if reloj_pos != Vector3.INF and not reloj_abierto and pp.distance_to(reloj_pos) < 3.0:
		j._consejo("reloj", "Un reloj de pie con las agujas movidas. Con USAR mueves la aguja de las horas. Lee su nota: dice a qué hora se paró.")
	if not fusibles_puestos and m.level_of(pp.y + 0.5) == -1:
		j._consejo("fusibles", "El sótano está a oscuras: Damián quitó sus fusibles. Si los encuentras, ponlos en el cuadro eléctrico de la sala de calderas y tendrás luz aquí abajo.")
	if piano_pos != Vector3.INF and pp.distance_to(piano_pos) < 3.0:
		j._consejo("piano", "El piano de la madre. Si lees la partitura de su nana (está en esta casa), podrás tocarla: la calma, pero Damián lo oye.")
	if botellas > 0 or trapos > 0:
		j._consejo("coctel", "Botella + trapo + gasolina = cóctel incendiario. Cuando tengas las tres cosas, MANTÉN USAR donde no haya nada delante para prepararlo. Se lanza con el botón BENGALA.")
	if palanca:
		j._consejo("palanca", "Con la palanca, MANTÉN USAR frente a una ventana tapiada de la planta baja: arrancas las tablas y tienes un atajo al jardín.")
	if latas > 0:
		j._consejo("latas", "Las latas: en una puerta ABIERTA, MANTÉN USAR para colgarlas. Si alguien cruza esa puerta, sonarán y lo sabrás.")

## Quieta junto a una puerta cerrada un momento: pega la oreja.
func _escuchar(delta: float, pp: Vector3) -> void:
	if j.state != "juego" or j.player.moving > 0.1:
		_escucha_t = 0.0
		return
	var d: Dictionary = m.door_near(pp + j.player.forward() * 0.5, 1.3)
	if d.is_empty() or d.open:
		_escucha_t = 0.0
		return
	if d != _escucha_puerta:
		_escucha_puerta = d
		_escucha_t = 0.0
	_escucha_t += delta
	var k := str(d.pos)
	if _escucha_t > 1.3 and _t - float(_escuchadas.get(k, -99.0)) > 15.0:
		_escuchadas[k] = _t
		var otro := (d.pos as Vector3) + ((d.pos as Vector3) - pp).normalized() * 2.0
		var cerca := 99.0
		var quien := ""
		var e: ZarekElena = j.elena
		if e.visible and e.state != ZarekElena.S.DORMANT:
			cerca = e.global_position.distance_to(otro)
			quien = "damian"
		var hu: ZarekHuida = j.huida
		if hu.madre_suelta and is_instance_valid(hu.madre) and hu.madre.visible and hu.madre.global_position.distance_to(otro) < cerca:
			cerca = hu.madre.global_position.distance_to(otro)
			quien = "madre"
		var txt := "Pego la oreja a la puerta… Silencio."
		if cerca < 5.0:
			txt = "Pego la oreja a la puerta… Respira justo al otro lado. NO ABRAS." if quien == "damian" else "Pego la oreja… algo se arrastra al otro lado, muy cerca. Tararea."
		elif cerca < 12.0:
			txt = "Pego la oreja a la puerta… Pasos pesados, no muy lejos." if quien == "damian" else "Pego la oreja… un gemido, no muy lejos."
		j.message(txt, 2.6)
		j._consejo("escuchar", "Si te quedas quieta junto a una puerta cerrada, pegas la oreja: así sabes si hay alguien al otro lado antes de abrir. Agachada, con USAR, miras por la cerradura.")

## Las latas: suenan cuando Damián o la madre cruzan esa puerta.
func _latas_tick() -> void:
	for x in _latas_puertas.duplicate():
		var dp: Vector3 = (x.d as Dictionary).pos
		var alguien := false
		var e: ZarekElena = j.elena
		if e.visible and e.state != ZarekElena.S.DORMANT and e.global_position.distance_to(dp) < 1.5:
			alguien = true
		var hu: ZarekHuida = j.huida
		if hu.madre_suelta and is_instance_valid(hu.madre) and hu.madre.visible and hu.madre.global_position.distance_to(dp) < 1.5:
			alguien = true
		if alguien:
			ZarekSonido.en(m, "tintineo", dp + Vector3(0, 1.8, 0), 8.0, 60.0)
			ZarekSonido.en(m, "impacto_metal", dp + Vector3(0, 0.3, 0), 4.0, 60.0)
			if is_instance_valid(x.nodo):
				(x.nodo as Node3D).queue_free()
			_latas_puertas.erase(x)
			j.message("¡Las latas! Alguien ha cruzado la puerta de %s." % m.room_name(dp), 3.0)

# ---------------- qué se puede hacer aquí ----------------
func objetivo(pp: Vector3) -> Dictionary:
	for it in items:
		if not it.taken and Vector2(pp.x - it.pos.x, pp.z - it.pos.z).length() < 1.5 and absf(pp.y - (it.pos as Vector3).y) < 1.6:
			return {"kind": "inter", "que": "coger", "obj": it, "text": "USAR: coger " + String(NOMBRE[it.kind])}
	if caja_pos != Vector3.INF and not caja_abierta and pp.distance_to(caja_pos) < 1.6:
		return {"kind": "inter", "que": "caja", "text": "USAR: probar la combinación de la caja fuerte del padre"}
	if reloj_pos != Vector3.INF and not reloj_abierto and pp.distance_to(reloj_pos) < 1.7:
		return {"kind": "inter", "que": "reloj", "text": "USAR: mover la aguja de las horas (marca las %d)" % reloj_hora}
	if piano_pos != Vector3.INF and nana_leida and pp.distance_to(piano_pos) < 2.0 and _nana_cd <= 0.0 and not j.huida.madre_muerta:
		return {"kind": "hold_inter", "que": "nana", "text": "MANTÉN USAR: tocar la nana de la madre (la calma… y Damián lo oirá)"}
	var el: ZarekElectricidad = m.electricidad
	if el and fusibles and not fusibles_puestos and el.cuadro_cerca(pp):
		return {"kind": "hold_inter", "que": "fusibles", "text": "MANTÉN USAR: poner los fusibles del sótano"}
	# agachada en una puerta cerrada: mirar por la cerradura
	var d: Dictionary = m.door_near(pp + j.player.forward() * 0.6, 1.5)
	if not d.is_empty() and not d.open and j.player.crouching and not d.has("pivot2"):
		return {"kind": "inter", "que": "cerradura", "obj": d, "text": "USAR: mirar por la cerradura"}
	# ventana tapiada de la planta baja con la palanca
	if palanca:
		for w in m.ventanas_info:
			if w.get("tapiada", false) and not w.get("abierta", false) and m.level_of((w.c as Vector3).y + 0.3) == 0:
				var dentro: Vector3 = (w.c as Vector3) + (w.inward as Vector3) * 0.8
				if Vector2(pp.x - dentro.x, pp.z - dentro.z).length() < 1.4:
					return {"kind": "hold_inter", "que": "ventana", "obj": w, "text": "MANTÉN USAR: arrancar las tablas con la palanca (hace ruido)"}
	# fabricar: el cóctel
	if botellas > 0 and trapos > 0 and j.huida.tiene.get("gasolina", false) and not j.huida.gasolina_usada:
		return {"kind": "hold_inter", "que": "coctel", "text": "MANTÉN USAR: preparar un cóctel incendiario (gasta la gasolina: la camioneta ya no servirá)", "debil": true}
	return {}

func usar(t: Dictionary) -> void:
	match String(t.que):
		"coger":
			var it: Dictionary = t.obj
			it.taken = true
			j._a_la_mano(it.node)
			j.sound_at("recoger", it.pos, -8.0)
			match String(it.kind):
				"botella":
					botellas += 1
				"trapo":
					trapos += 1
				"latas":
					latas += 3
				"palanca":
					palanca = true
				"fusibles":
					fusibles = true
			j.message({"botella": "Una botella vacía. Con un trapo y gasolina… ardería.", "trapo": "Un trapo viejo. Empapado en gasolina, en una botella…",
				"latas": "Latas atadas con cordel. Colgadas en una puerta, sonarán si alguien la cruza (MANTÉN USAR en una puerta abierta).",
				"palanca": "Una palanca. Puedo arrancar las tablas de una ventana tapiada de abajo y salir al jardín.",
				"fusibles": "Los fusibles del sótano. Él los quitó para dejarlo a oscuras. El cuadro eléctrico está en la sala de calderas."}.get(String(it.kind), ""), 3.5)
		"caja":
			_abrir_teclado()
		"reloj":
			reloj_hora = reloj_hora % 12 + 1
			j.sound_at("tictac", reloj_pos + Vector3(0, 1.5, 0), -4.0)
			if reloj_hora == 3:
				reloj_abierto = true
				j.sound_at("campana", reloj_pos + Vector3(0, 1.6, 0), 2.0)
				llavero = true
				for c in j.salas_cerradas:
					if not String(c.nombre) in j.llaves_salas:
						j.llaves_salas.append(String(c.nombre))
				j.oir_ruido(reloj_pos, 9.0)
				j.message("Las tres en punto. El reloj da tres campanadas… y la caja del péndulo se abre.\nDentro, el llavero del padre: abre las salas cerradas con llave.", 5.0)
			else:
				j.message("Las agujas marcan las %d." % reloj_hora, 1.2)
		"cerradura":
			_mirar_cerradura(t.obj)

# ---------------- acciones mantenidas ----------------
func empezar_hold(t: Dictionary) -> void:
	hold_kind = String(t.que)
	hold_obj = t.get("obj", null)
	hold_t = 0.0

const DUR := {"nana": 6.0, "fusibles": 2.5, "ventana": 3.0, "coctel": 2.5, "latas": 1.2}
func _hold_tick(delta: float, pp: Vector3) -> void:
	if hold_kind == "":
		return
	var sigue: bool = Input.is_action_pressed("usar") and j.state == "juego"
	if hold_kind == "latas":
		sigue = sigue and hold_obj is Dictionary and (hold_obj.pos as Vector3).distance_to(pp) < 2.4
	else:
		sigue = sigue and str(objetivo(pp).get("que", "")) == hold_kind
	if not sigue:
		if hold_kind == "latas" and hold_t < 0.4 and hold_obj is Dictionary:
			j._mover_puerta(hold_obj)  # un toque: la puerta se cierra como siempre
		hold_kind = ""
		j.bar_rit.visible = false
		return
	hold_t += delta
	var dur: float = DUR.get(hold_kind, 2.0)
	j.bar_rit.visible = true
	j.bar_rit.value = hold_t / dur * 100.0
	if hold_kind == "nana" and fmod(hold_t, 1.0) < delta:
		j.sound_at("piano", piano_pos + Vector3(0, 1.0, 0), -2.0)
	if hold_kind == "ventana" and fmod(hold_t, 0.6) < delta:
		j.sound_at("madera_rota", pp + j.player.forward(), -4.0)
		j.oir_ruido(pp, 9.0)
	if hold_t >= dur:
		var k := hold_kind
		hold_kind = ""
		j.bar_rit.visible = false
		completar(k, hold_obj)

func completar(k: String, obj = null) -> void:
	match k:
		"nana":
			_nana_cd = 90.0
			j.huida.furia = maxf(0.0, j.huida.furia - 40.0)
			j.elena.hear(piano_pos, 999.0)
			j.message("La nana suena por toda la casa. Abajo, las cadenas dejan de moverse.\nElla se calma… pero Damián viene hacia el piano.", 4.0)
		"fusibles":
			fusibles = false
			fusibles_puestos = true
			if m.electricidad:
				m.electricidad.sin_fusibles = false
				m.electricidad.devolver()
			j.sound_at("interruptor", (m.electricidad.cuadro.pos as Vector3), 2.0)
			j.message("Los fusibles encajan. El sótano se ilumina.\nA ella no le gusta la luz: aquí abajo se enfadará menos con mi ruido.", 4.0)
		"ventana":
			var w: Dictionary = obj
			w["abierta"] = true
			for t in w.get("tablas", []):
				if is_instance_valid(t):
					(t as Node3D).queue_free()
			var c: Vector3 = w.c
			var dentro: Vector3 = w.inward
			var a := c + dentro * 0.9
			var b := c - dentro * 1.3
			m.portals.append({"pos": a, "to": b, "text": "saltar por la ventana al jardín"})
			m.portals.append({"pos": b, "to": a, "text": "entrar por la ventana"})
			var lk := NavigationLink3D.new()
			lk.start_position = a
			lk.end_position = b
			m.add_child(lk)
			j.message("Las tablas ceden. Por esta ventana puedo salir al jardín… y entrar.", 3.0)
		"coctel":
			botellas -= 1
			trapos -= 1
			cocteles += 1
			j.huida.gasolina_usada = true
			j.message("Un cóctel incendiario. Se lanza con el botón BENGALA.\nEl fuego es lo único que la mata.", 3.5)
		"latas":
			var d: Dictionary = obj
			latas -= 1
			var nodo := Node3D.new()
			nodo.position = (d.pos as Vector3) + Vector3(0, 2.1, 0)
			m._house.add_child(nodo)
			for k2 in 3:
				m.cyl(0.03, 0.03, 0.09, Vector3(-0.15 + k2 * 0.15, -0.1 - (k2 % 2) * 0.08, 0), m._mat.metal, nodo, 8)
			_latas_puertas.append({"d": d, "nodo": nodo})
			j.message("Latas colgadas. Si alguien cruza esta puerta, lo sabré. (Me quedan %d)" % latas, 2.5)

## Lanzar un cóctel (botón BENGALA). Devuelve true si se lanzó.
func lanzar_coctel() -> bool:
	if cocteles <= 0:
		return false
	cocteles -= 1
	var pp: Vector3 = j.player.global_position
	var mira: Vector3 = j.player.look_dir()
	var hu: ZarekHuida = j.huida
	j.sound_at("rotura_vidrio", pp + mira * 5.0, 4.0)
	var fuego := pp + mira * 5.0
	if hu.madre_suelta and not hu.madre_muerta and is_instance_valid(hu.madre) and hu.madre.visible:
		var to: Vector3 = hu.madre.global_position - pp
		if to.length() < 11.0 and to.normalized().dot(mira) > 0.8:
			hu.quemar_madre_en(hu.madre.global_position)
			return true
	var e: ZarekElena = j.elena
	if e.visible and e.state != ZarekElena.S.DORMANT:
		var to2: Vector3 = e.global_position - pp
		if to2.length() < 11.0 and to2.normalized().dot(mira) > 0.8:
			fuego = e.global_position
			e.aturdir(4.0, "dolor")
			e.repel(pp)
			j.message("¡Arde! Damián grita y se aparta del fuego.", 2.5)
	hu.fuego_en(fuego, 18.0)
	return true

# ---------------- la caja fuerte: teclado de 4 cifras ----------------
var _teclado: CanvasLayer
var _cifras := [0, 0, 0, 0]
func _abrir_teclado() -> void:
	if _teclado:
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_teclado = CanvasLayer.new()
	_teclado.layer = 60
	add_child(_teclado)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.75)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_teclado.add_child(fondo)
	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	caja.position = Vector2(-260, -190)
	caja.custom_minimum_size = Vector2(520, 380)
	caja.add_theme_constant_override("separation", 14)
	_teclado.add_child(caja)
	var tit := Label.new()
	tit.text = "CAJA FUERTE DEL PADRE · día y mes (DD MM)"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 24)
	caja.add_child(tit)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 18)
	caja.add_child(fila)
	var etiquetas: Array[Label] = []
	for i in 4:
		var col := VBoxContainer.new()
		var arriba := Button.new()
		arriba.text = "▲"
		arriba.custom_minimum_size = Vector2(90, 64)
		var lb := Label.new()
		lb.text = str(_cifras[i])
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.add_theme_font_size_override("font_size", 52)
		etiquetas.append(lb)
		var abajo := Button.new()
		abajo.text = "▼"
		abajo.custom_minimum_size = Vector2(90, 64)
		var ii := i
		arriba.pressed.connect(func(): _cifras[ii] = (_cifras[ii] + 1) % 10; etiquetas[ii].text = str(_cifras[ii]); j._click())
		abajo.pressed.connect(func(): _cifras[ii] = (_cifras[ii] + 9) % 10; etiquetas[ii].text = str(_cifras[ii]); j._click())
		col.add_child(arriba)
		col.add_child(lb)
		col.add_child(abajo)
		fila.add_child(col)
		if i == 1:
			var sep := Label.new()
			sep.text = "/"
			sep.add_theme_font_size_override("font_size", 52)
			fila.add_child(sep)
	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 30)
	caja.add_child(botones)
	var abrir := Button.new()
	abrir.text = "GIRAR LA MANIVELA"
	abrir.custom_minimum_size = Vector2(240, 60)
	abrir.pressed.connect(_probar_combinacion)
	var salir := Button.new()
	salir.text = "DEJARLO"
	salir.custom_minimum_size = Vector2(160, 60)
	salir.pressed.connect(_cerrar_teclado)
	botones.add_child(abrir)
	botones.add_child(salir)

func _cerrar_teclado() -> void:
	if _teclado:
		_teclado.queue_free()
		_teclado = null
	if not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func probar(dia: int, mes: int) -> bool:
	if dia == fecha_dia and mes == fecha_mes:
		caja_abierta = true
		j.sound_at("pomo", caja_pos + Vector3(0, 0.5, 0), 2.0)
		j.defensa.escopeta = true
		j.defensa.cartuchos += 2
		j.message("¡Clac! La caja fuerte se abre. Dentro, la escopeta del padre y dos cartuchos.\nNo lo matará. Pero lo tirará al suelo.", 4.5)
		return true
	j.sound_at("pomo_cerrado", caja_pos + Vector3(0, 0.5, 0), 0.0)
	j.oir_ruido(caja_pos, 4.0)
	j.message("La manivela no gira. No es esa fecha.", 2.0)
	return false

func _probar_combinacion() -> void:
	if probar(_cifras[0] * 10 + _cifras[1], _cifras[2] * 10 + _cifras[3]):
		_cerrar_teclado()

# ---------------- mirar por la cerradura ----------------
func _mirar_cerradura(d: Dictionary) -> void:
	if _cerradura_cam:
		return
	var pp: Vector3 = j.player.global_position
	var dp: Vector3 = d.pos
	var dir := Vector3(dp.x - pp.x, 0, dp.z - pp.z).normalized()
	_cerradura_cam = Camera3D.new()
	_cerradura_cam.fov = 55.0
	m.add_child(_cerradura_cam)
	_cerradura_cam.global_position = dp + dir * 0.25 + Vector3(0, 1.0, 0)
	_cerradura_cam.look_at(_cerradura_cam.global_position + dir, Vector3.UP)
	_cerradura_cam.current = true
	_cerradura_capa = CanvasLayer.new()
	_cerradura_capa.layer = 55
	add_child(_cerradura_capa)
	var r := TextureRect.new()
	r.texture = _textura_cerradura()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.stretch_mode = TextureRect.STRETCH_SCALE
	_cerradura_capa.add_child(r)
	j.player.frozen = true
	j.sound_at("pomo", dp + Vector3(0, 1.0, 0), -14.0)
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(_cerradura_cam):
		_cerradura_cam.queue_free()
	_cerradura_cam = null
	if is_instance_valid(_cerradura_capa):
		_cerradura_capa.queue_free()
	_cerradura_capa = null
	j.player.camera.current = true
	if j.state == "juego":
		j.player.frozen = false

var _tex_cerradura: ImageTexture
func _textura_cerradura() -> ImageTexture:
	if _tex_cerradura:
		return _tex_cerradura
	var w := 320
	var h := 180
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var u := (x - w * 0.5) / (h * 0.5)
			var v := (y - h * 0.42) / (h * 0.5)
			# ojo de cerradura antiguo: círculo arriba y trapecio abajo
			var dentro := u * u + v * v < 0.12 or (v > 0.0 and v < 0.75 and absf(u) < 0.12 + v * 0.18)
			img.set_pixel(x, y, Color(0, 0, 0, 0.0 if dentro else 1.0))
	_tex_cerradura = ImageTexture.create_from_image(img)
	return _tex_cerradura

# ---------------- el grifo ----------------
func grifo(pos: Vector3) -> void:
	_grifo_hasta = _t + 30.0
	_grifo_pos = pos

## Cuánto se oyen tus pasos aquí (el grifo abierto los tapa).
func mascara(pp: Vector3) -> float:
	if _t < _grifo_hasta and _grifo_pos != Vector3.INF and pp.distance_to(_grifo_pos) < 10.0:
		return 0.35
	return 1.0

## ¿Está apagada esta lámpara porque faltan los fusibles del sótano?
func sin_luz_sotano(l: Dictionary) -> bool:
	return not fusibles_puestos and m.level_of((l.pos as Vector3).y - 1.0) == -1
