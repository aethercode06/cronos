class_name ZarekDivisiones
## Las salas grandes dejan de ser pabellones: se parten en rincones con arcadas, tabiques, cortinas pesadas,
## estanterías en hileras, pilares de ladrillo, cubículos de tablas y arcos en los pasillos largos. Todo con
## colisión (la navegación de Damián los rodea) y siempre con huecos de paso. Nunca tapa puertas, escaleras,
## muebles, notas, objetos de la trampa, escondites ni el centro del cuarto de Damián.

static var _rng := RandomNumberGenerator.new()
static var _obst: Array[Vector3] = []
static var m: ZarekMansion

## tipo de división por sala: arcada (columnas y vanos), alcoba (tabique con cortina), estantes (hileras),
## pilares (sótano), cubiculos (ático), arcos (pasillos), cortinas_plastico (matadero), botelleros (cava)
const PLAN := {
	"Salón de baile": "arcada", "Salón con chimenea": "arcada", "Galería de retratos": "arcada", "Comedor formal": "arcada",
	"Sala de música": "arcada", "Sala de fumar y billar": "arcada",
	"Biblioteca": "estantes", "Archivo": "estantes", "Cuarto de lectura": "estantes",
	"Dormitorio de los padres": "alcoba", "Cuarto de huéspedes": "alcoba", "Cuarto de huéspedes azul": "alcoba",
	"Cuarto de la institutriz": "alcoba", "Cuarto del hermano": "alcoba", "Sala de costura": "alcoba", "Cuarto de niños": "alcoba",
	"Cuarto de Damián": "alcoba",
	"Sala de calderas": "pilares", "Capilla de la madre": "pilares", "Galería de servicio": "cortinas_plastico",
	"Cava de vinos": "botelleros", "Pasillo principal": "arcos", "Pasillo": "arcos", "Pasillo del sótano": "arcos",
}

static func aplicar(mansion: ZarekMansion) -> void:
	m = mansion
	var t0 := Time.get_ticks_msec()
	_rng.seed = 8128
	_obstaculos()
	var n := 0
	for r in m.rooms:
		var nombre := String(r.name)
		var tipo := String(PLAN.get(nombre, ""))
		if nombre.begins_with("Ático"):
			tipo = "cubiculos"
		match tipo:
			"arcada": n += _arcada(r)
			"alcoba": n += _alcoba(r)
			"estantes": n += _estantes(r)
			"pilares": n += _pilares(r, false)
			"cortinas_plastico": n += _pilares(r, true)
			"botelleros": n += _botelleros(r)
			"cubiculos": n += _cubiculos(r)
			"arcos": n += _arcos(r)
	print("ZAREK divisiones: %d piezas (%d ms)" % [n, Time.get_ticks_msec() - t0])

# ---------------- qué no se puede tapar ----------------
static func _obstaculos() -> void:
	_obst.clear()
	for c in m._house.get_children():
		if c is Node3D and (c as Node3D).scene_file_path != "":
			_obst.append((c as Node3D).global_position)
	for s in m.seals:
		_obst.append(s.pos)
	for k in m.pickups:
		_obst.append(k.pos if k.has("pos") else (k.node as Node3D).global_position)
	for w in m.wardrobes:
		_obst.append(w.pos)
		_obst.append(w.inside)
	for nt in m.notas:
		_obst.append(nt.pos)
	for l in m.lamps:
		_obst.append(Vector3(l.pos.x, l.pos.y, l.pos.z))

## ¿Se puede levantar algo entre a y b (en el suelo) sin tapar nada?
static func _libre(a: Vector3, b: Vector3, margen := 0.55) -> bool:
	var largo := a.distance_to(b)
	var pasos := maxi(2, int(largo / 0.6))
	for i in pasos + 1:
		var p := a.lerp(b, float(i) / pasos)
		if not m.door_near(p, 1.7).is_empty():
			return false
		if m._huella_en_escalera(p, Vector3(margen * 2, 0.2, margen * 2), 0.0):
			return false
		if p.distance_to(m.circle_pos) < 2.4:
			return false
		for o in _obst:
			if absf(o.y - p.y) < 1.6 and Vector2(o.x - p.x, o.z - p.z).length() < margen:
				return false
	return true

