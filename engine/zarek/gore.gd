class_name ZarekGore
## Lo que deja Damián por la casa: sangre (charcos, salpicaduras, chorretones, rastros de arrastre y pisadas
## descalzas), el matadero del sótano (ganchos con cuerpos envueltos y carne, mesa de despiece, silla con
## correas, bolsas, huesos), cuerpos tapados, la mesa del comedor servida y la bañera teñida.
## Las texturas salen de tools/gore/texturas_gore.py. Se puede apagar con SIN_GORE=1.

static var _rng := RandomNumberGenerator.new()
static var _mats := {}

static func _mat(nombre: String, rugosidad := 0.8) -> StandardMaterial3D:
	if _mats.has(nombre):
		return _mats[nombre]
	var mt := StandardMaterial3D.new()
	var ruta := "res://zarek/terror/%s.png" % nombre
	if ResourceLoader.exists(ruta):
		mt.albedo_texture = load(ruta)
	mt.roughness = rugosidad
	mt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[nombre] = mt
	return mt

## La sangre de las calcomanías, húmeda y con brillo (las demás calcomanías de terror son mate).
static func _preparar() -> void:
	for n in ["sangre_charco_1", "sangre_charco_2", "sangre_charco_3", "sangre_salpicadura_1", "sangre_salpicadura_2", "sangre_salpicadura_3",
			"sangre_arrastre_1", "sangre_arrastre_2", "sangre_goteo_1", "sangre_goteo_2", "sangre_pisadas"]:
		var mt := ZarekTerror._mat(n, 0.22)
		mt.metallic_specular = 0.75

static func _carne() -> StandardMaterial3D:
	var m := _mat("carne", 0.42)
	m.metallic_specular = 0.7  # húmeda
	return m

# ---------------- modelos reales (Objaverse CC-BY, zarek/objetos/x_*.glb) ----------------
## Coloca un modelo x_*; los órganos que vienen sin textura se tiñen de carne húmeda.
static func _x(m: ZarekMansion, nombre: String, p: Vector3, yaw := 0.0, escala := 1.0, choca := false) -> Node3D:
	var n := m._prop("x_" + nombre, p, yaw, escala, choca)
	if n == null:
		return null
	var tinte := {"organos_small_and_large_intestin": Color(0.55, 0.17, 0.15), "organos_human_liver": Color(0.3, 0.05, 0.04),
		"tortura_hanging_wall_chains": Color(0.25, 0.22, 0.2), "tortura_iron_shackles": Color(0.3, 0.26, 0.22)}
	if tinte.has(nombre):
		var mt := StandardMaterial3D.new()
		mt.albedo_color = tinte[nombre]
		mt.roughness = 0.3 if nombre.begins_with("organos") else 0.55
		mt.metallic = 0.0 if nombre.begins_with("organos") else 0.7
		mt.metallic_specular = 0.8
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = mt
	return n

## Modelo colgado de un gancho: su base queda `alto` metros por debajo de la punta.
static func _colgado(m: ZarekMansion, nombre: String, punta: Vector3, alto: float, yaw := 0.0) -> void:
	_x(m, nombre, punta - Vector3(0, alto, 0), yaw)

