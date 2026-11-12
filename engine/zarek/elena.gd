class_name ZarekElena
extends Node3D
## Elena poseída por Zarek: cuerpo hecho por código e IA que ronda, oye,
## ve, persigue, busca y huye de la sal. Teme la luz de las lámparas.

signal caught
signal state_changed(s: String)

enum S { DORMANT, WANDER, INVESTIGATE, CHASE, SEARCH, FLEE, GHOST }

var mansion: ZarekMansion
var player: AetherPlayerFP
var state := S.DORMANT
var timer := 12.0
var path: Array[Vector3] = []
var repath := 0.0
var last_seen := Vector3.ZERO
var lost_t := 0.0
var aggro := 0                 # sube con cada sello
var player_hidden := false
var flashlight_on := false
var can_catch := true
var sees_player := false
var seen_t := 0.0              # tiempo que lleva viéndote
var _speed := 1.6
var _anim_t := 0.0
var _twitch := 0.0
var _twitch_t := 0.0
var _burst := 0.0
var _vel := Vector3.ZERO
var _ray: PhysicsRayQueryParameters3D
var _snd_loop: AudioStreamPlayer3D
var _snd_one: AudioStreamPlayer3D
var _creak_t := 4.0

# partes del cuerpo
var body: Node3D
var torso: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var fore_l: Node3D
var fore_r: Node3D
var hair: Array[MeshInstance3D] = []
var dress_mat: StandardMaterial3D
var eye_mat: StandardMaterial3D
var only_visual := false
const MODEL := "res://zarek/modelos/elena.glb"
const USAR_NORMAL := 0.0
const PIEL := preload("res://zarek/elena_piel.gdshader")
## Expresiones faciales: si falta alguna se usa la de reserva.
const EXPRS := {"mirada": "sonrisa", "sonrisa": "sonrisa", "furia": "sonrisa", "grito": "sonrisa", "poseida": "poseida"}
var piel: ShaderMaterial
var skel: Skeleton3D
var jaw_bone := -1
var jaw_rest := Quaternion()
var jaw_open := 0.0
var jaw_target := 0.0
var expr := ""
var _expr_tex := {}
var _mix := 1.0
var _parpadeo := 3.0
var model: Node3D
var anim: AnimationPlayer
var eye_height := 1.86
var _cur_anim := ""

func setup(m: ZarekMansion, p: AetherPlayerFP) -> void:
	mansion = m
	player = p
	_ray = PhysicsRayQueryParameters3D.new()
	_ray.collision_mask = 1
	_snd_loop = AudioStreamPlayer3D.new()
	_snd_loop.stream = AetherSynth.make("aliento")
	_snd_loop.unit_size = 3.0
	_snd_loop.max_distance = 22.0
	_snd_loop.position.y = 1.6
	add_child(_snd_loop)
	_snd_one = AudioStreamPlayer3D.new()
	_snd_one.unit_size = 5.0
	_snd_one.max_distance = 35.0
	_snd_one.position.y = 1.5
	add_child(_snd_one)

func _ready() -> void:
	build_body()

