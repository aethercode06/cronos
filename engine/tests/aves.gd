extends Node3D
## Aves nocturnas de cerca (con luz de día para verlas): búho posado, búho volando, murciélagos y polillas. -- <carpeta>
func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0]
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.3, 0.34, 0.42)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.8, 0.8, 0.85); env.ambient_light_energy = 0.9
	we.environment = env; add_child(we)
	var sol := DirectionalLight3D.new(); sol.rotation_degrees = Vector3(-50, 30, 0); add_child(sol)
	var suelo := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(200, 200); suelo.mesh = pm
	var sm := StandardMaterial3D.new(); sm.albedo_color = Color(0.22, 0.2, 0.16); suelo.material_override = sm; add_child(suelo)
	var jug := Node3D.new(); add_child(jug); jug.position = Vector3(80, 0, 80)
	var a := ZarekAves.new(); add_child(a)
	a.setup(jug, null, Vector3(60, 0, 60), Rect2(-30, -30, 60, 60), [], Vector3(0, 0, -10), Vector3(0, 0, 10), Vector3(0, 0, 0))
	var po: Node3D = a._posados[0].nodo; po.position = Vector3(0, 0, 0); po.rotation.y = 0.3
	var po2: Node3D = a._posados[1].nodo; po2.position = Vector3(0.6, 0, -0.3); po2.rotation.y = -0.4
	var po3: Node3D = a._posados[2].nodo; po3.position = Vector3(-0.6, 0, -0.4); po3.rotation.y = 0.2
	var cam := Camera3D.new(); add_child(cam); cam.fov = 50
	cam.position = Vector3(0, 0.55, 1.9); cam.look_at(Vector3(0, 0.3, 0))
	for k in 4: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_jpg("%s/aves_0.jpg" % out, 0.9)
	# búho en vuelo: lo pongo delante
	for i in 2:
		var v: Dictionary = a._voladores[i]
		v.c = Vector3(0, 0, 0); v.r = 3.0; v.h = 2.0
	await get_tree().process_frame
	var vn: Node3D = a._voladores[0].nodo
	cam.position = vn.position + Vector3(2.2, 0.4, 2.2); cam.look_at(vn.position)
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_jpg("%s/aves_1.jpg" % out, 0.9)
	var vn2: Node3D = a._voladores[1].nodo
	cam.position = vn2.position + Vector3(2.0, 0.6, 2.0); cam.look_at(vn2.position)
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_jpg("%s/aves_2.jpg" % out, 0.9)
	# murciélagos (grupo del "tejado" en z -10)
	cam.position = Vector3(0, 3.5, -2); cam.look_at(Vector3(0, 4.0, -10))
	for k in 5: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_jpg("%s/aves_3.jpg" % out, 0.9)
	print("AVES OK")
	get_tree().quit()
