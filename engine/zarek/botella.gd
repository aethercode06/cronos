class_name ZarekBotella
extends RigidBody3D
## Botella de vidrio con física: cada una distinta (forma, color del vidrio, altura, etiqueta y cuánto líquido
## queda). Se empuja, se cae y, si choca fuerte, se rompe en pedazos que saltan por el suelo y deja un charco.
## Hace ruido (Elena lo oye): get_tree().call_group("zarek_oyentes", "oir_ruido", posición, fuerza).

const FORMAS := ["burdeos", "borgona", "rin", "licor", "frasco"]
const VIDRIOS := [Color(0.08, 0.22, 0.09, 0.42), Color(0.16, 0.24, 0.07, 0.4), Color(0.33, 0.17, 0.04, 0.42),
	Color(0.12, 0.07, 0.03, 0.5), Color(0.75, 0.78, 0.74, 0.18), Color(0.05, 0.08, 0.24, 0.4)]
const LIQUIDOS := [Color(0.1, 0.0, 0.015, 0.92), Color(0.16, 0.01, 0.03, 0.9), Color(0.32, 0.14, 0.02, 0.75), Color(0.4, 0.26, 0.06, 0.7)]

static var _mallas := {}
static var _mats := {}
static var _etiquetas: Array[Texture2D] = []

var forma := "burdeos"
var vidrio := 0
var lleno := 0.7
var liquido := 0
var _v_antes := Vector3.ZERO
var _rota := false
var _sonar_t := 0.0

## Crea una botella al azar (con la semilla del generador que se le pase).
static func azar(rng: RandomNumberGenerator) -> ZarekBotella:
	var b := ZarekBotella.new()
	b.forma = FORMAS[rng.randi_range(0, 3)] if rng.randf() < 0.88 else "frasco"
	b.vidrio = rng.randi_range(0, 3) if rng.randf() < 0.8 else rng.randi_range(4, 5)
	b.lleno = [0.0, 0.35, 0.7, 0.85][rng.randi_range(0, 3)]
	b.liquido = rng.randi_range(0, 1) if b.vidrio < 4 else rng.randi_range(2, 3)
	var e := rng.randf_range(0.92, 1.08)
	b.set_meta("escala", e)
	return b

func _ready() -> void:
	var e: float = get_meta("escala", 1.0)
	mass = 1.2 * e
	collision_layer = 8
	collision_mask = 1 | 2 | 8
	contact_monitor = true
	max_contacts_reported = 2
	continuous_cd = true
	can_sleep = true
	physics_material_override = _fisica()
	var mi := MeshInstance3D.new()
	mi.mesh = _malla(forma, lleno, liquido)
	mi.scale = Vector3.ONE * e
	mi.set_surface_override_material(0, _mat_vidrio(vidrio))
	if mi.mesh.get_surface_count() > 1:
		mi.set_surface_override_material(1, _mat_etiqueta(vidrio * 7 + int(e * 1000.0)))
	if mi.mesh.get_surface_count() > 2:
		mi.set_surface_override_material(2, _mat_liquido(liquido))
	add_child(mi)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	var dims := _dimensiones(forma)
	cil.radius = dims.x * e
	cil.height = dims.y * e
	cs.shape = cil
	cs.position.y = dims.y * e * 0.5
	add_child(cs)
	body_entered.connect(_al_chocar)

static func _fisica() -> PhysicsMaterial:
	if not _mats.has("fisica"):
		var pm := PhysicsMaterial.new()
		pm.friction = 0.55
		pm.bounce = 0.12
		_mats["fisica"] = pm
	return _mats["fisica"]

func _physics_process(delta: float) -> void:
	_v_antes = linear_velocity
	_sonar_t = maxf(0.0, _sonar_t - delta)

func _al_chocar(_otro: Node) -> void:
	if _rota:
		return
	var v := _v_antes.length()
	if v > 2.4:
		romper()
	elif v > 0.9 and _sonar_t <= 0.0:
		_sonar_t = 0.25
		_sonido("tintineo", -14.0 + v * 4.0)
		get_tree().call_group("zarek_oyentes", "oir_ruido", global_position, 3.0 + v * 2.0)

