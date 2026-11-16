extends Node3D
class_name ZarekCuervos
## Cuervos del bosque: bandadas que vuelan en círculos por encima de los pinos (aletean y planean, se inclinan
## al girar, graznan de vez en cuando) y un grupo posado en el suelo junto al Árbol de los cuervos que picotea
## y levanta el vuelo de golpe cuando el jugador se acerca. Cuervo hecho por código: ~0,95 m de envergadura.
var jugador: Node3D
var juego: Node
var nido := Vector3.ZERO          # Árbol de los cuervos
var _rng := RandomNumberGenerator.new()
var _bandadas: Array = []          # {centro, radio, alto, vel, fase, cuervos:[{nodo, ala_i, ala_d, off, aleteo, planeo}]}
var _posados: Array = []           # {nodo, ala_i, ala_d, cabeza, estado, vel, t}
var _espantados := false
var _t_graznido := 4.0
var _mat_pluma: StandardMaterial3D
var _mat_pico: StandardMaterial3D
var _malla_cuerpo: ArrayMesh
var _malla_ala_int: ArrayMesh
var _malla_ala_ext: ArrayMesh
var _malla_cola: ArrayMesh
var _malla_plegadas: ArrayMesh

func setup(p_jugador: Node3D, p_juego: Node, p_nido: Vector3, limites: Rect2) -> void:
	jugador = p_jugador
	juego = p_juego
	nido = p_nido
	_rng.seed = 1908
	_mallas()
	# tres bandadas repartidas por el bosque y una sobre el árbol de los cuervos
	var centros := [nido + Vector3(0, 0, 0), limites.position + limites.size * Vector2(0.25, 0.7), limites.position + limites.size * Vector2(0.75, 0.75), limites.position + limites.size * Vector2(0.2, 0.25)]
	for i in centros.size():
		var c: Vector3 = centros[i] if centros[i] is Vector3 else Vector3((centros[i] as Vector2).x, 0, (centros[i] as Vector2).y)
		var b := {"centro": c, "base": c, "radio": _rng.randf_range(14.0, 26.0), "alto": _rng.randf_range(21.0, 27.0), "vel": _rng.randf_range(0.18, 0.3) * (1.0 if i % 2 == 0 else -1.0), "fase": _rng.randf() * TAU, "cuervos": []}
		for k in (7 if i == 0 else _rng.randi_range(3, 6)):
			var cv := _cuervo()
			cv["off"] = Vector3(_rng.randf_range(-4, 4), _rng.randf_range(-2, 2), _rng.randf_range(-4, 4))
			cv["fase"] = _rng.randf() * TAU
			cv["planeo"] = _rng.randf() * 3.0
			b.cuervos.append(cv)
		_bandadas.append(b)
	# posados en el suelo alrededor del árbol
	for k in 6:
		var cv := _cuervo()
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(2.0, 5.5)
		cv.nodo.position = nido + Vector3(cos(a) * r, 0.13, sin(a) * r)
		cv.nodo.rotation.y = _rng.randf() * TAU
		cv["estado"] = "suelo"
		cv["t"] = _rng.randf() * 2.0
		cv["vel"] = Vector3.ZERO
		_plegar(cv)
		_posados.append(cv)

