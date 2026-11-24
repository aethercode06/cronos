class_name ZarekSigilo
extends Node
## Tanda 4: moverse sin ruido (todo con su porqué, un consejo la primera vez y en el DIARIO):
## - LAS TRAMPAS DE DAMIÁN: él caza en su casa. Cables con campanillas a ras de suelo en algunos umbrales (si los
##   rozas, suenan y viene; agachada pasas por encima) y cepos escondidos entre la basura (te atrapan el pie: hay
##   que abrirlos manteniendo USAR, gritas y te deja herida). Con la linterna se ven a tiempo; se pueden desarmar.
## - ROMPER UNA VENTANA para salir al jardín: rápido, pero lo oye toda la casa (y a ella le enfurece) y, sin un arma
##   para golpear el cristal, te cortas.
## (Abrir puertas despacio y las escaleras que crujen están en juego.gd: `_puerta_tick` y `_on_step`.)

var j: Node  # ZarekJuego
var m: ZarekMansion

var campanas: Array = []   # {a, b, nodo, sonada}
var cepos: Array = []      # {pos, nodo, armado, visto}
var atrapada := false
var _t_atrapada := 0.0
var _cepo_actual: Dictionary = {}

# acciones mantenidas
var hold_kind := ""
var hold_t := 0.0
var hold_obj = null

func preparar(mansion: ZarekMansion, dif: int) -> void:
	m = mansion
	var rng := RandomNumberGenerator.new()
	rng.seed = m.partida_seed + 555
	ZarekTerror._rng.seed = m.partida_seed + 556
	_campanas(rng, [2, 3, 4][clampi(dif, 0, 2)])
	_cepos(rng, [2, 3, 4][clampi(dif, 0, 2)])

# ---------------- cables con campanillas en los umbrales ----------------
func _campanas(rng: RandomNumberGenerator, n: int) -> void:
	var cand: Array = []
	for d in m.doors:
		if d.locked or d.has("celda") or d.has("pivot2") or String(d.get("llave", "")) != "":
			continue
		var p: Vector3 = d.pos
		var lv := m.level_of(p.y + 0.5)
		if lv < 0 or lv > 1 or not m.inside_house(p):
			continue
		if p.distance_to(j.huida.ancla) < 8.0:
			continue  # no junto a la celda del principio
		cand.append(d)
	cand.shuffle()
	for d in cand.slice(0, n):
		var b := float(d.base)
		var eje := Vector3(cos(b), 0, -sin(b))
		var pc: Vector3 = d.pos
		pc.y = float(m.lvl_y(m.level_of(pc.y + 0.5)))
		var a := pc - eje * 0.62 + Vector3(0, 0.16, 0)
		var c := pc + eje * 0.62 + Vector3(0, 0.16, 0)
		var nodo := Node3D.new()
		nodo.set_meta("dyn", true)
		m._house.add_child(nodo)
		var hilo := m.cyl(0.0035, 0.0035, 1.24, (a + c) * 0.5, m._plain(Color(0.55, 0.5, 0.42), 0.6), nodo, 4)
		hilo.look_at_from_position((a + c) * 0.5, c, Vector3.UP)
		hilo.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		for k in 3:
			var cp := a.lerp(c, 0.25 + k * 0.25) + Vector3(0, -0.04, 0)
			var bell := m.objeto_real("s_campanilla", nodo, Vector3.ZERO, rng.randf() * TAU, cp)
			if bell == null:
				m.cyl(0.012, 0.022, 0.035, cp, m._mat.laton_viejo, nodo, 8)
		# clavos a los lados donde se ata
		for e in [a, c]:
			m.cyl(0.006, 0.006, 0.05, e, m._mat.hierro, nodo, 5).rotation.z = PI * 0.5
		campanas.append({"a": a, "b": c, "nodo": nodo, "sonada": false, "d": d})