## Rompe la botella: fragmentos con física, charco si tenía líquido y un estruendo que se oye lejos.
func romper() -> void:
	if _rota:
		return
	_rota = true
	var padre := get_parent()
	var pos := global_position
	var e: float = get_meta("escala", 1.0)
	var dims := _dimensiones(forma)
	var rng := RandomNumberGenerator.new()
	rng.seed = get_instance_id()
	for k in 14:
		var t := ZarekFragmento.new()
		t.tam = Vector3(rng.randf_range(0.025, 0.07), rng.randf_range(0.004, 0.007), rng.randf_range(0.025, 0.08)) * e
		if k < 2:
			t.tam = Vector3(dims.x * 1.6, dims.y * 0.25, 0.006) * e
		t.material = mat_fragmento(vidrio)
		padre.add_child(t)
		t.global_position = pos + Vector3(rng.randf_range(-0.04, 0.04), dims.y * e * rng.randf_range(0.1, 0.8), rng.randf_range(-0.04, 0.04))
		t.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		t.linear_velocity = _v_antes * 0.25 + Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(0.6, 2.2), rng.randf_range(-1.6, 1.6))
		t.angular_velocity = Vector3(rng.randf_range(-15, 15), rng.randf_range(-15, 15), rng.randf_range(-15, 15))
	if lleno > 0.0:
		_charco(padre, pos, rng)
	_sonido("vidrio", 2.0, padre, pos)
	get_tree().call_group("zarek_oyentes", "oir_ruido", pos, 14.0)
	queue_free()

