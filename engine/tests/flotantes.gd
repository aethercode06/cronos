extends Node3D
## Busca objetos que flotan (sin nada debajo) y cuadros separados de la pared.
var m: ZarekMansion
func _aabb(n: Node3D) -> AABB:
	var ab := AABB()
	var primero := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		ab = b if primero else ab.merge(b)
		primero = false
	return ab

func _ready() -> void:
	m = ZarekMansion.new(); add_child(m); m.build(1)
	for i in 4: await get_tree().physics_frame
	if OS.get_environment("ASENTAR") != "":
		m.asentar()
		for i in 4: await get_tree().physics_frame
	var esp := get_world_3d().direct_space_state
	var colgados := m.COLGADOS.duplicate() + ["chandelier", "lamp", "lantern", "curtain", "cortina", "frame", "picture", "mirror", "head", "clock", "towel", "hanger", "rail", "cobweb", "shelf", "shelves", "percha", "crucifix", "sconce", "bell", "cage", "ropa_", "hanging", "wall"]
	var flotan := []
	var cuadros := []
	var hr: Rect2 = m.house_rect.grow(1.0)
	for c in m.find_children("*", "Node3D", true, false):
		var n := c as Node3D
		var es_glb := n.scene_file_path != ""
		var es_rb := n is RigidBody3D
		if not (es_glb or es_rb): continue
		if es_glb and n.get_parent() is RigidBody3D: continue
		if not hr.has_point(Vector2(n.global_position.x, n.global_position.z)): continue
		var nombre := (n.scene_file_path.get_file().get_basename() if es_glb else (n.get_child(0).scene_file_path.get_file().get_basename() if n.get_child_count() > 0 and n.get_child(0).scene_file_path != "" else String(n.name)))
		var ab := _aabb(n)
		if ab.size == Vector3.ZERO: continue
		var colgado := false
		for k in colgados:
			if nombre.to_lower().contains(k): colgado = true
		var ex: Array[RID] = []
		for co in n.find_children("*", "CollisionObject3D", true, false): ex.append((co as CollisionObject3D).get_rid())
		if es_rb: ex.append((n as RigidBody3D).get_rid())
		if colgado:
			if nombre.contains("frame") or nombre.contains("picture") or nombre.contains("mirror"):
				# detrás del cuadro tiene que haber pared a menos de 6 cm
				var centro := ab.get_center()
				var mejor := 9.0
				for d in [Vector3(1,0,0), Vector3(-1,0,0), Vector3(0,0,1), Vector3(0,0,-1)]:
					var q := PhysicsRayQueryParameters3D.create(centro, centro + d * 0.6)
					q.exclude = ex
					var h := esp.intersect_ray(q)
					if h: mejor = minf(mejor, centro.distance_to(h.position))
				var grosor := minf(ab.size.x, ab.size.z) * 0.5
				if mejor - grosor > 0.06: cuadros.append([nombre, ab.get_center().snapped(Vector3.ONE * 0.01), snappedf(mejor - grosor, 0.01)])
			continue
		# debajo del objeto tiene que haber algo (suelo, mueble) a menos de 4 cm
		var apoyos := 0
		var puntos := [ab.get_center(), ab.position + Vector3(ab.size.x * 0.3, 0, ab.size.z * 0.3) , ab.position + Vector3(ab.size.x * 0.7, 0, ab.size.z * 0.7)]
		var hueco := 9.0
		for pt in puntos:
			var desde := Vector3(pt.x, ab.position.y + 0.05, pt.z)
			var q := PhysicsRayQueryParameters3D.create(desde, desde - Vector3(0, 1.5, 0))
			q.exclude = ex
			var h := esp.intersect_ray(q)
			if h: hueco = minf(hueco, ab.position.y - h.position.y)
		if hueco > 0.05: flotan.append([nombre, ab.get_center().snapped(Vector3.ONE * 0.01), snappedf(hueco, 0.01), "RB" if es_rb else ""])
	print("FLOTAN ", flotan.size())
	for f in flotan: print("FLOTA ", f)
	print("CUADROS SEPARADOS ", cuadros.size())
	for f in cuadros: print("CUADRO ", f)
	get_tree().quit()
