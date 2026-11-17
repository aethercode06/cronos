class_name ZarekAnimal
extends CharacterBody3D
## Un bicho de la casa con física (gravedad, choca con paredes y muebles, empujado al pisarlo) y su propia
## inteligencia. tipo: "rata", "gato", "gusano" o "larva".

enum E { ANDA, PARA, HUYE, ESCONDE, SIGUE, SENTADO, MUERTO, DUERME, COME, ACECHA, SALTA, VENTANA, MIRA_NADA, MIMOS }
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
var _t_atasco := 0.0
var _pos_atasco := Vector3.ZERO

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
		_mat_ojos = primero

## Animaciones del gato real (57): andar, trote, carrera, quieto, sentado, tumbado, dormir, bufar, comer…
var anims_gato := {}
var _mat_ojos: ShaderMaterial
var _pupila := 0.35
## La pupila se cierra en rendija cuando le da la linterna y se abre en óvalo en la oscuridad.
func _actualizar_pupila(delta: float) -> void:
	if _mat_ojos == null:
		return
	var objetivo := 0.07 if _en_la_linterna() else 0.4
	_pupila = lerpf(_pupila, objetivo, 1.0 - exp(-delta * 3.0))
	_mat_ojos.set_shader_parameter("pupila", _pupila)
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
	if v.length() > 0.05:
		_t_atasco += delta
		if _t_atasco > 1.5:
			if global_position.distance_to(_pos_atasco) < 0.15:
				if not camino.is_empty():
					camino.remove_at(0)
				if camino.is_empty():
					destino = Vector3.INF
			_pos_atasco = global_position
			_t_atasco = 0.0
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.2
	move_and_slide()
	# animación al ritmo del paso
	if tipo == "gato" and not anims_gato.is_empty():
		_ajustar_suelo(delta)
		_actualizar_pupila(delta)
		var rp := Vector2(velocity.x, velocity.z).length()
		if _una_vez > 0.0:
			_una_vez -= delta
		elif _bufando > 0.0:
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
	var g: Node3D = fauna.gato if fauna and is_instance_valid(fauna.gato) else null
	# un gato que acecha agachado y despacio casi no se nota hasta tenerlo encima
	var alerta_gato := 0.9 if (g and g.estado == E.ACECHA and g.vel_obj < 1.0) else 1.4
	if g and estado != E.HUYE and g.global_position.distance_to(global_position) < alerta_gato:
		_sonar("chillido", -6.0)
		_huir(g.global_position, 2.2)
		return
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

## La rata atrapada por el gato: chilla, queda tirada y desaparece al rato.
func cazada() -> void:
	_cambiar(E.MUERTO)
	_sonar("chillido", -4.0)
	if anim:
		anim.stop()
	if modelo:
		modelo.rotation.z = PI * 0.5
		modelo.position.y += 0.03
	collision_layer = 0
	get_tree().create_timer(25.0).timeout.connect(func(): if is_instance_valid(self): queue_free())

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

# ---------------- gato ----------------
## Inteligencia del gato. Tiene necesidades que cambian con el tiempo (energía, hambre) y una confianza contigo:
##  - come y bebe en sus cuencos de la cocina cuando tiene hambre; duerme en sus sitios (junto a la chimenea,
##    al pie de las camas) cuando está cansado y se despierta con ruidos o si corres cerca;
##  - caza ratas: las acecha agachado, se lanza y a veces atrapa una;
##  - se sienta a mirar por las ventanas, explora, se lava;
##  - si te acercas despacio gana confianza: te sigue, se roza contigo y deja que lo acaricies (te calma);
##    si corres hacia él o hay ruidos fuertes se asusta;
##  - huye y bufa cuando Elena está cerca (te avisa) y a veces se queda mirando fijamente un rincón vacío.
var energia := 0.8
var hambre := 0.3
var confianza := 0.3
var _presa: Node3D
var _t_mirar_nada := randf_range(90.0, 200.0)
var _t_decidir := 0.0

func _cerca_jugador_despacio(d_jug: float, jv: Vector3) -> bool:
	return d_jug < 2.2 and Vector2(jv.x, jv.z).length() < 1.6

