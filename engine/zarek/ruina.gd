class_name ZarekRuina
## La casa abandonada de verdad: lo que hay tirado por el suelo de cada sala (sillas volcadas, tablones,
## periódicos, libros, botellas, cajas, velas consumidas), manchas de humedad en techos y paredes, telarañas en
## las esquinas, y los túneles del sótano con entibado de madera, piedras, huesos, cajas y charcos.
## Se aplica después del gore (no pisa nada: busca huecos libres con ZarekTerror._sitio_libre).

static var _rng := RandomNumberGenerator.new()
static var _ocupado: Array[Vector3] = []

const NO_TOCAR := ["jardin", "roca", "agua", "camino", "edificio", "exterior"]
## Lo que puede haber tirado en una sala: [modelo, peso, volcado (0-1), escala]
const TIRADO := [
	["WoodenChair_01", 3.0, 0.7, 1.0], ["vict_dining_chair", 2.0, 0.7, 1.0], ["dining_chair_02", 2.0, 0.7, 1.0],
	["t_tablas_podridas", 3.0, 0.0, 1.0], ["ropa_folded_newspaper", 3.0, 0.0, 1.0],
	["obj_old_book", 2.0, 0.0, 1.0], ["obj_old_book_3", 1.5, 0.0, 1.0], ["obj_old_books", 1.5, 0.0, 1.0],
	["cardboard_box_01", 2.0, 0.3, 1.0], ["obj_sack_v1", 1.0, 0.0, 1.0], ["coti_wine_bottle", 2.0, 1.0, 1.0],
	["coti_glass_bottle", 1.5, 1.0, 1.0], ["t_velas_dos", 1.5, 0.0, 1.0], ["obj_cup_and_plate", 1.0, 0.0, 1.0],
	["ropa_old_shoes", 1.0, 0.0, 1.0], ["obj_kerosene_lamp", 1.0, 1.0, 1.0], ["folding_wooden_stool", 1.5, 0.8, 1.0],
	["obj_envelope", 1.0, 0.0, 1.0], ["obj_dry_firewood", 1.0, 0.0, 1.0],
]
## Salas que estaban casi vacías: llevan el doble de cosas y algo grande en el centro.
const VACIAS := ["Cuarto de plancha", "Torre", "Sala de las mañanas", "Sala de costura", "Salón de baile", "Estudio del padre",
	"Cuarto de servicio", "Archivo", "Sala de calderas", "Cava de vinos", "Guardarropa", "Mirador de la torre"]
const CENTRO_VACIAS := {
	"Cuarto de plancha": [["WoodenTable_01", 0.0], ["coti_willoughsby_sewing_machine", 0.79], ["ropa_hanger_pile", 0.0], ["obj_sack_v2", 0.0]],
	"Torre": [["Rockingchair_01", 0.0], ["obj_birdcage", 0.0], ["terr_old_and_dusty_multi_crate_st", 0.0]],
	"Sala de las mañanas": [["Sofa_01", 0.0], ["CoffeeTable_01", 0.0], ["obj_tea_set", 0.45]],
	"Sala de costura": [["ropa_1900_dress_form", 0.0], ["ropa_mannequin_1900s_m_size", 0.0], ["vict_singer_15___old_sewing_machi", 0.0]],
	"Salón de baile": [["vict_victorian_two_seat_sofa", 0.0], ["obj_harp", 0.0], ["t_silla_ruedas_rota", 0.0]],
	"Estudio del padre": [["vict_antique_iron_safe", 0.0], ["coti_typewriter", 0.0]],
	"Cuarto de servicio": [["WoodenTable_02", 0.0], ["Barrel_01", 0.0]],
	"Archivo": [["terr_old_and_dusty_multi_crate_st", 0.0], ["cardboard_box_01", 0.0], ["cardboard_box_01", 0.0]],
	"Sala de calderas": [["obj_dry_firewood", 0.0], ["obj_old_shovel", 0.0], ["Barrel_01", 0.0]],
	"Cava de vinos": [["Barrel_01", 0.0], ["Barrel_01", 0.0], ["terr_old_and_dusty_multi_crate_st", 0.0]],
	"Mirador de la torre": [["obj_military_telescope", 0.0], ["Rockingchair_01", 0.0]],
}

