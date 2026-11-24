class_name ZarekSupervivencia
extends Node
## Lo que hace sentir que sobrevives de verdad (todo explicado con consejos la primera vez y en el DIARIO):
## - BOLSILLOS: solo caben 4 cosas (la rueda ocupa 2). Lo que no cabe se deja en el suelo desde el DIARIO → BOLSILLOS.
##   Lo que se gasta deja hueco (la llave del cuarto al abrirlo, la cizalla al cortar el portón, la gasolina…).
## - DAMIÁN CONOCE SU CASA: una puerta que estaba cerrada y ahora está abierta, una luz encendida o un cajón abierto
##   le hacen pararse y buscar por ahí. Si lo dejas como estaba, no nota nada.
## - EMPUJAR MUEBLES: una silla, una mesa o una caja pesada contra una puerta cerrada la bloquea (él la aporrea).
## - VELAS Y CERILLAS: luz sin pilas; la madre no se acerca a la llama… pero Damián la ve de lejos.
## - LA HERIDA DEL TOBILLO: la argolla te lo dejó en carne viva; al correr cojeas y dejas gotas de sangre que él
##   sigue. Se cura vendándolo con un trapo.
## - MIRAR POR LAS VENTANAS: ves el jardín (y si Damián anda fuera).

var j: Node  # ZarekJuego
var m: ZarekMansion
var huecos := 4

# velas
var velas := 0
var cerillas := 0
var vela_encendida := 0.0
var _luz_vela: OmniLight3D
var items: Array = []

# herida
var herida := true
var _t_gota := 0.0
var gotas: Array = []          # posiciones de sangre (él las sigue)

# cambios que nota Damián
var _ini_puertas := {}
var _ini_luces := {}
var _notados := {}
var _t_revisa := 0.0
var _t := 0.0

# acciones mantenidas
var hold_kind := ""
var hold_t := 0.0
var hold_obj = null

func preparar(mansion: ZarekMansion) -> void:
	m = mansion
	var rng := RandomNumberGenerator.new()
	rng.seed = m.partida_seed + 99
	ZarekTerror._rng.seed = m.partida_seed + 1313
	for x in [["vela", ["Capilla de la madre", "Comedor formal", "Sala de música", "Tocador de la madre", "Dormitorio de los padres"], 2],
			["cerillas", ["Cocina", "Salón con chimenea", "Sala de fumar y billar", "Despensa"], 1]]:
		var salas: Array = (x[1] as Array).duplicate()
		salas.shuffle()
		var puestos := 0
		for nombre in salas:
			if puestos >= int(x[2]):
				break
			var r := m._sala_por_nombre(nombre)
			if r.is_empty():
				continue
			var p := ZarekTerror._sitio_libre(m, r, 0.5)
			if p == Vector3.INF:
				continue
			items.append({"pos": p, "kind": x[0], "node": _modelo(String(x[0]), p), "taken": false})
			puestos += 1
	_luz_vela = OmniLight3D.new()
	_luz_vela.light_color = Color(1.0, 0.62, 0.3)
	_luz_vela.omni_range = 4.5
	_luz_vela.light_energy = 0.0
	_luz_vela.shadow_enabled = false
	add_child(_luz_vela)

## Lo de la casa tal como está al empezar (para saber qué has cambiado).
func foto_inicial() -> void:
	for d in m.doors:
		_ini_puertas[str(d.pos)] = d.open
	for l in m.lamps:
		_ini_luces[str(l.pos)] = l.on

