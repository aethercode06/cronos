class_name ZarekTerror
extends RefCounted
## Lo que hace que la Mansión Varela dé miedo por sí sola: escritos en las paredes, arañazos, huellas de manos,
## círculos de sal viejos, dibujos infantiles, retratos con la cara rayada, espejos tapados (y uno roto), la bañera
## con agua sucia, ventanas tapiadas con tablas, tablones rotos que crujen al pisarlos, goteras, el ojo de buey del
## ático, el montaplatos, la capilla del ritual del sótano, el cementerio familiar y el invernadero en ruinas.
## Texturas: tools/terror/texturas.py (dibujadas por código). Se aplica después del abandono.

static var _mats := {}
static var _rng := RandomNumberGenerator.new()
static var _puestos: Array = []  # centros de calcomanías de pared ya puestas (para no amontonarlas)

static var _muebles: Array = []  # [pos, alto, radio] de los muebles y cuadros (para no pintar encima)

static func aplicar(m: ZarekMansion) -> void:
	if OS.get_environment("SIN_TERROR") != "":
		return
	_rng.seed = 2311
	_puestos.clear()
	_muebles.clear()
	for n in m._house.get_children():
		var nd := n as Node3D
		if nd and nd.scene_file_path != "":
			var nom := nd.scene_file_path.get_file().get_basename()
			var t := m._prop_size(nom) * nd.scale.x
			_muebles.append([nd.global_position, t.y, maxf(t.x, t.z) * 0.5, nom.contains("frame") or nom.contains("mirror") or nom.contains("portrait") or nom.contains("head") or nom.contains("clock"), nom.begins_with("cortina") or nom.begins_with("luz_")])
	var t0 := Time.get_ticks_msec()
	_cortinas_tapadas(m)
	_escritos(m)
	_retratos_rayados(m)
	_espejos(m)
	_banera(m)
	_ventanas_tapiadas(m)
	_puerta_tapiada(m)
	_suelo_roto(m)
	_goteras(m)
	_ojo_de_buey(m)
	_montaplatos(m)
	_capilla(m)
	_cementerio(m)
	_invernadero(m)
	_reloj_parado(m)
	_mirilla(m)
	print("ZAREK terror: %d calcomanías, %d tablones que crujen (%d ms)" % [_puestos.size(), m.crujidos.size(), Time.get_ticks_msec() - t0])

# ---------------- materiales ----------------
static func _mat(nombre: String, rugosidad := 0.92) -> StandardMaterial3D:
	if _mats.has(nombre):
		return _mats[nombre]
	var mt := StandardMaterial3D.new()
	var ruta := "res://zarek/terror/%s.png" % nombre
	if ResourceLoader.exists(ruta):
		mt.albedo_texture = load(ruta)
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.roughness = rugosidad
	mt.cull_mode = BaseMaterial3D.CULL_BACK
	mt.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[nombre] = mt
	return mt

