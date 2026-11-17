extends Node3D
## Prueba de la inteligencia del gato: hambre, sueño, caza, ventanas, caricias, ruidos y Elena.
var m: ZarekMansion
var player: CharacterBody3D
var flash: SpotLight3D
var elena: Node3D = null
var mensajes: Array = []
func message(t: String, _d := 2.0) -> void: mensajes.append(t)
func _ready() -> void:
	m = ZarekMansion.new(); add_child(m); m.build(1)
	m.bake_nav()
	for k in 900:
		if m.nav_ready: break
		await get_tree().process_frame
	player = CharacterBody3D.new(); add_child(player)
	flash = SpotLight3D.new(); flash.visible = false; player.add_child(flash)
	var f := ZarekFauna.new(); add_child(f); f.poblar(m, self)
	var g: ZarekAnimal = f.gato
	print("GATO en ", g.global_position, " cuenco ", f.cuenco)
	player.global_position = g.global_position + Vector3(3, 0, 0)
	var estados := {}
	var anterior := -1
	Engine.time_scale = 6.0
	var fases := [["normal", 1200], ["hambre", 1500], ["sueño", 1500], ["caza", 1500], ["caricia", 300], ["ruido", 300], ["elena", 400]]
	for fase in fases:
		match fase[0]:
			"hambre": g.hambre = 0.95; g.t_estado = 0.0; g._decidir(5.0, player.global_position)
			"sueño": g.energia = 0.1; g.hambre = 0.0; g.t_estado = 0.0; g._decidir(5.0, player.global_position)
			"caza":
				g.energia = 0.9
				player.global_position = g.global_position + Vector3(-3, 0, 0)
				for a in f.animales:
					if a.tipo == "rata":
						a.global_position = g.global_position + Vector3(2.0, 0, 0)
						a.process_mode = Node.PROCESS_MODE_INHERIT; a.visible = true
						break
				for a in f.animales:
					if a.tipo == "rata": print("RATA ", a.global_position.distance_to(g.global_position), " vis ", a.visible, " est ", a.estado, " dy ", a.global_position.y - g.global_position.y); break
				await get_tree().physics_frame
				g.t_estado = 0.0; g._decidir(5.0, player.global_position)
			"caricia":
				g.confianza = 0.8; player.global_position = g.global_position + Vector3(0.8, 0, 0)
				print("CARICIA ", g.acariciar())
			"ruido": f.ruido(g.global_position + Vector3(2, 0, 0), 1.0)
			"elena":
				elena = Node3D.new(); add_child(elena); elena.global_position = g.global_position + Vector3(4, 0, 0)
		for k in fase[1]:
			await get_tree().physics_frame
			if k % 250 == 0:
				var pr := ""
				if g._presa and is_instance_valid(g._presa): pr = " presa a %.2f" % g._presa.global_position.distance_to(g.global_position)
				print("    [", fase[0], "] ", ZarekAnimal.E.keys()[g.estado], " pos ", g.global_position.snapped(Vector3.ONE * 0.1), " camino ", g.camino.size(), " vel ", g.vel_obj, " hambre %.2f" % g.hambre, pr, " proc ", g.process_mode)
			if g.estado != anterior:
				anterior = g.estado
				var n: String = ZarekAnimal.E.keys()[g.estado]
				estados[n] = estados.get(n, 0) + 1
				print("  ", fase[0], " -> ", n, "  hambre %.2f energía %.2f confianza %.2f" % [g.hambre, g.energia, g.confianza])
	print("ESTADOS ", estados)
	print("MENSAJES ", mensajes)
	print("GATO IA OK")
	get_tree().quit()