static func aplicar(m: ZarekMansion) -> void:
	var t0 := Time.get_ticks_msec()
	_rng.seed = 6661
	m._load_props_info()
	# lo que ya hay en la casa (modelos y cuerpos), para no amontonar: una sola pasada en vez de una por intento
	_ocupado.clear()
	for c in m._house.get_children():
		if c is Node3D and ((c as Node3D).scene_file_path != "" or c is RigidBody3D):
			_ocupado.append((c as Node3D).global_position)
	var n := 0
	for r in m.rooms:
		var t := String(r.type)
		var nombre := String(r.name)
		if int(r.level) == -1 and (t == "tunel" or (t == "roca" and nombre.begins_with("Cámara"))):
			n += _tunel(m, r)
			continue
		if t in NO_TOCAR or t == "tunel" or nombre.begins_with("MANSI") or nombre.begins_with("Terrenos") or int(r.level) < -1:
			continue
		n += _suelo(m, r)
		_techo(m, r)
		_telaranas(m, r)
	print("ZAREK ruina: %d cosas (%d ms)" % [n, Time.get_ticks_msec() - t0])

## Punto libre del suelo de la sala (lejos de puertas, escaleras y de lo que ya hay); Vector3.INF si no cabe.
static func _sitio(m: ZarekMansion, r: Dictionary, radio: float) -> Vector3:
	var rc: Rect2 = r.rect
	if rc.size.x < radio * 2.0 + 0.8 or rc.size.y < radio * 2.0 + 0.8:
		return Vector3.INF
	for intento in 30:
		var p := Vector3(_rng.randf_range(rc.position.x + radio + 0.4, rc.end.x - radio - 0.4), float(r.y), _rng.randf_range(rc.position.y + radio + 0.4, rc.end.y - radio - 0.4))
		if not m.door_near(p, radio + 1.0).is_empty() or m._huella_en_escalera(p, Vector3(radio * 2, 0.2, radio * 2), 0.0):
			continue
		var libre := true
		for g in _ocupado:
			if absf(g.y - p.y) < 1.5 and Vector2(g.x - p.x, g.z - p.z).length() < radio + 0.5:
				libre = false
				break
		if libre:
			_ocupado.append(p)
			return p
	return Vector3.INF

static func _elige() -> Array:
	var total := 0.0
	for x in TIRADO:
		total += float(x[1])
	var d := _rng.randf() * total
	for x in TIRADO:
		d -= float(x[1])
		if d <= 0.0:
			return x
	return TIRADO[0]

## Pone un modelo en el suelo (volcado si toca): de lado, apoyado sobre su costado.
static func _tirar(m: ZarekMansion, nombre: String, p: Vector3, volcado: bool, escala := 1.0) -> Node3D:
	if not m._props_info.has(nombre):
		return null
	var nd := m._prop(nombre, p, _rng.randf() * TAU, escala, false)
	if nd and volcado:
		var tam := m._prop_size(nombre) * escala
		nd.rotate_object_local(Vector3.FORWARD, PI * 0.5 * (1.0 if _rng.randf() < 0.5 else -1.0))
		nd.position.y += tam.x * 0.5 - 0.02
	return nd

static func _suelo(m: ZarekMansion, r: Dictionary) -> int:
	var rc: Rect2 = r.rect
	var nombre := String(r.name)
	var area := rc.size.x * rc.size.y
	var cuantas := clampi(int(area / 14.0), 2, 9)
	if nombre in VACIAS:
		cuantas = mini(cuantas * 2, 14)
	var puestas := 0
	for c in CENTRO_VACIAS.get(nombre, []):
		var p := _sitio(m, r, 0.9)
		if p == Vector3.INF:
			continue
		var nd := m._prop(String(c[0]), p + Vector3(0, float(c[1]), 0), _rng.randf() * TAU, 1.0, float(c[1]) == 0.0)
		if nd:
			puestas += 1
	for k in cuantas:
		var x := _elige()
		var p := _sitio(m, r, 0.45)
		if p == Vector3.INF:
			continue
		if _tirar(m, String(x[0]), p, _rng.randf() < float(x[2]), float(x[3])):
			puestas += 1
	# polvo y suciedad en el suelo
	for k in clampi(int(area / 25.0), 1, 4):
		var p := _sitio(m, r, 0.8)
		if p != Vector3.INF:
			ZarekTerror._en_suelo(m, "agua_sucia" if _rng.randf() < 0.3 else "humedad_2", p, _rng.randf_range(1.2, 2.4), _rng.randf() * TAU)
	return puestas

## Manchas de humedad y moho en el techo y chorretones en las paredes.
static func _techo(m: ZarekMansion, r: Dictionary) -> void:
	var rc: Rect2 = r.rect
	if int(r.level) >= 2:
		return
	var alto := float(r.y) + ZarekMansion.WALL_H - 0.01
	for k in _rng.randi_range(1, 3):
		var p := Vector3(_rng.randf_range(rc.position.x + 1.0, rc.end.x - 1.0), alto, _rng.randf_range(rc.position.y + 1.0, rc.end.y - 1.0))
		var tam := _rng.randf_range(1.4, 3.2)
		var mi := ZarekTerror._calco(m, "humedad_1" if k % 2 == 0 else "humedad_2", p, Vector3.DOWN, Vector2(tam, tam), _rng.randf() * TAU)
		mi.position.y -= 0.004
	if _rng.randf() < 0.7:
		ZarekTerror._en_pared(m, r, "humedad_2", Vector2(1.5, 2.2), ZarekMansion.WALL_H - 1.3)

