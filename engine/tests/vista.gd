extends Node3D
## Capturas de puntos concretos de la casa con la luz del juego (lámparas encendidas y linterna).
## VISTAS=caracol|camas|... godot --path . res://tests/vista.tscn -- <carpeta>
var m: ZarekMansion
func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp"
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.42, 0.38, 0.34); env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.35; env.tonemap_white = 6.0
	we.environment = env; add_child(we)
	m = ZarekMansion.new(); add_child(m); m.build(1)
	for k in 3: await get_tree().physics_frame
	m.asentar()
	for l in m.lamps: m.set_lamp(l, true)
	var cam := Camera3D.new(); cam.fov = 75.0; add_child(cam)
	var fl := SpotLight3D.new(); fl.light_color = Color(1, 0.9, 0.72); fl.light_energy = 5.0; fl.spot_range = 20.0; fl.spot_angle = 40.0; fl.shadow_enabled = true; cam.add_child(fl)
	var vistas: Array = []
	var modo := OS.get_environment("VISTAS")
	if modo == "caracol":
		for c in m.CARACOLES:
			var p := m._caracol_centro(c)
			var ya := m.lvl_y(int(m.plan[c[3]].nivel))
			for nivel_y in [p.y, ya]:
				var sala := m.room_at(Vector3(p.x, nivel_y + 0.5, p.z))
				var cr: Vector2 = (m.rooms[sala].rect as Rect2).get_center() if sala >= 0 else Vector2(p.x + 3, p.z + 3)
				var desde := Vector3(cr.x, nivel_y + 1.6, cr.y)
				if desde.distance_to(Vector3(p.x, desde.y, p.z)) < 2.5:
					desde += (desde - Vector3(p.x, desde.y, p.z)).normalized() * 2.5
				vistas.append([desde, Vector3(p.x, nivel_y + (2.4 if nivel_y == p.y else -0.3), p.z)])
				print("SALA ", m.rooms[sala].name if sala >= 0 else "?", " ", p)
	elif modo == "camas":
		var n := 0
		for c in m.find_children("*", "Node3D", true, false):
			if c.scene_file_path.ends_with("old_bed_frame.glb") and n < 4:
				var p: Vector3 = c.global_position
				var f: Vector3 = c.global_transform.basis.z
				vistas.append([p + f * 1.9 + c.global_transform.basis.x * 1.2 + Vector3(0, 1.5, 0), p + Vector3(0, 0.5, 0)])
				n += 1
	elif modo == "puertas":
		var n := 0
		for d in m.doors:
			if n >= 4 or not d.has("pivot2") and d.get("pivot") == null: continue
			var piv: Node3D = d.pivot
			piv.rotation.y = d.base
			var mano: Vector3 = piv.global_transform * Vector3(1.395, 0.98, 0.0)
			var fuera: Vector3 = piv.global_transform.basis.z.normalized()
			vistas.append([mano + fuera * 0.45 + Vector3(-0.0, 0.08, 0), mano])
			n += 1
	elif modo == "salas":
		# desde una esquina de cada sala nombrada, mirando al centro (SALAS="A;B;C")
		for nombre in OS.get_environment("SALAS").split(";"):
			for r in m.rooms:
				if String(r.name) == nombre:
					var rc: Rect2 = r.rect
					var c := rc.get_center()
					var desde := Vector3(rc.position.x + 0.7, float(r.y) + 1.7, rc.end.y - 0.7)
					vistas.append([desde, Vector3(c.x + rc.size.x * 0.15, float(r.y) + 0.9, c.y - rc.size.y * 0.15)])
					print("SALA ", nombre)
					break
	elif modo == "pos":
		for t in OS.get_environment("POS").split(";"):
			var v := t.split(",")
			vistas.append([Vector3(float(v[0]), float(v[1]), float(v[2])), Vector3(float(v[3]), float(v[4]), float(v[5]))])
	for i in vistas.size():
		cam.look_at_from_position(vistas[i][0], vistas[i][1])
		for k in 6: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/v_%d.jpg" % [out, i], 0.88)
	print("VISTA OK ", vistas.size())
	get_tree().quit()