## El jugador lo acaricia (desde juego.gd con USAR).
func acariciar() -> bool:
	if confianza > 0.35 and estado != E.HUYE:
		confianza = minf(1.0, confianza + 0.15)
		_cambiar(E.MIMOS, randf_range(4.0, 6.0))
		vel_obj = 0.0
		_pose_quieto = "Caress_sit"
		if ronroneo:
			ronroneo.play()
		return true
	confianza = minf(1.0, confianza + 0.05)
	_sonar("bufido", -6.0)
	_bufando = 0.6
	var jug := _jugador()
	if jug:
		_huir(jug.global_position, 2.4)
	return false

## Un ruido fuerte en la casa (portazos, golpes…).
func oir_ruido(pos: Vector3, fuerte: float) -> void:
	var d := pos.distance_to(global_position)
	if d > 14.0 * fuerte:
		return
	if estado == E.DUERME:
		_cambiar(E.PARA, 1.0)
	if d < 6.0 * fuerte and estado != E.HUYE:
		_bufando = 0.4
		_huir(pos, 2.6)

func _ia_gato(d_jug: float, pp: Vector3, delta: float) -> void:
	_t_sonido -= delta
	_avisado_elena -= delta
	_t_mirar_nada -= delta
	var j = fauna.juego
	var elena: Node3D = j.elena if j and "elena" in j else null
	var jv := Vector3.ZERO
	if j and "player" in j and j.player and "velocity" in j.player:
		jv = j.player.velocity
	# necesidades
	var activo := estado not in [E.DUERME, E.ESCONDE, E.SENTADO, E.VENTANA, E.MIMOS]
	energia = clampf(energia + delta * (0.012 if not activo else -0.004), 0.0, 1.0)
	hambre = clampf(hambre + delta * 0.0025, 0.0, 1.0)
	if _cerca_jugador_despacio(d_jug, jv):
		confianza = minf(1.0, confianza + delta * 0.02)
	# 1) Elena cerca: bufa, te avisa y huye lejos a esconderse
	if elena and elena.visible and elena.global_position.distance_to(global_position) < 9.0:
		if estado != E.HUYE:
			_sonar("bufido", -2.0)
			if _avisado_elena <= 0.0 and d_jug < 15.0 and j.has_method("message"):
				j.message("El gato bufa hacia la oscuridad…", 2.5)
				_avisado_elena = 20.0
			_bufando = 0.9
			_huir(elena.global_position, 2.9)
			t_estado = randf_range(2.5, 4.0)
		return
	# 2) si corres hacia él, se asusta y pierde confianza
	if d_jug < 1.8 and Vector2(jv.x, jv.z).length() > 3.5 and estado not in [E.HUYE]:
		confianza = maxf(0.0, confianza - 0.12)
		_sonar("bufido", -6.0)
		_bufando = 0.7
		_huir(pp, 2.7)
		return
	# ronronea cuando estás cerca y tranquilo (si te tiene confianza)
	if ronroneo:
		var quiere := (estado == E.MIMOS) or (confianza > 0.5 and d_jug < 1.8 and estado in [E.SENTADO, E.PARA, E.SIGUE] and Vector2(jv.x, jv.z).length() < 1.5)
		if quiere and not ronroneo.playing:
			ronroneo.play()
		elif not quiere and ronroneo.playing:
			ronroneo.stop()
	match estado:
		E.HUYE:
			if t_estado <= 0.0 or camino.is_empty():
				# se queda escondido un rato antes de volver a lo suyo
				_cambiar(E.ESCONDE, randf_range(4.0, 12.0))
				_pose_quieto = "Crouch_idle_loop"
				vel_obj = 0.0
		E.ESCONDE:
			vel_obj = 0.0
			if t_estado <= 0.0:
				_decidir(d_jug, pp)
		E.DUERME:
			vel_obj = 0.0
			if energia > 0.98 or t_estado <= 0.0 or (d_jug < 1.5 and Vector2(jv.x, jv.z).length() > 2.0):
				_pose_quieto = "Lie_end"
				_cambiar(E.PARA, 1.5)
		E.COME:
			vel_obj = 0.0
			if not camino.is_empty() or (destino != Vector3.INF and Vector2(destino.x - global_position.x, destino.z - global_position.z).length() > 0.5):
				vel_obj = 0.9
				t_estado = maxf(t_estado, 12.0)
				if camino.is_empty():
					_ir_a(fauna.cuenco)
			else:
				_mirar_a(fauna.cuenco_mira, delta)
				_pose_quieto = "Eat_loop" if t_estado > 4.0 else "Drink_loop"
				hambre = maxf(0.0, hambre - delta * 0.08)
				if t_estado <= 0.0:
					_cambiar(E.PARA, 2.0)
		E.ACECHA:
			if not is_instance_valid(_presa) or _presa.process_mode == Node.PROCESS_MODE_DISABLED or _presa.estado == E.MUERTO:
				_decidir(d_jug, pp)
			else:
				var dp := _presa.global_position.distance_to(global_position)
				if dp < 1.25:
					# salto de caza: se lanza hacia la rata
					_cambiar(E.SALTA, 0.7)
					vel_obj = 3.4
					_ir_a(_presa.global_position)
					_gato_anim_una("Attack_crouch_RM" if randf() < 0.5 else "Jump_Place_IP")
				elif dp > 7.0 or t_estado <= 0.0:
					_decidir(d_jug, pp)
				else:
					# agachado, despacio; se para a ratos
					vel_obj = (0.35 if fmod(t_estado, 2.0) > 0.5 else 0.0) if dp > 1.8 else 2.4
					_pose_quieto = "Crouch_idle_loop"
					if destino == Vector3.INF or destino.distance_to(_presa.global_position) > 0.5 or camino.is_empty():
						_ir_a(_presa.global_position)
		E.SALTA:
			if t_estado < 0.35:
				vel_obj = 0.0
			elif is_instance_valid(_presa):
				_mirar_a(_presa.global_position, delta * 4.0)
			if t_estado <= 0.0:
				if is_instance_valid(_presa) and _presa.global_position.distance_to(global_position) < 0.9 and randf() < 0.6:
					_presa.cazada()
					hambre = maxf(0.0, hambre - 0.3)
				energia = maxf(0.0, energia - 0.1)
				_cambiar(E.SENTADO, randf_range(3.0, 6.0))
		E.VENTANA:
			if not camino.is_empty():
				vel_obj = 0.45 if not _ir_a_dormir else 0.6
				t_estado = maxf(t_estado, 8.0)
			elif _ir_a_dormir:
				_ir_a_dormir = false
				_cambiar(E.DUERME, randf_range(50.0, 110.0))
				_pose_quieto = ["Lie_Idle_1", "Sleep_loop", "Lie_Idle_2", "Sleep_loop"][randi() % 4]
			else:
				vel_obj = 0.0
				_pose_quieto = "Sit_idle_%d" % (1 + int(t_estado) % 3) if not _pose_quieto.begins_with("Sit") else _pose_quieto
				_mirar_a(_mira_ventana, delta)
				if t_estado <= 0.0:
					_decidir(d_jug, pp)
		E.MIRA_NADA:
			# se queda mirando fijamente un rincón vacío; a veces bufa
			vel_obj = 0.0
			_mirar_a(_mira_ventana, delta)
			_pose_quieto = "Crouch_idle_loop"
			if randf() < delta * 0.25:
				_bufando = 0.6
				_sonar("bufido", -10.0)
			if t_estado <= 0.0:
				_decidir(d_jug, pp)
		E.MIMOS:
			vel_obj = 0.0
			_mirar_a(pp, delta)
			if t_estado <= 0.0:
				_cambiar(E.SENTADO, randf_range(3.0, 6.0))
		E.SENTADO:
			vel_obj = 0.0
			if not _pose_quieto.begins_with("Sit") and not _pose_quieto.begins_with("Caress"):
				_pose_quieto = "Sit_idle_%d" % randi_range(1, 3)
			if ronroneo and ronroneo.playing:
				_pose_quieto = "Caress_sit"
			if d_jug < 10.0:
				_mirar_a(pp, delta)
			if t_estado <= 0.0:
				_decidir(d_jug, pp)
		E.PARA:
			vel_obj = 0.0
			if not _pose_quieto.begins_with("Idle") and _pose_quieto != "Lie_end":
				_pose_quieto = "Idle_%d" % randi_range(1, 4)
			if t_estado <= 0.0:
				_decidir(d_jug, pp)
		E.SIGUE:
			# te sigue de cerca y se roza contigo
			if d_jug > 2.2 and d_jug < 22.0:
				vel_obj = 0.5 if d_jug < 6.0 else (1.0 if d_jug < 12.0 else 1.8)
				if destino == Vector3.INF or destino.distance_to(pp) > 1.5 or camino.is_empty():
					_ir_a(pp)
			elif d_jug <= 2.2:
				vel_obj = 0.0
				_pose_quieto = "Caress_idle" if confianza > 0.6 else "Sit_idle_1"
				_mirar_a(pp, delta)
			else:
				_decidir(d_jug, pp)
			if t_estado <= 0.0:
				_decidir(d_jug, pp)
		E.ANDA:
			if destino == Vector3.INF:
				vel_obj = 0.45
				_ir_a(_punto_cerca(8.0))
			if t_estado <= 0.0 or camino.is_empty():
				_cambiar(E.PARA, randf_range(1.0, 4.0))
	if _t_sonido <= 0.0:
		_t_sonido = randf_range(14.0, 35.0)
		if d_jug < 16.0 and estado != E.DUERME and estado != E.ACECHA:
			_sonar("maullido", -8.0 if confianza < 0.6 else -5.0)