func _charco(padre: Node, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var suelo := pos
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 0.3, 0), pos + Vector3(0, -3.0, 0), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		suelo = hit.position
	var ch := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1, 1)
	ch.mesh = pm
	var m := StandardMaterial3D.new()
	var c: Color = LIQUIDOS[liquido]
	m.albedo_color = Color(c.r * 0.5, c.g * 0.5, c.b * 0.5, 0.88)
	m.albedo_texture = _textura_charco()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.04
	m.metallic_specular = 0.9
	ch.material_override = m
	ch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(ch)
	ch.global_position = suelo + Vector3(0, 0.006 + rng.randf() * 0.003, 0)
	ch.rotation.y = rng.randf() * TAU
	ch.scale = Vector3(0.05, 1, 0.05)
	var final := 0.25 + lleno * 0.45
	var tw := ch.create_tween()
	tw.tween_property(ch, "scale", Vector3(final, 1, final * rng.randf_range(0.7, 1.0)), 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

static func _textura_charco() -> Texture2D:
	if _mats.has("charco"):
		return _mats["charco"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var nz := FastNoiseLite.new()
	nz.frequency = 0.08
	for y in 64:
		for x in 64:
			var d := Vector2(x - 32, y - 32).length() / 32.0
			var borde := 0.75 + nz.get_noise_2d(x, y) * 0.35
			img.set_pixel(x, y, Color(1, 1, 1, clampf((borde - d) * 6.0, 0.0, 1.0)))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_mats["charco"] = t
	return t

func _sonido(tipo: String, db: float, padre: Node = null, pos := Vector3.ZERO) -> void:
	var a := AudioStreamPlayer3D.new()
	a.stream = AetherSynth.make(tipo)
	a.volume_db = db
	a.unit_size = 3.0
	a.max_distance = 30.0
	a.pitch_scale = randf_range(0.9, 1.12)
	(padre if padre else get_parent()).add_child(a)
	a.global_position = pos if padre else global_position
	a.play()
	a.finished.connect(a.queue_free)

## Radio y alto de cada forma (metros, sin escalar).
static func _dimensiones(f: String) -> Vector2:
	match f:
		"borgona": return Vector2(0.041, 0.3)
		"rin": return Vector2(0.034, 0.34)
		"licor": return Vector2(0.046, 0.23)
		"frasco": return Vector2(0.03, 0.16)
	return Vector2(0.038, 0.31)

## Perfil (radio, altura) de cada forma, de abajo arriba.
static func _perfil(f: String) -> Array:
	match f:
		"borgona":
			return [[0.0, 0.0], [0.036, 0.0], [0.041, 0.006], [0.041, 0.13], [0.039, 0.165], [0.031, 0.205], [0.02, 0.24], [0.0145, 0.262], [0.0145, 0.288], [0.017, 0.29], [0.017, 0.3], [0.0, 0.3]]
		"rin":
			return [[0.0, 0.0], [0.03, 0.0], [0.034, 0.006], [0.034, 0.14], [0.031, 0.19], [0.024, 0.24], [0.016, 0.28], [0.0135, 0.31], [0.0135, 0.33], [0.016, 0.333], [0.016, 0.34], [0.0, 0.34]]
		"licor":
			return [[0.0, 0.0], [0.04, 0.0], [0.046, 0.008], [0.046, 0.12], [0.042, 0.14], [0.028, 0.158], [0.016, 0.168], [0.0135, 0.2], [0.0165, 0.21], [0.0165, 0.23], [0.0, 0.23]]
		"frasco":
			return [[0.0, 0.0], [0.026, 0.0], [0.03, 0.006], [0.03, 0.1], [0.026, 0.115], [0.014, 0.125], [0.012, 0.145], [0.015, 0.148], [0.015, 0.16], [0.0, 0.16]]
	return [[0.0, 0.0], [0.033, 0.0], [0.038, 0.007], [0.038, 0.2], [0.035, 0.215], [0.024, 0.228], [0.015, 0.245], [0.0135, 0.29], [0.016, 0.293], [0.016, 0.31], [0.0, 0.31]]

static func _malla(f: String, lleno_v: float, liq: int) -> ArrayMesh:
	var clave := "%s_%d" % [f, int(lleno_v * 100)]
	if _mallas.has(clave):
		return _mallas[clave]
	var perfil := _perfil(f)
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _torno(perfil, 0.0, TAU, 20).commit_to_arrays())
	# etiqueta de papel alrededor del cuerpo (no en el frasco)
	var dims := _dimensiones(f)
	if f != "frasco":
		var r := dims.x + 0.0012
		var et := [[r, dims.y * 0.2], [r, dims.y * 0.42]]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _torno(et, -1.2, 1.2, 12, true).commit_to_arrays())
	else:
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _torno([[0.0001, 0.0], [0.0001, 0.0001]], 0.0, 0.1, 1).commit_to_arrays())
	# líquido por dentro, hasta donde llegue
	if lleno_v > 0.0:
		var alto: float = dims.y * 0.62 * lleno_v
		var interior: Array = []
		for p in perfil:
			if float(p[1]) <= alto:
				interior.append([float(p[0]) * 0.9, float(p[1]) + 0.003])
		interior.append([dims.x * 0.88, alto])
		interior.append([0.0, alto])
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _torno(interior, 0.0, TAU, 16).commit_to_arrays())
	_mallas[clave] = am
	return am

static func _torno(perfil: Array, a0: float, a1: float, seg: int, uv_etiqueta := false) -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in perfil.size() - 1:
		var p0: Array = perfil[i]
		var p1: Array = perfil[i + 1]
		for k in seg:
			var t0 := a0 + (a1 - a0) * k / seg
			var t1 := a0 + (a1 - a0) * (k + 1) / seg
			var v := [Vector3(cos(t0) * float(p0[0]), float(p0[1]), sin(t0) * float(p0[0])), Vector3(cos(t1) * float(p0[0]), float(p0[1]), sin(t1) * float(p0[0])),
				Vector3(cos(t1) * float(p1[0]), float(p1[1]), sin(t1) * float(p1[0])), Vector3(cos(t0) * float(p1[0]), float(p1[1]), sin(t0) * float(p1[0]))]
			var u0 := float(k) / seg
			var u1 := float(k + 1) / seg
			var uv := [Vector2(u0, 1), Vector2(u1, 1), Vector2(u1, 0), Vector2(u0, 0)] if uv_etiqueta else [Vector2(u0, float(p0[1])), Vector2(u1, float(p0[1])), Vector2(u1, float(p1[1])), Vector2(u0, float(p1[1]))]
			for idx in [0, 2, 1, 0, 3, 2]:
				st.set_uv(uv[idx])
				st.add_vertex(v[idx])
	st.generate_normals()
	return st