static func _ocupar(a: Vector3, b: Vector3) -> void:
	var pasos := maxi(2, int(a.distance_to(b) / 0.5))
	for i in pasos + 1:
		_obst.append(a.lerp(b, float(i) / pasos))

## Tabique (con colisión) entre dos puntos del suelo.
static func _muro(a: Vector3, b: Vector3, alto: float, grosor: float, mat: Material, choca := true) -> MeshInstance3D:
	var d := b - a
	var largo := Vector2(d.x, d.z).length()
	var mi := m.box(Vector3(largo, alto, grosor), (a + b) * 0.5 + Vector3(0, alto * 0.5, 0), mat, choca)
	mi.rotation.y = -atan2(d.z, d.x)
	return mi

static func _poste(p: Vector3, alto: float, lado: float, mat: Material) -> void:
	m.box(Vector3(lado, alto, lado), p + Vector3(0, alto * 0.5, 0), mat, true)

static func _cortina(a: Vector3, b: Vector3, alto: float, abierta := 0.35) -> void:
	# barra de latón y tela pesada que cae hasta el suelo, recogida en parte hacia un lado
	var d := b - a
	var largo := Vector2(d.x, d.z).length()
	var barra := m.cyl(0.02, 0.02, largo, (a + b) * 0.5 + Vector3(0, alto - 0.15, 0), m._mat.laton_viejo, m._house, 6)
	barra.rotation = Vector3(0, -atan2(d.z, d.x), PI * 0.5)
	var tela_l := largo * (1.0 - abierta)
	var c := a.lerp(b, tela_l / largo * 0.5)
	var t := m.box(Vector3(tela_l, alto - 0.2, 0.06), c + Vector3(0, (alto - 0.2) * 0.5, 0), m._mat.cortina, false)
	t.rotation.y = -atan2(d.z, d.x)
	# pliegues
	var n := int(tela_l / 0.22)
	for i in n:
		var q := a.lerp(b, (0.11 + i * 0.22) / largo)
		var pl := m.box(Vector3(0.09, alto - 0.22, 0.1), q + Vector3(0, (alto - 0.22) * 0.5, 0), m._mat.cortina, false, null, false)
		pl.rotation.y = -atan2(d.z, d.x)
	# la tela recogida al otro lado
	var r := a.lerp(b, 1.0 - abierta * 0.35)
	var rec := m.box(Vector3(0.28, alto - 0.3, 0.18), r + Vector3(0, (alto - 0.3) * 0.5, 0), m._mat.cortina, false)
	rec.rotation.y = -atan2(d.z, d.x)

