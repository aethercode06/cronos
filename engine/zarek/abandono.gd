class_name ZarekAbandono
extends RefCounted
## Medio siglo de abandono sobre la casa ya amueblada: sábanas sobre muebles, papel pintado despegado en tiras,
## yeso caído del techo, hojas secas que entraron por las ventanas, cuadros torcidos o caídos y plantas muertas.
## Se aplica después de vestir las salas y antes de fusionar las mallas.

const TAPABLES := ["sofa", "armchair", "lounge", "piano", "chair", "table", "desk", "cabinet", "chest", "dresser",
	"commode", "sideboard", "console", "bureau", "wardrobe", "harp", "globe", "bed"]
const SIN_SABANAS := ["Cocina", "Despensa", "Antecocina", "Baño", "Sala de calderas", "Cava de vinos", "Archivo",
	"EPICENTRO · cuarto de Elena", "Pasillo principal", "Pasillo", "Pasillo del sótano"]
## salas cerradas desde 1974: casi todo tapado
const MUY_TAPADAS := ["Cuarto de huéspedes", "Cuarto de huéspedes azul", "Salón con chimenea", "Sala de fumar y billar",
	"Ático (vigas, baúles, muñecos tapados)", "Cuarto de la institutriz", "Sala de costura"]

static var _mat_sabana: StandardMaterial3D
static var _mat_hoja: StandardMaterial3D
static var _mat_tallo: StandardMaterial3D
static var _mat_escombro: StandardMaterial3D

static func aplicar(m: ZarekMansion) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1974
	_materiales(m)
	var por_sala := {}
	for n in m._house.get_children():
		if n is Node3D and (n as Node3D).scene_file_path != "" and not (n is RigidBody3D):
			var id := m.room_at((n as Node3D).global_position + Vector3(0, 0.3, 0))
			if id >= 0:
				if not por_sala.has(id):
					por_sala[id] = []
				por_sala[id].append(n)
	for r in m.rooms:
		var t := String(r.type)
		var nombre := String(r.name)
		if t in ["jardin", "tunel", "roca", "agua", "camino", "edificio", "exterior"] or nombre.begins_with("MANSI") or nombre.begins_with("Terrenos"):
			continue
		var cosas: Array = por_sala.get(int(r.id), [])
		# 1) sábanas
		if not nombre in SIN_SABANAS:
			# solo algunas cosas tapadas: las salas cerradas desde 1974 tienen más, pero nunca todo
			var prob := 0.4 if nombre in MUY_TAPADAS else 0.12
			var max_tapados := 3 if nombre in MUY_TAPADAS else 1
			var tapados := 0
			for n in cosas:
				if tapados >= max_tapados:
					break
				var archivo := String((n as Node3D).scene_file_path.get_file()).to_lower()
				var vale := false
				for k in TAPABLES:
					if archivo.contains(k):
						vale = true
						break
				if vale and rng.randf() < prob and _tiene_sabana(n):
					_sabana(m, n, rng)
					tapados += 1
		# 2) papel despegado
		if String(r.paper).begins_with("p_") or String(r.paper).begins_with("papel"):
			for k in rng.randi_range(1, 3):
				_tira_papel(m, r, rng)
		# 3) yeso caído
		if rng.randf() < 0.5:
			_escombros(m, r, rng)
		# 4) cuadros torcidos o caídos
		for n in cosas:
			var archivo := String((n as Node3D).scene_file_path.get_file()).to_lower()
			if archivo.contains("frame") or archivo.contains("painting") or archivo.contains("portrait") or archivo.contains("picture"):
				var dado := rng.randf()
				if dado < 0.3:
					(n as Node3D).rotate_object_local(Vector3(0, 0, 1), rng.randf_range(-0.16, 0.16))
		# 4b) centro de las salas grandes: un grupo de muebles (o la araña caída en el salón de baile)
		_centro(m, r, cosas, rng)
		# 5) plantas muertas
		if t in ["salon", "dormitorio", "estudio", "pasillo", "biblioteca", "comedor", "vestibulo", "galeria"] and rng.randf() < 0.45:
			_planta_muerta(m, r, rng)
	# 6) la capa de 1974: lo que la familia usaba la última noche
	for sala in OBJETOS_1974:
		var r := m._sala_por_nombre(sala)
		if r.is_empty():
			continue
		for o in OBJETOS_1974[sala]:
			_sobre_mesa(m, r, o, rng)
	# 7) hojas secas que entraron por las ventanas (rotas o no)
	for v in m.ventanas:
		if rng.randf() < 0.55:
			_hojas(m, v, rng)

