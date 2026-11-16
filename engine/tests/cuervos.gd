extends Node3D
## Cuervos de cerca: una bandada baja para verlos volar y el grupo posado. -- <carpeta>
func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0]
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.32, 0.36, 0.45)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.8, 0.8, 0.85); env.ambient_light_energy = 0.8
	we.environment = env; add_child(we)
	var sol := DirectionalLight3D.new(); sol.rotation_degrees = Vector3(-50, 30, 0); add_child(sol)
	var suelo := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(80, 80); suelo.mesh = pm
	var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.25, 0.22, 0.18); suelo.material_override = sm; add_child(suelo)
	var jug := Node3D.new(); add_child(jug); jug.position = Vector3(30, 0, 30)
	var c := ZarekCuervos.new(); add_child(c)
	c.setup(jug, null, Vector3.ZERO, Rect2(-20, -20, 40, 40))
	var b: Dictionary = c._bandadas[0]
	b.alto = 2.2; b.radio = 3.5; b.base = Vector3(0, 0, 0)
	var cam := Camera3D.new(); add_child(cam); cam.fov = 45
	var tomas := [[Vector3(0, 2.6, 7.5), Vector3(0, 2.2, 0)], [Vector3(0, 2.6, 7.5), Vector3(0, 2.2, 0)], [Vector3(4, 1.5, 6), Vector3(0, 0.1, 0)], [Vector3(0, 0.6, 2.2), Vector3(-2, 0.1, -3)]]
	var i := 0
	for t in tomas:
		cam.position = t[0]; cam.look_at(t[1])
		for k in (20 if i != 1 else 9): await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/cuervo_%d.jpg" % [out, i], 0.9)
		i += 1
	# retratos: uno posado y uno volando, de cerca
	var po: Node3D = c._posados[0].nodo
	po.position = Vector3(20, 0, 20); po.rotation = Vector3(0, 0.6, 0)
	c._posados[0].t = 1.0
	cam.position = Vector3(20.6, 0.35, 20.7); cam.look_at(Vector3(20, 0.08, 20))
	for k in 3: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_jpg("%s/cuervo_4.jpg" % out, 0.9)
	c.set_process(false)
	var vo: Dictionary = c._bandadas[1].cuervos[0]
	(vo.nodo as Node3D).position = Vector3(-20, 3, -20); (vo.nodo as Node3D).rotation = Vector3(0, 0.4, 0)
	for fase in [0.0, 1.6, 3.6]:
		c._alas(vo, fase, 0.0)
		cam.position = Vector3(-20, 3.5, -18.8); cam.look_at(Vector3(-20, 3, -20))
		for k in 3: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/cuervo_v%d.jpg" % [out, int(fase * 10)], 0.9)
	print("CUERVOS OK")
	get_tree().quit()
