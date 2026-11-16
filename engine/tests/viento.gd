extends Node3D
## Viento en la vegetación: unos pinos, arbustos e hierba con una racha; guarda fotogramas. -- <carpeta>
func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0]
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.28, 0.32, 0.4)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.75, 0.78, 0.85); env.ambient_light_energy = 0.7
	env.fog_enabled = true; env.fog_light_color = Color(0.3, 0.33, 0.4); env.fog_density = 0.02
	we.environment = env; add_child(we)
	var sol := DirectionalLight3D.new(); sol.rotation_degrees = Vector3(-35, 40, 0); sol.shadow_enabled = true; add_child(sol)
	var m := ZarekMansion.new(); add_child(m)
	m._load_props_info()
	var suelo := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(120, 120); suelo.mesh = pm
	var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.2, 0.18, 0.13); suelo.material_override = sm; add_child(suelo)
	var arboles := ["pino_grande_1", "pino_mediano_1", "pino_grande_2", "pino_mediano_2", "pino_joven", "pino_grande_3"]
	var i := 0
	for x in [-9.0, -3.0, 4.0, 10.0]:
		for z in [-14.0, -24.0]:
			var mm := m._con_viento(m._malla_glb("res://zarek/arboles/%s.glb" % arboles[i % 6]), 0.025, 0.035)
			var mi := MeshInstance3D.new(); mi.mesh = mm; mi.position = Vector3(x + z * 0.1, 0, z); add_child(mi); i += 1
	for k in 14:
		var b := m._con_viento(m._malla_glb("res://zarek/arboles/arbusto_%d.glb" % (1 + k % 2)), 0.12, 0.03)
		var mi := MeshInstance3D.new(); mi.mesh = b; mi.position = Vector3(randf_range(-8, 8), 0, randf_range(-9, -3)); add_child(mi)
	var ps: PackedScene = load("res://zarek/muebles/grass_medium_01.glb")
	if ps:
		var g: Node3D = ps.instantiate()
		var gm: Mesh = (g.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
		var gv := m._con_viento(gm, 0.3, 0.01)
		var mmesh := MultiMesh.new(); mmesh.transform_format = MultiMesh.TRANSFORM_3D; mmesh.mesh = gv; mmesh.instance_count = 600
		for k in 600:
			mmesh.set_instance_transform(k, Transform3D(Basis(Vector3.UP, randf() * TAU), Vector3(randf_range(-7, 7), 0, randf_range(-6, 1.5))))
		var mmi := MultiMeshInstance3D.new(); mmi.multimesh = mmesh; add_child(mmi)
		g.free()
	var cam := Camera3D.new(); add_child(cam); cam.fov = 60
	cam.position = Vector3(0, 1.7, 4.0); cam.look_at(Vector3(0, 4.0, -12))
	for f in 90:
		var racha := clampf((f - 20) / 20.0, 0.0, 1.0) * clampf((80 - f) / 20.0, 0.0, 1.0)
		RenderingServer.global_shader_parameter_set("viento", Vector4(1.0, 0.25, 0.4, racha))
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/f_%03d.jpg" % [out, f], 0.85)
	print("VIENTO OK")
	get_tree().quit()