static func _materiales(m: ZarekMansion) -> void:
	if _mat_sabana:
		return
	_mat_sabana = (m._mat.cortina as StandardMaterial3D).duplicate()
	_mat_sabana.albedo_texture = null
	_mat_sabana.albedo_color = Color(0.5, 0.48, 0.44)
	# lino de verdad (ambientCG, CC0) con polvo: más oscuro arriba no, la tela vieja es gris amarillenta
	if ResourceLoader.exists("res://zarek/texturas/lino/color.jpg"):
		_mat_sabana.albedo_texture = load("res://zarek/texturas/lino/color.jpg")
		_mat_sabana.albedo_color = Color(0.62, 0.59, 0.53)
		if ResourceLoader.exists("res://zarek/texturas/lino/normal.jpg"):
			_mat_sabana.normal_enabled = true
			_mat_sabana.normal_texture = load("res://zarek/texturas/lino/normal.jpg")
			_mat_sabana.normal_scale = 1.0
	_mat_sabana.roughness = 0.95
	_mat_sabana.uv1_triplanar = true
	_mat_sabana.uv1_scale = Vector3(2.5, 2.5, 2.5)
	_mat_sabana.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_hoja = StandardMaterial3D.new()
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var u := (x - 15.5) / 15.5
			var v := (y - 15.5) / 15.5
			var dentro := u * u / 0.35 + v * v < 1.0
			var vena := absf(u) < 0.06
			var c := Color(0.36, 0.24, 0.12) * (0.8 if vena else 1.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0 if dentro else 0.0))
	img.generate_mipmaps()
	_mat_hoja.albedo_texture = ImageTexture.create_from_image(img)
	_mat_hoja.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_mat_hoja.alpha_scissor_threshold = 0.5
	_mat_hoja.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_hoja.roughness = 0.9
	_mat_tallo = StandardMaterial3D.new()
	_mat_tallo.albedo_color = Color(0.28, 0.22, 0.14)
	_mat_tallo.roughness = 0.95
	_mat_escombro = (m._mat.yeso as StandardMaterial3D).duplicate()
	_mat_escombro.albedo_color = Color(0.8, 0.76, 0.68)

## Sábana sobre un mueble. Si hay una simulada en Blender para ese modelo (sabanas/<modelo>.glb, tools/sabanas),
## se pone esa, en el espacio del propio modelo; si no, se aproxima con la tela por código.
static func _sabana(m: ZarekMansion, n: Node3D, rng: RandomNumberGenerator) -> void:
	var interior := n
	if n.scene_file_path == "":
		for h in n.get_children():
			if h is Node3D and (h as Node3D).scene_file_path != "":
				interior = h
	var modelo := interior.scene_file_path.get_file().get_basename()
	var ruta := "res://zarek/sabanas/%s.glb" % modelo
	if ResourceLoader.exists(ruta):
		var ps: PackedScene = load(ruta)
		if ps:
			var tela := ps.instantiate() as Node3D
			interior.add_child(tela)
			for g in tela.find_children("*", "MeshInstance3D", true, false):
				(g as MeshInstance3D).material_override = _mat_sabana
			return
	# sin simulación para ese modelo: se queda sin tapar (mejor que una tela falsa)

static func _tiene_sabana(n: Node3D) -> bool:
	var interior := n
	if n.scene_file_path == "":
		for h in n.get_children():
			if h is Node3D and (h as Node3D).scene_file_path != "":
				interior = h
	return ResourceLoader.exists("res://zarek/sabanas/%s.glb" % interior.scene_file_path.get_file().get_basename())

