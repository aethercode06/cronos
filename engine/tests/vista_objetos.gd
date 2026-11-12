extends Node3D
## Muestra varios objetos de zarek/objetos en fila para comprobar texturas: godot --path . res://tests/vista_objetos.tscn -- <png> <nombres...>
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.2, 0.2, 0.22)
	env.environment.ambient_light_color = Color(1, 1, 1); env.environment.ambient_light_energy = 0.2
	add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-45, 30, 0); sun.light_energy = 0.8; add_child(sun)
	var x := 0.0
	for i in range(1, a.size()):
		var p := "res://zarek/objetos/%s.glb" % a[i]
		if not ResourceLoader.exists(p): p = "res://zarek/muebles/%s.glb" % a[i]
		var n: Node3D = load(p).instantiate(); add_child(n); n.position.x = x; x += 1.6
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var mm: Mesh = (mi as MeshInstance3D).mesh
			for si in mm.get_surface_count():
				var mat = mm.surface_get_material(si)
				print("MAT ", a[i], " ", mat, " ", (mat.albedo_texture if mat is BaseMaterial3D else "-"), " ", (mat.albedo_color if mat is BaseMaterial3D else ""))
	var cam := Camera3D.new(); add_child(cam); cam.position = Vector3(x * 0.5 - 0.8, 1.2, 4.0); cam.look_at(Vector3(x * 0.5 - 0.8, 0.6, 0))
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png(a[0]); get_tree().quit()