## Una calcomanía (quad con transparencia) sobre una superficie: centro, normal hacia fuera, tamaño.
static func _calco(m: ZarekMansion, nombre: String, centro: Vector3, normal: Vector3, tam: Vector2, giro := 0.0, padre: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = tam
	mi.mesh = q
	mi.material_override = _mat(nombre)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var z := normal.normalized()
	var arriba := Vector3.UP if absf(z.y) < 0.9 else Vector3(sin(giro), 0, cos(giro))
	var x := arriba.cross(z).normalized()
	var y := z.cross(x).normalized()
	var b := Basis(x, y, z)
	if absf(z.y) < 0.9 and giro != 0.0:
		b = b.rotated(z, giro)
	mi.transform = Transform3D(b, centro + z * 0.007)
	(padre if padre else m._house).add_child(mi)
	return mi

## Pone una calcomanía en una pared libre de la sala (sin puertas, ventanas ni otras calcomanías cerca).
static func _en_pared(m: ZarekMansion, r: Dictionary, nombre: String, tam: Vector2, altura: float, girar := 0.0) -> bool:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	for intento in 24:
		var lado := _rng.randi() % 4
		var margen := tam.x * 0.5 + 0.35
		var p: Vector3
		var fuera: Vector3
		match lado:
			0:
				if rc.size.x < margen * 2.0: continue
				p = Vector3(_rng.randf_range(rc.position.x + margen, rc.end.x - margen), y, rc.position.y); fuera = Vector3(0, 0, -1)
			1:
				if rc.size.x < margen * 2.0: continue
				p = Vector3(_rng.randf_range(rc.position.x + margen, rc.end.x - margen), y, rc.end.y); fuera = Vector3(0, 0, 1)
			2:
				if rc.size.y < margen * 2.0: continue
				p = Vector3(rc.position.x, y, _rng.randf_range(rc.position.y + margen, rc.end.y - margen)); fuera = Vector3(-1, 0, 0)
			_:
				if rc.size.y < margen * 2.0: continue
				p = Vector3(rc.end.x, y, _rng.randf_range(rc.position.y + margen, rc.end.y - margen)); fuera = Vector3(1, 0, 0)
		if not m._pared_libre(r, p, fuera) or not m.door_near(p, tam.x * 0.5 + 1.0).is_empty():
			continue
		if m.ventana_cerca(p, tam.x * 0.5 + 1.0):
			continue
		var c := p - fuera * (m._sep_pared(p, fuera) - 0.004) + Vector3(0, altura, 0)
		var cerca := false
		for mu in _muebles:
			var mp: Vector3 = mu[0]
			if absf(mp.y - y) > 4.0 or Vector2(mp.x - c.x, mp.z - c.z).length() > tam.x * 0.5 + float(mu[2]) + 0.25:
				continue
			# los cuadros y espejos cuelgan (su origen es el centro); los muebles van del suelo hacia arriba
			var bajo: float = mp.y - float(mu[1]) * 0.5 if mu[3] else mp.y
			var alto: float = mp.y + float(mu[1]) * 0.5 if mu[3] else mp.y + float(mu[1])
			if alto > c.y - tam.y * 0.5 - 0.05 and bajo < c.y + tam.y * 0.5 + 0.05:
				cerca = true
				break
		for q in _puestos:
			if (q as Vector3).distance_to(c) < maxf(tam.x, 1.2):
				cerca = true
				break
		if cerca:
			continue
		_calco(m, nombre, c, -fuera, tam, girar)
		_puestos.append(c)
		return true
	return false

static func _en_suelo(m: ZarekMansion, nombre: String, c: Vector3, tam: float, giro := 0.0) -> void:
	_calco(m, nombre, c + Vector3(0, 0.006, 0), Vector3.UP, Vector2(tam, tam), giro)

static func _sala(m: ZarekMansion, nombre: String) -> Dictionary:
	return m._sala_por_nombre(nombre)

static func _local(r: Dictionary, x: float, z: float, alto := 0.0) -> Vector3:
	var rc: Rect2 = r.rect
	return Vector3(rc.position.x + x, float(r.y) + alto, rc.position.y + z)

# ---------------- escritos, arañazos, manos, humedad ----------------
const ESCRITOS := {
	"Vestíbulo y gran escalera": [["esc_sigue_aqui", 2.2, 1.1, 2.6], ["manos_sangre", 1.1, 1.1, 1.3]],
	"Pasillo": [["esc_no_mires", 1.8, 0.9, 2.3], ["aranazos_1", 0.5, 1.0, 1.1], ["manos_sucias", 1.0, 1.0, 1.0]],
	"Pasillo principal": [["esc_ya_viene", 2.0, 0.5, 2.5], ["manos_sucias", 1.0, 1.0, 1.2], ["aranazos_2", 0.5, 1.0, 0.9]],
	"Cuarto de niños": [["esc_clara", 1.6, 0.8, 1.5], ["mano_nina", 0.6, 0.6, 0.7], ["dibujo_familia", 0.42, 0.52, 1.25], ["dibujo_casa", 0.42, 0.52, 1.2], ["dibujo_ojos", 0.42, 0.52, 1.3]],
	"Cuarto de Damián": [["esc_sigue_aqui", 2.2, 1.1, 2.4], ["esc_perdonanos", 1.8, 0.45, 1.4], ["manos_sangre", 1.0, 1.0, 1.3], ["aranazos_1", 0.5, 1.0, 1.4], ["aranazos_2", 0.5, 1.0, 1.0], ["esc_palotes", 1.6, 0.8, 1.2]],
	"Cuarto de la institutriz": [["esc_perdonanos", 1.8, 0.45, 2.5]],
	"Cuarto del hermano": [["esc_la_sal", 1.5, 0.75, 2.3]],
	"Pasillo del sótano": [["esc_ya_viene", 2.0, 0.5, 2.3], ["humedad_1", 1.8, 1.8, 2.3], ["manos_sucias", 1.0, 1.0, 1.1]],
	"Sala de calderas": [["humedad_2", 1.8, 1.8, 2.2], ["aranazos_2", 0.5, 1.0, 1.0]],
	"Archivo": [["dibujo_pozo", 0.42, 0.52, 1.4], ["humedad_1", 1.6, 1.6, 2.4]],
	"Cava de vinos": [["humedad_2", 1.8, 1.8, 2.0]],
	"Salón de baile": [["esc_1974", 1.8, 0.45, 2.7]],
	"Ático (vigas, baúles, muñecos tapados)": [["esc_palotes", 1.6, 0.8, 1.3], ["dibujo_pozo", 0.42, 0.52, 1.2], ["aranazos_1", 0.5, 1.0, 1.0]],
	"Escondite de Damián niño": [["dibujo_familia", 0.42, 0.52, 1.2], ["mano_nina", 0.6, 0.6, 0.9]],
	"Baño": [["manos_sangre", 1.0, 1.0, 1.3], ["humedad_2", 1.4, 1.4, 2.6]],
	"Galería de servicio": [["humedad_1", 1.8, 1.8, 2.0], ["esc_palotes", 1.4, 0.7, 1.4]],
	"Cuarto de servicio": [["humedad_2", 1.4, 1.4, 2.4]],
	"Comedor formal": [["aranazos_2", 0.5, 1.0, 1.0]],
	"Dormitorio de los padres": [["humedad_1", 1.4, 1.4, 2.8]],
	"Biblioteca": [["humedad_2", 1.4, 1.4, 2.9]],
	"Capilla de la madre": [["esc_no_abras", 2.0, 1.0, 2.2], ["esc_perdonanos", 1.8, 0.45, 1.6], ["humedad_1", 1.8, 1.8, 2.2]],
}

static func _escritos(m: ZarekMansion) -> void:
	for nombre in ESCRITOS:
		for r in m.rooms:
			if String(r.name) != nombre:
				continue
			for e in ESCRITOS[nombre]:
				_en_pared(m, r, e[0], Vector2(e[1], e[2]), e[3], _rng.randf_range(-0.05, 0.05))

## Un punto del suelo de la sala sin muebles cerca (se comprueba con los cuerpos de colisión ya creados).
static func _sitio_libre(m: ZarekMansion, r: Dictionary, radio: float) -> Vector3:
	var rc: Rect2 = r.rect
	var cajas := _cajas_muebles(m)
	for intento in 60:
		var p := Vector3(_rng.randf_range(rc.position.x + radio + 0.4, rc.end.x - radio - 0.4), float(r.y), _rng.randf_range(rc.position.y + radio + 0.4, rc.end.y - radio - 0.4))
		if rc.size.x < radio * 2.0 + 0.8 or rc.size.y < radio * 2.0 + 0.8:
			p = Vector3(rc.get_center().x, float(r.y), rc.get_center().y)
		if not m.door_near(p, radio + 1.0).is_empty() or m._huella_en_escalera(p, Vector3(radio * 2, 0.2, radio * 2), 0.0):
			continue
		# nada de muebles (ni colisión ni solo malla) dentro de la huella, con 15 cm de aire alrededor
		var huella := Rect2(p.x - radio * 0.5 - 0.15, p.z - radio * 0.5 - 0.15, radio + 0.3, radio + 0.3)
		var libre := true
		for c in cajas:
			var b: AABB = c
			if b.end.y < p.y + 0.06 or b.position.y > p.y + 1.3:
				continue
			if huella.intersects(Rect2(b.position.x, b.position.z, b.size.x, b.size.z)):
				libre = false
				break
		if libre and _choca_caja(m, p, radio):
			libre = false
		if libre:
			# reservar el sitio para los que vengan después
			cajas.append(AABB(Vector3(p.x - radio * 0.5, p.y, p.z - radio * 0.5), Vector3(radio, 0.9, radio)))
			return p
	# sala llena: el sitio menos malo (sin puertas ni escaleras), mejor algo apretado que nada
	for intento in 30:
		var p := Vector3(_rng.randf_range(rc.position.x + 0.6, rc.end.x - 0.6), float(r.y), _rng.randf_range(rc.position.y + 0.6, rc.end.y - 0.6))
		if m.door_near(p, radio + 0.9).is_empty() and not m._huella_en_escalera(p, Vector3(radio * 2, 0.2, radio * 2), 0.0) and not _choca_caja(m, p, radio * 0.6):
			return p
	return Vector3.INF

## ¿Hay colisión (muros, tabiques, muebles con cuerpo) en la huella de un objeto de `radio` puesto en el suelo en p?
static func _choca_caja(m: ZarekMansion, p: Vector3, radio: float, excluir: Array[RID] = []) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(radio, 0.9, radio)
	q.shape = bx
	q.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, 0.55, 0))
	q.collision_mask = 1 | 8
	q.exclude = excluir
	return not m.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()

