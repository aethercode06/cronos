class_name ZarekEscondites
## Escondites y ruido: debajo de las camas se puede esconder Sofía (se suman a los armarios con tipo "cama"),
## cristales rotos que crujen al pisarlos y charcos que chapotean. Los dos avisan a Damián (juego.gd `_on_step`).

static var _rng := RandomNumberGenerator.new()

## Salas con cristales en el suelo (ventanas rotas, vajilla, espejos) y salas con charcos (goteras, sótano).
const CRISTALES := {"Pasillo principal": 2, "Vestíbulo y gran escalera": 1, "Comedor formal": 1, "Cocina": 1, "Pasillo": 2,
	"Galería de retratos": 1, "Baño": 1, "Salón con chimenea": 1, "Cuarto de huéspedes": 1}
const CHARCOS := {"Pasillo del sótano": 3, "Sala de calderas": 2, "Baño": 1, "Cocina": 1, "Cava de vinos": 1, "Despensa": 1}

static func aplicar(m: ZarekMansion, deco: ZarekDecorado) -> void:
	_rng.seed = 7171
	_camas(m, deco)
	_cristales(m)
	_charcos(m)
	print("ZAREK escondites: %d (camas %d), cristales %d, charcos %d" % [m.wardrobes.size(), m.wardrobes.filter(func(w): return w.get("tipo", "") == "cama").size(), m.cristales.size(), m.charcos.size()])

## Debajo de cada cama: Sofía se tumba y mira por el hueco entre el somier y el suelo.
static func _camas(m: ZarekMansion, deco: ZarekDecorado) -> void:
	for cama in deco._camas:
		if float(cama.alto) > 0.6:
			continue  # la cama gótica tiene el canapé hasta el suelo: no cabe nadie debajo
		var c: Vector3 = cama.pos
		var yaw: float = cama.yaw
		var t: Vector3 = cama.tam
		var r: Dictionary = m.rooms[int(cama.sala)] if int(cama.sala) < m.rooms.size() else {}
		if r.is_empty():
			continue
		var rc: Rect2 = r.rect
		var lado := Vector3(1, 0, 0).rotated(Vector3.UP, yaw)
		# sale por el lado de la cama que tenga más sitio hasta la pared
		var mejor := Vector3.ZERO
		var hueco := -1.0
		for s in [1.0, -1.0]:
			var p: Vector3 = c + lado * s * (t.x * 0.5 + 0.55)
			var dist := minf(minf(p.x - rc.position.x, rc.end.x - p.x), minf(p.z - rc.position.y, rc.end.y - p.z))
			if dist > hueco:
				hueco = dist
				mejor = p
		if hueco < 0.35:
			continue
		var fuera := (mejor - c)
		fuera.y = 0
		fuera = fuera.normalized()
		# dentro: tumbada bajo la cama mirando hacia el lado por donde entró
		m.wardrobes.append({"pos": mejor, "inside": c - fuera * 0.1, "yaw": atan2(-fuera.x, -fuera.z), "tipo": "cama", "alto": float(cama.alto)})

## Cristales rotos: trocitos de vidrio esparcidos (brillan con la linterna).
static func _cristales(m: ZarekMansion) -> void:
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.55, 0.65, 0.62, 0.35)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.roughness = 0.05
	vidrio.metallic_specular = 1.0
	for nombre in CRISTALES:
		var r := m._sala_por_nombre(nombre)
		if r.is_empty():
			continue
		for k in int(CRISTALES[nombre]):
			var p := ZarekTerror._sitio_libre(m, r, 0.6)
			if p == Vector3.INF or p == Vector3.ZERO:
				continue
			var n := Node3D.new()
			n.position = p
			m._house.add_child(n)
			for i in 16:
				var mi := MeshInstance3D.new()
				var pm := BoxMesh.new()
				var s := _rng.randf_range(0.04, 0.16)
				pm.size = Vector3(s, 0.004, s * _rng.randf_range(0.3, 1.2))
				mi.mesh = pm
				mi.material_override = vidrio
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var a := _rng.randf() * TAU
				var rr := sqrt(_rng.randf()) * 0.6
				mi.position = Vector3(cos(a) * rr, 0.004, sin(a) * rr)
				mi.rotation = Vector3(_rng.randf_range(-0.08, 0.08), _rng.randf() * TAU, _rng.randf_range(-0.08, 0.08))
				n.add_child(mi)
			m.cristales.append(p)

## Charcos de agua sucia: una lámina oscura y brillante en el suelo.
static func _charcos(m: ZarekMansion) -> void:
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.07, 0.07, 0.06, 0.6)
	agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	agua.roughness = 0.03
	agua.metallic_specular = 1.0
	for nombre in CHARCOS:
		var r := m._sala_por_nombre(nombre)
		if r.is_empty():
			continue
		for k in int(CHARCOS[nombre]):
			var p := ZarekTerror._sitio_libre(m, r, 0.8)
			if p == Vector3.INF or p == Vector3.ZERO:
				continue
			var mi := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 1.0
			cm.bottom_radius = 1.0
			cm.height = 0.004
			cm.radial_segments = 20
			mi.mesh = cm
			mi.material_override = agua
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.position = p + Vector3(0, 0.004, 0)
			mi.scale = Vector3(_rng.randf_range(0.5, 0.85), 1, _rng.randf_range(0.4, 0.75))
			mi.rotation.y = _rng.randf() * TAU
			m._house.add_child(mi)
			m.charcos.append(p)