func _modelo(kind: String, p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = p
	m._house.add_child(n)
	if m.objeto_real("s_vela" if kind == "vela" else "s_cerillas", n, Vector3.ZERO, randf() * TAU) != null:
		return n
	if kind == "vela":
		m.cyl(0.025, 0.025, 0.16, Vector3(0, 0.08, 0), m._plain(Color(0.9, 0.86, 0.75), 0.6), n, 10)
		m.cyl(0.05, 0.06, 0.02, Vector3(0, 0.01, 0), m._mat.laton_viejo, n, 12)
	else:
		m.box(Vector3(0.06, 0.015, 0.035), Vector3(0, 0.008, 0), m._plain(Color(0.6, 0.12, 0.08), 0.7), false, n, false)
	return n

# ---------------- bolsillos ----------------
## Lo que llevo encima, con lo que ocupa cada cosa. [{id, nombre, peso}]
func bolsillos() -> Array:
	var b: Array = []
	var hu: ZarekHuida = j.huida
	for s in m.seals:
		if s.taken and not s.get("gastado", false):
			var t := String(s.tipo)
			if t == "gasolina" and hu.gasolina_usada:
				continue
			b.append({"id": "sello", "obj": s, "nombre": String(ZarekMansion.NOMBRE_OBJETO.get(t, t)), "peso": 2 if t == "rueda" else 1})
	if hu.tiene.get("llaves_camioneta", false):
		b.append({"id": "llaves", "nombre": "las llaves de la camioneta", "peso": 1})
	var it: ZarekInteraccion = j.inter
	if it.botellas > 0: b.append({"id": "botella", "nombre": "botella vacía" + (" ×%d" % it.botellas if it.botellas > 1 else ""), "peso": it.botellas})
	if it.trapos > 0: b.append({"id": "trapo", "nombre": "trapo", "peso": it.trapos})
	if it.cocteles > 0: b.append({"id": "coctel", "nombre": "cóctel incendiario ×%d" % it.cocteles, "peso": it.cocteles})
	if it.latas > 0: b.append({"id": "latas", "nombre": "latas con cordel (%d)" % it.latas, "peso": 1})
	if it.palanca: b.append({"id": "palanca", "nombre": "palanca", "peso": 1})
	if it.fusibles: b.append({"id": "fusibles", "nombre": "fusibles", "peso": 1})
	if velas > 0: b.append({"id": "vela", "nombre": "vela" + (" ×%d" % velas if velas > 1 else ""), "peso": velas})
	if cerillas > 0: b.append({"id": "cerillas", "nombre": "cerillas (%d)" % cerillas, "peso": 1})
	return b

func ocupado() -> int:
	var n := 0
	for x in bolsillos():
		n += int(x.peso)
	return n

## ¿Cabe algo más? Si no, lo avisa.
func cabe(peso := 1) -> bool:
	if ocupado() + peso <= huecos:
		return true
	j.message("No me cabe nada más en los bolsillos (%d/%d).\nPuedo dejar algo en el suelo: DIARIO → BOLSILLOS." % [ocupado(), huecos], 3.0)
	j._consejo("bolsillos", "Solo puedes llevar 4 cosas (la rueda ocupa 2). En el DIARIO, pestaña BOLSILLOS, puedes dejar algo en el suelo y volver luego a por ello.")
	return false

## Dejar algo en el suelo (desde el diario).
func dejar(x: Dictionary) -> void:
	var pp: Vector3 = j.player.global_position + j.player.forward() * 0.6
	pp.y = j.player.global_position.y
	var it: ZarekInteraccion = j.inter
	match String(x.id):
		"sello":
			var s: Dictionary = x.obj
			s.taken = false
			s.pos = pp
			j.huida.tiene.erase(String(s.tipo))
			var n := s.node as Node3D
			n.visible = true
			n.scale = Vector3.ONE
			n.global_position = pp + Vector3(0, 0.02, 0)
		"llaves":
			j.huida.tiene.erase("llaves_camioneta")
			for k in m.pickups:
				if k.kind == "llaves":
					k.taken = false
					k.pos = pp
					(k.item as Node3D).visible = true
					(k.item as Node3D).scale = Vector3.ONE
					(k.item as Node3D).global_position = pp + Vector3(0, 0.02, 0)
		"botella", "trapo", "palanca", "fusibles", "latas":
			match String(x.id):
				"botella": it.botellas -= 1
				"trapo": it.trapos -= 1
				"palanca": it.palanca = false
				"fusibles": it.fusibles = false
				"latas": it.latas = 0
			it.items.append({"pos": pp, "kind": String(x.id), "node": it._modelo(String(x.id), pp), "taken": false})
		"coctel":
			j.message("Un cóctel no se deja por ahí: podría romperse.", 2.0)
			return
		"vela":
			velas -= 1
			items.append({"pos": pp, "kind": "vela", "node": _modelo("vela", pp), "taken": false})
		"cerillas":
			items.append({"pos": pp, "kind": "cerillas", "node": _modelo("cerillas", pp), "taken": false, "usos": cerillas})
			cerillas = 0
	j.sound_at("impacto_tela", pp, -10.0)
	j.message("Lo dejo aquí: %s. Lo apunto para volver." % String(x.nombre), 2.0)

# ---------------- cada fotograma ----------------
func tick(delta: float) -> void:
	if m == null:
		return
	_t += delta
	var pp: Vector3 = j.player.global_position
	_vela(delta, pp)
	_herida(delta, pp)
	_t_revisa -= delta
	if _t_revisa <= 0.0:
		_t_revisa = 0.5
		_cambios()
	_hold_tick(delta, pp)

# ---------------- la vela ----------------
func _vela(delta: float, pp: Vector3) -> void:
	if vela_encendida > 0.0:
		vela_encendida -= delta
		_luz_vela.global_position = pp + Vector3(0, 1.3, 0) + j.player.forward() * 0.35
		_luz_vela.light_energy = 1.4 * (0.85 + 0.15 * sin(_t * 17.0) * sin(_t * 7.0))
		j.player.set_meta("vela", true)
		if vela_encendida <= 0.0:
			_luz_vela.light_energy = 0.0
			j.player.set_meta("vela", false)
			j.message("La vela se ha consumido.", 2.0)
	# con la madre suelta: no se acerca a la llama
	var hu: ZarekHuida = j.huida
	if vela_encendida > 0.0 and hu.madre_suelta and is_instance_valid(hu.madre) and hu.madre.visible \
			and hu.madre.state == ZarekElena.S.CHASE and hu.madre.global_position.distance_to(pp) < 4.0:
		hu.madre.repel(pp)

## Encender una vela (botón LUZ cuando la linterna no tiene pilas). Devuelve true si se encendió.
func encender_vela() -> bool:
	if vela_encendida > 0.0:
		vela_encendida = 0.0
		_luz_vela.light_energy = 0.0
		j.player.set_meta("vela", false)
		j.message("Apago la vela de un soplo.", 1.5)
		return true
	var con_mechero: bool = j.ast != null and j.ast.mechero
	if velas <= 0 or (cerillas <= 0 and not con_mechero):
		return false
	velas -= 1
	if not con_mechero:
		cerillas -= 1
	vela_encendida = 120.0
	j.player.set_meta("vela", true)
	j.sound_at("cerilla", j.player.global_position + Vector3(0, 1.2, 0), -6.0)
	j.message("Enciendo una vela. A ella no le gusta el fuego… pero a él le dice dónde estoy.", 3.0)
	return true

# ---------------- la herida del tobillo ----------------
func _herida(delta: float, pp: Vector3) -> void:
	if not herida or j.huida.encadenada or j.state != "juego":
		return
	if j.player.running and j.player.moving > 0.5:
		j.player.speed_mult = minf(j.player.speed_mult, 0.82)
		_t_gota -= delta
		if _t_gota <= 0.0:
			_t_gota = 1.6
			var g := pp + Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.2, 0.2))
			ZarekGore._charco(m, g, 0.18)
			gotas.append(g)
			if gotas.size() > 40:
				gotas.remove_at(0)
			j._consejo("herida", "La argolla te dejó el tobillo herido: al correr cojeas y dejas gotas de sangre que Damián puede seguir. Véndalo con un trapo (MANTÉN USAR con un trapo en los bolsillos).")
	# Damián sigue el rastro si pasa por encima
	var e: ZarekElena = j.elena
	if e.visible and e.state in [ZarekElena.S.WANDER, ZarekElena.S.SEARCH]:
		for g in gotas:
			if (g as Vector3).distance_to(e.global_position) < 1.2:
				gotas.erase(g)
				var hacia := (pp - (g as Vector3))
				e.last_seen = (g as Vector3) + hacia.normalized() * minf(hacia.length(), 8.0)
				e.set_state(ZarekElena.S.INVESTIGATE, 10.0)
				ZarekSonido.en(m, "damian_olfatea", e.global_position + Vector3(0, 1.6, 0), 0.0, 25.0)
				break

