class_name ZarekAnimal
extends CharacterBody3D
## Un bicho de la casa con física (gravedad, choca con paredes y muebles, empujado al pisarlo) y su propia
## inteligencia. tipo: "rata", "gato", "gusano" o "larva".

enum E { ANDA, PARA, HUYE, ESCONDE, SIGUE, SENTADO, MUERTO }
var tipo := "rata"
var fauna: ZarekFauna
var estado := E.PARA
var t_estado := 1.0
var camino: Array[Vector3] = []
var destino := Vector3.INF
var vel_obj := 0.0
var modelo: Node3D
var anim: AnimationPlayer
var anim_nombre := ""
var giro_modelo := 0.0
var _fase := randf() * 10.0
var _t_sonido := randf_range(4.0, 12.0)
var voz: AudioStreamPlayer3D
var ronroneo: AudioStreamPlayer3D
var _avisado_elena := 0.0
var _bufando := 0.0
var _escala := Vector3.ONE

func _cargar(nombre: String, largo: float, giro: float) -> Dictionary:
	var ps: PackedScene = load("res://zarek/fauna/%s.glb" % nombre)
	var mdl: Node3D = ps.instantiate()
	add_child(mdl)
	_quitar_sobrantes(mdl)
	var ab := _medir(mdl)
	var k := largo / maxf(maxf(ab.size.x, ab.size.z), 0.001)
	mdl.scale = Vector3.ONE * k
	mdl.rotation.y = giro
	mdl.position = Vector3(-ab.get_center().x * k, -ab.position.y * k, -ab.get_center().z * k).rotated(Vector3.UP, giro)
	return {"nodo": mdl, "alto": ab.size.y * k}

## Caja real del animal en el espacio de este nodo. En los modelos con esqueleto la caja de la malla es la de
## reposo (a veces de pie o girada): se mide con la pose animada de los huesos.
func _medir(mdl: Node3D) -> AABB:
	var inv := global_transform.affine_inverse()
	var esq: Skeleton3D = null
	for g in mdl.find_children("*", "Skeleton3D", true, false):
		esq = g as Skeleton3D
		break
	if esq and esq.get_bone_count() > 3:
		var ap := mdl.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap and ap.get_animation_list().size() > 0:
			if not ap.is_playing():
				ap.play(ap.get_animation_list()[0])
			ap.advance(0.0)
		var cb := AABB()
		var primero := true
		for i in esq.get_bone_count():
			var q: Vector3 = inv * (esq.global_transform * esq.get_bone_global_pose(i).origin)
			if primero:
				cb = AABB(q, Vector3.ZERO)
				primero = false
			else:
				cb = cb.expand(q)
		# la piel sobresale un poco de los huesos
		return cb.grow(cb.size.length() * 0.04)
	var ab := AABB()
	var p := true
	for g in mdl.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		var c: AABB = (inv * mi.global_transform) * mi.get_aabb()
		ab = c if p else ab.merge(c)
		p = false
	return ab

## los modelos traen una esfera auxiliar de 2 m («Icosphere») que no es parte del animal
func _quitar_sobrantes(n: Node) -> void:
	for g in n.find_children("Icosphere*", "MeshInstance3D", true, false):
		g.get_parent().remove_child(g)
		g.free()

## Pelaje negro de gato: oscuro, mate con un brillo suave en el borde (pelo) y relieve fino.
func _pelaje_negro(n: Node3D) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.018, 0.016, 0.015)
	m.roughness = 0.9
	m.metallic_specular = 0.25
	# un poco de brillo de pelo en el contorno
	m.rim_enabled = true
	m.rim = 0.12
	m.rim_tint = 0.7
	for g in n.find_children("*", "MeshInstance3D", true, false):
		(g as MeshInstance3D).material_override = m

## Malla remodelada en Blender (tools/gato) montada sobre el esqueleto y la piel originales del gato.
func _malla_nueva(n: Node3D) -> void:
	if not ResourceLoader.exists("res://zarek/fauna/gato_malla.res"):
		return
	var nueva: Mesh = load("res://zarek/fauna/gato_malla.res")
	for g in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.skin != null:
			mi.mesh = nueva