## Cajas (en el mundo) de todo lo que hay en la casa con malla: muebles, objetos, tabiques... sin suelos, techos,
## alfombras, calcomanías ni muros largos. Se va ampliando con lo que se añade después.
static func _cajas_muebles(m: ZarekMansion) -> Array:
	if not m.has_meta("cajas_muebles"):
		m.set_meta("cajas_muebles", [])
		m.set_meta("cajas_vistos", 0)
	var cajas: Array = m.get_meta("cajas_muebles")
	var vistos: int = m.get_meta("cajas_vistos")
	var hijos := m._house.get_children()
	if hijos.size() < vistos:
		cajas.clear()
		vistos = 0
	for i in range(vistos, hijos.size()):
		var n := hijos[i] as Node3D
		if n == null:
			continue
		var mallas: Array = n.find_children("*", "MeshInstance3D", true, false)
		if n is MeshInstance3D:
			mallas.append(n)
		if mallas.is_empty() or mallas.size() > 80:
			continue
		var ab := AABB()
		var primera := true
		for mi in mallas:
			var gm := mi as MeshInstance3D
			if gm.mesh == null:
				continue
			var b: AABB = gm.global_transform * gm.get_aabb()
			ab = b if primera else ab.merge(b)
			primera = false
		if primera or ab.size.y < 0.08 or ab.size.x > 3.6 or ab.size.z > 3.6:
			continue
		cajas.append(ab)
	m.set_meta("cajas_vistos", hijos.size())
	return cajas

# ---------------- retratos con la cara rayada ----------------
static func _retratos_rayados(m: ZarekMansion) -> void:
	var salas := ["Galería de retratos", "Dormitorio de los padres", "Vestíbulo y gran escalera", "Estudio del padre"]
	var n := 0
	for c in m._house.get_children():
		var nd := c as Node3D
		if nd == null or nd.scene_file_path == "":
			continue
		var f := nd.scene_file_path.get_file()
		if not (f.contains("picture_frame") or f.contains("portrait")):
			continue
		var id := m.room_at(nd.global_position - Vector3(0, 1.6, 0))
		if id < 0 or not String(m.rooms[id].name) in salas:
			continue
		# en la galería, casi todos; en las demás salas, uno de cada tres
		if String(m.rooms[id].name) != "Galería de retratos" and _rng.randf() > 0.34:
			continue
		for mi in nd.find_children("*", "MeshInstance3D", true, false):
			var m3 := mi as MeshInstance3D
			for si in m3.mesh.get_surface_count():
				var mt := m3.get_surface_override_material(si) as StandardMaterial3D
				if mt == null or mt.albedo_texture == null or not mt.albedo_texture.resource_path.contains("pinturas"):
					continue
				var raya := StandardMaterial3D.new()
				raya.albedo_texture = load("res://zarek/terror/rayado_%d.png" % (1 + n % 2))
				raya.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				raya.roughness = 0.95
				raya.render_priority = 1
				raya.uv1_scale = mt.uv1_scale
				raya.uv1_offset = mt.uv1_offset
				mt.next_pass = raya
				n += 1
	print("ZAREK   retratos rayados: %d" % n)

# ---------------- cortinas detrás de armarios y estanterías: se quitan (asomaban por un lado) ----------------
static func _cortinas_tapadas(m: ZarekMansion) -> void:
	var altos: Array = []
	var cortinas: Array = []
	for n in m._house.get_children():
		var nd := n as Node3D
		if nd == null or nd.scene_file_path == "":
			continue
		var nom := nd.scene_file_path.get_file()
		if nom.begins_with("cortina"):
			cortinas.append(nd)
		elif m._prop_size(nom.get_basename()).y * nd.scale.y > 1.3:
			altos.append(m._caja_mallas(nd))
	var quitadas := 0
	for c in cortinas:
		var cc: AABB = m._caja_mallas(c).grow(-0.03)
		for ab in altos:
			if (ab as AABB).grow(0.05).intersects(cc):
				c.queue_free()
				quitadas += 1
				break
	print("ZAREK   cortinas tapadas por muebles: %d de %d" % [quitadas, cortinas.size()])

# ---------------- espejos: tapados con telas; el del baño, roto ----------------
static func _espejos(m: ZarekMansion) -> void:
	for c in m._house.get_children():
		var nd := c as Node3D
		if nd == null or nd.scene_file_path == "" or not nd.scene_file_path.get_file().contains("mirror"):
			continue
		if nd.scene_file_path.get_file().contains("espejo_roto"):
			continue
		var ab := m._caja_mallas(nd)
		if ab.size.y < 0.3:
			continue
		var id := m.room_at(nd.global_position - Vector3(0, 1.6, 0)) if nd.global_position.y - floorf(nd.global_position.y / 4.2) * 4.2 > 0.8 else m.room_at(nd.global_position + Vector3(0, 0.3, 0))
		var sala := String(m.rooms[id].name) if id >= 0 else ""
		# el frente del espejo: el eje delgado de su caja, hacia el centro de la sala (el eje z del modelo no
		# siempre mira al frente y la tela quedaba al lado del espejo)
		var cen := ab.get_center()
		var sc: Vector2 = (m.rooms[id].rect as Rect2).get_center() if id >= 0 else Vector2(cen.x, cen.z)
		var frente := Vector3(signf(sc.x - cen.x), 0, 0) if ab.size.x < ab.size.z else Vector3(0, 0, signf(sc.y - cen.z))
		if frente == Vector3.ZERO:
			frente = Vector3(0, 0, 1)
		if sala == "Baño" or sala == "Tocador de la madre":
			# roto: grietas sobre el cristal
			var cc := ab.get_center()
			var ancho := maxf(ab.size.x, ab.size.z) * 0.8
			var g := _calco(m, "grietas_espejo", cc + frente * (minf(ab.size.x, ab.size.z) * 0.5 + 0.01), frente, Vector2(ancho, ab.size.y * 0.8))
			g.reparent(nd)
			continue
		# solo espejos planos y alineados con la pared: en uno girado en diagonal la tela quedaba al lado
		if minf(ab.size.x, ab.size.z) > maxf(ab.size.x, ab.size.z) * 0.4:
			continue
		_tela_espejo(m, nd, ab, frente)

