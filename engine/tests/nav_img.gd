extends Node
## Vuelca los polígonos de la navmesh, las salas, puertas y muebles con choque a /tmp/navpoly.json (para dibujarlo).
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
	var nm: NavigationMesh = m.nav_region.navigation_mesh
	var verts := nm.get_vertices()
	var polys: Array = []
	for i in nm.get_polygon_count():
		var pl: Array = []
		for idx in nm.get_polygon(i):
			var v: Vector3 = verts[idx]
			pl.append([v.x, v.y, v.z])
		polys.append(pl)
	var salas: Array = []
	for r in m.rooms:
		var rc: Rect2 = r.rect
		salas.append({"n": r.name, "l": r.level, "y": r.y, "r": [rc.position.x, rc.position.y, rc.size.x, rc.size.y]})
	var puertas: Array = []
	for d in m.doors:
		puertas.append({"p": [d.pos.x, d.pos.y, d.pos.z], "h": d.get("horiz", true), "l": d.get("level", 0)})
	var gat: Array = []
	for gg in m.gateras:
		gat.append({"p": [gg.pos.x, gg.pos.y, gg.pos.z], "h": gg.horiz, "l": gg.level})
	var cajas: Array = []
	for b in m.find_children("*", "CollisionShape3D", true, false):
		var cs := b as CollisionShape3D
		if cs.disabled or not (cs.shape is BoxShape3D):
			continue
		var co := cs.get_parent() as CollisionObject3D
		if co == null or (co.collision_layer & 1) == 0:
			continue
		var sz: Vector3 = (cs.shape as BoxShape3D).size
		if sz.y < 0.4 or (sz.x > 2.6 or sz.z > 2.6) and sz.y > 2.5:
			continue
		var ab := cs.global_transform * AABB(-sz * 0.5, sz)
		cajas.append([ab.position.x, ab.position.y, ab.position.z, ab.size.x, ab.size.y, ab.size.z])
	var f := FileAccess.open("/tmp/navpoly.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"polys": polys, "salas": salas, "puertas": puertas, "gateras": gat, "cajas": cajas, "inicio": [g.respawn_pos.x, g.respawn_pos.y, g.respawn_pos.z]}))
	f.close()
	print("NAVIMG OK ", polys.size())
	get_tree().quit()