## Pelaje de verdad: la piel horneada del bengalí oscurecida (gato atigrado oscuro) y pelo por capas.
func _pelaje_real(n: Node3D) -> void:
	var sh: Shader = load("res://zarek/pelo.gdshader")
	var capas := 8 if OS.get_name() == "Android" else 14
	for g in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		var tex: Texture2D = null
		var m0 := mi.get_active_material(0)
		if m0 is BaseMaterial3D:
			tex = (m0 as BaseMaterial3D).albedo_texture
		if tex == null:
			tex = load("res://zarek/fauna/gato_pelo.jpg") if ResourceLoader.exists("res://zarek/fauna/gato_pelo.jpg") else null
		var primero: ShaderMaterial = null
		var ant: ShaderMaterial = null
		for i in capas + 1:
			var m := ShaderMaterial.new()
			m.shader = sh
			m.set_shader_parameter("color_piel", tex)
			m.set_shader_parameter("tinte", Color(0.8, 0.76, 0.72))
			m.set_shader_parameter("capa", float(i) / capas)
			m.set_shader_parameter("largo", 0.005)
			if ResourceLoader.exists("res://zarek/fauna/gato_largo.png"):
				m.set_shader_parameter("mapa_largo", load("res://zarek/fauna/gato_largo.png"))
			m.set_shader_parameter("densidad", 2200.0)
			if ant:
				ant.next_pass = m
			else:
				primero = m
			ant = m
		mi.material_override = primero

## Animaciones del gato real (57): andar, trote, carrera, quieto, sentado, tumbado, dormir, bufar, comer…
var anims_gato := {}
func _preparar_anims_gato() -> void:
	if anim == null:
		return
	for n in anim.get_animation_list():
		var corto := String(n).get_slice("Anim_Cat_", 1).trim_suffix("_Mesh_Cat") if String(n).contains("Anim_Cat_") else String(n)
		anims_gato[corto] = n
		var a := anim.get_animation(n)
		if a and (corto.ends_with("_IP") or corto.contains("idle") or corto.contains("Idle") or corto.contains("loop")):
			a.loop_mode = Animation.LOOP_LINEAR
var _anim_gato_actual := ""
var _esq_gato: Skeleton3D
var _apoyos: Array[int] = []
var _t_suelo := 0.0
## Cada postura deja el cuerpo a una altura distinta (sentado, tumbado…): se ajusta para que las patas (o el
## cuerpo, si está tumbado) toquen el suelo y no flote ni se hunda.
func _ajustar_suelo(delta: float) -> void:
	if _esq_gato == null:
		for g in modelo.find_children("*", "Skeleton3D", true, false):
			_esq_gato = g
		if _esq_gato == null:
			return
		for nb in ["claw_b_L_016", "claw_b_R_020", "claw_f_L_041", "claw_f_R_046", "foot_b_L_015", "foot_b_R_019", "spine_01_07", "spine_03_05", "Spine_base_04", "head_024"]:
			var i := _esq_gato.find_bone(nb)
			if i >= 0:
				_apoyos.append(i)
	_t_suelo -= delta
	if _t_suelo > 0.0:
		return
	_t_suelo = 0.1
	var minimo := INF
	for i in _apoyos:
		var y := to_local(_esq_gato.global_transform * _esq_gato.get_bone_global_pose(i).origin).y
		minimo = minf(minimo, y)
	if minimo < INF:
		# las garras están ~1 cm por encima de la planta
		modelo.position.y -= (minimo - 0.012) * 0.6
func _gato_anim(nombre: String, velocidad := 1.0) -> void:
	if not anims_gato.has(nombre):
		return
	if _anim_gato_actual != nombre:
		_anim_gato_actual = nombre
		anim.play(anims_gato[nombre], 0.25)
	anim.speed_scale = velocidad
var _pose_quieto := "Idle_1"