# ---------------- arcada: columnas, vanos cerrados con paneles o cortinas y vanos abiertos ----------------
static func _arcada(r: Dictionary) -> int:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	var alto := ZarekMansion.WALL_H if int(r.level) < 2 else 3.2
	var largo_x := rc.size.x >= rc.size.y
	var n := 0
	# una línea de columnas que cruza la sala por su lado corto, a algo menos de la mitad
	for f: float in ([0.42] if maxf(rc.size.x, rc.size.y) < 13.0 else [0.36, 0.7]):
		var a: Vector3
		var b: Vector3
		if largo_x:
			var x: float = rc.position.x + rc.size.x * f
			a = Vector3(x, y, rc.position.y)
			b = Vector3(x, y, rc.end.y)
		else:
			var z: float = rc.position.y + rc.size.y * f
			a = Vector3(rc.position.x, y, z)
			b = Vector3(rc.end.x, y, z)
		var ancho := a.distance_to(b)
		var vanos := maxi(3, int(round(ancho / 2.4)))
		var paso := ancho / vanos
		var tipos: Array = []
		for i in vanos:
			var p0 := a.lerp(b, float(i) / vanos)
			var p1 := a.lerp(b, float(i + 1) / vanos)
			tipos.append("panel" if _libre(p0, p1) else "abierto")
		# al menos dos vanos abiertos, y uno cerca del centro; algunos cerrados con cortina en vez de panel
		var abiertos := tipos.count("abierto")
		var orden := range(vanos)
		orden.sort_custom(func(i, j): return absf(i - vanos * 0.5) < absf(j - vanos * 0.5))
		for i in orden:
			if abiertos >= 2:
				break
			if tipos[i] != "abierto":
				tipos[i] = "abierto"
				abiertos += 1
		var cortinas := 0
		for i in vanos:
			if tipos[i] == "panel" and cortinas < 1 and _rng.randf() < 0.5:
				tipos[i] = "cortina"
				cortinas += 1
		var col_mat: Material = m._mat.moldura if m._mat.has("moldura") else m._mat.madera
		for i in vanos + 1:
			var p := a.lerp(b, float(i) / vanos)
			if i == 0 or i == vanos:
				# pilastra pegada a la pared
				_poste(p + (b - a).normalized() * (0.12 if i == 0 else -0.12), alto, 0.28, col_mat)
			else:
				_poste(p, alto, 0.4, col_mat)
				m.box(Vector3(0.52, 0.18, 0.52), p + Vector3(0, 0.09, 0), col_mat, false)
				m.box(Vector3(0.52, 0.22, 0.52), p + Vector3(0, alto - 0.55, 0), col_mat, false)
			n += 1
		# viga que corre sobre las columnas (baja el techo en esa línea)
		var viga := _muro(a, b, 0.55, 0.42, m._mat.madera, false)
		viga.position.y = y + alto - 0.275
		for i in vanos:
			var p0 := a.lerp(b, (float(i) + 0.1) / vanos)
			var p1 := a.lerp(b, (float(i) + 0.9) / vanos)
			match tipos[i]:
				"panel":
					# boiserie de madera hasta la viga, con cuarterones
					_muro(p0, p1, alto - 0.55, 0.12, m._mat.revestimiento if m._mat.has("revestimiento") else m._mat.madera)
					var dir := (p1 - p0).normalized()
					var nrm := Vector3(-dir.z, 0, dir.x)
					for s in [-1.0, 1.0]:
						for h in [0.5, 1.7]:
							var cp: Vector3 = (p0 + p1) * 0.5 + nrm * s * 0.065 + Vector3(0, h + 0.4, 0)
							var cu := m.box(Vector3(p0.distance_to(p1) * 0.7, 0.8, 0.02), cp, m._mat.madera, false, null, false)
							cu.rotation.y = -atan2(dir.z, dir.x)
					_ocupar(p0, p1)
				"cortina":
					_cortina(p0, p1, alto - 0.55, _rng.randf_range(0.2, 0.45))
					_ocupar(p0, p1)
			n += 1
	return n

# ---------------- alcoba: un tabique corta la habitación y deja un rincón (vestidor o cama) ----------------
static func _alcoba(r: Dictionary) -> int:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	var alto := ZarekMansion.WALL_H if int(r.level) < 2 else 3.2
	var largo_x := rc.size.x >= rc.size.y
	var mat: Material = m._mat.revestimiento if m._mat.has("revestimiento") else m._mat.madera
	# prueba varias posiciones: tabique desde una pared hasta el 55 % de la sala, con cortina en el hueco
	for intento in 8:
		var f: float = [0.33, 0.67, 0.3, 0.7, 0.36, 0.64, 0.4, 0.6][intento]
		var desde_inicio := intento % 2 == 0
		var a: Vector3
		var b: Vector3
		var c: Vector3
		if largo_x:
			var x: float = rc.position.x + rc.size.x * f
			var z0: float = rc.position.y if desde_inicio else rc.end.y
			var z1: float = z0 + (rc.size.y * 0.58) * (1.0 if desde_inicio else -1.0)
			a = Vector3(x, y, z0)
			b = Vector3(x, y, z1)
			c = Vector3(x, y, z1 + (1.4 if desde_inicio else -1.4))
		else:
			var z: float = rc.position.y + rc.size.y * f
			var x0: float = rc.position.x if desde_inicio else rc.end.x
			var x1: float = x0 + (rc.size.x * 0.58) * (1.0 if desde_inicio else -1.0)
			a = Vector3(x0, y, z)
			b = Vector3(x1, y, z)
			c = Vector3(x1 + (1.4 if desde_inicio else -1.4), y, z)
		var a2 := a.lerp(b, 0.03)
		if not _libre(a2, b, 0.5):
			continue
		_muro(a2, b, alto, 0.14, mat)
		_poste(b, alto, 0.22, m._mat.madera)
		# cortina en el hueco de 1,4 m (se ve a través a medias)
		if _libre(b, c, 0.45):
			_cortina(b, c, alto - 0.3, _rng.randf_range(0.35, 0.6))
		_ocupar(a2, c)
		return 1
	return 0

