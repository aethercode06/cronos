extends Node3D
## Vista de calidad de una sala (renderizador móvil, misma luz que el juego).
## godot --rendering-method mobile --path . res://tests/salon.tscn -- <carpeta> <nombre de sala> [linterna 0/1]
var m: ZarekMansion
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var out := a[0] if a.size() > 0 else "/tmp"
	var sala := a[1].to_lower() if a.size() > 1 else "salón con chimenea"
	var linterna := a.size() > 2 and a[2] == "1"
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.38, 0.34); env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.35; env.tonemap_white = 6.0
	env.fog_enabled = true; env.fog_light_color = Color(0.07, 0.065, 0.07); env.fog_density = 0.016
	env.glow_enabled = true; env.glow_intensity = 0.8; env.glow_bloom = 0.06; env.glow_hdr_threshold = 0.9
	env.adjustment_enabled = true; env.adjustment_contrast = 1.06
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.02, 0.03, 0.06); sm.sky_horizon_color = Color(0.06, 0.07, 0.1); sky.sky_material = sm
	env.sky = sky; env.background_mode = Environment.BG_SKY
	we.environment = env; add_child(we)
	var moon := DirectionalLight3D.new(); moon.light_color = Color(0.55, 0.65, 0.95); moon.light_energy = 0.45
	moon.rotation_degrees = Vector3(-38, -55, 0); moon.shadow_enabled = true; add_child(moon)
	var cl := CanvasLayer.new(); var cr := ColorRect.new(); cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	var pm := ShaderMaterial.new(); pm.shader = load("res://zarek/post.gdshader"); cr.material = pm; cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(cr); add_child(cl)
	m = ZarekMansion.new(); add_child(m); m.build(2)
	for l in m.lamps: m.set_lamp(l, true)
	var cam := Camera3D.new(); cam.fov = 62.0; add_child(cam)
	var fl := SpotLight3D.new(); fl.light_color = Color(1, 0.9, 0.72); fl.light_energy = 5.0; fl.spot_range = 20.0; fl.spot_angle = 45.0
	fl.shadow_enabled = true; fl.shadow_bias = 0.05; cam.add_child(fl)
	var tomas: Array = []
	for q in m.rooms:
		var rp: Vector2 = q.rect.position
		var y: float = q.y
		if q.name == "Comedor formal":
			tomas.append(["comedor_1", Vector3(rp.x + 2.0, y + 1.55, rp.y + 2.9), Vector3(rp.x + 4.6, y + 0.8, rp.y + 4.5)])
			tomas.append(["comedor_2", Vector3(rp.x + 3.4, y + 1.25, rp.y + 3.7), Vector3(rp.x + 3.4, y + 0.85, rp.y + 4.1)])
		if String(q.name).begins_with("Ático"):
			tomas.append(["baul_1", Vector3(rp.x + 3.4 + 0.9, y + 1.5, rp.y + 12.2 + 0.9), Vector3(rp.x + 3.4, y + 0.3, rp.y + 12.2)])
			tomas.append(["baul_2", Vector3(rp.x + 27.6 + 0.2, y + 1.5, rp.y + 3.0 + 1.2), Vector3(rp.x + 27.6, y + 0.3, rp.y + 3.0)])
	for k in 2:
		var wd: Dictionary = m.wardrobes[k * 5]
		var ins: Vector3 = wd.inside
		var yaw: float = wd.yaw
		var f := Vector3(0, 0, -1).rotated(Vector3.UP, yaw)
		var izq := Vector3(-1, 0, 0).rotated(Vector3.UP, yaw)
		tomas.append(["armario_%d_izq" % k, ins + Vector3(0, 1.55, 0), ins + Vector3(0, 1.3, 0) + izq])
		tomas.append(["armario_%d_der" % k, ins + Vector3(0, 1.55, 0), ins + Vector3(0, 1.3, 0) - izq])
		tomas.append(["armario_%d_arriba" % k, ins + Vector3(0, 1.55, 0) + f * 0.15, ins + Vector3(0, 2.4, 0) - f * 0.3])
	for t in tomas:
		cam.position = t[1]
		cam.near = 0.03
		cam.look_at(t[2])
		for k in 6: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/%s.jpg" % [out, t[0]], 0.9)
	print("DETALLE OK")
	get_tree().quit()