# ---------------- piezas ----------------
## Capsula (cuerpo envuelto, trozo de carne...) tumbada a lo largo de `dir` o colgando si dir es vertical.
static func _capsula(m: ZarekMansion, c: Vector3, radio: float, largo: float, dir: Vector3, mat: Material, escala := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radio
	cm.height = largo
	cm.radial_segments = 12
	cm.rings = 4
	mi.mesh = cm
	mi.material_override = mat
	var y := dir.normalized()
	var x := (Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).cross(y).normalized()
	var z := x.cross(y).normalized()
	mi.transform = Transform3D(Basis(x * escala.x, y * escala.y, z * escala.z), c)
	m._house.add_child(mi)
	return mi

## Cuerpo envuelto en una sábana ensangrentada o en plástico, atado con cuerdas.
static func _envuelto(m: ZarekMansion, c: Vector3, dir: Vector3, mat: Material, largo := 1.75) -> void:
	_capsula(m, c, 0.24, largo, dir, mat, Vector3(1.0, 1.0, 0.8))
	var d := dir.normalized()
	var cuerda: Material = m._mat.madera_vieja
	for t in [-0.32, -0.05, 0.25]:
		var anillo := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.235
		tm.outer_radius = 0.26
		tm.rings = 14
		tm.ring_segments = 5
		anillo.mesh = tm
		anillo.material_override = cuerda
		var y := d
		var x := (Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).cross(y).normalized()
		anillo.transform = Transform3D(Basis(x, y, x.cross(y)).scaled(Vector3(1, 1, 0.8)), c + d * largo * t)
		m._house.add_child(anillo)

## Pieza de carne colgada o sobre una mesa, con el hueso asomando.
static func _trozo(m: ZarekMansion, c: Vector3, dir: Vector3, tam := 1.0) -> void:
	_capsula(m, c, 0.18 * tam, 0.75 * tam, dir, _carne(), Vector3(1.15, 1.0, 0.7))
	var d := dir.normalized()
	var h := m.cyl(0.035 * tam, 0.045 * tam, 0.25 * tam, c + d * 0.42 * tam, _mat("hueso", 0.6), m._house, 8)
	var x := (Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).cross(d).normalized()
	h.basis = Basis(x, d, x.cross(d))
	var punta := m.cyl(0.06 * tam, 0.06 * tam, 0.05 * tam, c + d * 0.56 * tam, _mat("hueso", 0.6), m._house, 8)
	punta.basis = h.basis

## Gancho de carnicero colgando de una barra a la altura `y`.
static func _gancho(m: ZarekMansion, p: Vector3, y: float, largo_cadena := 0.5) -> Vector3:
	m.cyl(0.012, 0.012, largo_cadena, Vector3(p.x, y - largo_cadena * 0.5, p.z), m._mat.hierro, m._house, 4)
	var g := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.06
	tm.outer_radius = 0.08
	tm.rings = 10
	tm.ring_segments = 4
	g.mesh = tm
	g.material_override = m._mat.hierro
	g.transform = Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(p.x, y - largo_cadena - 0.06, p.z))
	m._house.add_child(g)
	return Vector3(p.x, y - largo_cadena - 0.12, p.z)

static func _hueso(m: ZarekMansion, c: Vector3, largo: float, giro: float) -> void:
	var b := m.cyl(0.025, 0.03, largo, c + Vector3(0, 0.035, 0), _mat("hueso", 0.6), m._house, 6)
	b.rotation = Vector3(0, giro, PI * 0.5)
	for s in [-1.0, 1.0]:
		var e := m.cyl(0.045, 0.045, 0.06, c + Vector3(cos(giro) * s * largo * 0.5, 0.04, -sin(giro) * s * largo * 0.5), _mat("hueso", 0.6), m._house, 8)
		e.rotation = b.rotation

static func _cubo_sangre(m: ZarekMansion, c: Vector3) -> void:
	m._prop("wooden_bucket_01", c, _rng.randf() * TAU, 1.0, false)
	var s := m.cyl(0.13, 0.13, 0.01, c + Vector3(0, 0.25, 0), _sangre_liquida(), m._house, 16)
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func _sangre_liquida() -> StandardMaterial3D:
	if _mats.has("_liq"):
		return _mats["_liq"]
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.22, 0.01, 0.01)
	mt.roughness = 0.06
	mt.metallic_specular = 0.9
	_mats["_liq"] = mt
	return mt

static func _charco(m: ZarekMansion, c: Vector3, tam: float) -> void:
	ZarekTerror._en_suelo(m, "sangre_charco_%d" % _rng.randi_range(1, 3), c, tam, _rng.randf() * TAU)

