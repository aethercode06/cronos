extends Node
## Fotos de salas enteras (desde una esquina, a la altura de los ojos) para revisar el amueblado.
var g: ZarekJuego
func _ready() -> void:
	g = load("res://zarek/zarek.tscn").instantiate()
	g.autotest = true
	add_child(g)
	while g.mansion == null or not g.mansion.nav_ready or g.elena == null or g.player == null:
		await get_tree().process_frame
	for i in 30:
		await get_tree().physics_frame
	var m: ZarekMansion = g.mansion
	g.elena.visible = false
	for cl in g.find_children("*", "CanvasLayer", true, false):
		(cl as CanvasLayer).visible = false
	var cam := Camera3D.new()
	m.add_child(cam)
	cam.fov = 75
	var luz := OmniLight3D.new()
	luz.omni_range = 12.0
	luz.light_energy = 1.6
	luz.shadow_enabled = true
	m.add_child(luz)
	var nombres: PackedStringArray = OS.get_environment("SALAS").split(";", false)
	var salas: Array = []
	if OS.get_environment("TODAS") != "":
		var desde := int(OS.get_environment("DESDE")) if OS.get_environment("DESDE") != "" else 0
		for r in m.rooms:
			if int(r.level) >= 0 and String(r.type) != "jardin" and int(r.id) >= desde and (nombres.is_empty() or String(r.name) in nombres):
				salas.append(r)
	else:
		for nm in nombres:
			var r0 := m._sala_por_nombre(nm)
			if not r0.is_empty():
				salas.append(r0)
	var carpeta := OS.get_environment("CARPETA") if OS.get_environment("CARPETA") != "" else "/tmp/salas"
	for k in salas.size():
		var r: Dictionary = salas[k]
		var rc: Rect2 = r.rect
		var y := float(r.y)
		if OS.get_environment("TODAS") != "":
			# una foto desde la puerta (lo que ves al entrar), mirando a la pared de enfrente
			var dp := Vector3.INF
			for d in m.doors:
				var q: Vector3 = d.pos
				if absf(q.y - y) < 1.0 and rc.grow(0.3).has_point(Vector2(q.x, q.z)):
					dp = q
					break
			if dp == Vector3.INF:
				dp = Vector3(rc.position.x + 0.3, y, rc.position.y + 0.3)
			var cen := Vector3(rc.get_center().x, y, rc.get_center().y)
			var dentro := (cen - dp)
			dentro.y = 0
			dentro = dentro.normalized()
			cam.global_position = dp + dentro * 0.95 + Vector3(0, 1.6, 0)
			var lejos := Vector3(clampf(dp.x + dentro.x * 30.0, rc.position.x + 0.3, rc.end.x - 0.3), y + 0.7, clampf(dp.z + dentro.z * 30.0, rc.position.y + 0.3, rc.end.y - 0.3))
			if lejos.distance_to(cam.global_position) < 1.0:
				lejos = cen + Vector3(0, 0.7, 0)
			cam.look_at(lejos, Vector3.UP)
			cam.make_current()
			luz.global_position = Vector3(rc.get_center().x, y + 2.6, rc.get_center().y)
			for f in 3:
				await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%03d.png" % [carpeta, int(r.id)])
			print("SALA_FOTO ", int(r.id), " ", r.name, " ", int(rc.size.x * rc.size.y), "m2")
			continue
		for esq in 2:
			var a := Vector3(rc.position.x + 0.5, y + 1.65, rc.position.y + 0.5) if esq == 0 else Vector3(rc.end.x - 0.5, y + 1.65, rc.end.y - 0.5)
			var b := Vector3(rc.end.x - 0.5, y + 0.6, rc.end.y - 0.5) if esq == 0 else Vector3(rc.position.x + 0.5, y + 0.6, rc.position.y + 0.5)
			cam.global_position = a
			cam.look_at(b, Vector3.UP)
			cam.make_current()
			luz.global_position = Vector3(rc.get_center().x, y + 2.6, rc.get_center().y)
			for f in 4:
				await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%02d_%d.png" % [carpeta, k, esq])
		print("SALA_FOTO ", k, " ", r.name)
	print("FOTOS OK")
	get_tree().quit()