static func _sabana_codigo(m: ZarekMansion, n: Node3D, rng: RandomNumberGenerator) -> void:
	var ab := AABB()
	var primero := true
	for g in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		var caja: AABB = mi.global_transform * mi.get_aabb()
		ab = caja if primero else ab.merge(caja)
		primero = false
	if primero or ab.size.y < 0.3 or ab.size.x > 3.2 or ab.size.z > 3.2:
		return
	var suelo := ab.position.y
	var c := ab.get_center()
	# mapa de alturas del mueble (los triángulos de sus mallas, desde arriba) y la tela encima: cae entre los
	# puntos altos como un cono (pendiente de tela colgando) y se arruga
	var N := 30
	var margen := 0.32
	var x0 := ab.position.x - margen
	var z0 := ab.position.z - margen
	var dx := (ab.size.x + margen * 2.0) / N
	var dz := (ab.size.z + margen * 2.0) / N
	var alt := PackedFloat32Array()
	alt.resize((N + 1) * (N + 1))
	alt.fill(0.0)
	for g in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null:
			continue
		var tr := mi.global_transform
		for si in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(si)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ids: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var nt := ids.size() / 3 if ids.size() > 0 else vs.size() / 3
			var paso := maxi(1, nt / 2500)
			for t in range(0, nt, paso):
				var a := tr * vs[ids[t * 3] if ids.size() > 0 else t * 3]
				var b := tr * vs[ids[t * 3 + 1] if ids.size() > 0 else t * 3 + 1]
				var e := tr * vs[ids[t * 3 + 2] if ids.size() > 0 else t * 3 + 2]
				var ymax := maxf(a.y, maxf(b.y, e.y)) - suelo
				var i0 := clampi(int((minf(a.x, minf(b.x, e.x)) - x0) / dx), 0, N)
				var i1 := clampi(int((maxf(a.x, maxf(b.x, e.x)) - x0) / dx) + 1, 0, N)
				var j0 := clampi(int((minf(a.z, minf(b.z, e.z)) - z0) / dz), 0, N)
				var j1 := clampi(int((maxf(a.z, maxf(b.z, e.z)) - z0) / dz) + 1, 0, N)
				for jj in range(j0, j1 + 1):
					for ii in range(i0, i1 + 1):
						var k := jj * (N + 1) + ii
						if alt[k] < ymax:
							alt[k] = ymax
	# la tela no entra en los huecos: dilatación en cono (pendiente 2,4) y suavizado
	for pasada in 2:
		var nuevo := alt.duplicate()
		for jj in N + 1:
			for ii in N + 1:
				var mejor := alt[jj * (N + 1) + ii]
				for oy in range(-4, 5):
					for ox in range(-4, 5):
						var i2 := ii + ox
						var j2 := jj + oy
						if i2 < 0 or j2 < 0 or i2 > N or j2 > N:
							continue
						var d := Vector2(ox * dx, oy * dz).length()
						mejor = maxf(mejor, alt[j2 * (N + 1) + i2] - d * 2.4)
				nuevo[jj * (N + 1) + ii] = mejor
		alt = nuevo
	var fase := rng.randf() * 10.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	for jj in N + 1:
		var fila: Array = []
		for ii in N + 1:
			var x := x0 + ii * dx
			var z := z0 + jj * dz
			var h := alt[jj * (N + 1) + ii]
			# arrugas: más marcadas donde la tela cuelga
			var cuelga := clampf(1.0 - h / maxf(ab.size.y, 0.01), 0.0, 1.0)
			var arr := sin(x * 11.0 + fase) * sin(z * 9.0 - fase * 0.7) * 0.012 + sin((x - z) * 6.0 + fase) * 0.03 * cuelga
			fila.append(Vector3(x - c.x, maxf(h + 0.018 + arr, 0.008), z - c.z))
		pts.append(fila)
	for jj in N:
		for ii in N:
			var a: Vector3 = pts[jj][ii]
			var b: Vector3 = pts[jj][ii + 1]
			var cc: Vector3 = pts[jj + 1][ii]
			var d: Vector3 = pts[jj + 1][ii + 1]
			# los bordes que quedan en el suelo se recortan (la sábana no es infinita)
			if a.y < 0.012 and b.y < 0.012 and cc.y < 0.012 and d.y < 0.012:
				continue
			for vt in [a, b, cc, b, d, cc]:
				st.set_smooth_group(0)
				st.add_vertex(vt)
	st.generate_normals()
	var mi2 := MeshInstance3D.new()
	mi2.mesh = st.commit()
	mi2.material_override = _mat_sabana
	mi2.position = Vector3(c.x, suelo, c.z)
	m._house.add_child(mi2)

