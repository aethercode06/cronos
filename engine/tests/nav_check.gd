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
		var c := Vector3(rc.get_center().x, float(r.y), rc.get_center().y)
		var p := m.path(g.respawn_pos, c)
		var fin: Vector3 = p[p.size() - 1] if p.size() > 0 else g.respawn_pos
		if fin.distance_to(c) > 4.0:
			malas.append("%s (nivel %d, se queda a %.0f m)" % [r.name, r.level, fin.distance_to(c)])
	print("NAV salas sin camino: %d de %d" % [malas.size(), m.rooms.size()])
	for x in malas:
		print("NAV   " + x)
	print("NAV portales: %d" % m.portals.size())
	for pt in m.portals:
		print("NAV   paso %s: %s -> %s" % [pt.text, m.room_name(pt.pos), m.room_name(pt.to)])
	get_tree().quit()