## pelo negro para el gato que anda (el modelo original es atigrado)
func _tenir_negro(n: Node3D) -> void:
	for g in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		for si in mi.mesh.get_surface_count():
			var m0 := mi.get_active_material(si)
			var m := (m0.duplicate() if m0 is StandardMaterial3D else StandardMaterial3D.new()) as StandardMaterial3D
			m.albedo_color = Color(0.07, 0.065, 0.06)
			if m.albedo_texture:
				m.albedo_color = Color(0.16, 0.15, 0.14)
			m.roughness = 0.65
			mi.set_surface_override_material(si, m)

var sentado: Node3D
var anim_sentado: AnimationPlayer
var anim_quieto := ""

func montar(nombre: String, largo: float, giro: float) -> void:
	giro_modelo = giro
	var ps: PackedScene = load("res://zarek/fauna/%s.glb" % nombre)
	modelo = ps.instantiate()
	add_child(modelo)
	_quitar_sobrantes(modelo)
	# escala real: el lado horizontal más largo del modelo = largo
	var ab := _medir(modelo)
	for g in modelo.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		# solo el gato hace sombra (las ratas y los gusanos son pequeños: no se nota y ahorra mucho)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if tipo == "gato" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lado := maxf(ab.size.x, ab.size.z)
	var k := largo / maxf(lado, 0.001)
	modelo.scale = Vector3.ONE * k
	_escala = modelo.scale
	modelo.rotation.y = giro
	modelo.position = Vector3(-ab.get_center().x * k, -ab.position.y * k, -ab.get_center().z * k).rotated(Vector3.UP, giro)
	var alto := ab.size.y * k
	# cuerpo físico pequeño (no estorba al jugador: va en su propia capa)
	var col := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = clampf(minf(largo * 0.3, alto * 0.5), 0.01, 0.14)
	col.shape = sh
	col.position.y = sh.radius
	add_child(col)
	collision_layer = 1 << 7
	collision_mask = 1
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(50)
	safe_margin = 0.002
	anim = modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim and anim.get_animation_list().size() > 0:
		var lista := anim.get_animation_list()
		anim_nombre = lista[0]
		for n in lista:
			var l := String(n).to_lower()
			if l.contains("walk") or l.contains("run") or l.contains("anda"):
				anim_nombre = n
			if l.contains("idle"):
				anim_quieto = n
				var aq := anim.get_animation(n)
				if aq:
					aq.loop_mode = Animation.LOOP_LINEAR
		var a := anim.get_animation(anim_nombre)
		if a:
			a.loop_mode = Animation.LOOP_LINEAR
		anim.play(anim_nombre)
		anim.seek(randf() * a.length, true)
	# lombriz: rosada y húmeda (el modelo traía el color en los vértices)
	if tipo == "gusano":
		var mg := StandardMaterial3D.new()
		mg.albedo_color = Color(0.52, 0.3, 0.27)
		mg.roughness = 0.3
		mg.rim_enabled = true
		mg.rim = 0.3
		for g in modelo.find_children("*", "MeshInstance3D", true, false):
			(g as MeshInstance3D).material_override = mg
	voz = AudioStreamPlayer3D.new()
	voz.unit_size = 1.2 if tipo == "rata" else 2.5
	voz.max_distance = 14.0
	add_child(voz)
	if tipo == "gato":
		_malla_nueva(modelo)
		_pelaje_real(modelo)
		_preparar_anims_gato()
		var cs: Array = ZarekFauna.GATO_SENTADO
		if String(cs[0]) != "" and ResourceLoader.exists("res://zarek/fauna/%s.glb" % cs[0]):
			sentado = _cargar(cs[0], cs[1], cs[2]).nodo
			_tenir_negro(sentado)
			sentado.visible = false
			anim_sentado = sentado.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if anim_sentado and anim_sentado.get_animation_list().size() > 0:
				var an := anim_sentado.get_animation_list()[0]
				anim_sentado.get_animation(an).loop_mode = Animation.LOOP_LINEAR
				anim_sentado.play(an)
		ronroneo = AudioStreamPlayer3D.new()
		ronroneo.stream = AetherSynth.make("ronroneo")
		ronroneo.volume_db = -14.0
		ronroneo.unit_size = 0.8
		ronroneo.max_distance = 4.0
		add_child(ronroneo)
	_cambiar(E.PARA, randf_range(0.5, 3.0))