# ---------------- cepos escondidos ----------------
func _cepos(rng: RandomNumberGenerator, n: int) -> void:
	var salas: Array = []
	for r in m.rooms:
		var lv := m.level_of(float(r.y) + 0.5)
		if lv < -1 or lv > 2 or String(r.name) in ["Cuarto de huéspedes", "Capilla de la madre"] or not m.inside_house(Vector3((r.rect as Rect2).get_center().x, float(r.y), (r.rect as Rect2).get_center().y)):
			continue
		salas.append(r)
	salas.shuffle()
	for r in salas:
		if cepos.size() >= n:
			break
		var p := ZarekTerror._sitio_libre(m, r, 0.6)
		if p == Vector3.INF or p.distance_to(j.huida.ancla) < 8.0:
			continue
		var nodo: Node3D = _modelo_cepo(p, rng.randf() * TAU)
		# medio tapado: hojas secas y trapos alrededor
		for k in 3:
			var hoja := m.box(Vector3(rng.randf_range(0.15, 0.3), 0.01, rng.randf_range(0.1, 0.22)), Vector3(rng.randf_range(-0.2, 0.2), 0.02, rng.randf_range(-0.2, 0.2)), m._plain(Color(0.22, 0.17, 0.1), 0.95), false, nodo, false)
			hoja.rotation.y = rng.randf() * TAU
		cepos.append({"pos": p, "nodo": nodo, "armado": true, "visto": false})

func _modelo_cepo(p: Vector3, yaw: float) -> Node3D:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = yaw
	n.set_meta("dyn", true)
	m._house.add_child(n)
	var real := m.objeto_real("s_cepo", n, Vector3.ZERO, 0.0)
	if real == null:
		n.queue_free()
		return ZarekGore.cepo(m, p, false, yaw)
	# el modelo viene sin textura: hierro oxidado
	var oxido := m._plain(Color(0.33, 0.22, 0.15), 0.55, 0.75)
	for mi in real.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = oxido
	return n

# ---------------- qué se puede hacer aquí ----------------
func objetivo(pp: Vector3) -> Dictionary:
	if atrapada:
		return {"kind": "hold_sig", "que": "abrir_cepo", "text": "MANTÉN USAR: abrir el cepo con las manos"}
	for cp in cepos:
		if cp.armado and Vector2(pp.x - cp.pos.x, pp.z - cp.pos.z).length() < 1.3 and absf(pp.y - (cp.pos as Vector3).y) < 1.0 and cp.visto:
			return {"kind": "hold_sig", "que": "desarmar", "obj": cp, "text": "MANTÉN USAR: desarmar el cepo (me lo quedo)"}
	for w in m.ventanas_info:
		if w.get("tapiada", false) or w.get("abierta", false) or w.get("rota", false):
			continue
		var c: Vector3 = w.c
		var inward: Vector3 = w.inward
		if inward == Vector3.ZERO or m.level_of(c.y + 0.3) != 0:
			continue
		var dentro := c + inward * 0.7
		if Vector2(pp.x - dentro.x, pp.z - dentro.z).length() < 1.1 and absf(pp.y - c.y) < 1.5 and j.player.look_dir().dot(-inward) > 0.6:
			return {"kind": "hold_sig", "que": "romper", "obj": w, "text": "USAR: asomarme · MANTÉN USAR: romper el cristal para salir (mucho ruido)"}
	return {}

func empezar_hold(t: Dictionary) -> void:
	hold_kind = String(t.que)
	hold_obj = t.get("obj", null)
	hold_t = 0.0

const DUR := {"abrir_cepo": 2.5, "desarmar": 2.0, "romper": 1.4}
func _hold_tick(delta: float, pp: Vector3) -> void:
	if hold_kind == "":
		return
	var sigue: bool = Input.is_action_pressed("usar") and j.state == "juego" and str(objetivo(pp).get("que", "")) == hold_kind
	if not sigue:
		if hold_kind == "romper" and hold_t < 0.4 and hold_obj is Dictionary:
			j.sup._asomarse(hold_obj)  # un toque: asomarse, como en cualquier ventana
		hold_kind = ""
		j.bar_rit.visible = false
		return
	hold_t += delta
	var dur: float = DUR.get(hold_kind, 2.0)
	if hold_t > 0.4 or hold_kind != "romper":
		j.bar_rit.visible = true
		j.bar_rit.value = hold_t / dur * 100.0
	if hold_t >= dur:
		var k := hold_kind
		hold_kind = ""
		j.bar_rit.visible = false
		completar(k, hold_obj)

