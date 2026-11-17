extends Node
## Comprueba caminando de verdad (física del jugador) que se pueden cruzar pasos concretos del mapa: el puente.
var g: ZarekJuego
func _ready() -> void:
	g = load("res://zarek/zarek.tscn").instantiate()
	g.autotest = true
	add_child(g)
	var t0 := Time.get_ticks_msec()
	while (g.mansion == null or g.player == null or g.elena == null) and Time.get_ticks_msec() - t0 < 180000:
		await get_tree().process_frame
	for k in 20:
		await get_tree().physics_frame
	var m := g.mansion
	g.elena.process_mode = Node.PROCESS_MODE_DISABLED
	var p := g.player
	var puente := m._zone("Puente viejo")
	var rio := Rect2()
	for z in m.plan["exterior"]["zonas"]:
		if String(z[0]) == "Arroyo":
			rio = m._zone(z[0])
	print("PUENTE ", puente, " RIO ", rio)
	var bx := puente.get_center().x
	var z0 := rio.position.y - 6.0
	var z1 := rio.end.y + 6.0
	for sentido in [1.0, -1.0]:
		p.global_position = Vector3(bx, 1.0, z0 if sentido > 0 else z1)
		p.velocity = Vector3.ZERO
		var llego := false
		var max_z := -1e9
		p._yaw = 0.0
		p.rotation.y = 0.0
		p.move_override = Vector2(0, sentido)
		for f in 600:
			await get_tree().physics_frame
			if (sentido > 0 and p.global_position.z > z1 - 1.0) or (sentido < 0 and p.global_position.z < z0 + 1.0):
				llego = true
				break
		p.move_override = Vector2.ZERO
		print("CRUCE sentido %d: %s  final %s" % [sentido, "OK" if llego else "BLOQUEADO", p.global_position.snapped(Vector3.ONE * 0.1)])
	get_tree().quit()
