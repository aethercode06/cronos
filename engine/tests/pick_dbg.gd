extends Node
var g: ZarekJuego
func _ready() -> void:
	g = load("res://zarek/zarek.tscn").instantiate()
	g.set_meta("diag", true)
	add_child(g)
	while g.mansion == null or not g.mansion.nav_ready or g.elena == null or g.player == null:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	var m: ZarekMansion = g.mansion
	var cuenta := {}
	for d in m.doors:
		var dp: Vector3 = d.pos
		if dp.x > 90 and dp.x < 97 and dp.z > 75 and dp.z < 83 and dp.y > 3:
			print("PUERTA ", dp, " locked=", d.locked)
	for c in m.find_children("*", "Node3D", true, false):
		var f := (c as Node3D).scene_file_path.get_file()
		for k in ["bathtub", "old_bed_frame", "GothicBed_01"]:
			if f.contains(k):
				var gp := (c as Node3D).global_position
				var rid := m.room_at(gp + Vector3(0, 0.3, 0))
				print("MUEBLE ", k, " pos=", gp.snapped(Vector3.ONE * 0.01), " sala=", m.rooms[rid].name if rid >= 0 else "-", " padre=", c.get_parent().name)
	for r in m.rooms:
		if String(r.name) in ["Dormitorio de los padres", "Baño", "Cuarto de huéspedes azul", "Vestidor de los padres"]:
			print("RECT ", r.name, " ", r.rect, " y=", r.y)
		if false:
			var n := 0
			for c in m._house.get_children():
				var nd := c as Node3D
				if nd and nd.scene_file_path != "" and (r.rect as Rect2).has_point(Vector2(nd.global_position.x, nd.global_position.z)) and absf(nd.global_position.y - float(r.y)) < 2.0:
					n += 1
			print("SALA %-40s %5.1f m2 muebles=%d" % [r.name, (r.rect as Rect2).get_area(), n])
	get_tree().quit()
