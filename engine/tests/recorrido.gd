extends Node3D
## Recorrido en vídeo: del coche por el camino del bosque hasta la verja, el jardín delantero, el porche y dentro
## de la casa (vestíbulo y salón). Misma luz, niebla, viento y aves que el juego. Usar con --write-movie.
var m: ZarekMansion
var cam: Camera3D
var fl: SpotLight3D
var env: Environment
var nb: ZarekNiebla
var ruta: Array[Vector3] = []
var dist: Array[float] = []
var vel: Array[float] = []
var s := 0.0
var t := 0.0
var mira := Vector3.ZERO
var duracion_extra := 0.0

func _ready() -> void:
	var we := WorldEnvironment.new(); env = Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.38, 0.34); env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.35; env.tonemap_white = 6.0
	env.fog_enabled = true; env.fog_light_color = Color(0.12, 0.135, 0.18); env.fog_density = 0.05; env.fog_height = 1.4; env.fog_height_density = 0.32; env.fog_sky_affect = 0.85
	env.glow_enabled = true; env.glow_intensity = 0.8; env.glow_bloom = 0.06; env.glow_hdr_threshold = 0.9
	env.adjustment_enabled = true; env.adjustment_contrast = 1.06
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.02, 0.03, 0.06); sm.sky_horizon_color = Color(0.06, 0.07, 0.1); sky.sky_material = sm
	env.sky = sky; env.background_mode = Environment.BG_SKY
	we.environment = env; add_child(we)
	var moon := DirectionalLight3D.new(); moon.light_color = Color(0.55, 0.65, 0.95); moon.light_energy = 0.45
	moon.rotation_degrees = Vector3(-38, -55, 0); moon.shadow_enabled = true; moon.directional_shadow_max_distance = 60.0; add_child(moon)
	var cl := CanvasLayer.new(); var cr := ColorRect.new(); cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	var pm := ShaderMaterial.new(); pm.shader = load("res://zarek/post.gdshader"); cr.material = pm; cl.add_child(cr); add_child(cl)
	m = ZarekMansion.new(); add_child(m); m.build(2)
	for l in m.lamps: m.set_lamp(l, true)
	for d in m.doors:
		if not d.locked:
			d.open = true; d.target = 1.6; d.ang = 1.6; d.shape.disabled = true
			(d.pivot as Node3D).rotation.y = float(d.base) + 1.6
	cam = Camera3D.new(); cam.fov = 68.0; cam.far = 220.0; add_child(cam)
	fl = SpotLight3D.new(); fl.light_color = Color(1, 0.9, 0.72); fl.light_energy = 6.0; fl.spot_range = 32.0; fl.spot_angle = 40.0
	fl.spot_angle_attenuation = 1.6; fl.spot_attenuation = 0.8; fl.shadow_enabled = true; fl.shadow_bias = 0.04
	fl.position = Vector3(0.18, -0.15, 0); cam.add_child(fl)
	nb = ZarekNiebla.new(); add_child(nb); nb.objetivo = cam
	var ex0 := m.cell_to_world("exterior", 0.0, 0.0)
	var ex1 := m.cell_to_world("exterior", 90.0, 104.0)
	var evitar: Array = []
	for z in m.plan.exterior.zonas:
		if not String(z[0]).begins_with("Bosque"):
			var a := m.cell_to_world("exterior", float(z[2]), float(z[3]))
			evitar.append(Rect2(a.x, a.z, float(z[4]) * ZarekMansion.CELL, float(z[5]) * ZarekMansion.CELL).grow(3.0))
	var hr: Rect2 = m.house_rect
	var aves := ZarekAves.new(); add_child(aves)
	aves.setup(cam, null, m.cell_to_world("exterior", 79.0, 21.0), Rect2(ex0.x, ex0.z, ex1.x - ex0.x, ex1.z - ex0.z), evitar,
		Vector3(hr.get_center().x, 10.0, hr.get_center().y), m.cell_to_world("exterior", 36.5, 19.5), m.cell_to_world("exterior", 44.0, 43.0))
	_hacer_ruta()
	# por tramos (para grabar en paralelo): TRAMO_INI = segundo de inicio, TRAMO_DUR = segundos a grabar
	var ini := float(OS.get_environment("TRAMO_INI")) if OS.get_environment("TRAMO_INI") != "" else 0.0
	fin_tramo = ini + (float(OS.get_environment("TRAMO_DUR")) if OS.get_environment("TRAMO_DUR") != "" else 999.0)
	var paso := 1.0 / 24.0
	while t < ini - 0.0001:
		t += paso
		var total := dist[dist.size() - 1]
		if s < total:
			s += _vel(s) * paso
		else:
			duracion_extra += paso
	mira = _pos(s + 4.0) + Vector3(0, -0.25, 0)
	cam.position = _pos(s)

var fin_tramo := 999.0

func _c(cx: float, cy: float) -> Vector3:
	return m.cell_to_world("exterior", cx, cy) + Vector3(0, 1.65, 0)

func _sala(nombre: String) -> Dictionary:
	for r in m.rooms:
		if String(r.name) == nombre:
			return r
	return {}