## Una tira de papel pintado despegada de la pared (enrollada hacia fuera abajo) con el yeso desnudo detrás.
static func _tira_papel(m: ZarekMansion, r: Dictionary, rng: RandomNumberGenerator) -> void:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	for intento in 8:
		var lado := rng.randi() % 4
		var p: Vector3
		var fuera: Vector3
		match lado:
			0: p = Vector3(rng.randf_range(rc.position.x + 0.6, rc.end.x - 0.6), y, rc.position.y); fuera = Vector3(0, 0, -1)
			1: p = Vector3(rng.randf_range(rc.position.x + 0.6, rc.end.x - 0.6), y, rc.end.y); fuera = Vector3(0, 0, 1)
			2: p = Vector3(rc.position.x, y, rng.randf_range(rc.position.y + 0.6, rc.end.y - 0.6)); fuera = Vector3(-1, 0, 0)
			_: p = Vector3(rc.end.x, y, rng.randf_range(rc.position.y + 0.6, rc.end.y - 0.6)); fuera = Vector3(1, 0, 0)
		if not m._pared_libre(r, p, fuera):
			continue
		var sep := m._sep_pared(p, fuera)
		var base := p - fuera * (sep - 0.005)
		var ancho := rng.randf_range(0.35, 0.6)
		var largo := rng.randf_range(0.7, 1.5)
		var arriba := rng.randf_range(2.6, 3.6)
		var giro := atan2(-fuera.x, -fuera.z)
		# mancha de yeso desnudo donde estaba la tira
		var hueco := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(ancho * 1.05, largo * 0.85)
		hueco.mesh = qm
		hueco.material_override = m._mat.yeso
		hueco.position = base + Vector3(0, arriba - largo * 0.42, 0) - fuera * 0.003
		hueco.rotation.y = giro + PI
		m._house.add_child(hueco)
		# la tira: cuelga pegada arriba y se curva hacia la sala abajo
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var nseg := 10
		var curva := rng.randf_range(0.15, 0.4)
		var fila_ant: Array = []
		for k in nseg + 1:
			var t := float(k) / nseg
			var sale := curva * t * t * t
			var vy := -largo * t + curva * 0.4 * t * t * t * t
			var fila := [Vector3(-ancho * 0.5, vy, sale), Vector3(ancho * 0.5 * (1.0 - 0.25 * t), vy - 0.05 * t, sale + 0.02 * t)]
			if k > 0:
				for vt in [fila_ant[0], fila_ant[1], fila[0], fila_ant[1], fila[1], fila[0]]:
					st.set_uv(Vector2(vt.x / ancho + 0.5, -vt.y / largo))
					st.add_vertex(vt)
			fila_ant = fila
		st.generate_normals()
		var tira := MeshInstance3D.new()
		tira.mesh = st.commit()
		var mp: StandardMaterial3D = (m._mat[r.paper] as StandardMaterial3D).duplicate() if m._mat.get(r.paper) is StandardMaterial3D else m._mat.yeso
		if mp is StandardMaterial3D:
			(mp as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
			(mp as StandardMaterial3D).uv1_triplanar = false
		tira.material_override = mp
		tira.position = base + Vector3(0, arriba, 0)
		tira.rotation.y = giro + PI
		tira.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tira.set_meta("dyn", true)
		m._house.add_child(tira)
		return

## Trozos de yeso caídos del techo y polvo blanco en el suelo, con la mancha del hueco arriba.
static func _escombros(m: ZarekMansion, r: Dictionary, rng: RandomNumberGenerator) -> void:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	for intento in 10:
		var p := Vector3(rng.randf_range(rc.position.x + 0.8, rc.end.x - 0.8), y, rng.randf_range(rc.position.y + 0.8, rc.end.y - 0.8))
		if not m.door_near(p, 1.5).is_empty() or m._huella_en_escalera(p, Vector3(1.2, 0.1, 1.2), 0.0):
			continue
		for k in rng.randi_range(6, 14):
			var tam := Vector3(rng.randf_range(0.04, 0.22), rng.randf_range(0.015, 0.04), rng.randf_range(0.04, 0.18))
			var trozo := m.box(tam, p + Vector3(rng.randf_range(-0.6, 0.6), tam.y * 0.5, rng.randf_range(-0.6, 0.6)), _mat_escombro, false, null, false)
			trozo.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.2, 0.2))
		var polvo := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(1.6, 1.4)
		polvo.mesh = pm
		var mp := StandardMaterial3D.new()
		mp.albedo_color = Color(0.85, 0.82, 0.75, 0.55)
		mp.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mp.albedo_texture = _disco()
		polvo.material_override = mp
		polvo.position = p + Vector3(0, 0.008, 0)
		polvo.rotation.y = rng.randf() * TAU
		polvo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m._house.add_child(polvo)
		# arriba: el hueco en el techo (listones a la vista)
		var techo := y + (ZarekMansion.WALL_H if m.level_of(y + 0.3) < 2 else 3.2) - 0.012
		var hueco := MeshInstance3D.new()
		var hm := PlaneMesh.new()
		hm.size = Vector2(1.0, 0.8)
		hueco.mesh = hm
		hueco.material_override = m._mat.madera_vieja
		hueco.position = Vector3(p.x, techo, p.z)
		hueco.rotation = Vector3(PI, rng.randf() * TAU, 0)
		m._house.add_child(hueco)
		return