# ---------------- Damián nota los cambios ----------------
func _cambios() -> void:
	var e: ZarekElena = j.elena
	if _ini_puertas.is_empty() or not e.visible or e.state == ZarekElena.S.DORMANT:
		return
	var ep := e.global_position
	# lo que cambia él mismo (abre puertas al pasar, apaga salas) pasa a ser «lo normal»
	for d in m.doors:
		if (d.pos as Vector3).distance_to(ep) < 2.5:
			_ini_puertas[str(d.pos)] = d.open
	var rid := m.room_at(ep)
	if rid >= 0:
		for l in m.rooms[rid].get("lamps", []):
			_ini_luces[str(l.pos)] = l.on
	if not (e.state in [ZarekElena.S.WANDER, ZarekElena.S.SEARCH]):
		return
	var pista := Vector3.INF
	var que := ""
	for d in m.doors:
		var k := str(d.pos)
		var dp: Vector3 = d.pos
		if dp.distance_to(ep) < 7.0 and absf(dp.y - ep.y) < 2.0 and _ini_puertas.has(k) and bool(_ini_puertas[k]) != bool(d.open) and _t - float(_notados.get(k, -99.0)) > 40.0:
			_notados[k] = _t
			pista = dp
			que = "una puerta que no estaba así"
			break
	if pista == Vector3.INF:
		for l in m.lamps:
			var k := str(l.pos)
			var lp: Vector3 = l.pos
			if lp.distance_to(ep) < 18.0 and absf(lp.y - ep.y) < 3.0 and l.on and _ini_luces.has(k) and not bool(_ini_luces[k]) and _t - float(_notados.get(k, -99.0)) > 40.0:
				_notados[k] = _t
				pista = lp - Vector3(0, 2.0, 0)
				que = "una luz encendida"
				break
	if pista == Vector3.INF:
		for x in j.muebles_reg:
			var k := "c" + str(x.pos)
			var xp: Vector3 = x.pos
			if x.hecho and xp.distance_to(ep) < 6.0 and absf(xp.y - ep.y) < 2.0 and not _notados.has(k):
				_notados[k] = _t
				pista = xp
				que = "un cajón abierto"
				break
	if pista == Vector3.INF:
		return
	e.last_seen = pista
	e.set_state(ZarekElena.S.INVESTIGATE, 12.0)
	ZarekSonido.en(m, "damian_gruñe", ep + Vector3(0, 1.6, 0), 0.0, 30.0, 0.85)
	if j.player.global_position.distance_to(ep) < 25.0:
		j.message("Damián se ha parado: ha visto %s. Sabe que alguien ha pasado por aquí." % que, 3.0)
	if que == "una luz encendida":
		j._consejo("luz_cebo", "Las luces son un cebo: si enciendes una sala lejos de ti, Damián la ve desde lejos y va a mirar. Apágala después o sabrá que alguien anda por ahí.")
	j._consejo("cambios", "Damián conoce su casa: si deja una puerta cerrada y la encuentra abierta, ve una luz encendida o un cajón abierto, viene a buscar por ahí. Deja las cosas como estaban.")