func completar(k: String, obj = null) -> void:
	var pp: Vector3 = j.player.global_position
	match k:
		"abrir_cepo":
			_soltar()
		"desarmar":
			var cp: Dictionary = obj
			cp.armado = false
			if is_instance_valid(cp.nodo):
				(cp.nodo as Node3D).queue_free()
			j.defensa.cepos += 1
			j.sound_at("llaves", (cp.pos as Vector3) + Vector3(0, 0.3, 0), -6.0)
			j.message("Desarmado. Ahora es mío: puedo ponérselo a él en el camino.", 2.5)
		"romper":
			var w: Dictionary = obj
			w["rota"] = true
			var c: Vector3 = w.c
			var dentro: Vector3 = w.inward
			j.sound_at("rotura_vidrio" if ZarekSonido.hay("rotura_vidrio") else "vidrio", c + Vector3(0, 1.5, 0), 6.0)
			j.elena.hear(c, 999.0)
			j.huida.subir_furia(6.0, "ventana")
			j.player.shake(5.0)
			# el cristal desaparece y quedan trozos en el suelo
			for b in m.find_children("*", "MeshInstance3D", false, false):
				pass
			_quitar_cristal(c)
			for k2 in 6:
				m.cristales.append(c + dentro * randf_range(0.2, 1.0) + Vector3(randf_range(-0.6, 0.6), 0, 0) * (1.0 if bool(w.horiz) else 0.0) + Vector3(0, 0, randf_range(-0.6, 0.6)) * (0.0 if bool(w.horiz) else 1.0))
			var a := c + dentro * 0.9
			var b2 := c - dentro * 1.3
			m.portals.append({"pos": a, "to": b2, "text": "saltar por la ventana rota al jardín"})
			m.portals.append({"pos": b2, "to": a, "text": "entrar por la ventana rota"})
			var lk := NavigationLink3D.new()
			lk.start_position = a
			lk.end_position = b2
			m.add_child(lk)
			if j.defensa.arma != "":
				j.message("Reviento el cristal con el arma. ¡Lo ha oído toda la casa!\nPor aquí puedo salir al jardín.", 3.0)
			else:
				j.sup.herida = true
				j.sanity = maxf(0.0, j.sanity - 6.0)
				j.message("Rompo el cristal con el codo… me corto el brazo. ¡Lo ha oído toda la casa!\nPor aquí puedo salir al jardín.", 3.5)
			j._consejo("romper", "Romper una ventana te abre un camino al jardín al momento, pero Damián lo oye desde cualquier parte y la madre se enfurece. Sin un arma para golpear, te cortas.")

func _quitar_cristal(c: Vector3) -> void:
	# el cristal de la ventana es una caja con el material de cristal a 1,9 m sobre el centro
	for n in m.get_children():
		var mi := n as MeshInstance3D
		if mi and mi.global_position.distance_to(c + Vector3(0, 1.9, 0)) < 0.2:
			mi.visible = false
			for h in mi.get_children():
				if h is StaticBody3D:
					h.queue_free()
			return

