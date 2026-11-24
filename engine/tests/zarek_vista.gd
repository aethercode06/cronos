extends Node
## ¿Ve Damián a Sofía? Coloca a los dos en varias salas, frente a frente, y dice qué tapa el rayo.
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
	var m := g.mansion
	var e := g.elena
	g.huida.tiene_clavo = true
	g.huida.completar("argolla")
	g.huida.completar("cerradura")
	var ok := 0
	var tot := 0
	for r in m.rooms:
		if m.level_of(float(r.y) + 0.5) < 0 or tot >= 30:
			continue
		var c: Vector2 = (r.rect as Rect2).get_center()
		var a := Vector3(c.x - 2.0, float(r.y) + 0.05, c.y)
		var b := Vector3(c.x + 2.0, float(r.y) + 0.05, c.y)
		g.player.global_position = a
		e.visible = true
		e.global_position = b
		e.look_at(Vector3(a.x, e.global_position.y, a.z), Vector3.UP)
		e.set_state(ZarekElena.S.WANDER)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var ve: bool = e._can_see_player()
		tot += 1
		if ve:
			ok += 1
		else:
			var q := PhysicsRayQueryParameters3D.create(e.global_position + Vector3(0, 1.6, 0), g.player.global_position + Vector3(0, 1.5, 0))
			q.exclude = e._ray.exclude
			var hit := e.get_world_3d().direct_space_state.intersect_ray(q)
			var fwd := -e.global_transform.basis.z
			print("VISTA NO  %s  choque=%s  capa=%s  fwd·to=%.2f  lit=%s" % [r.name, (hit.collider as Node).name if hit.has("collider") else "-", (hit.collider as CollisionObject3D).collision_layer if hit.has("collider") and hit.collider is CollisionObject3D else -1, fwd.dot((a - b).normalized()), m.is_lit(a)])
	print("VISTA RESUMEN %d/%d" % [ok, tot])
	get_tree().quit()