# ---------------- qué se puede hacer aquí ----------------
func objetivo(pp: Vector3) -> Dictionary:
	for it in items:
		if not it.taken and Vector2(pp.x - it.pos.x, pp.z - it.pos.z).length() < 1.4 and absf(pp.y - (it.pos as Vector3).y) < 1.6:
			return {"kind": "sup", "que": "coger", "obj": it, "text": "USAR: coger " + ("una vela" if it.kind == "vela" else "la caja de cerillas")}
	# ventana: mirar fuera
	for w in m.ventanas_info:
		if w.get("tapiada", false) and not w.get("abierta", false):
			continue
		var c: Vector3 = w.c
		if (w.inward as Vector3) == Vector3.ZERO:
			continue
		var dentro := c + (w.inward as Vector3) * 0.7
		if Vector2(pp.x - dentro.x, pp.z - dentro.z).length() < 1.1 and absf(pp.y - c.y) < 1.5 and j.player.look_dir().dot(-(w.inward as Vector3)) > 0.6:
			return {"kind": "sup", "que": "ventana", "obj": w, "text": "USAR: asomarme a la ventana"}
	# un mueble pesado cerca de una puerta cerrada: empujarlo contra ella
	var d: Dictionary = m.door_near(pp + j.player.forward() * 0.6, 1.8)
	if not d.is_empty() and not d.open and float(d.get("barricada", 0.0)) <= 0.0 and not d.locked:
		var mueble := _mueble_cerca(pp)
		if mueble:
			return {"kind": "hold_sup", "que": "empujar", "obj": [d, mueble], "text": "MANTÉN USAR: empujar el mueble contra la puerta"}
	if herida and j.inter.trapos > 0 and not j.huida.encadenada:
		return {"kind": "hold_sup", "que": "vendar", "text": "MANTÉN USAR: vendarme el tobillo con el trapo", "debil": true}
	return {}

func _mueble_cerca(pp: Vector3) -> RigidBody3D:
	var mejor: RigidBody3D = null
	var md := 2.6
	for n in j.huida.fisicos:
		if not is_instance_valid(n):
			continue
		var rb := n as RigidBody3D
		if rb.mass < 5.5 or rb.freeze:
			continue
		var dd := rb.global_position.distance_to(pp)
		if dd < md and absf(rb.global_position.y - pp.y) < 1.5:
			md = dd
			mejor = rb
	return mejor

