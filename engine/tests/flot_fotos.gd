extends Node
## Fotos de cerca de sitios sospechosos (tablones, mesa del matadero, celda...) para revisar a ojo.
var g: ZarekJuego
func _ready() -> void:
	g = load("res://zarek/zarek.tscn").instantiate()
	g.set_meta("diag", true)
	add_child(g)
	var t0 := Time.get_ticks_msec()
	while (g.mansion == null or not g.mansion.nav_ready) and Time.get_ticks_msec() - t0 < 300000:
		await get_tree().process_frame
	while g.title_box and not g.title_box.visible:
		await get_tree().process_frame
	while g.elena == null or g.player == null:
		await get_tree().process_frame
	g._jugar(1)
	while g.state == "intro":
		g._saltar_intro = true
		await get_tree().physics_frame
	for i in 40:
		await get_tree().physics_frame
	var m: ZarekMansion = g.mansion
	var puntos: Array = []
	var vistos_k := {}
	for pk in m.pickups:
		if OS.get_environment("SOLO") != "" and vistos_k.has(pk.kind):
			continue
		vistos_k[pk.kind] = true
		puntos.append(["pick_" + String(pk.kind), (pk.node as Node3D).global_position + Vector3(0, 0.6, 0)])
	var extra: String = OS.get_environment("PUNTOS")
	for t in extra.split(";", false):
		var v := t.split(",")
		puntos.append([v[0], Vector3(float(v[1]), float(v[2]), float(v[3]))])
	# celda de Sofía
	puntos.append(["jugadora", g.player.global_position + Vector3(0, 0.3, 0)])
	var cam := Camera3D.new()
	m.add_child(cam)
	cam.fov = 60
	var luz := OmniLight3D.new()
	luz.omni_range = 7.0
	luz.light_energy = 2.5
	m.add_child(luz)
	for cl in g.find_children("*", "CanvasLayer", true, false):
		(cl as CanvasLayer).visible = false
	if m.has_meta("mesa_matadero"):
		puntos.append(["mesa_matadero", (m.get_meta("mesa_matadero") as Vector3) + Vector3(0, 1.0, 0)])
	for k in puntos.size():
		var p: Vector3 = puntos[k][1]
		for lado in 2:
			var dir := Vector3(1.3, 0.9, 1.0) if lado == 0 else Vector3(-1.0, 1.1, -1.2)
			cam.global_position = p + dir.normalized() * 1.7
			cam.look_at(p, Vector3.UP)
			cam.make_current()
			luz.global_position = cam.global_position + Vector3(0, 0.4, 0)
			for f in 4:
				await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/ff/%02d_%s_%d.png" % [k, puntos[k][0], lado])
		print("FOTO ", k, " ", puntos[k][0], " ", p, " ", m.room_name(p))
	print("FOTOS OK")
	get_tree().quit()