func _cambiar(e: E, t := 1.0) -> void:
	estado = e
	t_estado = t
	camino.clear()
	destino = Vector3.INF

func _sonar(nombre: String, db := -6.0) -> void:
	voz.stream = AetherSynth.make(nombre)
	voz.volume_db = db
	voz.pitch_scale = randf_range(0.9, 1.15)
	voz.play()

func _jugador() -> Node3D:
	return fauna.juego.player if fauna and fauna.juego and "player" in fauna.juego else null

## ¿Le da la luz de la linterna? (dentro del cono y cerca)
func _en_la_linterna() -> bool:
	var j = fauna.juego
	if j == null or not ("flash" in j) or j.flash == null or not j.flash.visible:
		return false
	var f: SpotLight3D = j.flash
	var a := global_position + Vector3(0, 0.05, 0) - f.global_position
	var d := a.length()
	if d > 7.0:
		return false
	return (-f.global_transform.basis.z).dot(a / d) > cos(deg_to_rad(f.spot_angle * 0.8))

func _ir_a(p: Vector3) -> void:
	destino = p
	camino = fauna.mansion.path(global_position, p)

func _punto_cerca(radio: float, lejos_de := Vector3.INF) -> Vector3:
	var mapa := get_world_3d().navigation_map
	var mejor := global_position
	var mejor_d := -1.0
	for k in 6:
		var dir := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		if lejos_de != Vector3.INF:
			var fuera := (global_position - lejos_de)
			fuera.y = 0
			dir = (fuera.normalized() + dir * 0.6).normalized()
		var p := NavigationServer3D.map_get_closest_point(mapa, global_position + dir * randf_range(radio * 0.5, radio))
		if absf(p.y - global_position.y) > 1.0:
			continue
		var puntos := p.distance_to(lejos_de) if lejos_de != Vector3.INF else randf()
		if puntos > mejor_d:
			mejor_d = puntos
			mejor = p
	return mejor

func _physics_process(delta: float) -> void:
	if estado == E.MUERTO:
		return
	t_estado -= delta
	var jug := _jugador()
	var pp := jug.global_position if jug else Vector3(9999, 0, 9999)
	var d_jug := Vector2(pp.x - global_position.x, pp.z - global_position.z).length() if absf(pp.y - global_position.y) < 2.2 else 99.0
	match tipo:
		"rata": _ia_rata(d_jug, pp)
		"gato": _ia_gato(d_jug, pp, delta)
		_: _ia_gusano(d_jug, pp)
	# moverse por el camino
	var v := Vector3.ZERO
	if not camino.is_empty() and vel_obj > 0.0:
		var sig: Vector3 = camino[0]
		var hacia := sig - global_position
		hacia.y = 0
		if hacia.length() < 0.15:
			camino.remove_at(0)
		else:
			v = hacia.normalized() * vel_obj
			var yaw := atan2(v.x, v.z)
			rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-delta * (14.0 if tipo == "rata" else 6.0)))
	elif tipo in ["gusano", "larva"] and vel_obj > 0.0:
		v = (transform.basis.z * vel_obj)
		rotation.y += sin(Time.get_ticks_msec() * 0.001 + _fase) * delta * 0.8
	velocity.x = v.x
	velocity.z = v.z
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.2
	move_and_slide()
	# animación al ritmo del paso
	if tipo == "gato" and not anims_gato.is_empty():
		_ajustar_suelo(delta)
		var rp := Vector2(velocity.x, velocity.z).length()
		if _bufando > 0.0:
			_bufando -= delta
			_gato_anim("Agression_loop")
		elif rp > 1.5:
			_gato_anim("Run_F_IP", clampf(rp / 2.6, 0.7, 1.5))
		elif rp > 0.7:
			_gato_anim("Trot_F_IP", clampf(rp / 1.1, 0.7, 1.4))
		elif rp > 0.03:
			_gato_anim("Walk_F_IP", clampf(rp / 0.45, 0.6, 1.5))
		else:
			_gato_anim(_pose_quieto)
	elif anim and anim_nombre != "":
		var rapidez := Vector2(velocity.x, velocity.z).length()
		if rapidez < 0.02:
			if anim_quieto != "":
				if anim.current_animation != anim_quieto:
					anim.play(anim_quieto, 0.2)
				anim.speed_scale = 1.0
			else:
				anim.speed_scale = 0.0
		else:
			if anim.current_animation != anim_nombre:
				anim.play(anim_nombre, 0.15)
			anim.speed_scale = clampf(rapidez / (0.45 if tipo == "gato" else 0.35), 0.4, 3.0)
		# el gato quieto usa su cuerpo sentado
		if sentado:
			var quieto := rapidez < 0.02 and estado in [E.SENTADO, E.PARA]
			sentado.visible = quieto
			modelo.visible = not quieto
	# gusanos: se estiran y encogen al arrastrarse
	if tipo in ["gusano", "larva"] and modelo:
		var s := sin(Time.get_ticks_msec() * 0.006 + _fase)
		modelo.scale = _escala * Vector3(1.0 - 0.06 * s, 1.0, 1.0 + 0.12 * s)
		modelo.rotation.z = s * 0.05
		modelo.position.x = s * 0.004
	# si el jugador lo pisa
	if d_jug < (0.22 if tipo in ["gusano", "larva"] else 0.3) and jug and absf(pp.y - global_position.y) < 2.0:
		if tipo in ["gusano", "larva"]:
			_aplastado()
		elif tipo == "rata" and estado != E.HUYE:
			_sonar("chillido", -2.0)
			_huir(pp, 2.6)