# ---------------- cuerpo ----------------
func _mat(col: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	return m

func _part(mesh: Mesh, mat: Material, pos: Vector3, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _cap(r: float, hgt: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = hgt
	c.radial_segments = 10
	c.rings = 4
	return c

func _stain_tex() -> ImageTexture:
	var sz := 128
	var img := Image.create(sz, sz, true, Image.FORMAT_RGB8)
	var n := FastNoiseLite.new()
	n.seed = 666
	n.frequency = 0.05
	var b := FastNoiseLite.new()
	b.seed = 13
	b.frequency = 0.03
	for y in sz:
		for x in sz:
			var v := 0.42 + 0.18 * n.get_noise_2d(x, y)
			var c := Color(v * 0.95, v * 0.9, v * 0.8)
			var dirt := clampf(float(y) / sz * 1.3 - 0.4, 0.0, 1.0) * (0.5 + 0.5 * n.get_noise_2d(x * 2.0, y))
			c = c.lerp(Color(0.12, 0.09, 0.07), dirt)
			var blood := b.get_noise_2d(x, y * 0.35)
			if blood > 0.32:
				c = c.lerp(Color(0.28, 0.02, 0.02), clampf((blood - 0.32) * 5.0, 0.0, 0.9))
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func build_body() -> void:
	if ResourceLoader.exists(MODEL):
		_build_model()
		return
	body = Node3D.new()
	add_child(body)
	var skin := _mat(Color(0.5, 0.52, 0.5), 0.75)
	dress_mat = _mat(Color(1, 1, 1), 1.0)
	dress_mat.albedo_texture = _stain_tex()
	dress_mat.emission_enabled = true
	dress_mat.emission = Color(0.35, 0.36, 0.4)
	dress_mat.emission_energy_multiplier = 0.03
	var dirt := _mat(Color(0.1, 0.07, 0.06), 1.0)
	var hair_mat := _mat(Color(0.2, 0.025, 0.02), 0.55)
	hair_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dark := _mat(Color(0.0, 0.0, 0.0), 1.0)
	# vestido de saco roto: falda estrecha y jirones colgando
	var skirt := CylinderMesh.new()
	skirt.top_radius = 0.16
	skirt.bottom_radius = 0.34
	skirt.height = 1.2
	skirt.radial_segments = 8
	_part(skirt, dress_mat, Vector3(0, 0.66, 0), body)
	for i in 9:
		var a := TAU * i / 9.0 + 0.2
		var bm := BoxMesh.new()
		bm.size = Vector3(0.09, randf_range(0.18, 0.4), 0.02)
		var rag := _part(bm, dress_mat if i % 3 else dirt, Vector3(sin(a) * 0.33, 0.06 - bm.size.y * 0.3, cos(a) * 0.33), body)
		rag.rotation.y = -a
		rag.rotation.x = 0.12
	# pies descalzos y sucios
	for sx in [-0.09, 0.1]:
		_part(_cap(0.045, 0.24), dirt, Vector3(sx, 0.04, -0.1), body).rotation.x = PI * 0.5
	torso = Node3D.new()
	torso.position = Vector3(0, 1.24, 0)
	body.add_child(torso)
	_part(_cap(0.14, 0.62), dress_mat, Vector3(0, 0.2, 0), torso)
	# cuello largo, antinatural
	_part(_cap(0.04, 0.34), skin, Vector3(0, 0.6, 0), torso)
	head = Node3D.new()
	head.position = Vector3(0, 0.8, 0)
	torso.add_child(head)
	var sk := SphereMesh.new()
	sk.radius = 0.11
	sk.height = 0.26
	var hd := _part(sk, skin, Vector3.ZERO, head)
	hd.scale = Vector3(0.88, 1.08, 0.92)
	# cuencas negras y pupilas rojas
	var sock := SphereMesh.new()
	sock.radius = 0.03
	sock.height = 0.045
	eye_mat = _mat(Color(0.05, 0.0, 0.0), 0.2)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.08, 0.04)
	eye_mat.emission_energy_multiplier = 0.6
	var em := SphereMesh.new()
	em.radius = 0.011
	em.height = 0.02
	for ex in [-0.04, 0.04]:
		_part(sock, dark, Vector3(ex, 0.02, -0.088), head)
		_part(em, eye_mat, Vector3(ex, 0.02, -0.112), head)
	# boca abierta, alargada
	var mouth := SphereMesh.new()
	mouth.radius = 0.025
	mouth.height = 0.1
	_part(mouth, dark, Vector3(0, -0.065, -0.09), head)
	# pelo rojo oscuro, largo, cubriendo media cara
	for i in 26:
		var a := -PI * 0.85 + (PI * 1.7) * i / 25.0
		var ln := randf_range(0.75, 1.1)
		var bm := BoxMesh.new()
		bm.size = Vector3(0.045, ln, 0.01)
		var hp := Vector3(sin(a) * 0.105, -ln * 0.5 + 0.08, cos(a) * 0.105)
		var strand := _part(bm, hair_mat, hp, head)
		strand.rotation.y = -a
		strand.rotation.x = 0.06
		hair.append(strand)
	for i in 6:
		var ln := randf_range(0.5, 0.75)
		var bm := BoxMesh.new()
		bm.size = Vector3(0.035, ln, 0.01)
		# cae por delante y deja ver un ojo
		var x := -0.075 + i * 0.022
		if i >= 4:
			x += 0.05
		var strand := _part(bm, hair_mat, Vector3(x, -ln * 0.5 + 0.1, -0.118), head)
		strand.rotation.x = -0.05
		hair.append(strand)
	# brazos muy largos con dedos
	arm_l = _arm(-1.0, skin)
	arm_r = _arm(1.0, skin)
	fore_l = arm_l.get_child(1)
	fore_r = arm_r.get_child(1)
	for mi in find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

## Modelo 3D real (TRELLIS + Blender) con animaciones idle/walk/run/attack.
func _build_model() -> void:
	var ps: PackedScene = load(MODEL)
	model = ps.instantiate()
	model.rotation.y = PI  # el modelo mira a +Z; Elena mira a -Z
	add_child(model)
	eye_height = 1.67
	var found := model.find_children("*", "AnimationPlayer", true, false)
	if found.size() > 0:
		anim = found[0]
		for n in ["idle", "walk", "run"]:
			if anim.has_animation(n):
				anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		play_anim("idle")
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for i in m.get_surface_override_material_count():
			var base: Material = m.mesh.surface_get_material(i)
			var tex: Texture2D = null
			var nt: Texture2D = null
			var rt: Texture2D = null
			if base is StandardMaterial3D:
				var bm := base as StandardMaterial3D
				tex = bm.albedo_texture
				nt = bm.normal_texture
				rt = bm.roughness_texture
			var sm := ShaderMaterial.new()
			sm.shader = PIEL
			sm.set_shader_parameter("albedo_tex", tex)
			if nt:
				sm.set_shader_parameter("normal_tex", nt)
				sm.set_shader_parameter("usar_normal", USAR_NORMAL)
			else:
				sm.set_shader_parameter("usar_normal", 0.0)
			if rt:
				sm.set_shader_parameter("mr_tex", rt)
			m.set_surface_override_material(i, sm)
			piel = sm
	var sk := model.find_children("*", "Skeleton3D", true, false)
	if sk.size() > 0:
		skel = sk[0]
		jaw_bone = skel.find_bone("jaw")
		if jaw_bone >= 0:
			jaw_rest = skel.get_bone_pose_rotation(jaw_bone)
	set_expr("mirada", true)
	# ojos rojos que brillan en la oscuridad
	eye_mat = _mat(Color(0.1, 0.0, 0.0), 0.3)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.08, 0.03)
	eye_mat.emission_energy_multiplier = 0.0

func _cara(nombre: String) -> Texture2D:
	if _expr_tex.has(nombre):
		return _expr_tex[nombre]
	var t: Texture2D = null
	var p := "res://zarek/modelos/cara/%s.png" % nombre
	if ResourceLoader.exists(p):
		t = load(p)
	elif EXPRS.has(nombre) and EXPRS[nombre] != nombre:
		t = _cara(EXPRS[nombre])
	_expr_tex[nombre] = t
	return t

## Cambia la expresión con un fundido corto (o al instante).
func set_expr(nombre: String, instant := false) -> void:
	if piel == null or nombre == expr:
		return
	var t := _cara(nombre)
	if t == null:
		return
	if instant or expr == "":
		piel.set_shader_parameter("cara_a", t)
		piel.set_shader_parameter("cara_b", t)
		_mix = 1.0
	else:
		piel.set_shader_parameter("cara_a", _cara(expr))
		piel.set_shader_parameter("cara_b", t)
		_mix = 0.0
	expr = nombre
	jaw_target = 0.42 if nombre == "grito" else (0.08 if nombre == "furia" else 0.0)
	piel.set_shader_parameter("ojos_brillo", 1.4 if nombre == "poseida" else 0.0)

## Elige la expresión según lo que hace Elena; la mandíbula y el fundido se animan aquí.
func _cara_process(delta: float) -> void:
	if piel == null:
		return
	var want := "mirada"
	match state:
		S.CHASE:
			want = "grito" if _cur_anim == "attack" else "furia"
		S.INVESTIGATE, S.SEARCH:
			want = "sonrisa"
		S.GHOST:
			want = "poseida"
		S.FLEE:
			want = "grito"
		_:
			want = "mirada"
	if _cur_anim == "attack":
		want = "grito"
	set_expr(want)
	if _mix < 1.0:
		_mix = minf(1.0, _mix + delta * 4.0)
		piel.set_shader_parameter("mezcla", _mix)
	# boca: se abre del todo al gritar y tiembla un poco
	var tgt := jaw_target + (0.04 * sin(Time.get_ticks_msec() * 0.03) if expr == "grito" else 0.0)
	jaw_open = lerpf(jaw_open, tgt, minf(1.0, delta * 10.0))
	if skel and jaw_bone >= 0:
		skel.set_bone_pose_rotation(jaw_bone, jaw_rest * Quaternion(Vector3.RIGHT, jaw_open))

func play_anim(n: String, speed := 1.0) -> void:
	if anim == null or not anim.has_animation(n):
		return
	anim.speed_scale = speed
	if _cur_anim != n:
		_cur_anim = n
		anim.play(n, 0.25)

func _arm(side: float, skin: Material) -> Node3D:
	var sh := Node3D.new()
	sh.position = Vector3(0.18 * side, 0.45, 0)
	torso.add_child(sh)
	_part(_cap(0.04, 0.48), dress_mat, Vector3(0, -0.22, 0), sh)
	var el := Node3D.new()
	el.position = Vector3(0, -0.46, 0)
	sh.add_child(el)
	_part(_cap(0.03, 0.5), skin, Vector3(0, -0.24, 0), el)
	var palm := BoxMesh.new()
	palm.size = Vector3(0.06, 0.09, 0.025)
	_part(palm, skin, Vector3(0, -0.52, 0), el)
	var fm := BoxMesh.new()
	fm.size = Vector3(0.012, 0.15, 0.012)
	for f in 4:
		var fi := _part(fm, skin, Vector3(-0.022 + f * 0.015, -0.63, 0), el)
		fi.rotation.z = (f - 1.5) * 0.06
	return sh

# ---------------- IA ----------------
func set_state(s: S, t := 0.0) -> void:
	if state == s:
		return
	state = s
	timer = t
	path.clear()
	repath = 0.0
	visible = s != S.DORMANT
	if _snd_loop:
		if s == S.CHASE:
			if not _snd_loop.playing:
				_snd_loop.play()
		else:
			_snd_loop.stop()
	state_changed.emit(S.keys()[s])

func state_name() -> String:
	return S.keys()[state]

## Aparece lejos del jugador y se queda quieta un rato.
func vanish(sec: float) -> void:
	set_state(S.DORMANT, sec)
	global_position = mansion.random_floor(player.global_position, 18.0)

func wake_far() -> void:
	global_position = mansion.random_floor(player.global_position, 16.0, mansion.region.get(mansion.to_cell(player.global_position), -1))
	set_state(S.WANDER)

func hear(pos: Vector3, loud: float) -> void:
	if state in [S.DORMANT, S.FLEE, S.GHOST] or player_hidden:
		return
	var d := global_position.distance_to(pos)
	if d < loud * (1.0 + aggro * 0.15):
		if state != S.CHASE:
			last_seen = pos
			set_state(S.INVESTIGATE, 12.0)

func repel(from: Vector3) -> void:
	set_state(S.FLEE, 2.0)
	var away := (global_position - from)
	away.y = 0
	_vel = away.normalized() * 7.0

func _can_see_player() -> bool:
	if player_hidden or player == null:
		return false
	var pp := player.global_position
	var to := pp - global_position
	to.y = 0
	var d := to.length()
	var max_d := (20.0 if flashlight_on else 12.0) + aggro * 1.5
	if mansion.is_lit(pp):
		max_d += 6.0
	if d > max_d:
		return false
	if d > 2.6:
		var fwd := -global_transform.basis.z
		fwd.y = 0
		if fwd.normalized().dot(to.normalized()) < cos(deg_to_rad(70.0 if state != S.CHASE else 110.0)):
			return false
	_ray.from = global_position + Vector3(0, 1.6, 0)
	_ray.to = pp + Vector3(0, 1.5, 0)
	var hit := get_world_3d().direct_space_state.intersect_ray(_ray)
	return hit.is_empty()

func _physics_process(delta: float) -> void:
	if only_visual or mansion == null:
		return
	timer -= delta
	sees_player = state != S.DORMANT and _can_see_player()
	seen_t = seen_t + delta if sees_player else 0.0
	match state:
		S.DORMANT:
			if timer <= 0.0:
				wake_far()
		S.WANDER:
			_speed = 1.5 + aggro * 0.18
			if sees_player:
				_start_chase()
			elif path.is_empty():
				var target: Vector3
				var bias := 0.25 + aggro * 0.17
				if randf() < bias:
					target = player.global_position + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
				else:
					target = mansion.random_floor()
				path = _safe_path(target)
				if path.is_empty():
					path = _safe_path(mansion.random_floor())
		S.INVESTIGATE:
			_speed = 2.5 + aggro * 0.2
			if sees_player:
				_start_chase()
			elif path.is_empty():
				path = _safe_path(last_seen)
				if path.is_empty() or global_position.distance_to(last_seen) < 1.2:
					set_state(S.SEARCH, 5.0)
		S.CHASE:
			_speed = minf(3.75 + aggro * 0.25, 4.7)
			if sees_player:
				last_seen = player.global_position
				lost_t = 0.0
			else:
				lost_t += delta
				if lost_t > 3.5:
					set_state(S.SEARCH, 6.0)
			repath -= delta
			if repath <= 0.0:
				repath = 0.35
				if sees_player and global_position.distance_to(last_seen) < 7.0:
					path = [Vector3(last_seen.x, 0, last_seen.z)]
				else:
					path = mansion.path(global_position, last_seen)
			if mansion.is_lit(player.global_position) and aggro < 2 and global_position.distance_to(player.global_position) > 2.0:
				# la luz la detiene: se aleja
				set_state(S.SEARCH, 3.0)
		S.SEARCH:
			_speed = 1.2
			if sees_player:
				_start_chase()
			elif timer <= 0.0:
				set_state(S.WANDER)
			elif path.is_empty():
				path = _safe_path(last_seen + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5)))
		S.FLEE:
			global_position += _vel * delta
			_vel = _vel.lerp(Vector3.ZERO, delta * 2.0)
			if timer <= 0.0:
				vanish(16.0 + randf() * 6.0)
			_animate(delta, 1.0)
			return
		S.GHOST:
			_animate(delta, 0.0)
			return
	_move(delta)
	# atrapar
	if can_catch and state in [S.CHASE, S.INVESTIGATE, S.WANDER, S.SEARCH] and not player_hidden:
		var dd := Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z).length()
		if dd < 1.05:
			caught.emit()
	# puertas: las abre de golpe al pasar
	var d := mansion.door_near(global_position, 1.3)
	if not d.is_empty() and not d.open and not d.locked:
		mansion.set_door(d, true, true)
		d.snd.stream = AetherSynth.make("portazo")
		d.snd.play()
		if player.global_position.distance_to(global_position) < 14.0:
			player.shake(6.0)
	_creak_t -= delta
	if _creak_t <= 0.0:
		_creak_t = randf_range(5.0, 11.0)
		_snd_one.stream = AetherSynth.make("crujido")
		_snd_one.play()