## Tela caída sobre un espejo (pliegues verticales, se ensancha abajo).
static func _tela_espejo(m: ZarekMansion, nd: Node3D, ab: AABB, frente: Vector3) -> void:
	var ancho := maxf(ab.size.x, ab.size.z) + 0.12
	var alto := ab.size.y + 0.08
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 14
	var ny := 10
	var semilla := _rng.randf() * 10.0
	var pts := []
	for j in ny + 1:
		var fila := []
		var v := float(j) / ny
		for i in nx + 1:
			var u := float(i) / nx
			var abre := 1.0 + 0.25 * v * v
			var x := (u - 0.5) * ancho * abre
			var pliegue := sin(u * 16.0 + semilla) * 0.07 * (0.35 + v) + sin(u * 6.0 + semilla * 2.0) * 0.05 + sin(v * 9.0 + u * 4.0) * 0.02
			fila.append(Vector3(x, alto * (1.0 - v) - 0.04 * v * v, 0.03 + pliegue + 0.05 * v * v))
		pts.append(fila)
	for j in ny:
		for i in nx:
			var a: Vector3 = pts[j][i]
			var b: Vector3 = pts[j][i + 1]
			var cq: Vector3 = pts[j + 1][i]
			var d: Vector3 = pts[j + 1][i + 1]
			for tri in [[a, b, cq, Vector2(float(i) / nx, float(j) / ny), Vector2(float(i + 1) / nx, float(j) / ny), Vector2(float(i) / nx, float(j + 1) / ny)],
					[b, d, cq, Vector2(float(i + 1) / nx, float(j) / ny), Vector2(float(i + 1) / nx, float(j + 1) / ny), Vector2(float(i) / nx, float(j + 1) / ny)]]:
				for k in 3:
					st.set_uv(tri[3 + k])
					st.add_vertex(tri[k])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = ZarekAbandono._mat_sabana if ZarekAbandono._mat_sabana else m._mat.sabana
	var yaw := atan2(frente.x, frente.z)
	var base := Vector3(ab.get_center().x, ab.position.y - 0.04, ab.get_center().z) + frente * (minf(ab.size.x, ab.size.z) * 0.5)
	nd.add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP, yaw), base)

# ---------------- bañera con agua sucia ----------------
static func _banera(m: ZarekMansion) -> void:
	for c in m._house.get_children():
		var nd := c as Node3D
		if nd == null or nd.scene_file_path == "" or not (nd.scene_file_path.get_file().contains("bathtub") or nd.scene_file_path.get_file().contains("bathtube")):
			continue
		var ab := m._caja_mallas(nd)
		# agua: un óvalo plano dentro de la bañera (no un rectángulo que se sale por los bordes)
		var agua := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.5
		cm.bottom_radius = 0.5
		cm.height = 0.004
		cm.radial_segments = 32
		cm.rings = 1
		agua.mesh = cm
		var largo_x := ab.size.x > ab.size.z
		agua.scale = Vector3(ab.size.x * (0.72 if largo_x else 0.5), 1.0, ab.size.z * (0.5 if largo_x else 0.72))
		var mt := StandardMaterial3D.new()
		mt.albedo_texture = load("res://zarek/terror/agua_sucia.png")
		mt.albedo_color = Color(0.55, 0.5, 0.35)
		mt.roughness = 0.08
		mt.metallic_specular = 0.8
		agua.material_override = mt
		agua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nd.add_child(agua)
		print("ZAREK   bañera: ", ab.get_center())
		agua.global_position = Vector3(ab.get_center().x, ab.position.y + ab.size.y * 0.5, ab.get_center().z)
		agua.global_basis = Basis().scaled(agua.scale)

# ---------------- ventanas tapiadas con tablas ----------------
static func _ventanas_tapiadas(m: ZarekMansion) -> void:
	var mad: Material = m._mat.madera_vieja
	var n := 0
	for w in m.ventanas_info:
		var c: Vector3 = w.c
		var lv := m.level_of(c.y + 0.3)
		if lv < 0 or (w.inward as Vector3) == Vector3.ZERO:
			continue
		# en la planta baja, casi la mitad; arriba, alguna
		if _rng.randf() > (0.45 if lv == 0 else 0.15):
			continue
		var dentro: Vector3 = w.inward
		var tapada := false
		for mu in _muebles:
			var pm: Vector3 = mu[0]
			if not mu[4] and mu[1] > 1.3 and absf(pm.y - c.y) < 1.0 and Vector2(pm.x - c.x, pm.z - c.z).length() < 0.9 + mu[2]:
				tapada = true
		if tapada:
			continue
		var along := Vector3(1, 0, 0) if w.horiz else Vector3(0, 0, 1)
		var yaw := atan2(along.x, along.z) - PI * 0.5
		var cuantas := _rng.randi_range(3, 5)
		w["tapiada"] = true
		w["tablas"] = []
		for k in cuantas:
			var hy := lerpf(1.1, 2.7, (k + _rng.randf_range(-0.2, 0.2)) / maxf(1.0, cuantas - 1))
			var largo := _rng.randf_range(2.0, 2.3)
			var tabla := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(largo, _rng.randf_range(0.16, 0.24), 0.035)
			tabla.mesh = bm
			tabla.material_override = mad
			var p := c + dentro * (float(w.get("thick", 0.45)) * 0.5 + 0.03 + k * 0.006) + Vector3(0, hy, 0) + along * _rng.randf_range(-0.12, 0.12)
			tabla.transform = Transform3D(Basis(Vector3.UP, yaw).rotated(dentro, _rng.randf_range(-0.22, 0.22)), p)
			m._house.add_child(tabla)
			(w["tablas"] as Array).append(tabla)
			# clavos
			for s in [-1.0, 1.0]:
				var cl := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.012; cm.bottom_radius = 0.012; cm.height = 0.02; cm.radial_segments = 6
				cl.mesh = cm
				cl.material_override = m._mat.metal
				tabla.add_child(cl)
				cl.position = Vector3(s * (largo * 0.5 - 0.12), 0, 0.02)
				cl.rotation.x = PI * 0.5
		if n == 0:
			print("ZAREK   ventana tapiada: ", c, " dentro ", dentro)
		n += 1
	print("ZAREK   ventanas tapiadas: %d" % n)