static func _mat_vidrio(i: int) -> StandardMaterial3D:
	var k := "vidrio%d" % i
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = VIDRIOS[i]
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.04
		m.metallic = 0.0
		m.metallic_specular = 1.0
		m.rim_enabled = true
		m.rim = 0.6
		m.rim_tint = 0.2
		m.refraction_enabled = true
		m.refraction_scale = 0.03
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		m.clearcoat_enabled = true
		m.clearcoat = 1.0
		m.clearcoat_roughness = 0.0
		_mats[k] = m
	return _mats[k]

## Vidrio de los fragmentos: algo más opaco y brillante para que se vean los cristales en el suelo.
static func mat_fragmento(i: int) -> StandardMaterial3D:
	var k := "frag%d" % i
	if not _mats.has(k):
		var m: StandardMaterial3D = _mat_vidrio(i).duplicate()
		var c: Color = VIDRIOS[i]
		m.albedo_color = Color(c.r * 1.15 + 0.06, c.g * 1.15 + 0.06, c.b * 1.15 + 0.06, 0.7)
		m.refraction_enabled = false
		_mats[k] = m
	return _mats[k]

static func _mat_liquido(i: int) -> StandardMaterial3D:
	var k := "liquido%d" % i
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = LIQUIDOS[i]
		m.roughness = 0.08
		m.metallic_specular = 0.8
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mats[k] = m
	return _mats[k]

## Etiquetas de papel viejo con una franja y un escudo, distintas según la botella.
static func _mat_etiqueta(semilla: int) -> StandardMaterial3D:
	if _etiquetas.is_empty():
		for v in 6:
			var rng := RandomNumberGenerator.new()
			rng.seed = 1874 + v
			var img := Image.create(96, 64, false, Image.FORMAT_RGB8)
			var papel := Color(0.82, 0.76, 0.6).darkened(rng.randf_range(0.0, 0.25))
			var tinta: Color = [Color(0.35, 0.05, 0.05), Color(0.08, 0.1, 0.25), Color(0.1, 0.1, 0.08)][v % 3]
			for y in 64:
				for x in 96:
					var c := papel.darkened(rng.randf() * 0.06)
					if y < 6 or y > 57:
						c = tinta
					elif absf(y - 32.0) < 2.0 + v % 2:
						c = tinta.lerp(papel, 0.3)
					elif Vector2(x - 48, y - 20).length() < 7.0 and v % 2 == 0:
						c = tinta.lerp(Color(0.6, 0.5, 0.2), 0.4)
					elif y > 38 and y < 52 and x > 18 and x < 78 and (x / 4 + y / 3) % 3 == 0:
						c = tinta.lerp(papel, 0.55)
					img.set_pixel(x, y, c)
			# manchas de humedad
			for k in 6:
				var cx := rng.randi_range(0, 95)
				var cy := rng.randi_range(0, 63)
				var rr := rng.randi_range(4, 12)
				for y in range(maxi(0, cy - rr), mini(64, cy + rr)):
					for x in range(maxi(0, cx - rr), mini(96, cx + rr)):
						if Vector2(x - cx, y - cy).length() < rr:
							img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.18))
			img.generate_mipmaps()
			_etiquetas.append(ImageTexture.create_from_image(img))
	var k := "etiqueta%d" % (absi(semilla) % 6)
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_texture = _etiquetas[absi(semilla) % 6]
		m.roughness = 0.9
		_mats[k] = m
	return _mats[k]
