class_name ZarekDefensa
extends Node
## Defenderse sin dejar de ser vulnerable: nada mata a Damián, solo compra unos segundos.
## - ARMA DE MANO (atizador, cuchillo, martillo): una sola a la vez. Si te atrapa, FORCEJEO: machaca USAR y se la
##   clavas; huye herido y el arma se pierde. Cada herida le enseña a cubrirse (el siguiente forcejeo es más duro).
## - OBJETOS LANZADOS (botellas, sillas…): si le dan, lo aturden un momento.
## - TRAMPA DE CAZA: se pone en el suelo; si la pisa, se queda atrapado unos segundos rugiendo.
## - ESCOPETA DE JULIÁN: aparece solo algunas noches, con uno o dos cartuchos. Lo derriba un buen rato, pero el
##   disparo se oye en toda la casa y después vuelve furioso.

const ARMAS := {
	"atizador": {"nombre": "el atizador", "rompe": "El atizador se quedó doblado dentro de él.", "modelo": "w_atizador"},
	"cuchillo": {"nombre": "el cuchillo de cocina", "rompe": "El cuchillo se quedó clavado en su hombro.", "modelo": "w_cuchillo"},
	"martillo": {"nombre": "el martillo", "rompe": "Le partí algo con el martillo. El mango se rompió.", "modelo": "w_martillo"},
}
## Dónde puede haber un arma a la vista (sala → arma).
const A_LA_VISTA := [["Salón con chimenea", "atizador"], ["Biblioteca", "atizador"], ["Cocina", "cuchillo"],
	["Despensa", "cuchillo"], ["Sala de calderas", "martillo"], ["Estudio del padre", "atizador"], ["Comedor formal", "cuchillo"]]

var j: Node  # ZarekJuego
var arma := ""
var cepos := 0
var escopeta := false
var cartuchos := 0
var suelo: Array = []          # armas a la vista {pos, tipo, nodo, cogida}
var trampas: Array = []        # cepos puestos {pos, nodo}
var lanzados: Array = []       # {cuerpo, t}
var _forcejeo := 0.0
var _toques := 0
var _necesarios := 6
var _mano: Node3D
var _cache_modelos := {}

