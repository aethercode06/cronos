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
	moon.rotation_degrees = Vector3(-38, 30, 0); moon.shadow_enabled = true; add_child(moon)
	var cl := CanvasLayer.new(); var cr := ColorRect.new(); cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	var pm := ShaderMaterial.new(); pm.shader = load("res://zarek/post.gdshader"); cr.material = pm; cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(cr); add_child(cl)
	m = ZarekMansion.new(); add_child(m); m.build(2)
	for l in m.lamps: m.set_lamp(l, true)
	var r: Dictionary = {}
	for q in m.rooms:
		if String(q.name).to_lower() == sala: r = q
	var rect: Rect2 = r.rect
	var y: float = r.y
	# para que el renderizado por software sea rápido: fuera todo lo que no esté cerca de la sala
	var cen := Vector3(rect.get_center().x, y + 2.0, rect.get_center().y)
	var quitar: Array[Node] = []
	var recortar := a.size() > 3 and a[3] == "1"
	for n in (m.find_children("*", "VisualInstance3D", true, false) if recortar else []):
		var vi := n as VisualInstance3D
		var aabb := vi.global_transform * vi.get_aabb()
		if aabb.grow(2.0).has_point(cen) or vi.global_position.distance_to(cen) < 14.0:
			continue
		if absf(vi.global_position.y - y) > 3.5 or vi.global_position.distance_to(cen) > 14.0:
			quitar.append(vi)
	for n in quitar:
		n.queue_free()
	var cam := Camera3D.new(); cam.fov = 70.0; add_child(cam)
	var fl := SpotLight3D.new(); fl.light_color = Color(1, 0.9, 0.72); fl.light_energy = 6.0; fl.spot_range = 32.0; fl.spot_angle = 40.0
	fl.spot_angle_attenuation = 1.6; fl.shadow_enabled = true; fl.shadow_bias = 0.08; fl.shadow_normal_bias = 2.0; fl.spot_attenuation = 0.8; fl.visible = linterna; cam.add_child(fl)
	var vistas := [[Vector2(0.5, 0.06), Vector2(0.25, 0.45)], [Vector2(0.94, 0.62), Vector2(0.1, 0.38)], [Vector2(0.5, 0.5), Vector2(0.8, 0.02)], [Vector2(0.55, 0.45), Vector2(0.3, 1.0)], [Vector2(0.2, 0.75), Vector2(0.0, 0.3)]]
	var i := 0
	for v in vistas:
		var p: Vector2 = rect.position + rect.size * v[0]
		var t: Vector2 = rect.position + rect.size * v[1]
		cam.position = Vector3(p.x, y + 1.65, p.y)
		cam.look_at(Vector3(t.x, y + 1.1, t.y))
		for k in 6: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/vista_%d.jpg" % [out, i], 0.9)
		i += 1
	# planta desde arriba para comprobar la colocación
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = rect.size.y + 1.0; cam.far = 3.4; cam.near = 0.05
	cam.position = Vector3(rect.get_center().x, y + 3.3, rect.get_center().y); cam.rotation = Vector3(-PI * 0.5, 0, 0)
	fl.visible = false; env.ambient_light_energy = 3.0; env.fog_enabled = false; cl.visible = false
	for k in 6: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_jpg("%s/planta.jpg" % out, 0.9)
	print("SALON OK")
	get_tree().quit()