# ---------------- el cuervo ----------------
func _mallas() -> void:
	_mat_pluma = StandardMaterial3D.new()
	_mat_pluma.albedo_texture = _textura_pluma()
	_mat_pluma.albedo_color = Color(0.06, 0.06, 0.075)
	_mat_pluma.metallic = 0.25
	_mat_pluma.roughness = 0.42
	_mat_pluma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_mat_pluma.alpha_scissor_threshold = 0.4
	_mat_pluma.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_pico = StandardMaterial3D.new()
	_mat_pico.albedo_color = Color(0.05, 0.05, 0.05)
	_mat_pico.roughness = 0.3
	# cuerpo: huso alargado + cabeza + pico, mirando a -Z
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_elipsoide(st, Vector3(0, 0, 0.02), Vector3(0.075, 0.07, 0.19), 10, 8)
	_elipsoide(st, Vector3(0, 0.035, -0.19), Vector3(0.05, 0.05, 0.06), 8, 6)
	st.generate_normals()
	_malla_cuerpo = st.commit()
	_malla_cuerpo.surface_set_material(0, _mat_pluma)
	var sp := SurfaceTool.new()
	sp.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := Vector3(0, 0.03, -0.235)
	var punta := Vector3(0, 0.02, -0.31)
	for k in 6:
		var a0 := TAU * k / 6.0
		var a1 := TAU * (k + 1) / 6.0
		sp.add_vertex(base + Vector3(cos(a0) * 0.016, sin(a0) * 0.014, 0))
		sp.add_vertex(base + Vector3(cos(a1) * 0.016, sin(a1) * 0.014, 0))
		sp.add_vertex(punta)
	sp.generate_normals()
	_malla_cuerpo = sp.commit(_malla_cuerpo)
	_malla_cuerpo.surface_set_material(1, _mat_pico)
	# alas plegadas a los lados del cuerpo (para los que están posados), con la punta hacia la cola
	var sf := SurfaceTool.new()
	sf.begin(Mesh.PRIMITIVE_TRIANGLES)
	for lado in [-1.0, 1.0]:
		_elipsoide(sf, Vector3(0.058 * lado, 0.02, 0.09), Vector3(0.022, 0.05, 0.2), 8, 6)
	sf.generate_normals()
	_malla_plegadas = sf.commit()
	_malla_plegadas.surface_set_material(0, _mat_pluma)
	# alas: tramo interior (del hombro al codo) y exterior con las plumas primarias abiertas como dedos
	_malla_ala_int = _quad(Vector2(0.0, 0.24), Vector2(-0.09, 0.08), Rect2(0, 0, 0.5, 1), 0.0)
	_malla_ala_ext = _quad(Vector2(0.0, 0.25), Vector2(-0.08, 0.1), Rect2(0.5, 0, 0.5, 1), 0.04)
	_malla_cola = _quad(Vector2(-0.065, 0.065), Vector2(0.0, 0.16), Rect2(0, 0, 0.5, 1), -0.02)