# ---------------- estanterías en hileras (biblioteca, archivo, lectura) ----------------
static func _estantes(r: Dictionary) -> int:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	var largo_x := rc.size.x >= rc.size.y
	var n := 0
	var modelo := "vict_antique_wooden_bookcase___ga" if m._props_info.has("vict_antique_wooden_bookcase___ga") else ""
	var filas := maxi(1, int((rc.size.x if largo_x else rc.size.y) / 3.2) - 1)
	for i in filas:
		var f := float(i + 1) / (filas + 1)
		# cada hilera deja pasillo en los dos extremos (1,3 m)
		var a: Vector3
		var b: Vector3
		if largo_x:
			var x: float = rc.position.x + rc.size.x * f
			a = Vector3(x, y, rc.position.y + 1.3)
			b = Vector3(x, y, rc.end.y - 1.3)
		else:
			var z: float = rc.position.y + rc.size.y * f
			a = Vector3(rc.position.x + 1.3, y, z)
			b = Vector3(rc.end.x - 1.3, y, z)
		var largo := a.distance_to(b)
		var k := int(largo / 1.0)
		var dir := (b - a).normalized()
		var j := 0
		while j < k:
			var p0 := a + dir * (j * 1.0)
			var p1 := p0 + dir * 1.0
			if not _libre(p0, p1, 0.5):
				j += 1
				continue
			var cp := (p0 + p1) * 0.5
			var yaw := atan2(dir.x, dir.z) + PI * 0.5
			if modelo != "":
				# dos librerías espalda con espalda
				for s in [-1.0, 1.0]:
					var nrm := Vector3(-dir.z, 0, dir.x)
					var lib := m._prop(modelo, cp + nrm * s * 0.2, yaw + (0.0 if s > 0 else PI), 1.0, true)
					if lib:
						n += 1
			else:
				_muro(p0, p1, 2.1, 0.6, m._mat.madera)
				n += 1
			_ocupar(p0, p1)
			j += 1
	return n