static func _salpicadura(m: ZarekMansion, c: Vector3, tam: float) -> void:
	ZarekTerror._en_suelo(m, "sangre_salpicadura_%d" % _rng.randi_range(1, 3), c, tam, _rng.randf() * TAU)

## Rastro de arrastre de `a` a `b` por el suelo (varias calcomanías encadenadas).
static func _rastro(m: ZarekMansion, a: Vector3, b: Vector3, ancho := 0.75, nombre := "") -> void:
	var l := a.distance_to(b)
	var tramo := ancho * 3.6
	var n := maxi(int(ceil(l / tramo)), 1)
	var d := (b - a).normalized()
	var giro := atan2(d.x, d.z)
	for k in n:
		var c := a + d * (l * (k + 0.5) / n) + Vector3(_rng.randf_range(-0.08, 0.08), 0.004 + k * 0.0004, 0)
		var nm := nombre if nombre != "" else "sangre_arrastre_%d" % (k % 2 + 1)
		ZarekTerror._calco(m, nm, c, Vector3.UP, Vector2(ancho, l / n * 1.15), giro + PI)

# ---------------- todo ----------------
static func aplicar(m: ZarekMansion) -> void:
	if OS.get_environment("SIN_GORE") != "":
		return
	var t0 := Time.get_ticks_msec()
	_preparar()
	_rng.seed = 1988
	_sangre_por_salas(m)
	_rastros(m)
	_comedor(m)
	_banera_sangre(m)
	_cuerpos(m)
	_despensa(m)
	_capilla(m)
	print("ZAREK gore: %d ms" % (Time.get_ticks_msec() - t0))

## Charcos y salpicaduras en el suelo y chorretones y salpicaduras en las paredes de las salas por donde caza.
const SALAS := {
	"Pasillo principal": [2, 2, 1], "Vestíbulo y gran escalera": [2, 2, 1], "Comedor formal": [2, 1, 1], "Cocina": [3, 2, 2],
	"Antecocina": [1, 1, 1], "Despensa": [2, 1, 1], "Pasillo del sótano": [3, 2, 2], "Sala de calderas": [2, 1, 1],
	"Cuarto de huéspedes": [1, 1, 1], "Baño": [1, 1, 1], "Pasillo": [1, 1, 1], "Capilla del ritual": [3, 2, 1],
	"Cava de vinos": [1, 1, 0], "Galería de retratos": [1, 0, 1], "Salón de baile": [1, 1, 0], "Cuarto del hermano": [1, 0, 1],
}

static func _sangre_por_salas(m: ZarekMansion) -> void:
	for nombre in SALAS:
		var r := m._sala_por_nombre(nombre)
		if r.is_empty():
			continue
		var cfg: Array = SALAS[nombre]
		for k in int(cfg[0]):
			var p := ZarekTerror._sitio_libre(m, r, 0.6)
			if p != Vector3.INF:
				_charco(m, p, _rng.randf_range(0.9, 1.7))
		for k in int(cfg[1]):
			var p := ZarekTerror._sitio_libre(m, r, 0.4)
			if p != Vector3.INF:
				_salpicadura(m, p, _rng.randf_range(0.8, 1.5))
		for k in int(cfg[2]):
			if _rng.randf() < 0.5:
				ZarekTerror._en_pared(m, r, "sangre_goteo_%d" % _rng.randi_range(1, 2), Vector2(0.9, 1.8), 1.3)
			else:
				ZarekTerror._en_pared(m, r, "sangre_salpicadura_%d" % _rng.randi_range(1, 3), Vector2(1.3, 1.3), 1.4)