func _start_chase() -> void:
	last_seen = player.global_position
	lost_t = 0.0
	set_state(S.CHASE)
	_snd_one.stream = AetherSynth.make("grito")
	_snd_one.volume_db = -6.0
	_snd_one.play()

## Camino que evita habitaciones iluminadas (le temen a la luz).
func _safe_path(target: Vector3) -> Array[Vector3]:
	if aggro < 2 and mansion.is_lit(target):
		return [] as Array[Vector3]
	var p := mansion.path(global_position, target)
	if aggro < 2:
		for wp in p:
			if mansion.is_lit(wp):
				return [] as Array[Vector3]
	return p

func _move(delta: float) -> void:
	var moving := 0.0
	if not path.is_empty():
		var wp: Vector3 = path[0]
		var to := wp - global_position
		to.y = 0
		if to.length() < 0.35:
			path.remove_at(0)
		else:
			# movimiento a tirones cuando persigue (da más miedo)
			var k := 1.0
			if state == S.CHASE:
				_burst += delta * 3.2
				k = 0.55 + 0.9 * absf(sin(_burst))
			var step := to.normalized() * _speed * k * delta
			if step.length() > to.length():
				step = to
			global_position += step
			var yaw := atan2(-to.x, -to.z)
			rotation.y = lerp_angle(rotation.y, yaw, minf(1.0, delta * (9.0 if state == S.CHASE else 4.0)))
			moving = _speed * k
	elif state == S.CHASE:
		var to := player.global_position - global_position
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, delta * 8.0))
	global_position.y = 0.0
	_animate(delta, moving)