# ---------------- sótano: pilares de ladrillo y tabiques bajos; en el matadero, cortinas de plástico ----------------
static func _pilares(r: Dictionary, plastico: bool) -> int:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	var alto := 3.0
	var n := 0
	var paso := 3.6
	var x := rc.position.x + paso
	while x < rc.end.x - 1.5:
		var z := rc.position.y + paso
		while z < rc.end.y - 1.5:
			var p := Vector3(x, y, z)
			if _libre(p, p + Vector3(0.01, 0, 0), 0.7):
				# poste de madera con zapata y jabalcones que sostienen la viga del techo
				_poste(p, alto + 1.0, 0.3, m._mat.madera_vieja)
				m.box(Vector3(0.45, 0.18, 0.45), p + Vector3(0, 0.09, 0), m._mat.madera_vieja, false)
				var viga := m.box(Vector3(1.4, 0.22, 0.26), p + Vector3(0, alto + 0.85, 0), m._mat.madera_vieja, false)
				viga.rotation.y = _rng.randf_range(0.0, 0.1) + (PI * 0.5 if _rng.randf() < 0.5 else 0.0)
				_ocupar(p, p + Vector3(0.01, 0, 0))
				n += 1
				# entre algunos pilares, un tabique bajo de ladrillo o una cortina de plástico grueso
				var q := p + (Vector3(paso, 0, 0) if _rng.randf() < 0.5 else Vector3(0, 0, paso))
				if q.x < rc.end.x - 1.0 and q.z < rc.end.y - 1.0 and _rng.randf() < 0.55:
					var a := p.lerp(q, 0.1)
					var b := p.lerp(q, 0.9)
					if _libre(a, b, 0.55):
						if plastico:
							_plastico(a, b, alto)
						else:
							_muro(a, b, 1.3 if _rng.randf() < 0.5 else 2.2, 0.08, m._mat.tablas if m._mat.has("tablas") else m._mat.madera_vieja)
						_ocupar(a, b)
						n += 1
			z += paso
		x += paso
	return n

static var _mat_plastico: StandardMaterial3D
static func _plastico(a: Vector3, b: Vector3, alto: float) -> void:
	if _mat_plastico == null:
		_mat_plastico = StandardMaterial3D.new()
		_mat_plastico.albedo_color = Color(0.75, 0.72, 0.62, 0.55)
		_mat_plastico.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_plastico.roughness = 0.25
		_mat_plastico.cull_mode = BaseMaterial3D.CULL_DISABLED
	var d := b - a
	var largo := Vector2(d.x, d.z).length()
	var tiras := int(largo / 0.3)
	for i in tiras:
		var p := a.lerp(b, (i + 0.5) / tiras)
		var t := m.box(Vector3(0.29, alto - 0.2, 0.01), p + Vector3(0, (alto - 0.2) * 0.5 + 0.15, 0), _mat_plastico, false, null, false)
		t.rotation = Vector3(0, -atan2(d.z, d.x), _rng.randf_range(-0.03, 0.03))
		if _rng.randf() < 0.35:
			ZarekTerror._calco(m, "sangre_salpicadura_%d" % (1 + _rng.randi() % 2), p + Vector3(0, _rng.randf_range(0.6, 1.6), 0), Vector3(-d.z, 0, d.x).normalized(), Vector2(0.4, 0.4), _rng.randf() * TAU)
	var barra := m.cyl(0.015, 0.015, largo, (a + b) * 0.5 + Vector3(0, alto, 0), m._mat.hierro, m._house, 5)
	barra.rotation = Vector3(0, -atan2(d.z, d.x), PI * 0.5)

# ---------------- cava: botelleros en hileras ----------------
static func _botelleros(r: Dictionary) -> int:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	var n := 0
	var largo_x := rc.size.x >= rc.size.y
	var filas := int((rc.size.y if largo_x else rc.size.x) / 3.0) - 1
	for i in filas:
		var f := float(i + 1) / (filas + 1)
		var a := Vector3(rc.position.x + 1.4, y, rc.position.y + rc.size.y * f) if largo_x else Vector3(rc.position.x + rc.size.x * f, y, rc.position.y + 1.4)
		var b := Vector3(rc.end.x - 1.4, y, a.z) if largo_x else Vector3(a.x, y, rc.end.y - 1.4)
		var dir := (b - a).normalized()
		var k := int(a.distance_to(b) / 1.2)
		for j in k:
			var p0 := a + dir * (j * 1.2)
			var p1 := p0 + dir * 1.1
			if not _libre(p0, p1, 0.5):
				continue
			# botellero de madera: marco y baldas en rombo con botellas tumbadas
			_muro(p0, p1, 2.0, 0.45, m._mat.madera_vieja)
			var nrm := Vector3(-dir.z, 0, dir.x)
			for s in [-1.0, 1.0]:
				for h in 5:
					for q in 4:
						var bp: Vector3 = p0.lerp(p1, (q + 0.5) / 4.0) + nrm * s * 0.2 + Vector3(0, 0.25 + h * 0.36, 0)
						var bo := m.cyl(0.035, 0.035, 0.05, bp, m._mat.oscuro, m._house, 6)
						bo.rotation = Vector3(PI * 0.5, -atan2(nrm.z, nrm.x) + PI * 0.5, 0)
			_ocupar(p0, p1)
			n += 1
	return n