## Reparte las defensas de la noche entre el suelo y los cajones (con la misma semilla que el resto).
func preparar(m: ZarekMansion, muebles: Array, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = (seed if seed != 0 else 555) + 61
	# dos armas a la vista en salas distintas
	var sitios := A_LA_VISTA.duplicate()
	for i in range(sitios.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var t0 = sitios[i]
		sitios[i] = sitios[k]
		sitios[k] = t0
	ZarekTerror._rng.seed = (seed if seed != 0 else 555) + 62
	for s in sitios:
		if suelo.size() >= 2:
			break
		var r := m._sala_por_nombre(s[0])
		if r.is_empty():
			continue
		var p := ZarekTerror._sitio_libre(m, r, 0.6)
		if p == Vector3.INF:
			continue
		var n := _orientado(_modelo_arma(s[1]), Vector3.RIGHT)
		var piv := Node3D.new()
		piv.position = p + Vector3(0, 0.01, 0)
		piv.rotation.y = rng.randf() * TAU
		piv.set_meta("dyn", true)
		piv.add_child(n)
		m._house.add_child(piv)
		n = piv
		suelo.append({"pos": p, "tipo": s[1], "nodo": n, "cogida": false})
	# en los cajones vacíos: otra arma, una trampa de caza y, algunas noches, la escopeta con cartuchos
	var vacios := muebles.filter(func(x): return x.tipo != "" and String(x.botin) == "")
	for i in range(vacios.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var t0 = vacios[i]
		vacios[i] = vacios[k]
		vacios[k] = t0
	var botin: Array = ["arma:" + ["cuchillo", "martillo", "atizador"][rng.randi_range(0, 2)], "cepo", "cepo"]
	if seed == 0 or rng.randf() < 0.4:
		botin.append_array(["escopeta", "cartucho"])
	for i in mini(botin.size(), vacios.size()):
		vacios[i].botin = botin[i]
	print("ZAREK defensa: %d armas a la vista, en cajones %s" % [suelo.size(), str(botin)])

## Modelo del arma (Objaverse si está, si no hecho por código).
func _modelo_arma(tipo: String) -> Node3D:
	var ruta := "res://zarek/objetos/%s.glb" % String(ARMAS.get(tipo, {}).get("modelo", "w_" + tipo))
	if ResourceLoader.exists(ruta):
		if not _cache_modelos.has(ruta):
			_cache_modelos[ruta] = load(ruta)
		return (_cache_modelos[ruta] as PackedScene).instantiate()
	var n := Node3D.new()
	var hierro := StandardMaterial3D.new()
	hierro.albedo_color = Color(0.16, 0.15, 0.14)
	hierro.metallic = 0.8
	hierro.roughness = 0.45
	var madera := StandardMaterial3D.new()
	madera.albedo_color = Color(0.3, 0.18, 0.1)
	madera.roughness = 0.8
	var piezas: Array = []
	match tipo:
		"atizador":
			piezas = [[Vector3(0.02, 0.75, 0.02), Vector3(0, 0, 0), hierro], [Vector3(0.02, 0.09, 0.02), Vector3(0.03, 0.36, 0), hierro], [Vector3(0.05, 0.1, 0.05), Vector3(0, -0.38, 0), madera]]
		"cuchillo":
			piezas = [[Vector3(0.035, 0.2, 0.005), Vector3(0, 0.1, 0), hierro], [Vector3(0.03, 0.12, 0.025), Vector3(0, -0.06, 0), madera]]
		"martillo":
			piezas = [[Vector3(0.03, 0.32, 0.03), Vector3(0, 0, 0), madera], [Vector3(0.12, 0.04, 0.04), Vector3(0, 0.17, 0), hierro]]
		"escopeta":
			piezas = [[Vector3(0.05, 0.05, 0.6), Vector3(0, 0, -0.3), hierro], [Vector3(0.06, 0.1, 0.35), Vector3(0, -0.03, 0.15), madera]]
		_:
			piezas = [[Vector3(0.1, 0.1, 0.1), Vector3.ZERO, hierro]]
	for pz in piezas:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = pz[0]
		mi.mesh = bm
		mi.position = pz[1]
		mi.material_override = pz[2]
		n.add_child(mi)
	return n

## Gira el modelo para que su lado más largo apunte a `eje` (tumbado en el suelo: RIGHT; en la mano: FORWARD)
## y lo apoya con su punto más bajo en y = 0 (solo para el suelo).
func _orientado(n: Node3D, eje: Vector3) -> Node3D:
	var caja := AABB()
	var primera := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		var t := _transform_rel(n, m3)
		var b := t * m3.get_aabb()
		caja = b if primera else caja.merge(b)
		primera = false
	if primera:
		return n
	var largo := caja.get_longest_axis()
	var raiz := Node3D.new()
	raiz.add_child(n)
	var q := Quaternion(largo.normalized(), eje.normalized())
	n.quaternion = q
	var c := caja.get_center()
	n.position = -(q * c)
	if eje == Vector3.RIGHT:
		# apoyado en el suelo: la mitad del grosor por encima
		var rot := Basis(q) * caja.size
		var grueso := absf(rot.y)
		n.position.y += grueso * 0.5
	return raiz

static func _transform_rel(raiz: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D()
	var x: Node = n
	while x != null and x != raiz:
		if x is Node3D:
			t = (x as Node3D).transform * t
		x = x.get_parent()
	return t

func arma_cerca(p: Vector3) -> Dictionary:
	for a in suelo:
		if not a.cogida and absf(p.y - (a.pos as Vector3).y) < 1.5 and Vector2(p.x - a.pos.x, p.z - a.pos.z).length() < 1.4:
			return a
	return {}

func coger_del_suelo(a: Dictionary) -> String:
	if arma != "":
		return "Ya llevo %s. No puedo con dos." % ARMAS[arma].nombre
	a.cogida = true
	arma = a.tipo
	j._a_la_mano(a.nodo)
	return "Cojo %s. Si me atrapa, puedo defenderme… una vez." % ARMAS[arma].nombre

## Botín de un cajón relacionado con la defensa. Devuelve el mensaje (o "" si no era de defensa).
func botin(b: String) -> String:
	if b.begins_with("arma:"):
		var t := b.trim_prefix("arma:")
		if arma != "":
			return "Hay %s… pero ya llevo %s." % [ARMAS[t].nombre, ARMAS[arma].nombre]
		arma = t
		return "¡%s! Si me atrapa, puedo defenderme una vez." % String(ARMAS[t].nombre).capitalize()
	match b:
		"cepo":
			cepos += 1
			return "Una trampa de caza. Puedo dejarla en el suelo donde vaya a pasar (USAR sin nada delante)."
		"escopeta":
			escopeta = true
			cartuchos += 1
			return "La escopeta de Julián… con un cartucho dentro.\nNo lo matará. Pero lo tirará al suelo."
		"cartucho":
			cartuchos += 1
			return "Un cartucho de escopeta." + ("" if escopeta else " ¿Dónde estará el arma?")
	return ""

func poner_trampa(p: Vector3, yaw: float) -> void:
	if cepos <= 0:
		return
	cepos -= 1
	var n := ZarekGore.cepo(j.mansion, p, false, yaw)
	n.set_meta("dyn", true)
	trampas.append({"pos": p, "nodo": n})
	j.sound_at("llaves", p + Vector3(0, 0.3, 0), -6.0)

func lanzado(cuerpo: RigidBody3D) -> void:
	lanzados.append({"cuerpo": cuerpo, "t": 2.0})

## Forcejeo: ¿puede defenderse ahora? Lo llama el juego cuando Damián la atrapa.
func puede_forcejear() -> bool:
	return arma != ""

func empezar_forcejeo() -> void:
	_necesarios = [4, 6, 9][j.dif] + j.elena.heridas * 2
	_toques = 0
	_forcejeo = 2.4
	j.bar_rit.visible = true
	j.bar_rit.value = 0.0
	j.message("¡FORCEJEA! ¡MACHACA USAR!", 2.4)
	_ver_arma(true)

func _ver_arma(v: bool) -> void:
	if v and _mano == null:
		_mano = _orientado(_modelo_arma(arma), Vector3.FORWARD)
		j.player.camera.add_child(_mano)
		_mano.position = Vector3(0.16, -0.22, -0.45)
		_mano.rotation = Vector3(0.3, -0.15, 0.0)
	elif not v and _mano:
		_mano.queue_free()
		_mano = null

func disparar() -> void:
	if not escopeta or cartuchos <= 0:
		return
	cartuchos -= 1
	var e: ZarekElena = j.elena
	var p: Vector3 = j.player.global_position
	# el arma aparece, retrocede y desaparece
	var g := _orientado(_modelo_arma("escopeta"), Vector3.FORWARD)
	j.player.camera.add_child(g)
	g.position = Vector3(0.2, -0.3, -0.65)
	var tw := create_tween()
	tw.tween_property(g, "position:z", -0.2, 0.06)
	tw.tween_property(g, "rotation:x", 0.35, 0.08)
	tw.tween_interval(0.5)
	tw.tween_callback(g.queue_free)
	Aether.flash(Color(1.0, 0.85, 0.6), 0.25)
	j.player.shake(16.0)
	j.sound_at("disparo" if ZarekSonido.hay("disparo") else "portazo", p + Vector3(0, 1.5, 0), 6.0)
	var to := e.global_position - p
	to.y = 0.0
	var mira: Vector3 = j.player.look_dir()
	mira.y = 0.0
	var acierta: bool = e.visible and e.state != ZarekElena.S.DORMANT and to.length() < 16.0 and mira.normalized().dot(to.normalized()) > 0.93
	if acierta:
		var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.5, 0), e.global_position + Vector3(0, 1.4, 0))
		q.collision_mask = 1
		acierta = j.get_world_3d().direct_space_state.intersect_ray(q).is_empty()
	if acierta:
		e.heridas += 1
		e.aturdir(3.0)
		j.sound_at("damian_rugido", e.global_position + Vector3(0, 1.6, 0), 4.0)
		j.message("Cayó al suelo… se levanta y se arrastra lejos.\nVolverá. Y volverá furioso.", 3.5)
		await j.get_tree().create_timer(3.0).timeout
		e.vanish(45.0)
		e.aggro += 1
		if j.tension:
			j.tension._poner_fase("respiro")
	else:
		j.message("Fallé. Y todo el mundo en esta casa lo ha oído.", 2.5)
	# el disparo se oye en toda la casa
	e.hear(p, 999.0)

func tick(delta: float) -> void:
	var e: ZarekElena = j.elena
	if e == null:
		return
	# forcejeo
	if _forcejeo > 0.0:
		_forcejeo -= delta
		if Input.is_action_just_pressed("usar") or ((j.autotest or j.has_meta("bot")) and Engine.get_process_frames() % 6 == 0):
			_toques += 1
			j.player.shake(3.0)
			if _mano:
				_mano.position.z = -0.6
		if _mano:
			_mano.position.z = lerpf(_mano.position.z, -0.45, minf(1.0, delta * 10.0))
		j.bar_rit.value = float(_toques) / float(_necesarios) * 100.0
		if _toques >= _necesarios:
			_forcejeo = 0.0
			_ganar_forcejeo()
		elif _forcejeo <= 0.0:
			j.bar_rit.visible = false
			_ver_arma(false)
			j._morir_atrapada()
		return
	# objetos lanzados que le dan
	for x in lanzados.duplicate():
		x.t -= delta
		var c: RigidBody3D = x.cuerpo
		if x.t <= 0.0 or not is_instance_valid(c):
			lanzados.erase(x)
			continue
		if e.visible and c.linear_velocity.length() > 2.5 and c.global_position.distance_to(e.global_position + Vector3(0, 1.2, 0)) < 0.9:
			lanzados.erase(x)
			e.aturdir(1.8)
			j.sound_at("golpe_madera", c.global_position, 2.0)
			j.message("¡Le di! Está aturdido… ¡corre!", 1.8)
	# trampas de caza
	if e.visible and e.state != ZarekElena.S.DORMANT and e.aturdido <= 0.0:
		for t in trampas.duplicate():
			var tp: Vector3 = t.pos
			if absf(tp.y - e.global_position.y) < 1.0 and Vector2(tp.x - e.global_position.x, tp.z - e.global_position.z).length() < 0.55:
				trampas.erase(t)
				e.global_position = Vector3(tp.x, e.global_position.y, tp.z)
				e.aturdir(9.0)
				if is_instance_valid(t.nodo):
					t.nodo.queue_free()
				ZarekGore.cepo(j.mansion, tp, true, randf() * TAU)
				j.sound_at("cepo_salta" if ZarekSonido.hay("cepo_salta") else "golpe_madera", tp + Vector3(0, 0.3, 0), 4.0)
				j.sound_at("damian_rugido", e.global_position + Vector3(0, 1.6, 0), 4.0)
				if j.player.global_position.distance_to(tp) < 25.0:
					j.message("¡Ha pisado la trampa! Se oye cómo tira de la cadena…", 2.5)
				break

func _ganar_forcejeo() -> void:
	var e: ZarekElena = j.elena
	j.bar_rit.visible = false
	j.sound_at("carne" if ZarekSonido.hay("carne") else "aplastar", e.global_position + Vector3(0, 1.3, 0), 2.0)
	j.sound_at("damian_rugido", e.global_position + Vector3(0, 1.6, 0), 4.0)
	Aether.flash(Color(0.5, 0.0, 0.0), 0.3)
	j.player.shake(12.0)
	var msg := String(ARMAS[arma].rompe)
	arma = ""
	_ver_arma(false)
	e.heridas += 1
	e.aturdido = 0.0
	e.set_state(ZarekElena.S.FLEE, 2.5)
	e.repel(j.player.global_position)
	e.timer = 2.5
	j.message(msg + "\nHuye herido. Pero esto le ha enseñado a cubrirse.", 3.5)
	j.state = "juego"
	j.player.frozen = false
	if j.tension:
		j.tension._poner_fase("respiro")
	await j.get_tree().create_timer(3.0).timeout
	e.can_catch = true