## Puertas viejas clavadas con tablas en el sótano: no llevan a ninguna parte (o eso parece).
static func _puerta_tapiada(m: ZarekMansion) -> void:
	for nombre in ["Pasillo del sótano", "Galería de servicio"]:
		var r := _sala(m, nombre)
		if r.is_empty():
			continue
		var rc: Rect2 = r.rect
		var y := float(r.y)
		for intento in 30:
			var lado := _rng.randi() % 4
			var p: Vector3
			var fuera: Vector3
			match lado:
				0: p = Vector3(_rng.randf_range(rc.position.x + 1.2, rc.end.x - 1.2), y, rc.position.y); fuera = Vector3(0, 0, -1)
				1: p = Vector3(_rng.randf_range(rc.position.x + 1.2, rc.end.x - 1.2), y, rc.end.y); fuera = Vector3(0, 0, 1)
				2: p = Vector3(rc.position.x, y, _rng.randf_range(rc.position.y + 1.2, rc.end.y - 1.2)); fuera = Vector3(-1, 0, 0)
				_: p = Vector3(rc.end.x, y, _rng.randf_range(rc.position.y + 1.2, rc.end.y - 1.2)); fuera = Vector3(1, 0, 0)
			if (lado < 2 and rc.size.x < 2.6) or (lado >= 2 and rc.size.y < 2.6):
				continue
			if not m._pared_libre(r, p, fuera) or not m.door_near(p, 2.2).is_empty():
				continue
			var hay := false
			for q in _puestos:
				if (q as Vector3).distance_to(p + Vector3(0, 1.2, 0)) < 1.8:
					hay = true
			if hay:
				continue
			var cara := p - fuera * (m._sep_pared(p, fuera) - 0.004)
			var along := Vector3(absf(fuera.z), 0, absf(fuera.x))
			var hoja := Vector3(1.1, 2.2, 0.06) if absf(fuera.z) > 0.5 else Vector3(0.06, 2.2, 1.1)
			m.box(hoja + Vector3(0.16 * along.x, 0.08, 0.16 * along.z), cara - fuera * 0.02 + Vector3(0, 1.12, 0), m._mat.madera, false, m._house, false)
			m.box(hoja, cara - fuera * 0.045 + Vector3(0, 1.1, 0), m._mat.oscuro, false, m._house, false)
			var yaw := atan2(along.x, along.z) - PI * 0.5
			for k in 4:
				var tabla := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(1.5, 0.19, 0.04)
				tabla.mesh = bm
				tabla.material_override = m._mat.madera_vieja
				tabla.transform = Transform3D(Basis(Vector3.UP, yaw).rotated(fuera, [0.45, -0.5, 0.08, -0.1][k]), cara - fuera * 0.1 + Vector3(0, [0.6, 1.1, 1.6, 2.0][k], 0))
				m._house.add_child(tabla)
			_calco(m, "aranazos_puerta", cara - fuera * 0.125 + Vector3(0, 1.0, 0), -fuera, Vector2(0.55, 1.1))
			_puestos.append(p + Vector3(0, 1.2, 0))
			print("ZAREK   puerta tapiada: ", nombre, " ", cara.snapped(Vector3.ONE * 0.1), " fuera ", fuera)
			break

# ---------------- tablones rotos que crujen ----------------
static func _suelo_roto(m: ZarekMansion) -> void:
	var salas := ["Pasillo", "Pasillo principal", "Ático (vigas, baúles, muñecos tapados)", "Galería de retratos", "Cuarto de la institutriz",
		"Salón de baile", "Dormitorio de los padres", "Cuarto de huéspedes", "Biblioteca", "Escondite de Damián niño", "Cuarto de niños"]
	for r in m.rooms:
		if not String(r.name) in salas:
			continue
		var cuantos := 3 if String(r.name).begins_with("Pasillo") or String(r.name).begins_with("Ático") else 1
		for k in cuantos:
			var p := _sitio_libre(m, r, 0.6)
			if p == Vector3.INF:
				continue
			m.crujidos.append(p)
			if k == 0 and String(r.name) == "Pasillo principal":
				print("ZAREK   tablón roto: ", p.snapped(Vector3.ONE * 0.1))
			# un tablón partido: dos trozos levantados y el hueco oscuro debajo
			var giro := 0.0 if _rng.randf() < 0.5 else PI * 0.5
			var hueco := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.95, 0.01, 0.17)
			hueco.mesh = bm
			hueco.material_override = m._mat.oscuro
			hueco.transform = Transform3D(Basis(Vector3.UP, giro), p + Vector3(0, 0.003, 0))
			m._house.add_child(hueco)
			for s in [-1.0, 1.0]:
				var tz := MeshInstance3D.new()
				var tm := BoxMesh.new()
				tm.size = Vector3(0.48, 0.03, 0.15)
				tz.mesh = tm
				tz.material_override = m._mat.madera_vieja
				var b := Basis(Vector3.UP, giro).rotated(Basis(Vector3.UP, giro) * Vector3(0, 0, 1), s * _rng.randf_range(0.12, 0.25))
				tz.transform = Transform3D(b, p + Basis(Vector3.UP, giro) * Vector3(s * 0.26, 0.04, 0))
				m._house.add_child(tz)

# ---------------- goteras en el sótano ----------------
static func _goteras(m: ZarekMansion) -> void:
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.6, 0.65, 0.7, 0.7)
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.roughness = 0.05
	for nombre in ["Pasillo del sótano", "Sala de calderas", "Cava de vinos", "Capilla de la madre", "Baño"]:
		var r := _sala(m, nombre)
		if r.is_empty():
			continue
		var p := _sitio_libre(m, r, 0.3)
		if p == Vector3.INF:
			continue
		var pt := GPUParticles3D.new()
		pt.amount = 2
		pt.lifetime = 1.6
		pt.explosiveness = 0.0
		pt.randomness = 0.6
		pt.visibility_aabb = AABB(Vector3(-0.5, -4.2, -0.5), Vector3(1, 4.4, 1))
		var pm := ParticleProcessMaterial.new()
		pm.gravity = Vector3(0, -9.8, 0)
		pm.initial_velocity_min = 0.0
		pm.initial_velocity_max = 0.05
		pt.process_material = pm
		var gota := SphereMesh.new()
		gota.radius = 0.012
		gota.height = 0.04
		gota.radial_segments = 6
		gota.rings = 3
		gota.material = mt
		pt.draw_pass_1 = gota
		pt.position = p + Vector3(0, ZarekMansion.WALL_H - 0.05, 0)
		pt.set_meta("dyn", true)
		m._house.add_child(pt)
		# charco y sonido
		_en_suelo(m, "humedad_2", p, 0.9, _rng.randf() * TAU)
		var son := AudioStreamPlayer3D.new()
		var w := (AetherSynth.make("goteo") as AudioStreamWAV).duplicate() as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = w.data.size() / 2
		son.stream = w
		son.volume_db = -14.0
		son.unit_size = 2.0
		son.max_distance = 10.0
		son.autoplay = true
		son.position = p + Vector3(0, 0.1, 0)
		m._house.add_child(son)

