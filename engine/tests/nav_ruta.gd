extends Node
## Rutas de la navegación entre pares de puntos: PARES="x,y,z>x,y,z;..."
func _ready() -> void:
	var g: ZarekJuego = load("res://zarek/zarek.tscn").instantiate()
	g.autotest = true
	add_child(g)
	var t0 := Time.get_ticks_msec()
	while (g.mansion == null or g.player == null or not g.mansion.nav_ready) and Time.get_ticks_msec() - t0 < 240000:
		await get_tree().process_frame
	for k in 10:
		await get_tree().physics_frame
	var m := g.mansion
	var map := m.get_world_3d().navigation_map
	for par in OS.get_environment("PARES").split(";", false):
		var ab := par.split(">")
		var v := []
		for t in ab:
			if t == "INICIO":
				v.append(g.respawn_pos)
				continue
			var c := t.split(",")
			v.append(Vector3(float(c[0]), float(c[1]), float(c[2])))
		var pa := NavigationServer3D.map_get_closest_point(map, v[0])
		var pb := NavigationServer3D.map_get_closest_point(map, v[1])
		var r := NavigationServer3D.map_get_path(map, pa, pb, true)
		var txt := ""
		for q in r:
			txt += str(q.snapped(Vector3(0.1, 0.1, 0.1))) + " "
		print("RUTA %s -> %s | cerca %s %s | %s" % [v[0], v[1], pa.snapped(Vector3(0.1,0.1,0.1)), pb.snapped(Vector3(0.1,0.1,0.1)), txt])
	get_tree().quit()