static func _telaranas(m: ZarekMansion, r: Dictionary) -> void:
	if not m._props_info.has("terr_cobwebs"):
		return
	var rc: Rect2 = r.rect
	var y := float(r.y) + (ZarekMansion.WALL_H - 0.9 if int(r.level) < 2 else 2.0)
	var esquinas := [rc.position, Vector2(rc.end.x, rc.position.y), Vector2(rc.position.x, rc.end.y), rc.end]
	for e in esquinas:
		if _rng.randf() < 0.5:
			continue
		var q: Vector2 = e
		var c := rc.get_center()
		var p := Vector3(q.x + signf(c.x - q.x) * 0.35, y, q.y + signf(c.y - q.y) * 0.35)
		m._prop("terr_cobwebs", p, atan2(c.x - q.x, c.y - q.y), 0.9, false)

## Túneles: cuadros de entibado de madera cada pocos metros, piedras caídas, huesos, cajas podridas, sacos,
## cadenas y charcos; una lámpara de aceite medio apagada en algunos.
static func _tunel(m: ZarekMansion, r: Dictionary) -> int:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	var largo_x := rc.size.x >= rc.size.y
	var largo := rc.size.x if largo_x else rc.size.y
	var ancho := rc.size.y if largo_x else rc.size.x
	var alto := 2.9
	var n := 0
	var k := 1.6
	while k < largo - 1.0 and ancho < 6.0:
		var cx := rc.position.x + (k if largo_x else ancho * 0.5)
		var cz := rc.position.y + (ancho * 0.5 if largo_x else k)
		for s in [-1.0, 1.0]:
			var off := Vector3(0, 0, s * (ancho * 0.5 - 0.18)) if largo_x else Vector3(s * (ancho * 0.5 - 0.18), 0, 0)
			var poste := m.box(Vector3(0.2, alto, 0.2), Vector3(cx, y + alto * 0.5, cz) + off, m._mat.madera_vieja, false)
			poste.rotation.y = _rng.randf_range(-0.05, 0.05)
		var viga := m.box(Vector3(0.22, 0.24, ancho) if largo_x else Vector3(ancho, 0.24, 0.22), Vector3(cx, y + alto - 0.05, cz), m._mat.madera_vieja, false)
		viga.rotation.z = _rng.randf_range(-0.03, 0.03)
		k += _rng.randf_range(3.2, 4.4)
		n += 1
	var cosas := [["boulder_01", 0.45, 3], ["bark_debris_01", 1.0, 2], ["obj_sack_v1", 1.0, 1], ["terr_old_and_dusty_multi_crate_st", 0.8, 1],
		["Barrel_01", 1.0, 1], ["x_huesos_human_skull", 1.0, 1], ["obj_old_pickaxe", 1.0, 1], ["obj_old_shovel", 1.0, 1]]
	for c in cosas:
		for i in int(c[2]):
			if _rng.randf() < 0.45:
				continue
			var p := _sitio(m, r, 0.4)
			if p == Vector3.INF:
				continue
			if m._prop(String(c[0]), p, _rng.randf() * TAU, float(c[1]) * _rng.randf_range(0.8, 1.2), false):
				n += 1
	for i in 6:
		var p := _sitio(m, r, 0.2)
		if p != Vector3.INF:
			ZarekGore._hueso(m, p, _rng.randf_range(0.2, 0.5), _rng.randf() * TAU)
	for i in 2:
		var p := _sitio(m, r, 0.7)
		if p != Vector3.INF:
			ZarekTerror._en_suelo(m, "agua_sucia", p, _rng.randf_range(1.0, 1.8), _rng.randf() * TAU)
			m.charcos.append(p)
	if largo > 7.0 and _rng.randf() < 0.6:
		var lp := Vector3(rc.get_center().x, y + 2.2, rc.get_center().y)
		m._prop("obj_old_lantern", lp, 0.0, 1.0, false)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.55, 0.25)
		l.light_energy = 0.5
		l.omni_range = 5.0
		l.position = lp + Vector3(0, 0.15, 0)
		l.set_meta("vela", true)
		l.set_meta("e", 0.5)
		m._house.add_child(l)
		m.fires.append(l)
	return n