## Rastros: algo arrastrado por el pasillo del sótano hasta el matadero, y las pisadas descalzas de Damián
## de la cocina al pasillo principal.
static func _rastros(m: ZarekMansion) -> void:
	var ps := m._sala_por_nombre("Pasillo del sótano")
	if not ps.is_empty():
		var rc: Rect2 = ps.rect
		var y := float(ps.y)
		var z := rc.get_center().y + 0.4
		_rastro(m, Vector3(rc.position.x + 2.0, y, z), Vector3(rc.position.x + 12.0, y, z - 0.3))
		_rastro(m, Vector3(rc.position.x + 12.0, y, z - 0.3), Vector3(rc.position.x + 11.5, y, rc.position.y + 0.3))
	var pp := m._sala_por_nombre("Pasillo principal")
	if not pp.is_empty():
		var rc: Rect2 = pp.rect
		var y := float(pp.y)
		var z := rc.get_center().y - 0.3
		var x := rc.end.x - 4.0
		while x > rc.end.x - 22.0:
			ZarekTerror._calco(m, "sangre_pisadas", Vector3(x, y + 0.005, z), Vector3.UP, Vector2(0.5, 2.0), -PI * 0.5)
			x -= 2.1
		_rastro(m, Vector3(rc.position.x + 6.0, y, rc.get_center().y + 0.2), Vector3(rc.position.x + 14.0, y, rc.get_center().y), 0.6)

## La mesa del comedor servida: platos con carne cruda, un charco sobre el mantel y sangre goteando al suelo.
static func _comedor(m: ZarekMansion) -> void:
	var r := m._sala_por_nombre("Comedor formal")
	if r.is_empty():
		return
	var mesa: Node3D = null
	for n in m._house.get_children():
		if n is Node3D and String((n as Node3D).scene_file_path).get_file().contains("dining_table") and (r.rect as Rect2).has_point(Vector2(n.global_position.x, n.global_position.z)):
			mesa = n
			break
	if mesa == null:
		return
	var ab := m._caja_mallas(mesa)
	var y := ab.end.y
	var largo_x := ab.size.x > ab.size.z
	var c := ab.get_center()
	var eje := Vector3(1, 0, 0) if largo_x else Vector3(0, 0, 1)
	var lado := Vector3(0, 0, 1) if largo_x else Vector3(1, 0, 0)
	var l := maxf(ab.size.x, ab.size.z)
	var w := minf(ab.size.x, ab.size.z)
	ZarekTerror._calco(m, "sangre_charco_2", Vector3(c.x, y + 0.012, c.z), Vector3.UP, Vector2(w * 0.9, w * 0.9), 0.3)
	for k in 3:
		var p := Vector3(c.x, y + 0.04, c.z) + eje * (l * (k - 1) * 0.28) + lado * _rng.randf_range(-0.1, 0.1)
		var plato := m.cyl(0.22, 0.2, 0.025, p, m._mat.marmol, m._house, 20)
		plato.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var plato_de: String = ["carne_cote_de_boeuf", "organos_human_heart", "carne_eataly_steak_scanned_wit"][k]
		_x(m, plato_de, p + Vector3(0, 0.015, 0), _rng.randf() * TAU)
	# chorro que cae por el borde y charco en el suelo
	var borde := Vector3(c.x, float(r.y), c.z) + lado * (w * 0.5 + 0.25)
	_charco(m, borde, 1.1)
	ZarekTerror._calco(m, "sangre_goteo_1", Vector3(c.x, y - 0.25, c.z) + lado * (w * 0.5 + 0.005), lado, Vector2(0.5, 0.5))