# ---------------- ojo de buey del ático ----------------
static func _ojo_de_buey(m: ZarekMansion) -> void:
	var r := _sala(m, "Ático (vigas, baúles, muñecos tapados)")
	if r.is_empty():
		return
	var rc: Rect2 = r.rect
	var c := Vector3(rc.end.x - (m._sep_pared(Vector3(rc.end.x, float(r.y), rc.get_center().y), Vector3(1, 0, 0)) - 0.02), float(r.y) + 2.1, rc.get_center().y)
	var aro := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.55
	tm.rings = 24
	tm.ring_segments = 8
	aro.mesh = tm
	aro.material_override = m._mat.madera_vieja
	aro.transform = Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), c)
	m._house.add_child(aro)
	var vidrio := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = 0.43
	cy.bottom_radius = 0.43
	cy.height = 0.02
	cy.radial_segments = 24
	vidrio.mesh = cy
	var mv := StandardMaterial3D.new()
	mv.albedo_color = Color(0.12, 0.16, 0.25)
	mv.emission_enabled = true
	mv.emission = Color(0.35, 0.45, 0.75)
	mv.emission_energy_multiplier = 0.9
	mv.roughness = 0.1
	vidrio.material_override = mv
	vidrio.transform = Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), c + Vector3(0.02, 0, 0))
	m._house.add_child(vidrio)
	# cruz del marco
	for g in [0.0, PI * 0.5]:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.04, 0.86, 0.04)
		b.mesh = bm
		b.material_override = m._mat.madera_vieja
		b.transform = Transform3D(Basis(Vector3(1, 0, 0), g), c - Vector3(0.02, 0, 0))
		m._house.add_child(b)
	# la luna entra por él: luz fría que dibuja el círculo en el suelo
	var sl := SpotLight3D.new()
	sl.light_color = Color(0.55, 0.65, 1.0)
	sl.light_energy = 1.4
	sl.spot_range = 9.0
	sl.spot_angle = 16.0
	sl.shadow_enabled = false
	sl.transform = Transform3D(Basis.looking_at(Vector3(-1, -0.55, 0).normalized(), Vector3.UP), c - Vector3(0.1, 0, 0))
	m._house.add_child(sl)

# ---------------- montaplatos (despensa ↔ cuarto de plancha) ----------------
static func _montaplatos(m: ZarekMansion) -> void:
	for nombre in ["Despensa", "Cuarto de plancha"]:
		var r := _sala(m, nombre)
		if r.is_empty():
			continue
		var rc: Rect2 = r.rect
		# en la pared este (la fachada lateral), centrado en la sala
		var pz := rc.get_center().y
		var p := Vector3(rc.end.x, float(r.y), pz)
		var sep := m._sep_pared(p, Vector3(1, 0, 0))
		var x0 := rc.end.x - sep
		var mad: Material = m._mat.madera
		var oscuro: Material = m._mat.oscuro
		# mueble empotrado: marco, fondo negro (el hueco), la caja con la cuerda y la portezuela abierta
		m.box(Vector3(0.12, 2.3, 1.15), Vector3(x0 - 0.06, float(r.y) + 1.15, pz), mad, false, m._house, false)
		m.box(Vector3(0.02, 0.85, 0.85), Vector3(x0 - 0.125, float(r.y) + 1.35, pz), oscuro, false, m._house, false)
		m.box(Vector3(0.36, 0.06, 1.15), Vector3(x0 - 0.18, float(r.y) + 0.88, pz), mad, true, m._house, false)
		m.box(Vector3(0.36, 0.08, 1.15), Vector3(x0 - 0.18, float(r.y) + 1.82, pz), mad, false, m._house, false)
		# portezuela de guillotina medio subida
		m.box(Vector3(0.03, 0.4, 0.84), Vector3(x0 - 0.15, float(r.y) + 1.66, pz), m._mat.madera_vieja, false, m._house, false)
		# cuerdas
		for dz in [-0.32, 0.32]:
			m.box(Vector3(0.015, 0.9, 0.015), Vector3(x0 - 0.2, float(r.y) + 1.35, pz + dz), m._mat.madera_vieja, false, m._house, false)
		if nombre == "Despensa":
			m._prop("coci_basic_bowl", Vector3(x0 - 0.25, float(r.y) + 0.91, pz - 0.15), 0.0, 1.0, false)
		# el montaplatos sube y baja solo a ratos
		var son := AudioStreamPlayer3D.new()
		son.stream = AetherSynth.make("crujido")
		son.volume_db = -6.0
		son.unit_size = 3.0
		son.max_distance = 14.0
		son.position = Vector3(x0 - 0.2, float(r.y) + 1.3, pz)
		m._house.add_child(son)
		var t := Timer.new()
		t.wait_time = 55.0 + _rng.randf() * 40.0
		t.autostart = true
		t.timeout.connect(func(): if is_instance_valid(son) and son.is_inside_tree(): son.pitch_scale = randf_range(0.6, 0.85); son.play())
		son.add_child(t)
		m.montaplatos.append(Vector3(x0 - 0.3, float(r.y), pz))

# ---------------- capilla del ritual (sótano) ----------------
static func _capilla(m: ZarekMansion) -> void:
	pass  # la capilla ahora es la celda de la madre (ZarekGore.celda_madre)

# ---------------- cementerio familiar ----------------
const TUMBAS := ["lap_aurelio", "lap_esteban", "lap_isabel", "lap_tomas", "lap_clara", "lap_marta"]

static func _cementerio(m: ZarekMansion) -> void:
	var r := m._zone("Cementerio familiar")
	if r.size == Vector2.ZERO:
		return
	var y := 0.0
	# tierra removida y hierba seca
	m.box(Vector3(r.size.x, 0.04, r.size.y), Vector3(r.get_center().x, 0.035, r.get_center().y), m._mat.tierra, false, m, false)
	# verja de hierro alrededor, con la puerta abierta al norte (hacia el jardín trasero)
	_verja(m, r)
	# panteón al fondo (oeste), ángeles y lápidas viejas
	m._prop("t_cripta", Vector3(r.position.x + 2.6, y, r.get_center().y), PI * 0.5, 1.0, true, m)
	m._prop("t_angel_pedestal", Vector3(r.position.x + 5.2, y, r.position.y + 1.6), PI * 0.5 + 0.3, 1.0, true, m)
	m._prop("t_angel_reza", Vector3(r.position.x + 5.2, y, r.end.y - 1.6), PI * 0.5 - 0.3, 1.0, true, m)
	m._prop("t_lap_coleccion", Vector3(r.end.x - 2.2, y, r.position.y + 1.6), -PI * 0.5, 1.0, true, m)
	m._prop("t_lap_cruces", Vector3(r.end.x - 2.0, y, r.end.y - 1.7), -PI * 0.5, 1.0, true, m)
	# las tumbas de la familia, con nombre: en fila, mirando al este
	var x := r.position.x + 8.0
	for k in TUMBAS.size():
		var z := r.position.y + 1.8 + k * (r.size.y - 3.6) / float(TUMBAS.size() - 1)
		_lapida(m, Vector3(x, y, z), TUMBAS[k], false)
	# la de Elena, aparte: sin fecha de muerte y abierta, la tierra apartada
	_lapida(m, Vector3(r.end.x - 4.2, y, r.get_center().y), "lap_elena", true)
	var nota := {"pos": Vector3(r.end.x - 3.3, y, r.get_center().y), "titulo": "Tumba del padre", "texto": "«Aquí descansa el padre. 1987.» La tierra está removida y hay flores frescas, mordisqueadas. Alguien viene a verle… o a vigilar que no salga.", "nodo": Node3D.new(), "leida": false, "sala": "Cementerio familiar"}
	m.add_child(nota.nodo)
	m.notas.append(nota)
	var l := OmniLight3D.new()
	l.light_color = Color(0.55, 0.65, 1.0)
	l.light_energy = 0.35
	l.omni_range = 9.0
	l.position = Vector3(r.get_center().x, 3.0, r.get_center().y)
	m.add_child(l)