func _huir(de: Vector3, vel: float) -> void:
	_cambiar(E.HUYE, randf_range(1.5, 3.0))
	vel_obj = vel
	_ir_a(_punto_cerca(6.0, de))

# ---------------- rata ----------------
func _ia_rata(d_jug: float, pp: Vector3) -> void:
	_t_sonido -= get_physics_process_delta_time()
	if estado != E.HUYE and (d_jug < 2.8 or (_en_la_linterna() and d_jug < 6.0)):
		if randf() < 0.6:
			_sonar("chillido", -8.0)
		_huir(pp, randf_range(2.0, 2.8))
		return
	match estado:
		E.HUYE:
			if t_estado <= 0.0 or camino.is_empty():
				_cambiar(E.ESCONDE, randf_range(2.5, 7.0))
				vel_obj = 0.0
		E.ESCONDE, E.PARA:
			vel_obj = 0.0
			if t_estado <= 0.0:
				_cambiar(E.ANDA, randf_range(2.0, 6.0))
				vel_obj = randf_range(0.35, 0.7)
				_ir_a(_punto_cerca(4.0))
		E.ANDA:
			# corretea a ratos: se para de golpe a olfatear
			if t_estado <= 0.0 or camino.is_empty():
				_cambiar(E.PARA, randf_range(0.6, 2.5))
	if _t_sonido <= 0.0:
		_t_sonido = randf_range(8.0, 20.0)
		if d_jug < 10.0:
			_sonar("chillido", -16.0)

# ---------------- gusanos ----------------
func _ia_gusano(d_jug: float, pp: Vector3) -> void:
	vel_obj = 0.012 if tipo == "gusano" else 0.006
	# se apartan despacio de la luz
	if _en_la_linterna() and d_jug < 3.0:
		var fuera := global_position - pp
		rotation.y = lerp_angle(rotation.y, atan2(fuera.x, fuera.z), 0.02)
		vel_obj *= 2.0

func _aplastado() -> void:
	_cambiar(E.MUERTO)
	_sonar("aplastar", -6.0)
	if modelo:
		_escala.y *= 0.2
		modelo.scale = _escala
	if anim:
		anim.stop()
	var mancha := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.12, 0.1)
	mancha.mesh = pm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.2, 0.12, 0.08, 0.9)
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.albedo_texture = ZarekAbandono._disco()
	mancha.material_override = mt
	mancha.position = Vector3(0, 0.005, 0)
	add_child(mancha)
	collision_layer = 0

