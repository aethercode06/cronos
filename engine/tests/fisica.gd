extends Node3D
## Botellas de vidrio con física: de pie, cayendo y rotas. godot --path . res://tests/fisica.tscn -- <carpeta>
var bots: Array = []
func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp"
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.42, 0.38, 0.34); env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.3; env.glow_enabled = true
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.02, 0.02, 0.025)
	we.environment = env; add_child(we)
	var cl := CanvasLayer.new(); var cr := ColorRect.new(); cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	var pm := ShaderMaterial.new(); pm.shader = load("res://zarek/post.gdshader"); cr.material = pm; cl.add_child(cr); add_child(cl)
	var mat_suelo := StandardMaterial3D.new()
	mat_suelo.albedo_texture = load("res://zarek/texturas/WoodFloor070/color.jpg"); mat_suelo.uv1_scale = Vector3(3, 3, 3)
	mat_suelo.albedo_color = Color(0.64, 0.58, 0.54)
	_caja(Vector3(8, 0.2, 8), Vector3(0, -0.1, 0), mat_suelo)
	var mat_mesa := StandardMaterial3D.new(); mat_mesa.albedo_color = Color(0.25, 0.14, 0.08); mat_mesa.roughness = 0.5
	_caja(Vector3(1.4, 0.06, 0.7), Vector3(0, 0.8, 0), mat_mesa)
	for lx in [-0.62, 0.62]:
		for lz in [-0.28, 0.28]:
			_caja(Vector3(0.06, 0.8, 0.06), Vector3(lx, 0.4, lz), mat_mesa)
	var luz := OmniLight3D.new(); luz.position = Vector3(0.6, 2.2, 1.2); luz.light_color = Color(1, 0.78, 0.5); luz.light_energy = 2.5; luz.omni_range = 7; luz.shadow_enabled = true; add_child(luz)
	var luz2 := OmniLight3D.new(); luz2.position = Vector3(-1.5, 1.6, -1.0); luz2.light_color = Color(0.5, 0.6, 1.0); luz2.light_energy = 0.8; luz2.omni_range = 5; add_child(luz2)
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	for i in 9:
		var b := ZarekBotella.azar(rng)
		b.position = Vector3(-0.55 + i * 0.135, 0.831, rng.randf_range(-0.12, 0.15))
		add_child(b); bots.append(b)
	add_to_group("zarek_oyentes")
	var cam := Camera3D.new(); cam.fov = 50; add_child(cam)
	cam.position = Vector3(0.25, 1.25, 1.55); cam.look_at(Vector3(0, 0.75, 0))
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_jpg(out + "/f_0.jpg", 0.9)
	for b in bots:
		if is_instance_valid(b):
			(b as RigidBody3D).apply_central_impulse(Vector3(0, 0.3, 1.4 + randf()) * 1.0)
	await get_tree().create_timer(0.28).timeout
	get_viewport().get_texture().get_image().save_jpg(out + "/f_1.jpg", 0.9)
	await get_tree().create_timer(2.6).timeout
	cam.position = Vector3(0.3, 0.9, 1.9); cam.look_at(Vector3(0, 0.05, 0.6))
	await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_jpg(out + "/f_2.jpg", 0.9)
	var rotas := 0
	for b in bots:
		if not is_instance_valid(b): rotas += 1
	print("FISICA OK rotas=", rotas)
	get_tree().quit()
func oir_ruido(_p: Vector3, _f: float) -> void:
	pass
func _caja(sz: Vector3, pos: Vector3, mat: Material) -> void:
	var sb := StaticBody3D.new(); sb.position = pos; add_child(sb)
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = sz; cs.shape = bs; sb.add_child(cs)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = sz; mi.mesh = bm; mi.material_override = mat; sb.add_child(mi)