static func _verja(m: ZarekMansion, r: Rect2) -> void:
	var paso := 2.0
	var lados := [[Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y)],
		[Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y)], [Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y)]]
	for i in 4:
		var a: Vector2 = lados[i][0]
		var b: Vector2 = lados[i][1]
		var l := a.distance_to(b)
		var dir := (b - a) / l
		var n := int(l / paso)
		for k in n:
			var mid := a + dir * (k + 0.5) * (l / n)
			# hueco de la puerta en el lado este (hacia la casa)
			if i == 3 and absf(mid.y - r.get_center().y) < 1.6:
				continue
			var yaw := atan2(dir.x, dir.y) - PI * 0.5
			var v := m._prop("t_verja_hierro", Vector3(mid.x, 0, mid.y), yaw, 1.0, true, m)
			if v == null:
				m.box(Vector3(l / n, 1.3, 0.05) if absf(dir.x) > 0.5 else Vector3(0.05, 1.3, l / n), Vector3(mid.x, 0.65, mid.y), m._mat.metal, true, m)

## Lápida con nombre grabado (piedra y texto por código).
static func _lapida(m: ZarekMansion, p: Vector3, archivo: String, abierta: bool) -> void:
	var piedra: Material = m._mat.get("piedra_tumba", null)
	if piedra == null:
		var pt := (m._mat.piedra as BaseMaterial3D).duplicate() as BaseMaterial3D
		pt.albedo_color = Color(0.42, 0.42, 0.38)
		m._mat["piedra_tumba"] = pt
		piedra = pt
	var alto := 1.05 if not abierta else 1.25
	var lap := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.16, alto, 0.75)
	lap.mesh = bm
	lap.material_override = piedra
	var inclina := _rng.randf_range(-0.08, 0.08)
	lap.transform = Transform3D(Basis(Vector3(0, 0, 1), inclina), p + Vector3(0, alto * 0.5 - 0.05, 0))
	m.add_child(lap)
	var tapa := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.375; cm.bottom_radius = 0.375; cm.height = 0.16; cm.radial_segments = 16
	tapa.mesh = cm
	tapa.material_override = piedra
	tapa.position = Vector3(0, alto * 0.5, 0)
	tapa.rotation.z = PI * 0.5
	lap.add_child(tapa)
	var cuerpo := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.16, alto, 0.75)
	cs.shape = sh
	cuerpo.add_child(cs)
	lap.add_child(cuerpo)
	# el nombre grabado
	var tex := _texto_lapida(archivo)
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.66, 0.44)
	q.mesh = qm
	var mt := StandardMaterial3D.new()
	mt.albedo_texture = tex
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.roughness = 1.0
	q.material_override = mt
	q.position = Vector3(0.085, 0.12, 0)
	q.rotation.y = PI * 0.5
	lap.add_child(q)
	if abierta:
		# fosa abierta delante de la lápida y la tierra amontonada
		var fosa := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(2.0, 0.02, 0.85)
		fosa.mesh = fm
		fosa.material_override = m._mat.oscuro
		fosa.position = p + Vector3(1.2, 0.06, 0)
		m.add_child(fosa)
		var monton := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.7; sm.height = 0.7; sm.radial_segments = 12; sm.rings = 6
		monton.mesh = sm
		monton.material_override = m._mat.tierra
		monton.scale = Vector3(1.6, 0.6, 1.0)
		monton.position = p + Vector3(1.2, 0.05, 1.2)
		m.add_child(monton)
		m._prop("obj_dirty_shovel", p + Vector3(2.4, 0.0, 0.9), 0.4, 1.0, false, m)
		# la tapa del ataúd, apoyada y arañada
		var tapa2 := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(1.9, 0.06, 0.6)
		tapa2.mesh = tb
		tapa2.material_override = m._mat.madera_vieja
		tapa2.transform = Transform3D(Basis(Vector3(0, 0, 1), 0.35), p + Vector3(1.3, 0.35, -1.0))
		m.add_child(tapa2)
		_calco(m, "aranazos_puerta", tapa2.global_position + Vector3(0, 0.04, 0).rotated(Vector3(0, 0, 1), 0.35), Vector3(0, 1, 0).rotated(Vector3(0, 0, 1), 0.35), Vector2(0.5, 1.6), 0.0, m).rotate_object_local(Vector3(0, 0, 1), PI * 0.5)

static func _texto_lapida(archivo: String) -> Texture2D:
	return load("res://zarek/terror/%s.png" % archivo)

# ---------------- el reloj de pie parado a las tres ----------------
static func _reloj_parado(m: ZarekMansion) -> void:
	for c in m._house.get_children():
		var nd := c as Node3D
		if nd == null or not nd.scene_file_path.get_file().begins_with("vintage_grandfather_clock"):
			continue
		var id := m.room_at(nd.global_position + Vector3(0, 0.3, 0))
		if id < 0 or not String(m.rooms[id].name).begins_with("Vestíbulo"):
			continue
		var frente := nd.global_transform.basis.z.normalized()
		m.notas.append({"pos": nd.global_position + frente * 0.55, "titulo": "Reloj de pie · parado", "texto": "Las agujas están paradas en las tres en punto. El péndulo no se mueve desde la madrugada del 23 de noviembre de 1974. Alguien escribió con el dedo en el polvo del cristal: NO LO PONGAS EN HORA.", "nodo": nd, "leida": false, "sala": "Vestíbulo y gran escalera"})
		return

