extends Node
var g: ZarekJuego
func _ready() -> void:
	g = load("res://zarek/zarek.tscn").instantiate()
	g.set_meta("diag", true)
	add_child(g)
	while g.mansion == null or not g.mansion.nav_ready or g.elena == null or g.player == null:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	for pk in []:
		var n := pk.node as Node3D
		var it := pk.item as Node3D
		var s := "PICK %s taken=%s vis=%s n=%s" % [pk.kind, pk.taken, n.visible, n.global_position.snapped(Vector3.ONE * 0.01)]
		if it:
			s += " item=%s vis=%s" % [it.global_position.snapped(Vector3.ONE * 0.01), it.is_visible_in_tree()]
			for mi in it.find_children("*", "MeshInstance3D", true, false):
				s += " malla=%s" % (mi as MeshInstance3D).global_position.snapped(Vector3.ONE * 0.01)
				break
		print(s)
	var m: ZarekMansion = g.mansion
	var cajas := []
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var gm := mi as MeshInstance3D
		if gm.mesh != null and gm.is_visible_in_tree():
			cajas.append([gm.global_transform * gm.get_aabb(), gm])
	for cb in cajas:
		var ab: AABB = cb[0]
		var c2 := ab.get_center()
		if Vector2(c2.x - 86.7, c2.z - 79.0).length() > 3.0 or c2.y < -1.0 or c2.y > 3.0:
			continue
		if ab.position.y < 0.12 or ab.position.y > 1.5 or ab.size.y > 1.6:
			continue
		var apoyo := ""
		for cc in cajas:
			var b2: AABB = cc[0]
			if cc[1] == cb[1]:
				continue
			if b2.end.y <= ab.position.y + 0.05 and b2.end.y >= ab.position.y - 0.12 and c2.x > b2.position.x and c2.x < b2.end.x and c2.z > b2.position.z and c2.z < b2.end.z:
				apoyo = str((cc[1] as Node).name)
				break
		var mi := cb[1] as MeshInstance3D
		var raiz: Node = mi
		while raiz.get_parent() != m._house and raiz.get_parent() != null and raiz.get_parent() != m:
			raiz = raiz.get_parent()
		print("MALLA %s raiz=%s(%s) abajo=%.2f tam=%s apoyo=%s c=%s" % [mi.name, raiz.name, raiz.scene_file_path.get_file(), ab.position.y, ab.size.snapped(Vector3.ONE*0.01), apoyo, c2.snapped(Vector3.ONE*0.01)])
	get_tree().quit()