static func _banera_sangre(m: ZarekMansion) -> void:
	for n in m._house.get_children():
		var nd := n as Node3D
		if nd == null or not String(nd.scene_file_path).get_file().contains("bathtub"):
			continue
		for h in nd.get_children():
			if h is MeshInstance3D and (h as MeshInstance3D).mesh is CylinderMesh:
				var mt := ((h as MeshInstance3D).material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
				mt.albedo_color = Color(0.45, 0.04, 0.03)
				(h as MeshInstance3D).material_override = mt
		var ab := m._caja_mallas(nd)
		ZarekTerror._calco(m, "sangre_goteo_2", Vector3(ab.get_center().x, ab.end.y - 0.3, ab.end.z + 0.005), Vector3(0, 0, 1), Vector2(0.6, 0.8))
		_charco(m, Vector3(ab.get_center().x, ab.position.y, ab.end.z + 0.5), 1.0)
		_x(m, "restos_severed_hand", Vector3(ab.get_center().x + 0.4, ab.position.y + 0.01, ab.end.z + 0.45), 2.2)

## Cuerpos: uno tapado con una sábana empapada en el cuarto de huéspedes, otro envuelto en plástico a medio
## arrastrar en el pasillo del sótano, y uno bajo la escalera de servicio.
static func _cuerpos(m: ZarekMansion) -> void:
	var tela := _mat("tela_sangre", 0.95)
	var plast := _mat("plastico", 0.35)
	var lista := [["Cuarto de huéspedes", tela], ["Pasillo del sótano", plast], ["Escalera de servicio", tela], ["Sala de calderas", plast], ["Cuarto de servicio", tela]]
	for it in lista:
		var r := m._sala_por_nombre(it[0])
		if r.is_empty():
			continue
		var p := ZarekTerror._sitio_libre(m, r, 1.0)
		if p == Vector3.INF:
			continue
		var giro := _rng.randf() * TAU
		var dir := Vector3(1, 0, 0).rotated(Vector3.UP, giro)
		if it[1] == tela:
			_x(m, "cadaver_murder_scene_cloth_body", p, giro)
		else:
			_envuelto(m, p + Vector3(0, 0.2, 0), dir, it[1])
		_charco(m, p + dir * 0.2, 1.8)

## Despensa: carne colgada de ganchos en una barra del techo.
static func _despensa(m: ZarekMansion) -> void:
	var r := m._sala_por_nombre("Despensa")
	if r.is_empty():
		return
	var rc: Rect2 = r.rect
	var y := float(r.y) + 3.4
	var a := Vector3(rc.position.x + 1.2, y, rc.get_center().y)
	var b := Vector3(rc.end.x - 1.2, y, rc.get_center().y)
	var barra := m.box(Vector3(a.distance_to(b), 0.06, 0.06), (a + b) * 0.5, m._mat.hierro, false)
	barra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 4:
		var p := a.lerp(b, (k + 0.5) / 4.0)
		var punta := _gancho(m, p, y, 0.2)
		if k % 2 == 0:
			_colgado(m, "cerdo_lamb_in_carcass", punta + Vector3(0, 0.1, 0), 1.2, _rng.randf_range(-0.4, 0.4))
		else:
			_colgado(m, "cerdo_pig_carcass", punta + Vector3(0, 0.15, 0), 1.6, _rng.randf_range(-0.4, 0.4))
		_charco(m, Vector3(p.x, float(r.y), p.z), 0.9)

## Capilla: huesos roídos alrededor de donde comía la madre.
static func _capilla(m: ZarekMansion) -> void:
	var r := m._sala_por_nombre("Capilla del ritual")
	if r.is_empty():
		return
	for k in 14:
		var p := ZarekTerror._sitio_libre(m, r, 0.2)
		if p != Vector3.INF:
			_hueso(m, p, _rng.randf_range(0.25, 0.5), _rng.randf() * TAU)
	for k in 4:
		var p := ZarekTerror._sitio_libre(m, r, 0.3)
		if p != Vector3.INF:
			_x(m, "huesos_human_skull" if k < 3 else "huesos_skeleton_hand", p, _rng.randf() * TAU)

## El matadero (antes la galería de servicio): lo llama ZarekDecorado en lugar del taller.
static func matadero(m: ZarekMansion, r: Dictionary) -> void:
	_rng.seed = 1666
	_preparar()
	var rc: Rect2 = r.rect
	var y := float(r.y)
	var L := func(x: float, z: float, alto := 0.0) -> Vector3: return Vector3(rc.position.x + x, y + alto, rc.position.y + z)
	var plast := _mat("plastico", 0.35)
	# barra con ganchos: un cuerpo desollado, canales de cerdo y cordero, uno envuelto en plástico y un gancho vacío
	var ya := y + 3.3
	var a: Vector3 = L.call(7.0, 2.6, 3.3)
	var b: Vector3 = L.call(13.8, 2.6, 3.3)
	m.box(Vector3(a.distance_to(b), 0.08, 0.08), (a + b) * 0.5, m._mat.hierro, false)
	for s in [a, b]:
		m.box(Vector3(0.08, 0.6, 0.08), s + Vector3(0, 0.3, 0), m._mat.hierro, false)
	var cuelgan := ["cerdo", "desollado", "cordero", "plastico", "vacio", "cerdo"]
	for k in cuelgan.size():
		var p := a.lerp(b, (k + 0.5) / cuelgan.size())
		var punta := _gancho(m, p, ya, 0.3)
		var giro := _rng.randf_range(-0.5, 0.5)
		match cuelgan[k]:
			"cerdo":
				_colgado(m, "cerdo_pig_carcass", punta + Vector3(0, 0.15, 0), 1.6, giro)
			"cordero":
				_colgado(m, "cerdo_lamb_in_carcass", punta + Vector3(0, 0.1, 0), 1.2, giro)
			"desollado":
				_colgado(m, "restos_skeleton_gore_model", punta + Vector3(0, 0.05, 0), 1.75, giro)
			"plastico":
				_envuelto(m, punta - Vector3(0, 0.9, 0), Vector3.UP, plast)
		if cuelgan[k] != "vacio":
			_charco(m, Vector3(p.x, y, p.z), _rng.randf_range(0.9, 1.4))
	# mesa de despiece: tablón manchado con vísceras, una mano cortada, cuchillas y el hacha
	var mc: Vector3 = L.call(10.0, 7.2)
	m.box(Vector3(2.4, 0.12, 1.0), mc + Vector3(0, 0.88, 0), m._mat.madera_vieja, true)
	for q in [Vector3(-1.05, 0, -0.38), Vector3(1.05, 0, -0.38), Vector3(-1.05, 0, 0.38), Vector3(1.05, 0, 0.38)]:
		m.box(Vector3(0.12, 0.82, 0.12), mc + q + Vector3(0, 0.41, 0), m._mat.madera_vieja, false)
	var top := mc + Vector3(0, 0.94, 0)
	ZarekTerror._calco(m, "sangre_charco_1", top + Vector3(0, 0.005, 0), Vector3.UP, Vector2(1.7, 1.0), 0.0)
	_x(m, "organos_small_and_large_intestin", top + Vector3(-0.55, 0, 0.05), 0.4, 1.0)
	_x(m, "organos_human_liver", top + Vector3(-0.1, 0, -0.2), 1.1)
	_x(m, "organos_human_heart", top + Vector3(0.15, 0, 0.18), 2.0)
	_x(m, "restos_severed_hand", top + Vector3(0.5, 0, -0.1), 0.7)
	_x(m, "carnicero_cleaver___butcher_s_best", top + Vector3(0.85, 0, 0.25), 1.6)
	_x(m, "carnicero_knife_collection", top + Vector3(0.75, 0, -0.32), 0.1, 0.8)
	_cubo_sangre(m, mc + Vector3(0.4, 0, 0.75))
	_charco(m, mc, 2.4)
	# gancho de sacrificio (viga con gancho ensangrentado) en la esquina
	_x(m, "carnicero_sacrificial_hook", L.call(1.3, 1.3), PI * 0.25, 1.0, true)
	# silla de bruja con púas y correas, el aplastacabezas y cadenas colgando de la pared
	_x(m, "tortura_witch_s_chair", L.call(2.6, 9.4), PI * 0.15, 1.0, true)
	_charco(m, L.call(2.6, 9.4), 2.0)
	_x(m, "tortura_rusty_chains", L.call(3.4, 8.4), 0.6)
	_x(m, "tortura_head_crusher", L.call(5.6, 11.4), PI, 1.0, true)
	_x(m, "tortura_hanging_wall_chains", L.call(0.12, 6.0, 1.0), PI * 0.5)
	_x(m, "tortura_iron_shackles", L.call(0.15, 4.2, 1.2), PI * 0.5)
	_x(m, "tortura_rusted_chain_shackles", L.call(1.0, 5.0), 0.8)
	# jaula colgada con un esqueleto dentro
	var jc: Vector3 = L.call(5.0, 6.5)
	_x(m, "tortura_medieval_asset_19__cage", jc, 0.3, 1.0, true)
	_x(m, "huesos_skeleton", jc + Vector3(0, 0.12, 0), 0.3, 0.85)
	# cama ensangrentada donde los ata, y cuerpo bajo una sábana empapada
	_x(m, "cadaver_dead_body", L.call(12.2, 10.2), PI * 0.5, 1.0, true)
	ZarekTerror._calco(m, "sangre_charco_3", L.call(12.2, 10.0, 0.9), Vector3.UP, Vector2(0.7, 0.7), 0.4)
	ZarekTerror._calco(m, "sangre_salpicadura_2", L.call(12.2, 10.7, 0.88), Vector3.UP, Vector2(0.6, 0.6), 1.3)
	_charco(m, L.call(12.2, 10.2), 1.6)
	_x(m, "cadaver_murder_scene_cloth_body", L.call(8.2, 9.6), 1.9)
	_charco(m, L.call(8.2, 9.6), 2.0)
	# calaveras, huesos y frascos con restos en una repisa
	var rep: Vector3 = L.call(9.0, 0.3, 1.45)
	m.box(Vector3(2.6, 0.06, 0.4), rep, m._mat.madera_vieja, false)
	_x(m, "huesos_human_skull", rep + Vector3(-0.9, 0.03, 0.02), PI)
	_x(m, "organos_brain_in_a_jar", rep + Vector3(-0.3, 0.03, 0.0), PI)
	_x(m, "restos_formaldehyde_jar_asset_p", rep + Vector3(0.45, 0.03, 0.0), PI)
	_x(m, "huesos_human_skull", rep + Vector3(1.0, 0.03, 0.02), PI * 0.8)
	for k in 10:
		_hueso(m, L.call(_rng.randf_range(4.0, 6.5), _rng.randf_range(10.4, 11.4)), _rng.randf_range(0.2, 0.5), _rng.randf() * TAU)
	_x(m, "huesos_human_skull", L.call(4.6, 11.0), 0.7)
	_x(m, "huesos_skeleton_hand", L.call(5.6, 10.6), 2.0)
	_x(m, "restos_bloody_axe", L.call(13.9, 6.8, 0.0), -PI * 0.5)
	_cubo_sangre(m, L.call(8.2, 11.2))
	_cubo_sangre(m, L.call(6.6, 3.0))
	# desagüe en el centro con sangre acumulada y el rastro desde la puerta
	var dc: Vector3 = L.call(7.8, 6.4)
	m.cyl(0.18, 0.18, 0.01, dc + Vector3(0, 0.005, 0), m._mat.hierro, m._house, 12)
	_charco(m, dc + Vector3(0.6, 0, 0), 2.6)
	_rastro(m, L.call(7.2, 0.4), dc, 0.7)
	for k in 4:
		ZarekTerror._en_pared(m, r, "sangre_salpicadura_%d" % _rng.randi_range(1, 3), Vector2(1.5, 1.5), 1.3)
	for k in 2:
		ZarekTerror._en_pared(m, r, "sangre_goteo_%d" % _rng.randi_range(1, 2), Vector2(1.0, 2.0), 1.4)
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.35, 0.25)
	luz.light_energy = 0.7
	luz.omni_range = 9.0
	luz.position = L.call(9.5, 6.0, 3.2)
	m._house.add_child(luz)
	m.cyl(0.06, 0.06, 0.12, luz.position, m._mat.ventana_luz, m._house, 8)