# ---------------- la mirilla del pasadizo: un retrato con los ojos recortados ----------------
## Posición de los ojos en el retrato: [altura sobre el centro, desplazamiento lateral, media separación] (fracciones).
const OJOS := [0.075, 0.0, 0.03]
static func _mirilla(m: ZarekMansion) -> void:
	var cuadro: Node3D = null
	if true:
		# el estudio no tenía retrato: se cuelga uno en una pared libre
		var r := _sala(m, "Estudio del padre")
		if r.is_empty():
			return
		var rc: Rect2 = r.rect
		for intento in 30:
			var lado := _rng.randi() % 4
			var p: Vector3
			var fuera: Vector3
			match lado:
				0: p = Vector3(_rng.randf_range(rc.position.x + 0.9, rc.end.x - 0.9), float(r.y), rc.position.y); fuera = Vector3(0, 0, -1)
				1: p = Vector3(_rng.randf_range(rc.position.x + 0.9, rc.end.x - 0.9), float(r.y), rc.end.y); fuera = Vector3(0, 0, 1)
				2: p = Vector3(rc.position.x, float(r.y), _rng.randf_range(rc.position.y + 0.9, rc.end.y - 0.9)); fuera = Vector3(-1, 0, 0)
				_: p = Vector3(rc.end.x, float(r.y), _rng.randf_range(rc.position.y + 0.9, rc.end.y - 0.9)); fuera = Vector3(1, 0, 0)
			if not m._pared_libre(r, p, fuera) or m.ventana_cerca(p, 1.6) or not m.door_near(p, 1.8).is_empty():
				continue
			var ocupado := false
			for mu in _muebles:
				var mp: Vector3 = mu[0]
				if absf(mp.y - p.y) < 3.5 and Vector2(mp.x - p.x, mp.z - p.z).length() < 1.0 + float(mu[2]) and float(mu[1]) > 1.2:
					ocupado = true
					break
			if ocupado:
				continue
			# retrato de un caballero (pintura de dominio público) con los ojos recortados
			var c := p - fuera * (m._sep_pared(p, fuera) - 0.03) + Vector3(0, 1.1, 0)
			cuadro = m._prop("obj_sir_isaac_newton_portrait_pa", c, atan2(-fuera.x, -fuera.z), 1.8, false)
			break
	if cuadro == null:
		return
	var negro := StandardMaterial3D.new()
	negro.albedo_color = Color(0.01, 0.01, 0.01)
	negro.roughness = 1.0
	var ab := m._caja_mallas(cuadro)
	var frente := cuadro.global_transform.basis.z.normalized()
	var lado2 := Vector3.UP.cross(frente).normalized()
	var ancho := maxf(ab.size.x, ab.size.z)
	var cc := ab.get_center() + frente * (minf(ab.size.x, ab.size.z) * 0.5 + 0.004) + Vector3(0, ab.size.y * float(OJOS[0]), 0) + lado2 * ancho * float(OJOS[1])
	for s2 in [-1.0, 1.0]:
		var ojo := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = ancho * 0.011; cm.bottom_radius = ancho * 0.011; cm.height = 0.004; cm.radial_segments = 12
		ojo.mesh = cm
		ojo.material_override = negro
		cuadro.add_child(ojo)
		ojo.global_transform = Transform3D(Basis(lado2, frente, lado2.cross(frente)), cc + lado2 * s2 * ancho * float(OJOS[2]))
	print("ZAREK   mirilla: ", cc.snapped(Vector3.ONE * 0.1), " frente ", frente.snapped(Vector3.ONE * 0.1))

# ---------------- invernadero en ruinas ----------------
static func _invernadero(m: ZarekMansion) -> void:
	var r := m._zone("Invernadero")
	if r.size == Vector2.ZERO:
		return
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	# mesas de cultivo con macetas y plantas muertas
	for s in [-1.0, 1.0]:
		var mx := c + Vector3(s * r.size.x * 0.28, 0, 0)
		m.box(Vector3(1.0, 0.08, r.size.y * 0.7), mx + Vector3(0, 0.85, 0), m._mat.madera_vieja, true, m)
		for k in 4:
			m.box(Vector3(0.08, 0.85, 0.08), mx + Vector3(0.42 * (1 if k % 2 == 0 else -1), 0.42, r.size.y * 0.33 * (1 if k < 2 else -1)), m._mat.madera_vieja, false, m)
		for k in 5:
			var mp := mx + Vector3(_rng.randf_range(-0.3, 0.3), 0.89, lerpf(-r.size.y * 0.3, r.size.y * 0.3, k / 4.0))
			if _rng.randf() < 0.25:
				# maceta caída y rota en el suelo
				m._prop("t_macetas", Vector3(mp.x + s * 0.8, 0.0, mp.z), _rng.randf() * TAU, 0.8, false, m)
				continue
			m._prop("t_macetas", mp, _rng.randf() * TAU, 0.7, false, m)
			_planta_seca(m, mp + Vector3(0, 0.22, 0))
	# cristales rotos: grietas en los paneles y esquirlas por el suelo
	for k in 6:
		var lado := _rng.randi() % 4
		var p: Vector3
		var n: Vector3
		match lado:
			0: p = Vector3(_rng.randf_range(r.position.x + 1, r.end.x - 1), 0, r.position.y + 0.16); n = Vector3(0, 0, 1)
			1: p = Vector3(_rng.randf_range(r.position.x + 1, r.end.x - 1), 0, r.end.y - 0.16); n = Vector3(0, 0, -1)
			2: p = Vector3(r.position.x + 0.16, 0, _rng.randf_range(r.position.y + 1, r.end.y - 1)); n = Vector3(1, 0, 0)
			_: p = Vector3(r.end.x - 0.16, 0, _rng.randf_range(r.position.y + 1, r.end.y - 1)); n = Vector3(-1, 0, 0)
		_calco(m, "grietas_espejo", p + Vector3(0, _rng.randf_range(1.2, 2.6), 0), n, Vector2(1.4, 1.4), 0.0, m)
	var mv := StandardMaterial3D.new()
	mv.albedo_color = Color(0.7, 0.8, 0.85, 0.45)
	mv.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mv.roughness = 0.05
	mv.metallic_specular = 1.0
	for k in 24:
		var e := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(_rng.randf_range(0.08, 0.3), _rng.randf_range(0.08, 0.25), 0.006)
		e.mesh = pm
		e.material_override = mv
		e.position = c + Vector3(_rng.randf_range(-r.size.x * 0.45, r.size.x * 0.45), 0.11, _rng.randf_range(-r.size.y * 0.45, r.size.y * 0.45))
		e.rotation = Vector3(PI * 0.5 + _rng.randf_range(-0.1, 0.1), _rng.randf() * TAU, 0)
		e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(e)

## Planta seca en su maceta: tallos secos doblados y hojas caídas alrededor.
static func _planta_seca(m: ZarekMansion, base: Vector3) -> void:
	var mt: Material = ZarekAbandono._mat_tallo if ZarekAbandono._mat_tallo else m._mat.madera_vieja
	for k in _rng.randi_range(6, 10):
		var largo := _rng.randf_range(0.3, 0.7)
		var a := _rng.randf() * TAU
		var inc := _rng.randf_range(0.15, 1.1)
		var t := m.cyl(0.004, 0.009, largo, Vector3.ZERO, mt, m, 4)
		t.rotation = Vector3(inc * cos(a), 0, inc * sin(a))
		t.position = base + t.transform.basis.y * largo * 0.5
		t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if ZarekAbandono._mat_hoja:
		for k in 5:
			var h := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.07, 0.1)
			h.mesh = qm
			h.material_override = ZarekAbandono._mat_hoja
			h.position = base + Vector3(_rng.randf_range(-0.35, 0.35), -0.2, _rng.randf_range(-0.35, 0.35))
			h.rotation = Vector3(-PI * 0.5, _rng.randf() * TAU, 0)
			m.add_child(h)
