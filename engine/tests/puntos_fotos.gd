extends Node
## Fotos desde un punto mirando a otro: FOTOS="nombre,cx,cy,cz,lx,ly,lz;..." (coordenadas del mundo). Salida en /tmp/pf.
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
	g.elena.visible = false
	var cam := Camera3D.new()
	m.add_child(cam)
	cam.fov = 70
	var luz := OmniLight3D.new()
	luz.omni_range = 8.0
	luz.light_energy = 2.0
	m.add_child(luz)
	for cl in g.find_children("*", "CanvasLayer", true, false):
		(cl as CanvasLayer).visible = false
	DirAccess.make_dir_recursive_absolute("/tmp/pf")
	for t in OS.get_environment("FOTOS").split(";", false):
		var v := t.split(",")
		cam.global_position = Vector3(float(v[1]), float(v[2]), float(v[3]))
		cam.look_at(Vector3(float(v[4]), float(v[5]), float(v[6])), Vector3.UP)
		cam.make_current()
		luz.global_position = cam.global_position + Vector3(0, 0.3, 0)
		for f in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/pf/%s.png" % v[0])
		print("FOTO ", v[0])
	print("FOTOS OK")
	get_tree().quit()