func _process(delta: float) -> void:
	_cara_process(delta)
	if only_visual:
		_animate(delta, 0.0)

# ---------------- animación procedural ----------------
func _animate(delta: float, spd: float) -> void:
	if model != null:
		if state == S.GHOST and not only_visual and _cur_anim == "attack":
			return
		if state == S.CHASE or state == S.FLEE:
			play_anim("run", 1.15)
		elif spd > 0.2:
			play_anim("walk", clampf(spd / 1.6, 0.7, 1.6))
		else:
			play_anim("idle")
		return
	if body == null:
		return
	_anim_t += delta * (1.0 + spd * 1.6)
	_twitch_t -= delta
	if _twitch_t <= 0.0:
		_twitch_t = randf_range(0.6, 2.4) if state != S.CHASE else randf_range(0.15, 0.6)
		_twitch = randf_range(-0.6, 0.6)
	var chase := state == S.CHASE
	var lean := 0.42 if chase else 0.08
	torso.rotation.x = lerpf(torso.rotation.x, -lean - (0.0 if spd < 0.1 else 0.06 * sin(_anim_t * 4.0)), delta * 6.0)
	torso.rotation.z = sin(_anim_t * 1.3) * 0.05
	head.rotation.z = lerpf(head.rotation.z, 0.42 + _twitch * (1.0 if chase else 0.5), delta * (18.0 if chase else 5.0))
	head.rotation.x = lerpf(head.rotation.x, 0.3 if chase else -0.25 + sin(_anim_t * 0.7) * 0.08, delta * 5.0)
	body.position.y = absf(sin(_anim_t * 3.0)) * 0.03 * minf(spd, 2.0)
	var reach := 1.25 if chase else 0.0
	arm_l.rotation.x = lerpf(arm_l.rotation.x, reach + sin(_anim_t * 3.0) * 0.25 * minf(spd, 1.0), delta * 7.0)
	arm_r.rotation.x = lerpf(arm_r.rotation.x, reach - sin(_anim_t * 3.0) * 0.25 * minf(spd, 1.0), delta * 7.0)
	arm_l.rotation.z = -0.08 + sin(_anim_t * 1.1) * 0.04
	arm_r.rotation.z = 0.08 - sin(_anim_t * 1.3) * 0.04
	fore_l.rotation.x = 0.25 if chase else 0.05
	fore_r.rotation.x = 0.25 if chase else 0.05
	for i in hair.size():
		hair[i].rotation.x = sin(_anim_t * 2.0 + i) * 0.04 - (0.15 if chase else 0.0)
	eye_mat.emission_energy_multiplier = 2.5 if chase else 0.6
