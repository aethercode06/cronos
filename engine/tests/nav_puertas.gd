extends Node
## Para cada puerta y gatera: ¿se puede ir de un lado al otro por la navmesh? Si no, qué cuerpos hay al lado.
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
	var space := m.get_world_3d().direct_space_state
	var malas := 0
	for d in m.doors:
		var c: Vector3 = d.pos
		var n := Vector3(0, 0, 1) if d.get("horiz", true) else Vector3(1, 0, 0)
		var a := c + n * 1.0
		var b := c - n * 1.0
		var pa := NavigationServer3D.map_get_closest_point(map, a)
		var pb := NavigationServer3D.map_get_closest_point(map, b)
		var ruta := NavigationServer3D.map_get_path(map, pa, pb, true)
		var largo := 0.0
		for i in range(1, ruta.size()):
			largo += ruta[i - 1].distance_to(ruta[i])
		var ok := ruta.size() > 0 and ruta[ruta.size() - 1].distance_to(pb) < 0.5 and largo < 6.0 and pa.distance_to(a) < 1.0 and pb.distance_to(b) < 1.0
		if ok:
			continue
		malas += 1
		var salas := []
		for id in d.get("ids", []):
			salas.append(m.rooms[id].name)
		var cerca := []
		var q := PhysicsShapeQueryParameters3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(2.6, 1.2, 2.6)
		q.shape = bx
		q.transform = Transform3D(Basis.IDENTITY, c + Vector3(0, 0.8, 0))
		q.collision_mask = 1
		for hit in space.intersect_shape(q, 12):
			var o: Node = hit.collider
			var nombre := String(o.name)
			var p0 := o.get_parent()
			if p0:
				nombre = String(p0.name) + "/" + nombre
				if p0.get_parent():
					nombre = String(p0.get_parent().name) + "/" + nombre
			cerca.append(nombre)
		print("PUERTA MAL %s  (lados a %.1f/%.1f, ruta %.1f m)  cerca: %s" % [" / ".join(salas), pa.distance_to(a), pb.distance_to(b), largo, ", ".join(cerca)])
	print("PUERTAS MAL: %d de %d" % [malas, m.doors.size()])
	get_tree().quit()