func usar(t: Dictionary) -> void:
	match String(t.que):
		"coger":
			var it: Dictionary = t.obj
			if not cabe():
				return
			it.taken = true
			j._a_la_mano(it.node)
			if it.kind == "vela":
				velas += 1
				j.message("Una vela. Si se acaban las pilas, con una cerilla me dará luz (botón LUZ).", 3.0)
			else:
				cerillas += int(it.get("usos", 5))
				j.message("Una caja de cerillas (%d). Con una vela, luz sin pilas." % cerillas, 3.0)
			j._consejo("vela", "Velas y cerillas: si la linterna se queda sin pilas, el botón LUZ enciende una vela (dura 2 minutos). La madre no se acerca a la llama; Damián la ve de lejos.")
		"ventana":
			_asomarse(t.obj)

func empezar_hold(t: Dictionary) -> void:
	hold_kind = String(t.que)
	hold_obj = t.get("obj", null)
	hold_t = 0.0

const DUR := {"empujar": 1.6, "vendar": 3.0}
func _hold_tick(delta: float, pp: Vector3) -> void:
	if hold_kind == "":
		return
	var sigue: bool = Input.is_action_pressed("usar") and j.state == "juego" and str(objetivo(pp).get("que", "")) == hold_kind
	if not sigue:
		hold_kind = ""
		j.bar_rit.visible = false
		return
	hold_t += delta
	var dur: float = DUR.get(hold_kind, 2.0)
	j.bar_rit.visible = true
	j.bar_rit.value = hold_t / dur * 100.0
	if hold_t >= dur:
		var k := hold_kind
		hold_kind = ""
		j.bar_rit.visible = false
		completar(k, hold_obj)

func completar(k: String, obj = null) -> void:
	match k:
		"empujar":
			var d: Dictionary = obj[0]
			var rb: RigidBody3D = obj[1]
			var pp: Vector3 = j.player.global_position
			var dp: Vector3 = d.pos
			var lado := Vector3(pp.x - dp.x, 0, pp.z - dp.z).normalized()
			rb.freeze = true
			var destino := dp + lado * 0.65
			destino.y = rb.global_position.y
			var tw := rb.create_tween()
			tw.tween_property(rb, "global_position", destino, 0.5)
			d["barricada"] = 9.0
			d["mueble"] = rb
			j.sound_at("impacto_mueble", dp, 0.0)
			j.oir_ruido(pp, 6.0)
			j.message("Mueble contra la puerta. No la abrirá sin hacer ruido… y le costará.", 2.5)
			j._consejo("mueble", "Puedes empujar sillas, mesas y cajas pesadas contra una puerta cerrada para bloquearla. Damián la aporreará hasta apartarlas: te da tiempo, y le oyes venir.")
		"vendar":
			herida = false
			j.inter.trapos -= 1
			j.message("Me vendo el tobillo con el trapo. Ya no sangra, y puedo correr sin cojear.", 3.0)

# ---------------- asomarse a una ventana ----------------
var _cam_ventana: Camera3D
func _asomarse(w: Dictionary) -> void:
	if _cam_ventana:
		return
	var c: Vector3 = w.c
	var fuera: Vector3 = -(w.inward as Vector3)
	_cam_ventana = Camera3D.new()
	_cam_ventana.fov = 70.0
	m.add_child(_cam_ventana)
	_cam_ventana.global_position = c + fuera * 0.05 + Vector3(0, 1.6, 0)
	_cam_ventana.look_at(_cam_ventana.global_position + fuera + Vector3(0, -0.25, 0), Vector3.UP)
	_cam_ventana.current = true
	j.player.frozen = true
	var e: ZarekElena = j.elena
	var txt := "El jardín, a oscuras. No se mueve nada."
	if e.visible and e.state != ZarekElena.S.DORMANT and not m.inside_house(e.global_position):
		txt = "Ahí fuera… una silueta enorme con un hacha camina entre los setos."
	elif e.visible and e.state != ZarekElena.S.DORMANT:
		txt = "El jardín está vacío. Entonces él está dentro de la casa."
	j.message(txt, 3.0)
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(_cam_ventana):
		_cam_ventana.queue_free()
	_cam_ventana = null
	j.player.camera.current = true
	if j.state == "juego":
		j.player.frozen = false