static var _mat_maceta: StandardMaterial3D
static func _maceta() -> StandardMaterial3D:
	if _mat_maceta == null:
		_mat_maceta = StandardMaterial3D.new()
		_mat_maceta.albedo_color = Color(0.48, 0.3, 0.22)
		_mat_maceta.roughness = 0.85
	return _mat_maceta

static var _tex_disco: ImageTexture
static func _disco() -> ImageTexture:
	if _tex_disco == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		var nz := FastNoiseLite.new()
		nz.frequency = 0.09
		for y in 64:
			for x in 64:
				var d := Vector2(x - 31.5, y - 31.5).length() / 32.0
				var a := clampf((1.0 - d) * 1.6 + nz.get_noise_2d(x, y) * 0.6, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		img.generate_mipmaps()
		_tex_disco = ImageTexture.create_from_image(img)
	return _tex_disco

## Maceta con una planta muerta: tallos secos doblados y unas hojas marrones caídas alrededor.
static func _planta_muerta(m: ZarekMansion, r: Dictionary, rng: RandomNumberGenerator) -> void:
	var rc: Rect2 = r.rect
	var y := float(r.y)
	var esquinas := [Vector3(rc.position.x + 0.45, y, rc.position.y + 0.45), Vector3(rc.end.x - 0.45, y, rc.position.y + 0.45),
		Vector3(rc.position.x + 0.45, y, rc.end.y - 0.45), Vector3(rc.end.x - 0.45, y, rc.end.y - 0.45)]
	esquinas.shuffle()
	for p in esquinas:
		if not m.door_near(p, 1.3).is_empty():
			continue
		var maceta := m.cyl(0.17, 0.12, 0.32, p + Vector3(0, 0.16, 0), _maceta(), null, 14)
		maceta.set_meta("dyn", false)
		m.cyl(0.155, 0.155, 0.02, p + Vector3(0, 0.3, 0), m._mat.oscuro, null, 12)
		for k in rng.randi_range(5, 9):
			var ang := rng.randf() * TAU
			var largo := rng.randf_range(0.35, 0.8)
			var tallo := m.cyl(0.006, 0.01, largo, Vector3.ZERO, _mat_tallo, null, 4)
			var inclina := rng.randf_range(0.2, 1.2)
			tallo.rotation = Vector3(inclina * cos(ang), 0, inclina * sin(ang))
			tallo.position = p + Vector3(0, 0.31, 0) + tallo.transform.basis.y * largo * 0.5
		for k in rng.randi_range(4, 9):
			var hoja := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.07, 0.1)
			hoja.mesh = qm
			hoja.material_override = _mat_hoja
			hoja.position = p + Vector3(rng.randf_range(-0.5, 0.5), 0.006, rng.randf_range(-0.5, 0.5))
			hoja.rotation = Vector3(-PI * 0.5, rng.randf() * TAU, 0)
			hoja.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m._house.add_child(hoja)
		return