## Quad plano en XZ (envergadura en X, cuerda en Z) con UV de la textura de plumas.
func _quad(xr: Vector2, zr: Vector2, uv: Rect2, estrecha: float, cola := false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var p := [Vector3(xr.x, 0, zr.x), Vector3(xr.y, 0, zr.x + estrecha), Vector3(xr.y, 0, zr.y - estrecha), Vector3(xr.x, 0, zr.y)]
	var u := [Vector2(uv.position.x, 0), Vector2(uv.end.x, 0), Vector2(uv.end.x, 1), Vector2(uv.position.x, 1)]
	if cola:
		u = [Vector2(0.5, 1), Vector2(0.5, 0), Vector2(1, 0), Vector2(1, 1)]
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(Vector3.UP)
		st.set_uv(u[i])
		st.add_vertex(p[i])
	var m := st.commit()
	m.surface_set_material(0, _mat_pluma)
	return m

func _elipsoide(st: SurfaceTool, c: Vector3, r: Vector3, seg: int, anillos: int) -> void:
	for j in anillos:
		var v0 := PI * j / anillos
		var v1 := PI * (j + 1) / anillos
		for i in seg:
			var u0 := TAU * i / seg
			var u1 := TAU * (i + 1) / seg
			var q := [_pe(c, r, u0, v0), _pe(c, r, u1, v0), _pe(c, r, u1, v1), _pe(c, r, u0, v1)]
			for k in [0, 2, 1, 0, 3, 2]:
				st.set_uv(Vector2(0.25, 0.5))
				st.add_vertex(q[k])

func _pe(c: Vector3, r: Vector3, u: float, v: float) -> Vector3:
	return c + Vector3(cos(u) * sin(v) * r.x, cos(v) * r.y, sin(u) * sin(v) * r.z)

## Textura de plumas (blanco con alfa): mitad izquierda ala interior / cola, mitad derecha punta del ala con
## cinco plumas primarias separadas.
func _textura_pluma() -> ImageTexture:
	var W := 128
	var img := Image.create(W, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in W:
			var a := 1.0
			var u := float(x) / W
			var v := float(y) / 64.0
			var tono := 0.85 + 0.15 * sin(u * 90.0)
			if u < 0.5:
				# borde de salida con plumas redondeadas
				var ondas := 0.9 + 0.035 * sin(u * 2.0 * 5.0 * TAU) - 0.04 * pow(absf(u * 2.0 - 0.5) * 2.0, 2.0)
				a = 1.0 if v < ondas else 0.0
			else:
				var uu := (u - 0.5) * 2.0
				var dedo := fmod(v * 5.0, 1.0)
				var largo := 1.0 - absf(v - 0.25) * 0.35
				var hueco := uu > 0.45 and (dedo < 0.18 or dedo > 0.86)
				a = 0.0 if hueco or uu > largo else 1.0
			img.set_pixel(x, y, Color(tono, tono, tono, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _cuervo() -> Dictionary:
	var n := Node3D.new()
	add_child(n)
	var cuerpo := MeshInstance3D.new()
	cuerpo.mesh = _malla_cuerpo
	n.add_child(cuerpo)
	var cola := MeshInstance3D.new()
	cola.mesh = _malla_cola
	cola.position = Vector3(0, 0.01, 0.16)
	n.add_child(cola)
	var alas: Array = []
	for lado in [-1.0, 1.0]:
		var hombro := Node3D.new()
		hombro.position = Vector3(0.05 * lado, 0.03, -0.02)
		hombro.scale.x = lado
		n.add_child(hombro)
		var ai := MeshInstance3D.new()
		ai.mesh = _malla_ala_int
		hombro.add_child(ai)
		var codo := Node3D.new()
		codo.position = Vector3(0.24, 0, 0)
		hombro.add_child(codo)
		var ae := MeshInstance3D.new()
		ae.mesh = _malla_ala_ext
		codo.add_child(ae)
		alas.append([hombro, codo, lado])
	var patas := Node3D.new()
	patas.visible = false
	n.add_child(patas)
	var plegadas := MeshInstance3D.new()
	plegadas.mesh = _malla_plegadas
	patas.add_child(plegadas)
	for lado in [-1.0, 1.0]:
		var pata := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.006
		cm.bottom_radius = 0.005
		cm.height = 0.09
		cm.radial_segments = 5
		cm.rings = 1
		pata.mesh = cm
		pata.material_override = _mat_pico
		pata.position = Vector3(0.025 * lado, -0.085, 0.03)
		patas.add_child(pata)
		var dedos := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.03, 0.006, 0.06)
		dedos.mesh = bm
		dedos.material_override = _mat_pico
		dedos.position = Vector3(0.025 * lado, -0.128, 0.01)
		patas.add_child(dedos)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var esc := _rng.randf_range(0.92, 1.1)
	n.scale = Vector3.ONE * esc
	return {"nodo": n, "alas": alas, "cola": cola, "patas": patas}

## Ángulo de las alas: batido (sube y baja con giro del codo) o planeo (alas extendidas en V suave).
func _alas(cv: Dictionary, batido: float, planeo: float) -> void:
	for par in cv.alas:
		var hombro: Node3D = par[0]
		var codo: Node3D = par[1]
		var lado: float = par[2]
		var a := lerpf(sin(batido) * 0.85 + 0.15, 0.12, planeo)
		hombro.rotation.z = a * lado
		codo.rotation.z = lerpf(sin(batido - 0.9) * 0.45, 0.06, planeo) * lado
		hombro.rotation.y = lerpf(cos(batido) * 0.12, 0.0, planeo) * lado

func _plegar(cv: Dictionary) -> void:
	for par in cv.alas:
		var hombro: Node3D = par[0]
		var codo: Node3D = par[1]
		var lado: float = par[2]
		hombro.visible = false
	if cv.has("patas"):
		(cv.patas as Node3D).visible = true

# ---------------- vuelo ----------------
func _process(delta: float) -> void:
	if jugador == null:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var jp := jugador.global_position
	var fuera: bool = jp.y < 2.5 and (juego == null or not juego.mansion.inside_house(jp))
	for b in _bandadas:
		b.fase += b.vel * delta
		# la bandada deriva despacio alrededor de su sitio
		b.centro = b.base + Vector3(sin(t * 0.03 + b.radio) * 18.0, 0, cos(t * 0.025 + b.alto) * 18.0)
		for cv in b.cuervos:
			var n: Node3D = cv.nodo
			var ang: float = b.fase + float(cv.fase) * 0.12
			var r: float = b.radio + float(cv.off.x)
			var p := Vector3(b.centro.x + cos(ang) * r, b.alto + cv.off.y + sin(t * 0.4 + cv.fase) * 1.2, b.centro.z + sin(ang) * r)
			var antes := n.position
			n.position = p
			var dir := p - antes
			if dir.length() > 0.0005:
				var objetivo := atan2(-dir.x, -dir.z)
				n.rotation.y = lerp_angle(n.rotation.y, objetivo, minf(1.0, delta * 4.0))
				# se inclina hacia dentro del giro
				n.rotation.z = lerpf(n.rotation.z, -0.35 * signf(b.vel), delta * 2.0)
				n.rotation.x = lerpf(n.rotation.x, clampf(-dir.y / maxf(dir.length(), 0.001), -0.4, 0.4), delta * 3.0)
			# ciclos: unos segundos aleteando y otros planeando
			cv.planeo = fmod(cv.planeo + delta, 6.0)
			var plan := smoothstep(2.6, 3.2, cv.planeo) * (1.0 - smoothstep(5.4, 6.0, cv.planeo))
			_alas(cv, t * 7.5 + cv.fase, plan)
			n.visible = fuera
	_posados_proceso(delta, t, jp, fuera)
	# graznidos de vez en cuando desde alguna bandada cercana
	_t_graznido -= delta
	if _t_graznido <= 0.0 and fuera and juego != null:
		_t_graznido = _rng.randf_range(6.0, 16.0)
		var mejor: Vector3 = Vector3.ZERO
		var dmin := 1e9
		for b in _bandadas:
			var cv0: Dictionary = b.cuervos[_rng.randi_range(0, b.cuervos.size() - 1)]
			var d := (cv0.nodo as Node3D).position.distance_to(jp)
			if d < dmin:
				dmin = d
				mejor = (cv0.nodo as Node3D).position
		if dmin < 70.0:
			juego.sound_at("graznido", mejor, 6.0)

func _posados_proceso(delta: float, t: float, jp: Vector3, fuera: bool) -> void:
	if not _espantados and Vector2(jp.x - nido.x, jp.z - nido.z).length() < 11.0 and fuera:
		_espantados = true
		if juego:
			juego.sound_at("aleteo", nido + Vector3(0, 1, 0), 6.0)
			juego.sound_at("graznido", nido + Vector3(0, 2, 0), 8.0)
		for cv in _posados:
			var huir := ((cv.nodo as Node3D).position - jp)
			huir.y = 0
			cv.estado = "vuela"
			(cv.patas as Node3D).visible = false
			for par in cv.alas:
				(par[0] as Node3D).visible = true
			cv.vel = huir.normalized() * _rng.randf_range(4.0, 6.0) + Vector3(0, _rng.randf_range(4.0, 6.5), 0)
			cv.t = 0.0
	for cv in _posados:
		var n: Node3D = cv.nodo
		n.visible = fuera
		cv.t += delta
		if cv.estado == "suelo":
			# picotea: el cuerpo cabecea hacia delante a ratos y da saltitos
			var pico := maxf(0.0, sin(cv.t * 3.0 + n.position.x))
			n.rotation.x = -pow(pico, 4.0) * 0.6
			n.position.y = nido.y + 0.13 * n.scale.y + (0.05 if fmod(cv.t, 4.0) < 0.15 else 0.0)
			if fmod(cv.t, 4.0) < delta:
				n.rotation.y += _rng.randf_range(-0.8, 0.8)
		else:
			# levanta el vuelo: sube aleteando rápido y se aleja hasta desaparecer entre los árboles
			cv.vel.y = maxf(cv.vel.y - delta * 1.2, 1.5)
			n.position += cv.vel * delta
			n.rotation.y = lerp_angle(n.rotation.y, atan2(-cv.vel.x, -cv.vel.z), delta * 6.0)
			n.rotation.x = lerpf(n.rotation.x, 0.5, delta * 4.0)
			_alas(cv, t * 11.0 + n.position.x, 0.0)
			if cv.t > 12.0:
				n.visible = false
