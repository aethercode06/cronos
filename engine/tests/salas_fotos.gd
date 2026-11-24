extends Node
## Fotos de salas enteras (desde una esquina, a la altura de los ojos) para revisar el amueblado.
var g: ZarekJuego
func _ready() -> void:
	g = load("res://zarek/zarek.tscn").instantiate()
	g.autotest = true
	add_child(g)
	while g.mansion == null or not g.mansion.nav_ready or g.elena == null or g.player == null:
		await get_tree().process_frame
	for i in 30:
		await get_tree().physics_frame
	var m: ZarekMansion = g.mansion
	g.elena.visible = false
	for cl in g.find_children("*", "CanvasLayer", true, false):
		(cl as CanvasLayer).visible = false
	var cam := Camera3D.new()
	m.add_child(cam)
	cam.fov = 75
	var luz := OmniLight3D.new()
	luz.omni_range = 12.0
	luz.light_energy = 1.6
	luz.shadow_enabled = true
	m.add_child(luz)
	var nombres: PackedStringArray = OS.get_environment("SALAS").split(";", false)
	for k in nombres.size():
		var r := m._sala_por_nombre(nombres[k])
		if r.is_empty():
			continue
		var rc: Rect2 = r.rect
		var y := float(r.y)
		for esq in 2:
			var a := Vector3(rc.position.x + 0.5, y + 1.65, rc.position.y + 0.5) if esq == 0 else Vector3(rc.end.x - 0.5, y + 1.65, rc.end.y - 0.5)
			var b := Vector3(rc.end.x - 0.5, y + 0.6, rc.end.y - 0.5) if esq == 0 else Vector3(rc.position.x + 0.5, y + 0.6, rc.position.y + 0.5)
			cam.global_position = a
			cam.look_at(b, Vector3.UP)
			cam.make_current()
			luz.global_position = Vector3(rc.get_center().x, y + 2.6, rc.get_center().y)
			for f in 4:
				await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/salas/%02d_%d.png" % [k, esq])
		print("SALA_FOTO ", k, " ", nombres[k])
	print("FOTOS OK")
	get_tree().quit()
