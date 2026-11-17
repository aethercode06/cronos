extends Node3D
## Sala sencilla con la linterna del juego (misma configuración que juego.gd) para ver el haz con el renderizador
## del teléfono. Uso: godot --rendering-method mobile --path . res://tests/linterna_vista.tscn -- salida_dir [vieja]
func _mat(dir: String, escala := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://zarek/texturas/%s/color.jpg" % dir)
	if ResourceLoader.exists("res://zarek/texturas/%s/normal.jpg" % dir):
		m.normal_enabled = true
		m.normal_texture = load("res://zarek/texturas/%s/normal.jpg" % dir)
	if ResourceLoader.exists("res://zarek/texturas/%s/rough.jpg" % dir):
		m.roughness_texture = load("res://zarek/texturas/%s/rough.jpg" % dir)
	m.uv1_scale = Vector3(escala, escala, escala)
	m.uv1_triplanar = true
	return m

func _caja(t: Vector3, p: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = t
	mi.mesh = b
	mi.material_override = m
	mi.position = p
	add_child(mi)

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var dir := args[0] if args.size() > 0 else "/tmp"
	var vieja := args.size() > 1 and args[1] == "vieja"
	var etiqueta: String = args[1] if args.size() > 1 else "nueva"
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0, 0, 0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.42, 0.38, 0.34)
	e.ambient_light_energy = 0.55 if not vieja else 0.32
	e.tonemap_exposure = 1.65 if not vieja else 1.35
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var pared := _mat("Wallpaper001C", 0.6)
	var suelo := _mat("WoodFloor043", 0.5)
	_caja(Vector3(10, 0.2, 14), Vector3(0, -0.1, -5), suelo)
	_caja(Vector3(10, 0.2, 14), Vector3(0, 3.3, -5), pared)
	_caja(Vector3(10, 3.2, 0.2), Vector3(0, 1.6, -9), pared)
	_caja(Vector3(0.2, 3.2, 14), Vector3(-3.5, 1.6, -5), pared)
	_caja(Vector3(0.2, 3.2, 14), Vector3(3.5, 1.6, -5), pared)
	for n in ["vict_antique_chair", "GothicCommode_01", "t_mu_polly"]:
		var path := "res://zarek/muebles/%s.glb" % n
		if not ResourceLoader.exists(path):
			path = "res://zarek/objetos/%s.glb" % n
		if ResourceLoader.exists(path):
			var o: Node3D = (load(path) as PackedScene).instantiate()
			add_child(o)
			match n:
				"vict_antique_chair": o.position = Vector3(-0.8, 0, -5.5); o.rotation.y = 0.5
				"GothicCommode_01": o.position = Vector3(1.6, 0, -8.5)
				_: o.position = Vector3(-0.85, 0.45, -5.45); o.rotation.y = 0.5
	var cam := Camera3D.new()
	cam.fov = 70
	add_child(cam)
	cam.position = Vector3(0.3, 1.6, 0.5)
	var fn := Node3D.new()
	add_child(fn)
	fn.position = cam.position + Vector3(0.18, -0.15, 0)
	var juego: Node = load("res://zarek/juego.gd").new()
	if args.size() > 1 and args[1] == "diag":
		var f := SpotLight3D.new()
		f.light_energy = 4.0; f.spot_range = 32.0; f.spot_angle = 40.0; f.spot_angle_attenuation = 1.0
		f.light_projector = load("res://tests/_diag/diag.png")
		fn.add_child(f)
		vieja = true
	elif vieja:
		var f := SpotLight3D.new()
		f.light_color = Color(1.0, 0.9, 0.72); f.light_energy = 6.0; f.spot_range = 32.0; f.spot_angle = 40.0
		f.spot_angle_attenuation = 1.6; f.spot_attenuation = 0.8; f.shadow_enabled = true; f.shadow_bias = 0.04
		fn.add_child(f)
		var near := OmniLight3D.new(); near.light_color = Color(1.0, 0.88, 0.7); near.omni_range = 4.5; near.light_energy = 0.7
		fn.add_child(near)
	else:
		# la misma linterna del juego: se construye con su función y se mueve a este punto
		juego._flashlight()
		juego.flash_node.reparent(self, false)
		juego.flash_node.position = fn.position
		for c in [juego._rebote, juego._polvo]:
			c.reparent(self, false)
		juego._rebote.light_energy = 0.0
		juego.flash.light_energy = 7.0 * 0.55
		juego.flash_foco.light_energy = 7.0
		juego._polvo.position = Vector3(0.3, 1.5, -2.0)
	var vistas := [[Vector3(0, 1.4, -9), "pared"], [Vector3(-0.8, 0.6, -5.5), "silla"], [Vector3(1.6, 0.6, -8.4), "comoda"]]
	for v in vistas:
		cam.look_at(v[0])
		var nodo: Node3D = fn if vieja else juego.flash_node
		nodo.look_at(v[0])
		if not vieja:
			# rebote como en el juego: a 0,45 m de la superficie donde da el haz
			var haz: Vector3 = ((v[0] as Vector3) - nodo.global_position).normalized()
			juego._rebote.global_position = v[0] - haz * 0.45
			juego._rebote.light_energy = 0.55 * clampf(1.0 - nodo.global_position.distance_to(v[0] as Vector3) / 14.0, 0.0, 1.0)
		for k in 12:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [dir, etiqueta, v[1]])
		print("CAPTURA ", v[1])
	get_tree().quit()
