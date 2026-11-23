class_name ZarekRegistro
## Muebles que se pueden registrar: mesillas, cómodas, escritorios, armarios, aparadores y baúles.
## Al registrar sale de verdad un cajón (o se abre una puertecita o la tapa) y a veces hay algo dentro:
## pilas, bengalas, tablones, una cerilla para nada… o nada. Cada partida el botín cambia de sitio.
## También grifos, lavabos, váteres y el piano, que hacen ruido (y pueden servir para distraerle).

const CAJONES := ["nightstand", "commode", "drawer", "dresser", "desk", "sideboard", "bureau", "vanity"]
const PUERTAS := ["cabinet", "wardrobe", "cupboard"]
const TAPAS := ["chest", "trunk", "baul"]
const RUIDOSOS := {"sink": "grifo", "washbasin": "grifo", "lavabo": "grifo", "toilet": "cisterna", "bathtub": "grifo", "tub": "grifo",
	"piano": "piano"}

static func preparar(m: ZarekMansion) -> Array:
	var lista: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = m.partida_seed + 99
	for c in m._house.get_children():
		if not (c is Node3D) or (c as Node3D).scene_file_path == "":
			continue
		var n := c as Node3D
		var nombre := n.scene_file_path.get_file().get_basename()
		var bajo := nombre.to_lower()
		var tipo := ""
		for w in CAJONES:
			if w in bajo:
				tipo = "cajon"
		for w in PUERTAS:
			if w in bajo and tipo == "":
				tipo = "puerta"
		for w in TAPAS:
			if w in bajo and tipo == "" and not "tree" in bajo:
				tipo = "tapa"
		var ruido := ""
		for w in RUIDOSOS:
			if w in bajo:
				ruido = RUIDOSOS[w]
		if tipo == "" and ruido == "":
			continue
		var tam: Vector3 = m._prop_size(nombre) * n.scale.x
		if tipo != "" and (tam.y < 0.35 or tam.y > 2.6):
			continue
		lista.append({"nodo": n, "pos": n.global_position, "tam": tam, "tipo": tipo, "ruido": ruido, "hecho": false, "botin": ""})
	# reparte el botín: un cuarto de los muebles tiene algo
	var con_cajon := lista.filter(func(x): return x.tipo != "")
	var botin := ["pila", "pila", "pila", "bengala", "bengala", "tablon", "tablon", "pila", "bengala", "nota"]
	for i in range(con_cajon.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t0 = con_cajon[i]
		con_cajon[i] = con_cajon[j]
		con_cajon[j] = t0
	for i in mini(botin.size(), con_cajon.size()):
		con_cajon[i].botin = botin[i]
	print("ZAREK registro: %d muebles para registrar, %d con ruido" % [con_cajon.size(), lista.size() - con_cajon.size()])
	return lista

static func cerca(lista: Array, p: Vector3, mira: Vector3) -> Dictionary:
	var mejor := {}
	var bd := 1.7
	for x in lista:
		var q: Vector3 = x.pos
		if absf(q.y - p.y) > 1.3:
			continue
		var d := Vector2(q.x - p.x, q.z - p.z).length() - maxf(x.tam.x, x.tam.z) * 0.4
		if d > bd:
			continue
		var hacia := Vector3(q.x - p.x, 0, q.z - p.z).normalized()
		if hacia.dot(Vector3(mira.x, 0, mira.z).normalized()) < 0.45:
			continue
		bd = d
		mejor = x
	return mejor

## Animación: sale el cajón, se abre la puertecita o se levanta la tapa (piezas nuevas pegadas al mueble).
static func abrir(m: ZarekMansion, x: Dictionary) -> void:
	var n: Node3D = x.nodo
	var tam: Vector3 = x.tam
	var frente := n.global_basis.z.normalized()
	var lado := n.global_basis.x.normalized()
	var base := n.global_position
	var mat: Material = m._mat.madera
	var pieza := Node3D.new()
	m._house.add_child(pieza)
	pieza.global_position = base
	pieza.look_at(base - frente, Vector3.UP)
	var tw := m.create_tween()
	match String(x.tipo):
		"cajon":
			var h := clampf(tam.y * 0.18, 0.1, 0.18)
			var ancho := clampf(tam.x * 0.7, 0.3, 0.9)
			var y := clampf(tam.y * 0.62, 0.35, 0.9)
			var caja := Node3D.new()
			pieza.add_child(caja)
			caja.position = Vector3(0, y, tam.z * 0.5 - 0.17)
			m.box(Vector3(ancho, 0.02, 0.34), Vector3(0, -h * 0.5, 0), mat, false, caja, false)
			m.box(Vector3(ancho, h, 0.02), Vector3(0, 0, 0.17), mat, false, caja, false)
			m.box(Vector3(ancho, h, 0.02), Vector3(0, 0, -0.17), mat, false, caja, false)
			for s in [-1.0, 1.0]:
				m.box(Vector3(0.02, h, 0.34), Vector3(s * ancho * 0.5, 0, 0), mat, false, caja, false)
			m.box(Vector3(0.08, 0.02, 0.02), Vector3(0, 0, 0.19), m._mat.laton_viejo, false, caja, false)
			tw.tween_property(caja, "position:z", tam.z * 0.5 + 0.12, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		"puerta":
			var alto := clampf(tam.y * 0.45, 0.4, 1.6)
			var ancho := clampf(tam.x * 0.45, 0.25, 0.6)
			var bis := Node3D.new()
			pieza.add_child(bis)
			bis.position = Vector3(tam.x * 0.5 - 0.02, tam.y * 0.5, tam.z * 0.5 + 0.015)
			m.box(Vector3(ancho, alto, 0.025), Vector3(-ancho * 0.5, 0, 0), mat, false, bis, false)
			m.box(Vector3(0.02, 0.07, 0.02), Vector3(-ancho + 0.05, 0, 0.02), m._mat.laton_viejo, false, bis, false)
			tw.tween_property(bis, "rotation:y", 1.7, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"tapa":
			var bis := Node3D.new()
			pieza.add_child(bis)
			bis.position = Vector3(0, tam.y + 0.01, -tam.z * 0.5)
			m.box(Vector3(tam.x * 0.98, 0.04, tam.z * 0.98), Vector3(0, 0, tam.z * 0.49), mat, false, bis, false)
			tw.tween_property(bis, "rotation:x", -1.4, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	x.hecho = true
