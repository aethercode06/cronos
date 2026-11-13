extends Node3D
## Vistas del exterior (bosque y fachada) con la luz del juego: godot --path . res://tests/exterior.tscn -- <carpeta>
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var out := a[0] if a.size() > 0 else "/tmp"
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.38, 0.34); env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.35; env.tonemap_white = 6.0
	env.fog_enabled = true; env.fog_light_color = Color(0.07, 0.065, 0.07); env.fog_density = 0.016
	env.glow_enabled = true; env.glow_intensity = 0.8; env.glow_bloom = 0.06; env.glow_hdr_threshold = 0.9
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.02, 0.03, 0.06); sm.sky_horizon_color = Color(0.06, 0.07, 0.1); sky.sky_material = sm
	env.sky = sky; env.background_mode = Environment.BG_SKY
	we.environment = env; add_child(we)
	var moon := DirectionalLight3D.new(); moon.light_color = Color(0.55, 0.65, 0.95); moon.light_energy = 0.45
	moon.rotation_degrees = Vector3(-38, 30, 0); moon.shadow_enabled = true; moon.directional_shadow_max_distance = 60.0; add_child(moon)
	var cl := CanvasLayer.new(); var cr := ColorRect.new(); cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	var pm := ShaderMaterial.new(); pm.shader = load("res://zarek/post.gdshader"); cr.material = pm; cl.add_child(cr); add_child(cl)
	var m := ZarekMansion.new(); add_child(m); m.build(2)
	var cam := Camera3D.new(); cam.fov = 70.0; cam.far = 300.0; add_child(cam)
	var fl := SpotLight3D.new(); fl.light_color = Color(1, 0.9, 0.72); fl.light_energy = 6.0; fl.spot_range = 32.0; fl.spot_angle = 40.0
	fl.spot_angle_attenuation = 1.6; fl.shadow_enabled = true; cam.add_child(fl)
	var hr: Rect2 = m.house_rect
	var casa := Vector3(hr.get_center().x, 4.0, hr.get_center().y)
	var s: Vector3 = m.start_pos
	var vistas := [[s + Vector3(0, 1.65, 0), casa], [s + Vector3(-6, 1.65, -10), s + Vector3(-20, 1.0, -25)],
		[Vector3(hr.position.x - 14, 1.65, hr.end.y + 12), casa], [Vector3(hr.end.x + 20, 1.65, hr.get_center().y), Vector3(hr.end.x + 40, 3.0, hr.get_center().y - 15)]]
	var i := 0
	for v in vistas:
		cam.position = v[0]
		cam.look_at(v[1])
		fl.visible = i % 2 == 1
		for k in 8: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/ext_%d.jpg" % [out, i], 0.9)
		i += 1
	print("EXTERIOR OK")
	get_tree().quit()