## Hojas secas en el suelo bajo una ventana (una sola malla con muchas hojas).
static func _hojas(m: ZarekMansion, v: Vector3, rng: RandomNumberGenerator) -> void:
	var id := m.room_at(v + Vector3(0, 0.5, 0))
	if id < 0:
		return
	var c: Vector2 = (m.rooms[id].rect as Rect2).get_center()
	var hacia := Vector3(c.x - v.x, 0, c.y - v.z).normalized()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := rng.randi_range(14, 32)
	for k in n:
		var d := absf(rng.randfn(0.0, 0.7)) + 0.3
		var lado := rng.randfn(0.0, 0.6)
		var p := hacia * d + hacia.cross(Vector3.UP) * lado + Vector3(0, 0.005 + k * 0.0004, 0)
		var a := rng.randf() * TAU
		var s := rng.randf_range(0.05, 0.08)
		var ex := Vector3(cos(a), 0, sin(a)) * s
		var ez := Vector3(-sin(a), 0, cos(a)) * s * 1.4
		var arq := Vector3(0, rng.randf_range(0.0, 0.015), 0)
		var q := [p - ex - ez, p + ex - ez + arq, p + ex + ez, p - ex + ez + arq]
		var uv := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(uv[i])
			st.add_vertex(q[i])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _mat_hoja
	mi.position = Vector3(v.x, float(m.rooms[id].y), v.z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m._house.add_child(mi)

## Rellena el centro vacío de una sala grande con un grupo de estar alrededor de una mesita; en el salón de
## baile, la araña de cristal caída en medio de la pista con cristales rotos alrededor.
static func _centro(m: ZarekMansion, r: Dictionary, cosas: Array, rng: RandomNumberGenerator) -> void:
	var rc: Rect2 = r.rect
	var t := String(r.type)
	var nombre := String(r.name)
	if rc.get_area() < 38.0 or minf(rc.size.x, rc.size.y) < 5.0:
		return
	var c := Vector3(rc.get_center().x, float(r.y), rc.get_center().y)
	for n in cosas:
		var q: Vector3 = (n as Node3D).global_position
		if Vector2(q.x - c.x, q.z - c.z).length() < 1.7:
			return
	if not m.door_near(c, 2.0).is_empty() or m._huella_en_escalera(c, Vector3(3.0, 0.1, 3.0), 0.0):
		return
	if nombre == "Salón de baile":
		var arana := m._prop("vict_chandelier", c + Vector3(0.4, 0.0, -0.3), rng.randf() * TAU, 1.7, false)
		if arana:
			arana.rotation.x = 0.35
			arana.rotation.z = -0.2
			# el modelo cuelga de su origen: se sube para que quede apoyada, torcida, en el suelo
			var cja := m._caja_mallas(arana)
			arana.position.y += c.y - cja.position.y - 0.05
		for k in 40:
			var vidrio := m.box(Vector3(rng.randf_range(0.02, 0.07), 0.006, rng.randf_range(0.02, 0.06)),
				c + Vector3(rng.randfn(0.0, 1.0), 0.004, rng.randfn(0.0, 1.0)), m._mat.cristal, false, null, false)
			vidrio.rotation.y = rng.randf() * TAU
		return
	if not t in ["salon", "estudio", "biblioteca", "galeria", "dormitorio"]:
		return
	var largo_x := rc.size.x >= rc.size.y
	var eje := Vector3(1, 0, 0) if largo_x else Vector3(0, 0, 1)
	var perp := Vector3(0, 0, 1) if largo_x else Vector3(1, 0, 0)
	if t == "dormitorio":
		# un baúl y una butaca junto a una mesita, desplazados del centro
		m._prop("treasure_chest", c - perp * 0.8, atan2(perp.x, perp.z), 1.0)
		m._prop("vict_victorian_armchair", c + eje * 1.1, atan2(-eje.x, -eje.z), 1.0)
		m._prop("vict_small_antique_table_asset", c + eje * 1.1 + perp * 0.7, 0.0, 1.0)
		return
	m._prop("vict_victorian_coffee_table", c, atan2(eje.x, eje.z), 1.0)
	m._prop("vict_victorian_lounge_sofa", c - perp * 1.25, atan2(perp.x, perp.z), 1.0)
	m._prop("vict_victorian_armchair", c + eje * 1.3, atan2(-eje.x, -eje.z), 1.0)
	m._prop("vict_victorian_armchair", c - eje * 1.3, atan2(eje.x, eje.z), 1.0)
	if rng.randf() < 0.6:
		m._prop("vict_victorian_armchair", c + perp * 1.3 + eje * 0.4, atan2(-perp.x, -perp.z) + 0.6, 1.0)

## Objetos de 1974 por sala (sobre una mesita junto a la pared); los que llevan «suelo:» van directamente en el suelo.
const OBJETOS_1974 := {
	"Vestíbulo y gran escalera": ["d_telefono_viejo"],
	"Salón con chimenea": ["suelo:d_tele_patas", "d_tocadiscos", "d_fotos_familia"],
	"Sala de música": ["d_tocadiscos_maleta", "d_radio_capilla"],
	"Cocina": ["d_radio_1937"],
	"Cuarto del hermano": ["d_tele_madera", "suelo:d_foto_rota"],
	"Dormitorio de los padres": ["d_telefono_negro", "d_fotos_familia"],
	"Tocador de la madre": ["d_fotos_familia"],
	"Estudio del padre": ["d_telefono_negro", "d_radio_1937"],
	"Cuarto de la institutriz": ["d_radio_capilla"],
	"Sala de fumar y billar": ["d_tele_retro"]}
const GIRO_1974 := {"d_tele_madera": PI}
const ESCALA_1974 := {"d_tocadiscos_maleta": 1.7}

static func _sobre_mesa(m: ZarekMansion, r: Dictionary, objeto: String, rng: RandomNumberGenerator) -> void:
	var en_suelo := objeto.begins_with("suelo:")
	var nombre := objeto.trim_prefix("suelo:")
	var rc: Rect2 = r.rect
	var y := float(r.y)
	for intento in 14:
		var lado := rng.randi() % 4
		var p: Vector3
		var fuera: Vector3
		match lado:
			0: p = Vector3(rng.randf_range(rc.position.x + 0.9, rc.end.x - 0.9), y, rc.position.y); fuera = Vector3(0, 0, -1)
			1: p = Vector3(rng.randf_range(rc.position.x + 0.9, rc.end.x - 0.9), y, rc.end.y); fuera = Vector3(0, 0, 1)
			2: p = Vector3(rc.position.x, y, rng.randf_range(rc.position.y + 0.9, rc.end.y - 0.9)); fuera = Vector3(-1, 0, 0)
			_: p = Vector3(rc.end.x, y, rng.randf_range(rc.position.y + 0.9, rc.end.y - 0.9)); fuera = Vector3(1, 0, 0)
		if not m._pared_libre(r, p, fuera) or m.ventana_cerca(p, 1.4):
			continue
		var donde := p - fuera * (m._sep_pared(p, fuera) + 0.32)
		if m._huella_en_escalera(donde, Vector3(0.7, 0.1, 0.7), 0.0) or m.room_at(donde + Vector3(0, 0.3, 0)) != int(r.id):
			continue
		# que no caiga encima de otro mueble
		var libre := true
		for n in m._house.get_children():
			if n is Node3D and (n as Node3D).scene_file_path != "" and ((n as Node3D).global_position - donde).length() < 1.0:
				libre = false
				break
		if not libre:
			continue
		var yaw := atan2(-fuera.x, -fuera.z) + float(GIRO_1974.get(nombre, 0.0)) + rng.randf_range(-0.25, 0.25)
		var alto := 0.0
		if not en_suelo:
			var mesa := m._prop("small_wooden_table_01", donde, yaw, 1.0)
			if mesa == null:
				continue
			alto = m._caja_mallas(mesa).end.y - y
		var o := m._prop(nombre, donde + Vector3(0, alto + 0.005, 0), yaw, float(ESCALA_1974.get(nombre, 1.0)), en_suelo)
		if o:
			if nombre == "d_foto_rota":
				o.position = donde + fuera * 0.1
			return