# ---------------- ático: cubículos de tablas (trasteros) y postes ----------------
static func _cubiculos(r: Dictionary) -> int:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	var alto := 2.3
	var n := 0
	var paso := 4.8
	var x := rc.position.x + paso
	while x < rc.end.x - 2.0:
		var z := rc.position.y + paso
		while z < rc.end.y - 2.0:
			var p := Vector3(x, y, z)
			if _libre(p, p + Vector3(0.01, 0, 0), 0.6):
				_poste(p, alto + 0.6, 0.22, m._mat.madera_vieja)
				n += 1
				for eje in [Vector3(1, 0, 0), Vector3(0, 0, 1)]:
					if _rng.randf() < 0.45:
						continue
					var a: Vector3 = p + eje * 0.15
					var b: Vector3 = p + eje * (paso * _rng.randf_range(0.45, 0.75))
					if b.x > rc.end.x - 1.0 or b.z > rc.end.y - 1.0 or not _libre(a, b, 0.5):
						continue
					# pared de tablas desiguales con rendijas
					var dir: Vector3 = (b - a).normalized()
					var largo: float = a.distance_to(b)
					var tablas := int(largo / 0.22)
					for t in tablas:
						var tp: Vector3 = a + dir * ((t + 0.5) * largo / tablas)
						var h: float = alto * _rng.randf_range(0.8, 1.0)
						var tb := m.box(Vector3(0.18, h, 0.03), tp + Vector3(0, h * 0.5, 0), m._mat.tablas if m._mat.has("tablas") else m._mat.madera_vieja, false, null, false)
						tb.rotation.y = -atan2(dir.z, dir.x)
					m._choque(Vector3(largo, alto, 0.06) if absf(dir.x) > 0.5 else Vector3(0.06, alto, largo), (a + b) * 0.5 + Vector3(0, alto * 0.5, 0))
					_ocupar(a, b)
					n += 1
			z += paso
		x += paso
	return n

# ---------------- pasillos largos: arcos cada pocos metros ----------------
static func _arcos(r: Dictionary) -> int:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	var alto := ZarekMansion.WALL_H if int(r.level) >= 0 else 3.0
	var largo_x := rc.size.x >= rc.size.y
	var largo := rc.size.x if largo_x else rc.size.y
	var ancho := rc.size.y if largo_x else rc.size.x
	if largo < 14.0 or ancho > 5.0:
		return 0
	var n := 0
	var k := 7.2
	var mat: Material = m._mat.moldura if m._mat.has("moldura") else m._mat.madera
	if int(r.level) < 0:
		mat = m._mat.ladrillo
	while k < largo - 4.0:
		var c := Vector3(rc.position.x + k, y, rc.position.y + ancho * 0.5) if largo_x else Vector3(rc.position.x + ancho * 0.5, y, rc.position.y + k)
		var lado := Vector3(0, 0, 1) if largo_x else Vector3(1, 0, 0)
		var a := c - lado * ancho * 0.5
		var b := c + lado * ancho * 0.5
		if m.door_near(c, 2.0).is_empty():
			# dos pilastras y un dintel que baja el techo a 2,7 m: el pasillo se ve por tramos
			for s: Vector3 in [a + lado * 0.15, b - lado * 0.15]:
				_poste(s, alto, 0.3, mat)
			var din := _muro(a, b, alto - 2.7, 0.35, mat, false)
			din.position.y = y + 2.7 + (alto - 2.7) * 0.5
			n += 1
		k += 7.2 + _rng.randf_range(-1.2, 1.2)
	return n