# ---------------- cada fotograma ----------------
func tick(delta: float) -> void:
	if m == null:
		return
	var pp: Vector3 = j.player.global_position
	_hold_tick(delta, pp)
	if j.state != "juego":
		return
	var lint: bool = j.flash_on and j.battery > 0.0
	# campanillas: rozarlas sin agacharse
	for cb in campanas:
		if cb.sonada:
			continue
		var a: Vector3 = cb.a
		var b: Vector3 = cb.b
		if absf(pp.y - a.y + 0.16) > 1.0:
			continue
		var d := Geometry3D.get_closest_point_to_segment(Vector3(pp.x, a.y, pp.z), a, b).distance_to(Vector3(pp.x, a.y, pp.z))
		if d < 0.9 and lint and not cb.has("aviso"):
			cb["aviso"] = true
			j._consejo("campanas", "Damián pone cables con campanillas a ras de suelo en algunas puertas. Si los rozas, suenan y viene. AGACHADA pasas por encima sin tocarlos.")
		if d < 0.3:
			if j.player.crouching:
				if not cb.has("pasada"):
					cb["pasada"] = true
					j.message("Paso por encima del cable con cuidado. Las campanillas ni se mueven.", 2.2)
				continue
			cb.sonada = true
			j.sound_at("campana", (a + b) * 0.5 + Vector3(0, 0.2, 0), 4.0)
			j.elena.hear((a + b) * 0.5, 999.0)
			j.message("¡Las campanillas! He tropezado con un cable. Él lo ha oído.", 2.5)
			j._consejo("campanas", "Damián pone cables con campanillas a ras de suelo en algunas puertas. Si los rozas, suenan y viene. AGACHADA pasas por encima sin tocarlos.")
			if is_instance_valid(cb.nodo):
				var tw: Tween = (cb.nodo as Node3D).create_tween()
				tw.tween_property(cb.nodo, "position:y", -0.12, 0.25)
	# cepos: se ven con la linterna de cerca; pisarlos te atrapa
	for cp in cepos:
		if not cp.armado:
			continue
		var cpp: Vector3 = cp.pos
		var dd := Vector2(pp.x - cpp.x, pp.z - cpp.z).length()
		if absf(pp.y - cpp.y) > 1.0:
			continue
		if not cp.visto and dd < 3.0 and lint and j._in_view(cpp):
			cp.visto = true
			j.message("Algo brilla entre la basura del suelo… dientes de metal. Un cepo.", 2.5)
			j._consejo("cepos", "Damián esconde cepos entre la basura del suelo. Con la linterna se ven brillar. Si pisas uno, te atrapa el pie: MANTÉN USAR para abrirlo. Puedes desarmarlos y quedártelos.")
		if dd < 0.32 and not atrapada:
			_atrapar(cp)
	if atrapada:
		_t_atrapada += delta
		j.player.velocity = Vector3.ZERO
		if j.has_meta("bot") and _t_atrapada > 3.0:
			_soltar()

func _atrapar(cp: Dictionary) -> void:
	cp.armado = false
	atrapada = true
	_t_atrapada = 0.0
	_cepo_actual = cp
	j.player.frozen = true
	j.sound_at("cepo_salta" if ZarekSonido.hay("cepo_salta") else "golpe_madera", (cp.pos as Vector3) + Vector3(0, 0.2, 0), 4.0)
	j.sound_at("grito", j.player.global_position + Vector3(0, 1.5, 0), 0.0)
	j.elena.hear(cp.pos, 999.0)
	j.player.shake(12.0)
	Aether.flash(Color(0.6, 0.05, 0.05), 0.3)
	j.sup.herida = true
	j.sanity = maxf(0.0, j.sanity - 10.0)
	j.message("¡AAAH! ¡Un cepo! Me ha atrapado el pie. ¡Tengo que abrirlo YA!", 3.0)
	j._consejo("cepos", "Damián esconde cepos entre la basura del suelo. Con la linterna se ven brillar. Si pisas uno, te atrapa el pie: MANTÉN USAR para abrirlo. Puedes desarmarlos y quedártelos.")

func _soltar() -> void:
	atrapada = false
	j.player.frozen = false
	if not _cepo_actual.is_empty() and is_instance_valid(_cepo_actual.nodo):
		j.sound_at("llaves", (_cepo_actual.pos as Vector3) + Vector3(0, 0.3, 0), -4.0)
	_cepo_actual = {}
	j.message("Abro los dientes del cepo y saco el pie. Sangra.", 2.0)
