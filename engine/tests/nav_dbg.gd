extends Node
var g: ZarekJuego
func _ready() -> void:
	g = load("res://zarek/zarek.tscn").instantiate()
	g.set_meta("diag", true)
	g.autotest = OS.get_environment("AUTOTEST") != ""
	add_child(g)
	while g.mansion == null or not g.mansion.nav_ready or g.elena == null or g.player == null:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	var m: ZarekMansion = g.mansion
	var a: Vector3 = g.respawn_pos
	print("ANTES iter=", NavigationServer3D.map_get_iteration_id(m.get_world_3d().navigation_map))
	print("RESPAWN ", a, " sala=", m.room_name(a))
	for nombre in ["Vestíbulo y gran escalera", "Recibidor", "Guardarropa", "Galería del vestíbulo", "Pasillo principal", "Dormitorio de los padres"]:
		var r := m._sala_por_nombre(nombre)
		var c := Vector3((r.rect as Rect2).get_center().x, float(r.y), (r.rect as Rect2).get_center().y)
		var p := m.path(a, c)
		print("CAMINO a ", nombre, ": ", p.size(), " fin=", (p[p.size() - 1] if p.size() > 0 else Vector3.INF), " objetivo=", c)
	NavigationServer3D.map_force_update(m.get_world_3d().navigation_map)
	var malas := []
	for r in m.rooms:
		if String(r.type) in ["jardin", "agua", "roca", "tunel"] or int(r.level) < 0:
			continue
		var c := Vector3((r.rect as Rect2).get_center().x, float(r.y), (r.rect as Rect2).get_center().y)
		var p := m.path(a, c)
		if p.is_empty() or (p[p.size() - 1] as Vector3).distance_to(c) > 2.5:
			malas.append("%s(%s)" % [r.name, ("vacío" if p.is_empty() else "%.1f m" % (p[p.size() - 1] as Vector3).distance_to(c))])
	print("SIN_CAMINO ", malas.size(), " ", malas)
	var rh := m._sala_por_nombre("Cuarto del hermano")
	var ch := Vector3((rh.rect as Rect2).get_center().x, float(rh.y), (rh.rect as Rect2).get_center().y)
	print("HERMANO->VESTIDOR ", m.path(ch, Vector3(105.6, 4.2, 73.2)))
	print("INICIO->HERMANO ", m.path(a, ch))
	print("INICIO->VESTIDOR ", m.path(a, Vector3(105.6, 4.2, 73.2)))
	var pq := NavigationPathQueryParameters3D.new()
	pq.map = m.get_world_3d().navigation_map
	pq.start_position = a
	pq.target_position = Vector3(105.6, 4.2, 73.2)
	var res := NavigationPathQueryResult3D.new()
	NavigationServer3D.query_path(pq, res)
	print("CONSULTA max_pol=", pq.path_search_max_polygons, " dist=", pq.path_search_max_distance, " -> ", res.path.size(), " fin=", res.path[res.path.size() - 1] if res.path.size() > 0 else "")
	pq.path_search_max_polygons = 0
	NavigationServer3D.query_path(pq, res)
	print("CONSULTA sin limite -> ", res.path.size(), " fin=", res.path[res.path.size() - 1] if res.path.size() > 0 else "")
	print("HERMANO->PUERTA_NORTE ", m.path(ch, Vector3(104.4, 4.2, 74.0)))
	print("PUERTA->VESTIDOR ", m.path(Vector3(104.4, 4.2, 74.9), Vector3(104.4, 4.2, 73.5)))
	var esp2 := m.get_world_3d().direct_space_state
	for r in m.rooms:
		if not (String(r.name) in ["Vestidor del hermano", "Aseo de la institutriz", "Armario de la limpieza", "Habitación del mayordomo", "Cuarto de las criadas", "Biblioteca", "Sala de fumar y billar"]):
			continue
		var c := Vector3((r.rect as Rect2).get_center().x, float(r.y), (r.rect as Rect2).get_center().y)
		print("SALA ", r.name, " punto_nav=", NavigationServer3D.map_get_closest_point(m.get_world_3d().navigation_map, c + Vector3(0, 0.3, 0)), " centro=", c)
		for d in m.doors:
			var dp: Vector3 = d.pos
			if absf(dp.y - float(r.y)) > 1.0 or not (r.rect as Rect2).grow(0.3).has_point(Vector2(dp.x, dp.z)):
				continue
			var q := PhysicsShapeQueryParameters3D.new()
			var bx := BoxShape3D.new()
			bx.size = Vector3(1.6, 1.4, 1.6)
			q.shape = bx
			q.transform = Transform3D(Basis.IDENTITY, dp + Vector3(0, 0.9, 0))
			q.collision_mask = 1
			var cosas := []
			for h in esp2.intersect_shape(q, 24):
				var co: Node = h.collider
				var raiz := co
				while raiz.get_parent() != m._house and raiz.get_parent() != m and raiz.get_parent() != null:
					raiz = raiz.get_parent()
				var nom: String = raiz.scene_file_path.get_file()
				if nom == "":
					var mi := co.get_parent()
					nom = "%s(%s)" % [mi.name, str((mi as MeshInstance3D).mesh.get_aabb().size.snapped(Vector3.ONE * 0.01)) if mi is MeshInstance3D and (mi as MeshInstance3D).mesh else ""]
				cosas.append("%s@%s" % [nom, str((co as Node3D).global_position.snapped(Vector3.ONE * 0.1))])
			print("   puerta ", dp, " cerca: ", cosas)
			var mp := m.get_world_3d().navigation_map
			for off in [Vector3(0, 0, -0.7), Vector3(0, 0, 0), Vector3(0, 0, 0.7), Vector3(-0.7, 0, 0), Vector3(0.7, 0, 0)]:
				var q2: Vector3 = dp + off + Vector3(0, 0.3, 0)
				print("      nav cerca de ", off, ": ", NavigationServer3D.map_get_closest_point(mp, q2).snapped(Vector3.ONE * 0.01))
			var rayo := PhysicsRayQueryParameters3D.create(dp + Vector3(0, 0.5, -1.0), dp + Vector3(0, 0.5, 1.0), 1)
			var hr := esp2.intersect_ray(rayo)
			print("      rayo z: ", hr.get("position", "nada"), " ", (hr.get("collider") as Node).get_parent().name if hr.has("collider") else "")
			var rayo2 := PhysicsRayQueryParameters3D.create(dp + Vector3(-1.0, 0.5, 0), dp + Vector3(1.0, 0.5, 0), 1)
			var hr2 := esp2.intersect_ray(rayo2)
			print("      rayo x: ", hr2.get("position", "nada"), " ", (hr2.get("collider") as Node).get_parent().name if hr2.has("collider") else "")
	var rv := m._sala_por_nombre("Vestíbulo y gran escalera")
	var cv := Vector3((rv.rect as Rect2).get_center().x, float(rv.y), (rv.rect as Rect2).get_center().y)
	print("OTRA_VEZ ", m.path(a, cv).size(), " a=", a, " nav_ready=", m.nav_ready, " mapa=", m.get_world_3d().navigation_map, " iter=", NavigationServer3D.map_get_iteration_id(m.get_world_3d().navigation_map))
	var esp := m.get_world_3d().direct_space_state
	var cerca := NavigationServer3D.map_get_closest_point(m.get_world_3d().navigation_map, a)
	print("PUNTO_NAV_MAS_CERCANO ", cerca)
	var mapa := m.get_world_3d().navigation_map
	print("REGIONES ", NavigationServer3D.map_get_regions(mapa).size(), " enlaces=", NavigationServer3D.map_get_links(mapa).size(), " region_mapa=", m.nav_region.get_navigation_map(), " habilitada=", m.nav_region.enabled, " polis=", m.nav_region.navigation_mesh.get_polygon_count(), " en_arbol=", m.nav_region.is_inside_tree(), " activo=", NavigationServer3D.map_is_active(mapa))
	var q0 := PhysicsShapeQueryParameters3D.new()
	var sp0 := SphereShape3D.new()
	sp0.radius = 2.0
	q0.shape = sp0
	q0.transform = Transform3D(Basis.IDENTITY, a + Vector3(0, 0.5, 0))
	q0.collision_mask = 1
	for h in m.get_world_3d().direct_space_state.intersect_shape(q0, 32):
		var co: Node = h.collider
		var raiz := co
		while raiz.get_parent() != m._house and raiz.get_parent() != m and raiz.get_parent() != null:
			raiz = raiz.get_parent()
		print("   junto_respawn: ", co.get_class(), " ", raiz.name, " ", raiz.scene_file_path.get_file(), " ", (co as Node3D).global_position)
	for d in []:
		if (d.pos as Vector3).distance_to(a) < 8.0:
			print("PUERTA ", d.pos, " abierta=", d.open, " locked=", d.locked)
			var q := PhysicsShapeQueryParameters3D.new()
			var sp := SphereShape3D.new()
			sp.radius = 1.0
			q.shape = sp
			q.transform = Transform3D(Basis.IDENTITY, (d.pos as Vector3) + Vector3(0, 0.8, 0))
			q.collision_mask = 1 | 8
			for h in esp.intersect_shape(q, 16):
				var co: Node = h.collider
				var raiz := co
				while raiz.get_parent() != m._house and raiz.get_parent() != m and raiz.get_parent() != null:
					raiz = raiz.get_parent()
				print("   cerca: ", co.name, " / ", raiz.name, " ", raiz.scene_file_path.get_file(), " ", (co as Node3D).global_position)
	get_tree().quit()
