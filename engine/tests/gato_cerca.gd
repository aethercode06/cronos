extends Node3D
## Primeros planos del gato (pelo y ojos) en un escenario neutro.
func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp"
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.05, 0.05, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.5, 0.48, 0.45); env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.2
	we.environment = env; add_child(we)
	var sol := DirectionalLight3D.new(); sol.rotation_degrees = Vector3(-40, 30, 0); sol.light_energy = 1.6; sol.shadow_enabled = true; add_child(sol)
	var suelo := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(4, 4); suelo.mesh = pm; add_child(suelo)
	var sb := StaticBody3D.new(); var cs := CollisionShape3D.new(); cs.shape = WorldBoundaryShape3D.new(); sb.add_child(cs); add_child(sb)
	var a := ZarekAnimal.new(); a.tipo = "gato"; add_child(a); a.montar("gato_real", 0.62, 0.0)
	a.set_physics_process(false)
	var cam := Camera3D.new(); cam.fov = 40.0; add_child(cam)
	var esq: Skeleton3D = a.modelo.find_children("*", "Skeleton3D", true, false)[0]
	var tomas := [["Idle_2", "cara"], ["Idle_2", "ojo"], ["Idle_2", "perfil"], ["Idle_2", "nuca"], ["Walk_F_IP", "lado"], ["Sit_idle_1", "lado"]]
	var n := 0
	for t in tomas:
		a._gato_anim(t[0])
		for k in 25:
			a._ajustar_suelo(0.2)
			await get_tree().process_frame
		var cab: Vector3 = esq.global_transform * esq.get_bone_global_pose(esq.find_bone("head_024")).origin
		var cuerpo: Vector3 = esq.global_transform * esq.get_bone_global_pose(esq.find_bone("spine_03_05")).origin
		var frente: Vector3 = (cab - cuerpo); frente.y = 0; frente = frente.normalized()
		cam.fov = 40.0
		if t[1] == "cara":
			cam.global_position = cab + frente * 0.22 + Vector3(0, -0.01, 0); cam.look_at(cab + frente * 0.05)
		elif t[1] == "ojo":
			var lado2 := frente.cross(Vector3.UP)
			cam.fov = 25.0
			cam.global_position = cab + frente * 0.2 + Vector3(0, 0.0, 0); cam.look_at(cab + frente * 0.05)
		elif t[1] == "perfil":
			cam.fov = 35.0
			cam.global_position = cab + frente.cross(Vector3.UP) * 0.25 + frente * 0.05 + Vector3(0, 0.03, 0); cam.look_at(cab + frente * 0.05)
		elif t[1] == "nuca":
			cam.fov = 40.0
			cam.global_position = cab - frente * 0.3 + frente.cross(Vector3.UP) * 0.12 + Vector3(0, 0.12, 0); cam.look_at(cab)
		elif t[1] == "cara34":
			cam.global_position = cab + frente * 0.2 + frente.cross(Vector3.UP) * 0.15 + Vector3(0, 0.03, 0); cam.look_at(cab + frente * 0.04)
		elif t[1] == "lado":
			cam.global_position = cuerpo + frente.cross(Vector3.UP) * 0.9 + frente * 0.3 + Vector3(0, 0.2, 0); cam.look_at(cuerpo)
		else:
			cam.global_position = cuerpo + Vector3(0.4, 0.6, 0.3); cam.look_at(cuerpo)
		for k in 3: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg(out + "/c_%d.jpg" % n, 0.9); n += 1
	print("GATO CERCA OK")
	get_tree().quit()
