extends Node3D
## Antes y después de la luz precalculada en el salón: godot --path . res://tests/luz/comparar.tscn -- <carpeta>
func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp"
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.38, 0.34)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.35
	env.tonemap_white = 6.0
	we.environment = env
	add_child(we)
	var sala: Node3D = load("res://tests/luz/salon.scn").instantiate()
	add_child(sala)
	var cam := Camera3D.new()
	cam.fov = 70.0
	add_child(cam)
	var vistas := [[Vector3(85.0, 1.6, 85.0), Vector3(91.0, 1.0, 90.0)], [Vector3(95.2, 1.6, 92.8), Vector3(88.0, 1.2, 86.0)]]
	for modo in ["antes", "despues"]:
		var lm: LightmapGI = sala.get_node("LightmapGI")
		lm.visible = modo == "despues"
		for l in sala.get_children():
			if l is Light3D:
				l.light_bake_mode = Light3D.BAKE_STATIC if modo == "despues" else Light3D.BAKE_DYNAMIC
				l.visible = true
		# con luz precalculada, el ambiente plano ya no hace falta (la luz rebota de verdad)
		env.ambient_light_energy = 0.32 if modo == "antes" else 0.12
		for i in vistas.size():
			cam.look_at_from_position(vistas[i][0], vistas[i][1])
			for k in 8:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_jpg("%s/salon_%s_%d.jpg" % [out, modo, i], 0.9)
	print("COMPARAR OK")
	get_tree().quit()
