extends Node
## Comprueba a qué salas llega la navegación (Damián y el bot) desde el vestíbulo.
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
	var malas := []
	for r in m.rooms:
		if r.type == "jardin":
			continue
		var rc: Rect2 = r.rect
		var c0 := Vector3(rc.get_center().x, float(r.y), rc.get_center().y)
		# el punto andable de la sala más cercano al centro (el centro puede tener un mueble)
		var c := NavigationServer3D.map_get_closest_point(m.get_world_3d().navigation_map, c0)
		if absf(c.y - c0.y) > 1.0 or not rc.grow(0.2).has_point(Vector2(c.x, c.z)):
			malas.append("%s (nivel %d): no hay suelo andable en la sala" % [r.name, r.level])
			continue
		var p := m.path(g.respawn_pos, c)
		var fin: Vector3 = p[p.size() - 1] if p.size() > 0 else g.respawn_pos
		if fin.distance_to(c) > 1.5:
			malas.append("%s (nivel %d, se queda a %.0f m) fin=%s en %s, objetivo %s" % [r.name, r.level, fin.distance_to(c), str(fin.snapped(Vector3(0.1,0.1,0.1))), m.room_name(fin + Vector3(0, 0.5, 0)), str(c.snapped(Vector3(0.1,0.1,0.1)))])
	print("NAV salas sin camino: %d de %d" % [malas.size(), m.rooms.size()])
	for x in malas:
		print("NAV   " + x)
	print("NAV portales: %d" % m.portals.size())
	for pt in m.portals:
		print("NAV   paso %s: %s -> %s" % [pt.text, m.room_name(pt.pos), m.room_name(pt.to)])
	get_tree().quit()
