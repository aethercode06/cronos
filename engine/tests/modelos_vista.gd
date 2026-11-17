extends Node3D
## Hoja de contacto de modelos: uno por casilla, mirando a cámara (+Z), con su nombre. Uso:
## godot --path . res://tests/modelos_vista.tscn -- prefijo salida.png
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var pref := args[0] if args.size() > 0 else "t_"
	var salida := args[1] if args.size() > 1 else "/tmp/modelos.png"
	var lista: Array = []
	for f in DirAccess.get_files_at("res://zarek/objetos"):
		if f.begins_with(pref) and f.ends_with(".glb"):
			lista.append(f)
	lista.sort()
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.35, 0.36, 0.4)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.6)
	env.environment = e
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sol)
	var cols := 6
	var vp := get_viewport()
	var imgs: Array = []
	for i in lista.size():
		var n: Node3D = (load("res://zarek/objetos/" + lista[i]) as PackedScene).instantiate()
		add_child(n)
		var ab := AABB()
		var pr := true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
			ab = b if pr else ab.merge(b)
			pr = false
		var cam := Camera3D.new()
		add_child(cam)
		var tam := maxf(ab.size.x, maxf(ab.size.y, ab.size.z))
		var c := ab.get_center()
		cam.look_at_from_position(c + Vector3(tam * 0.9, tam * 0.6, tam * 1.6), c)
		cam.current = true
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var im := vp.get_texture().get_image()
		im.convert(Image.FORMAT_RGBA8)
		im.resize(320, 240)
		imgs.append(im)
		n.queue_free()
		cam.queue_free()
		print(lista[i], " ", ab.size)
	var filas := int(ceil(imgs.size() / float(cols)))
	var hoja := Image.create(cols * 320, filas * 240, false, Image.FORMAT_RGBA8)
	for i in imgs.size():
		hoja.blit_rect(imgs[i], Rect2i(0, 0, 320, 240), Vector2i((i % cols) * 320, (i / cols) * 240))
	hoja.save_png(salida)
	get_tree().quit()
