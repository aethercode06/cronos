extends Node3D
## Vistas del exterior (bosque y fachada) con la luz del juego: godot --path . res://tests/exterior.tscn -- <carpeta>
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var out := a[0] if a.size() > 0 else "/tmp"
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.38, 0.34); env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.35; env.tonemap_white = 6.0
	env.fog_enabled = true; env.fog_light_color = Color(0.12, 0.135, 0.18); env.fog_density = 0.05; env.fog_height = 1.4; env.fog_height_density = 0.32; env.fog_sky_affect = 0.85
	env.glow_enabled = true; env.glow_intensity = 0.8; env.glow_bloom = 0.06; env.glow_hdr_threshold = 0.9
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.02, 0.03, 0.06); sm.sky_horizon_color = Color(0.06, 0.07, 0.1); sky.sky_material = sm
	env.sky = sky; env.background_mode = Environment.BG_SKY
	we.environment = env; add_child(we)
	var moon := DirectionalLight3D.new(); moon.light_color = Color(0.55, 0.65, 0.95); moon.light_energy = 0.45
	moon.rotation_degrees = Vector3(-38, -55, 0); moon.shadow_enabled = true; moon.directional_shadow_max_distance = 60.0; moon.shadow_bias = 0.06; moon.shadow_normal_bias = 2.5; add_child(moon)
	var cl := CanvasLayer.new(); var cr := ColorRect.new(); cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	var pm := ShaderMaterial.new(); pm.shader = load("res://zarek/post.gdshader"); cr.material = pm; cl.add_child(cr); add_child(cl)
	var m := ZarekMansion.new(); add_child(m); m.build(int(OS.get_environment("Q")) if OS.get_environment("Q") != "" else 2)
	var cam := Camera3D.new(); cam.fov = 70.0; cam.far = 300.0; add_child(cam)
	var nb := ZarekNiebla.new(); add_child(nb); nb.objetivo = cam
	var fl := SpotLight3D.new(); fl.light_color = Color(1, 0.9, 0.72); fl.light_energy = 6.0; fl.spot_range = 32.0; fl.spot_angle = 40.0
	fl.spot_angle_attenuation = 1.6; fl.shadow_enabled = true; cam.add_child(fl)
	var hr: Rect2 = m.house_rect
	var casa := Vector3(hr.get_center().x, 4.0, hr.get_center().y)
	var fu := m.cell_to_world("exterior", 44.0, 53.0)
	var pu := m.cell_to_world("exterior", 31.0, 83.0)
	var vistas := [[fu + Vector3(-7.5, 1.7, 5.0), fu + Vector3(0, 1.8, 0)], [fu + Vector3(-2.2, 1.6, 2.6), fu + Vector3(0, 1.0, 0)],
		[pu + Vector3(-9.0, 1.7, -4.0), pu + Vector3(0, 0.4, 0)], [Vector3(hr.get_center().x - 9.0, 1.7, hr.end.y + 7.0), Vector3(hr.get_center().x - 4.0, 3.5, hr.end.y)]]
	if OS.get_environment("VISTAS") == "todo":
		var en := m.cell_to_world("exterior", 44.0, 42.0)
		vistas = [[en + Vector3(-1.5, 1.7, 8.0), en + Vector3(0, 2.3, 0)], [en + Vector3(0.8, 1.7, 3.2), en + Vector3(0, 1.8, 0)],
			[pu + Vector3(-7.0, 1.7, -3.5), pu + Vector3(0, -0.3, 0.5)], [pu + Vector3(-20.0, 1.7, -9.0), pu + Vector3(-20.0, 0.0, -6.0)]]
	if OS.get_environment("VISTAS") == "bordes":
		var F: Rect2 = m.bosque_rect
		var cxx := F.get_center().x + 20.0
		vistas = [[Vector3(cxx, 1.7, F.position.y + 9.0), Vector3(cxx, 8.0, F.position.y - 10.0)],
			[Vector3(F.end.x - 8.0, 1.7, F.get_center().y), Vector3(F.end.x + 10.0, 6.0, F.get_center().y + 4.0)],
			[Vector3(cxx, 1.7, F.end.y - 2.0), Vector3(cxx, -10.0, F.end.y + 12.0)],
			[Vector3(F.position.x + 8.0, 1.7, F.get_center().y + 30.0), Vector3(F.position.x - 10.0, 6.0, F.get_center().y + 26.0)]]
	if OS.get_environment("VISTAS") == "agua":
		vistas = [[pu + Vector3(-7.0, 1.7, -3.5), pu + Vector3(0, -0.3, 0.5)], [pu + Vector3(-14.0, 1.6, 1.5), pu + Vector3(-5.0, -0.4, 0.3)], [fu + Vector3(-2.2, 1.7, 2.6), fu + Vector3(0, 0.6, 0)]]
	if OS.get_environment("VISTAS") == "fachada":
		vistas = [[Vector3(hr.get_center().x - 2.0, 1.7, hr.end.y + 24.0), Vector3(hr.get_center().x, 5.5, hr.end.y)],
			[Vector3(hr.position.x - 9.0, 1.7, hr.end.y + 11.0), Vector3(hr.position.x + 6.0, 4.5, hr.end.y - 2.0)],
			[Vector3(hr.get_center().x + 6.0, 1.7, hr.end.y + 5.5), Vector3(hr.get_center().x + 6.0, 3.0, hr.end.y)]]
	if OS.get_environment("VISTAS") == "rio":
		vistas = [[pu + Vector3(-9.0, 1.7, -4.0), pu + Vector3(0, -0.2, 0)], [pu + Vector3(-14.0, 1.7, 1.0), pu + Vector3(-4.0, -0.4, 0.5)], [Vector3(hr.get_center().x - 9.0, 1.7, hr.end.y + 7.0), Vector3(hr.get_center().x - 4.0, 3.5, hr.end.y)]]
	if OS.get_environment("VISTAS") == "viejas":
		var s0: Vector3 = m.start_pos
		vistas = [[s0 + Vector3(0, 1.65, 0), casa], [s0 + Vector3(-6, 1.65, -10), s0 + Vector3(-20, 1.0, -25)]]
	var i := 0
	for v in vistas:
		cam.position = v[0]
		cam.look_at(v[1])
		fl.visible = true
		for k in 8: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/ext_%d.jpg" % [out, i], 0.9)
		i += 1
	print("EXTERIOR OK")
	get_tree().quit()