# ---------------- gato negro ----------------
func _ia_gato(d_jug: float, pp: Vector3, delta: float) -> void:
	_t_sonido -= delta
	_avisado_elena -= delta
	var j = fauna.juego
	var elena: Node3D = j.elena if j and "elena" in j else null
	# huye de Elena y bufa: el jugador lo oye y sabe que está cerca
	if elena and elena.visible and elena.global_position.distance_to(global_position) < 9.0:
		if estado != E.HUYE:
			_sonar("bufido", -2.0)
			if _avisado_elena <= 0.0 and d_jug < 15.0 and j.has_method("message"):
				j.message("El gato bufa hacia la oscuridad…", 2.5)
				_avisado_elena = 20.0
			_bufando = 0.9
			_huir(elena.global_position, 2.8)
		return
	# si corres hacia él, se asusta
	var jv := Vector3.ZERO
	if j and "player" in j and j.player and "velocity" in j.player:
		jv = j.player.velocity
	if d_jug < 1.6 and Vector2(jv.x, jv.z).length() > 3.5 and estado != E.HUYE:
		_sonar("bufido", -6.0)
		_bufando = 0.7
		_huir(pp, 2.6)
		return
	if ronroneo:
		var quiere := d_jug < 1.8 and estado in [E.SENTADO, E.PARA] and Vector2(jv.x, jv.z).length() < 1.5
		if quiere and not ronroneo.playing:
			ronroneo.play()
		elif not quiere and ronroneo.playing:
			ronroneo.stop()
	match estado:
		E.HUYE:
			if t_estado <= 0.0 or camino.is_empty():
				_cambiar(E.PARA, randf_range(2.0, 5.0))
				vel_obj = 0.0
		E.SENTADO:
			vel_obj = 0.0
			if not _pose_quieto.begins_with("Sit") and not _pose_quieto.begins_with("Caress"):
				_pose_quieto = "Sit_idle_%d" % randi_range(1, 3)
			if ronroneo and ronroneo.playing:
				_pose_quieto = "Caress_sit"
			# te mira
			var hacia := pp - global_position
			rotation.y = lerp_angle(rotation.y, atan2(hacia.x, hacia.z), 1.0 - exp(-delta * 2.0))
			if t_estado <= 0.0:
				_cambiar(E.SIGUE if d_jug < 14.0 and randf() < 0.6 else E.ANDA, randf_range(5.0, 12.0))
		E.PARA:
			vel_obj = 0.0
			if not _pose_quieto.begins_with("Idle"):
				_pose_quieto = "Idle_%d" % randi_range(1, 4)
			if t_estado <= 0.0:
				if d_jug > 12.0 and randf() < 0.4:
					# lejos de ti, a veces se tumba o se duerme un buen rato
					_cambiar(E.ESCONDE, randf_range(15.0, 40.0))
					_pose_quieto = ["Lie_Idle_1", "Lie_Idle_2", "Lie_Idle_3", "Lie_Idle_1"][randi() % 4]
				else:
					_cambiar(E.SENTADO if d_jug < 10.0 else E.ANDA, randf_range(3.0, 9.0))
		E.ESCONDE:
			vel_obj = 0.0
			# tumbado o dormido: se despierta si te acercas mucho o pasa el rato
			if t_estado <= 0.0 or d_jug < 2.5:
				_cambiar(E.PARA, randf_range(1.0, 3.0))
		E.SIGUE:
			# te sigue a unos 3-5 m, sin acercarse del todo
			if d_jug > 5.0 and d_jug < 20.0:
				vel_obj = 0.55 if d_jug < 9.0 else 1.1
				if destino == Vector3.INF or destino.distance_to(pp) > 2.0 or camino.is_empty():
					_ir_a(pp)
			elif d_jug <= 3.2:
				_cambiar(E.SENTADO, randf_range(3.0, 8.0))
			if t_estado <= 0.0:
				_cambiar(E.ANDA, randf_range(4.0, 9.0))
		E.ANDA:
			if destino == Vector3.INF:
				vel_obj = 0.45
				_ir_a(_punto_cerca(8.0))
			if t_estado <= 0.0 or camino.is_empty():
				_cambiar(E.PARA, randf_range(1.0, 4.0))
	if _t_sonido <= 0.0:
		_t_sonido = randf_range(14.0, 35.0)
		if d_jug < 16.0:
			_sonar("maullido", -8.0)
