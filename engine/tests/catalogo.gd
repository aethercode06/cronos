extends Node3D
## Catálogo visual: objetos en rejilla vistos desde +Z (frente), con poste de 1 m y nombre. godot --path . res://tests/catalogo.tscn -- <jpg> <nombres...>
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.35, 0.36, 0.4)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1); env.environment.ambient_light_energy = 0.6
	add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 25, 0); sun.light_energy = 1.0; add_child(sun)
	var cols := 5
	var sp := 2.6
	var n_obj := a.size() - 1
	var rows := int(ceil(n_obj / float(cols)))
	for i in n_obj:
		var nm: String = a[i + 1]
		var p := "res://zarek/objetos/%s.glb" % nm
		if not ResourceLoader.exists(p): p = "res://zarek/muebles/%s.glb" % nm
		if not ResourceLoader.exists(p): print("FALTA ", nm); continue
		var ps: PackedScene = load(p)
		if ps == null: print("ROTO ", nm); continue
		var n: Node3D = ps.instantiate(); add_child(n)
		var pos := Vector3((i % cols) * sp, 0, -(i / cols) * 3.2)
		n.position = pos
		var post := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.04, 1.0, 0.04); post.mesh = bm
		post.position = pos + Vector3(-1.0, 0.5, 0); add_child(post)
		var l := Label3D.new(); l.text = nm.substr(0, 22); l.font_size = 40; l.pixel_size = 0.004; l.position = pos + Vector3(0, -0.12, 0.9)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.modulate = Color(1, 1, 0.3); add_child(l)
	var suelo := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(60, 60); suelo.mesh = pm
	var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.5, 0.5, 0.5); suelo.material_override = sm; add_child(suelo)
	var cam := Camera3D.new(); add_child(cam); cam.fov = 50
	var cx := (cols - 1) * sp * 0.5
	var cz := -(rows - 1) * 1.6
	cam.position = Vector3(cx, 4.5 + rows * 1.3, 6.0 + rows * 1.0); cam.look_at(Vector3(cx, 0.4, cz))
	await get_tree().create_timer(0.6).timeout
	get_viewport().get_texture().get_image().save_jpg(a[0], 0.9); get_tree().quit()