func _puerta_entre(a: Dictionary, b: Dictionary) -> Vector3:
	for d in m.doors:
		var p: Vector3 = d.pos
		if absf(p.y - float(a.y)) < 1.0 and (a.rect as Rect2).grow(0.7).has_point(Vector2(p.x, p.z)) and (b.rect as Rect2).grow(0.7).has_point(Vector2(p.x, p.z)):
			return Vector3(p.x, float(a.y) + 1.65, p.z)
	return Vector3.INF

func _hacer_ruta() -> void:
	var puntos: Array = []   # [posición, velocidad m/s]
	var ini := m.start_pos + Vector3(0, 1.65, 0)
	puntos.append([ini, 3.2])
	for c in [[49.0, 97.0], [49.0, 89.0], [31.0, 88.0], [31.0, 82.0], [31.0, 77.0], [44.0, 77.0], [44.0, 71.0], [44.0, 66.0], [44.0, 59.0], [40.0, 56.5], [39.3, 52.5], [40.5, 49.5], [44.0, 47.5], [44.0, 44.0]]:
		puntos.append([_c(c[0], c[1]), 4.0])
	var vest := _sala("Vestíbulo y gran escalera")
	var salon := _sala("Salón con chimenea")
	if not vest.is_empty():
		# la puerta de entrada: la más cercana al porche
		var mejor := Vector3.INF
		for d in m.doors:
			var p: Vector3 = d.pos
			if absf(p.y) < 1.0 and (vest.rect as Rect2).grow(0.8).has_point(Vector2(p.x, p.z)):
				if mejor == Vector3.INF or p.distance_to(_c(44, 43)) < mejor.distance_to(_c(44, 43)):
					mejor = Vector3(p.x, 1.65, p.z)
		if mejor != Vector3.INF:
			var fuera: Vector3 = mejor + (mejor - Vector3((vest.rect as Rect2).get_center().x, 1.65, (vest.rect as Rect2).get_center().y)).normalized() * 2.0
			puntos.append([fuera, 2.0])
			puntos.append([mejor, 1.6])
		var vc := Vector3((vest.rect as Rect2).get_center().x, 1.65, (vest.rect as Rect2).get_center().y)
		puntos.append([vc, 1.6])
		if not salon.is_empty():
			var pd := _puerta_entre(vest, salon)
			if pd != Vector3.INF:
				var dirv := (pd - vc).normalized()
				puntos.append([pd - dirv * 1.2, 1.6])
				puntos.append([pd, 1.4])
				puntos.append([pd + dirv * 1.2, 1.4])
			var sc := Vector3((salon.rect as Rect2).get_center().x, 1.65, (salon.rect as Rect2).get_center().y)
			puntos.append([sc, 1.4])
			puntos.append([sc + Vector3(-2.5, 0, 0), 1.0])
	for p in puntos:
		ruta.append(p[0]); vel.append(p[1])
	var acc := 0.0
	dist.append(0.0)
	for i in range(1, ruta.size()):
		acc += ruta[i].distance_to(ruta[i - 1])
		dist.append(acc)
	mira = ruta[1]
	cam.position = ruta[0]
	print("RUTA ", ruta.size(), " puntos, ", int(acc), " m")

func _pos(d: float) -> Vector3:
	# Catmull-Rom por tramos para que la cámara no gire en seco en las esquinas
	d = clampf(d, 0.0, dist[dist.size() - 1])
	var i := 0
	while i < dist.size() - 2 and dist[i + 1] < d:
		i += 1
	var u := (d - dist[i]) / maxf(dist[i + 1] - dist[i], 0.001)
	var p0 := ruta[maxi(i - 1, 0)]
	var p1 := ruta[i]
	var p2 := ruta[i + 1]
	var p3 := ruta[mini(i + 2, ruta.size() - 1)]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u * u * u)

func _vel(d: float) -> float:
	var i := 0
	while i < dist.size() - 2 and dist[i + 1] < d:
		i += 1
	return vel[i]

func _process(delta: float) -> void:
	if ruta.size() < 2:
		return
	t += delta
	var total := dist[dist.size() - 1]
	if s < total:
		s += _vel(s) * delta
	else:
		duracion_extra += delta
	var p := _pos(s)
	var paso := sin(t * 6.5) * 0.025
	cam.position = p + Vector3(0, paso, 0)
	var objetivo := _pos(s + 4.0) + Vector3(0, -0.25, 0)
	if s >= total:
		objetivo = p + Vector3(-1, -0.2, 0.3)
	mira = mira.lerp(objetivo, minf(1.0, delta * 2.2))
	if mira.distance_to(cam.position) > 0.1:
		cam.look_at(mira)
	# dentro de la casa: niebla fina; fuera: la del bosque
	var dentro := m.inside_house(p)
	var k := 0.0 if dentro else 1.0
	env.fog_density = lerpf(env.fog_density, lerpf(0.016, 0.05, k), minf(1.0, delta))
	env.fog_height_density = lerpf(env.fog_height_density, lerpf(0.0, 0.32, k), minf(1.0, delta))
	nb.fuerza = lerpf(nb.fuerza, k, minf(1.0, delta))
	var racha := clampf(sin(t * 0.35) * 1.4 - 0.4, 0.0, 1.0)
	RenderingServer.global_shader_parameter_set("viento", Vector4(0.8, 0.6, 0.38, racha))
	if t >= fin_tramo - 0.0001:
		print("TRAMO OK")
		get_tree().quit()
	if duracion_extra > 3.0:
		print("RECORRIDO OK ", int(t), " s")
		get_tree().quit()
