extends Node
## Auditoría de objetos flotando: para cada objeto suelto de la casa (no paredes ni suelos) mira si su base toca algo
## (suelo, mueble, estante) con rayos hacia abajo desde varios puntos de su base. Ignora lo que cuelga del techo o
## de la pared (lámparas, cuadros, cortinas, calcomanías). Imprime «FLOTA <nombre> sala=<sala> hueco=<m>».
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
	g._jugar(1)
	while g.state == "intro":
		g._saltar_intro = true
		await get_tree().physics_frame
	for i in 30:
		await get_tree().physics_frame  # que caigan los objetos con física
	var m: ZarekMansion = g.mansion
	var esp := m.get_world_3d().direct_space_state
	var raices: Array = []
	for padre in [m._house, m]:
		for c in padre.get_children():
			if c is Node3D and c != m._house:
				raices.append(c)
	# cajas de todas las mallas (los muebles decorativos no tienen colisión)
	var cajas: Array[AABB] = []
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var gm := mi as MeshInstance3D
		if gm.mesh != null and gm.is_visible_in_tree():
			cajas.append(gm.global_transform * gm.get_aabb())
	var flotan := 0
	var vistos := 0
	var por_tipo := {}
	for r in raices:
		var n := r as Node3D
		if not n.is_visible_in_tree():
			continue
		var mallas := n.find_children("*", "MeshInstance3D", true, false)
		if n is MeshInstance3D:
			mallas.append(n)
		if mallas.is_empty() or mallas.size() > 60:
			continue
		var caja := AABB()
		var primera := true
		for mi in mallas:
			var gi := mi as MeshInstance3D
			if gi.mesh == null:
				continue
			var b: AABB = gi.global_transform * gi.get_aabb()
			caja = b if primera else caja.merge(b)
			primera = false
		if primera:
			continue
		# fuera: muros, suelos, techos y cosas enormes; también lo plano y vertical (calcomanías, cuadros)
		if caja.size.x > 2.6 or caja.size.z > 2.6 or caja.size.y > 3.2:
			continue
		if minf(caja.size.x, caja.size.z) < 0.012:
			continue
		var abajo := caja.position.y
		var lv := m.level_of(caja.get_center().y)
		var techo: float = float(m.lvl_y(lv)) + 3.0 if lv > -9 else abajo + 3.0
		if caja.end.y > techo - 0.35:
			continue  # cuelga del techo
		vistos += 1
		var c := caja.get_center()
		var hx := caja.size.x * 0.35
		var hz := caja.size.z * 0.35
		var mejor := 99.0
		for o in [Vector2.ZERO, Vector2(hx, hz), Vector2(-hx, hz), Vector2(hx, -hz), Vector2(-hx, -hz)]:
			var desde := Vector3(c.x + o.x, abajo + 0.12, c.z + o.y)
			var q := PhysicsRayQueryParameters3D.create(desde, desde - Vector3(0, 3.0, 0), 1 | 8)
			var excl: Array[RID] = []
			for co in n.find_children("*", "CollisionObject3D", true, false):
				excl.append((co as CollisionObject3D).get_rid())
			if n is CollisionObject3D:
				excl.append((n as CollisionObject3D).get_rid())
			q.exclude = excl
			var h := esp.intersect_ray(q)
			if h.has("position"):
				mejor = minf(mejor, maxf(0.0, abajo - (h.position as Vector3).y))
			# ¿toca una pared de lado? (cuadros, perchas, estantes de pared)
		var pared := false
		for dir in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
			var q2 := PhysicsRayQueryParameters3D.create(c, c + dir * (absf(dir.x) * caja.size.x + absf(dir.z) * caja.size.z) * 0.5 + dir * 0.06, 1)
			if not esp.intersect_ray(q2).is_empty():
				pared = true
		if mejor > 0.06:
			# ¿apoyado en un mueble sin colisión? una malla cuya parte de arriba está justo debajo
			for b2 in cajas:
				if b2.end.y <= abajo + 0.04 and b2.end.y >= abajo - 0.08 and b2.size.y > 0.03 \
						and c.x > b2.position.x and c.x < b2.end.x and c.z > b2.position.z and c.z < b2.end.z:
					mejor = 0.0
					break
		if mejor > 0.06 and not (pared and mejor < 2.0):
			flotan += 1
			var nombre: String = n.name if n.scene_file_path == "" else n.scene_file_path.get_file()
			if n.scene_file_path == "" and mallas.size() > 0:
				var sub: Node = mallas[0]
				nombre = "%s/%s" % [n.name, sub.owner.scene_file_path.get_file() if sub.owner and sub.owner.scene_file_path != "" else sub.name]
			print("FLOTA %s sala=%s hueco=%.2f tam=%s pos=%.2f,%.2f,%.2f" % [nombre, m.room_name(c), mejor, caja.size.snapped(Vector3(0.01, 0.01, 0.01)), c.x, c.y, c.z])
			var tipo := String(nombre).get_slice("/", 0)
			por_tipo[tipo] = int(por_tipo.get(tipo, 0)) + 1
	print("FLOTANTES %d de %d revisados" % [flotan, vistos])
	# objetos con física: ¿por debajo del suelo de su sala?
	var bajo := 0
	for rb in m.find_children("*", "RigidBody3D", true, false):
		var b := rb as RigidBody3D
		var id := m.room_at(b.global_position + Vector3(0, 0.5, 0))
		var id2 := m.room_at(b.global_position + Vector3(0, 3.5, 0))
		if id < 0 and id2 >= 0:
			bajo += 1
			if bajo < 15:
				print("BAJO_SUELO %s y=%.2f suelo=%.2f sala=%s" % [b.get_child(0).scene_file_path.get_file() if b.get_child_count() > 0 else b.name, b.global_position.y, float(m.rooms[id2].y), m.rooms[id2].name])
	print("BAJO_SUELO total ", bajo, " de ", m.find_children("*", "RigidBody3D", true, false).size())
	get_tree().quit()
