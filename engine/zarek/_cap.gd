extends Node3D
func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.3, 0.29, 0.33); env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.65; env.tonemap_white = 10.0
	env.glow_enabled = OS.get_environment("GLOW") != ""; env.glow_intensity = 0.8; env.glow_bloom = 0.06; env.glow_hdr_threshold = 0.9
	we.environment = env; add_child(we)
	var m := ZarekMansion.new(); add_child(m); m.build(1)
	for l in m.lamps: m.set_lamp(l, true)
	var cam := Camera3D.new(); add_child(cam); cam.current = true; cam.fov = 50; cam.near = 0.02
	var vistos := {}
	var i := 0
	for l in m.lamps:
		if l.broken or vistos.get(l.get("tipo", "otro"), 0) >= 2: continue
		vistos[l.get("tipo", "otro")] = vistos.get(l.get("tipo", "otro"), 0) + 1
		var c: Vector3 = (l.light as OmniLight3D).global_position
		var off := Vector3(0.9, -0.35, 0.9) if l.get("tipo", "") != "aplique" else (l.node as Node3D).global_basis.z * 1.1 + Vector3(0.3, -0.2, 0)
		cam.global_position = c + off; cam.look_at(c)
		for n in 4: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("/home/claude/cap/b%d.jpg" % i, 0.85); i += 1
		if i >= 6: break
	get_tree().quit()
