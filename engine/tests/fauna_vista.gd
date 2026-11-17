extends Node3D
## Capturas de la fauna (ratas, gusanos, gato) moviéndose por la casa. godot --path . res://tests/fauna_vista.tscn -- <carpeta>
var m: ZarekMansion
var player: Node3D
var flash: SpotLight3D
var elena: Node3D = null
func message(_t: String, _d := 2.0) -> void: pass
func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp"
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.42, 0.38, 0.34); env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.4
	we.environment = env; add_child(we)
	m = ZarekMansion.new(); add_child(m); m.build(1)
	m.bake_nav()
	for k in 600:
		if m.nav_ready: break
		await get_tree().process_frame
	for l in m.lamps: m.set_lamp(l, true)
	player = Node3D.new(); add_child(player); player.global_position = Vector3(9999, 0, 9999)
	player.set("velocity", Vector3.ZERO)
	var f := ZarekFauna.new(); add_child(f); f.poblar(m, self)
	# que anden un rato
	for k in 240: await get_tree().physics_frame
	var cam := Camera3D.new(); cam.fov = 60.0; add_child(cam)
	flash = SpotLight3D.new(); flash.light_color = Color(1, 0.9, 0.72); flash.light_energy = 4.0; flash.spot_range = 12.0; flash.spot_angle = 40.0; cam.add_child(flash)
	flash.visible = false
	var hechos := {}
	var n := 0
	for a in f.animales:
		var tipo: String = a.tipo
		if hechos.get(tipo, 0) >= (3 if tipo != "gato" else 2): continue
		hechos[tipo] = hechos.get(tipo, 0) + 1
		# el jugador cerca (pero no tanto como para que huya) y que se muevan un poco
		player.global_position = a.global_position + Vector3(4.5, 0, 0)
		for k in 90: await get_tree().physics_frame
		a.process_mode = Node.PROCESS_MODE_DISABLED
		f.set_physics_process(false)
		flash.visible = true
		var p: Vector3 = a.global_position
		var lado: Vector3 = a.global_transform.basis.x
		var dist := 0.35 if tipo in ["gusano", "larva"] else (0.6 if tipo == "rata" else 1.2)
		cam.global_position = p + lado * dist + Vector3(0, dist * 0.6, 0) + a.global_transform.basis.z * dist * 0.4
		cam.look_at(p + Vector3(0, 0.05, 0))
		for k in 6: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg(out + "/f_%d.jpg" % n, 0.85)
		print("FAUNA ", tipo, " ", p)
		f.set_physics_process(true)
		flash.visible = false
		n += 1
	# el gato en varias posturas
	for a in f.animales:
		if a.tipo != "gato": continue
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = true
		for pose in ["Walk_F_IP", "Sit_idle_1", "Sleep_loop", "Agression_loop", "Run_F_IP", "Lie_Idle_1"]:
			a.process_mode = Node.PROCESS_MODE_INHERIT
			a.set_physics_process(false)
			a._gato_anim(pose)
			for k in 30: await get_tree().process_frame
			a.process_mode = Node.PROCESS_MODE_DISABLED
			var p: Vector3 = a.global_position
			var lado: Vector3 = a.global_transform.basis.x
			var cerca := 0.55 if pose == "Sit_idle_1" else 0.9
			cam.global_position = p + lado * cerca * 0.6 + a.global_transform.basis.z * cerca + Vector3(0, 0.3, 0)
			cam.look_at(p + Vector3(0, 0.18, 0))
			flash.visible = true
			for k in 4: await get_tree().process_frame
			get_viewport().get_texture().get_image().save_jpg(out + "/g_%s.jpg" % pose, 0.85)
			print("GATO ", pose)
		break
	print("FAUNA OK ", n)
	get_tree().quit()