var _mira_ventana := Vector3.ZERO
func _mirar_a(p: Vector3, delta: float) -> void:
	var h := p - global_position
	if Vector2(h.x, h.z).length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(h.x, h.z), 1.0 - exp(-delta * 3.0))

## Una animación que se juega una vez (salto, zarpazo); luego vuelve a la normal.
func _gato_anim_una(nombre: String) -> void:
	if anims_gato.has(nombre):
		_anim_gato_actual = nombre
		anim.play(anims_gato[nombre], 0.1)
		_bufando = 0.0
		_una_vez = 0.7

## Elige qué hacer según sus necesidades y lo que tiene alrededor.
func _decidir(d_jug: float, pp: Vector3) -> void:
	# cazar una rata cercana
	if energia > 0.3:
		var mejor: Node3D = null
		var md := 6.0
		for a in fauna.animales:
			if is_instance_valid(a) and a.tipo == "rata" and a.estado != E.MUERTO and a.visible and absf((a as Node3D).global_position.y - global_position.y) < 1.0:
				var d := (a as Node3D).global_position.distance_to(global_position)
				if d < md:
					md = d
					mejor = a
		if mejor and randf() < 0.85:
			_presa = mejor
			_cambiar(E.ACECHA, 25.0)
			return
	# comer
	if hambre > 0.75 and fauna.cuenco != Vector3.INF:
		_cambiar(E.COME, 14.0)
		vel_obj = 0.5
		_ir_a(fauna.cuenco)
		return
	# dormir en uno de sus sitios
	if energia < 0.25:
		var sitio := fauna.sitio_dormir(global_position)
		_cambiar(E.DUERME, randf_range(50.0, 110.0))
		_pose_quieto = ["Lie_Idle_1", "Sleep_loop", "Lie_Idle_2", "Sleep_loop"][randi() % 4]
		if sitio != Vector3.INF and sitio.distance_to(global_position) > 1.0 and sitio.distance_to(global_position) < 10.0:
			# va andando y se tumba al llegar
			_cambiar(E.VENTANA, 30.0)
			_mira_ventana = sitio + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
			_ir_a(sitio)
			_ir_a_dormir = true
		return
	# mirar fijamente un rincón vacío (muy de vez en cuando)
	if _t_mirar_nada <= 0.0:
		_t_mirar_nada = randf_range(150.0, 300.0)
		_mira_ventana = global_position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 2.5
		_cambiar(E.MIRA_NADA, randf_range(6.0, 12.0))
		var j = fauna.juego
		if d_jug < 8.0 and j and j.has_method("message"):
			j.message("El gato mira fijamente un rincón vacío…", 3.0)
		return
	var dado := randf()
	if confianza > 0.55 and d_jug < 18.0 and dado < 0.45:
		_cambiar(E.SIGUE, randf_range(10.0, 25.0))
	elif dado < 0.6:
		var v := fauna.ventana_cerca(global_position)
		if v.size() == 2:
			_cambiar(E.VENTANA, randf_range(12.0, 25.0))
			_mira_ventana = v[1]
			_ir_a(v[0])
		else:
			_cambiar(E.ANDA, randf_range(4.0, 9.0))
	elif dado < 0.75 and d_jug < 10.0:
		_cambiar(E.SENTADO, randf_range(4.0, 10.0))
	elif dado < 0.85:
		_cambiar(E.PARA, randf_range(2.0, 5.0))
	else:
		_cambiar(E.ANDA, randf_range(4.0, 9.0))
var _ir_a_dormir := false
var _una_vez := 0.0
