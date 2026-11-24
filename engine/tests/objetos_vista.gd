extends Node3D
## Muestra los objetos reales (s_*) tal como los coloca el juego, con su giro, para revisar orientación y texturas.
const LISTA := [["s_cizalla", Vector3(PI * 0.5, 0, 0)], ["s_rueda", Vector3(0, 0, PI * 0.5)], ["s_cuerda", Vector3(PI * 0.5, 0, 0)], ["s_garfio", Vector3.ZERO],
	["s_bateria", Vector3.ZERO], ["s_gato", Vector3.ZERO], ["s_gasolina", Vector3.ZERO], ["s_gasolina2", Vector3.ZERO],
	["s_botella", Vector3(0, 0, PI * 0.5)], ["s_trapo", Vector3(PI * 0.5, 0, 0)], ["s_latas", Vector3.ZERO], ["s_latas2", Vector3(PI * 0.5, 0, 0)],
	["s_palanca", Vector3.ZERO], ["s_fusible", Vector3(PI * 0.5, 0, 0)], ["s_vela", Vector3.ZERO], ["s_cerillas", Vector3.ZERO],
	["s_caja_fuerte", Vector3.ZERO], ["s_colchon", Vector3.ZERO], ["s_cadena", Vector3.ZERO], ["s_clavo", Vector3(0, 0, PI * 0.5)]]

func _ready() -> void:
	var piso := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(20, 20); piso.mesh = pm
	var mt := StandardMaterial3D.new(); mt.albedo_color = Color(0.35, 0.3, 0.25); piso.material_override = mt
	add_child(piso)
	var sol := DirectionalLight3D.new(); sol.rotation = Vector3(-0.9, 0.6, 0); sol.light_energy = 1.6; add_child(sol)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.2, 0.2, 0.22)
	add_child(env)
	for i in LISTA.size():
		var ps: PackedScene = load("res://zarek/objetos/%s.glb" % LISTA[i][0])
		var w := Node3D.new(); add_child(w)
		var n: Node3D = ps.instantiate(); w.add_child(n); n.rotation = LISTA[i][1]
		var caja := AABB(); var primera := true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var t := Transform3D.IDENTITY; var x: Node = mi
			while x != null and x != w:
				t = (x as Node3D).transform * t; x = x.get_parent()
			var b: AABB = t * (mi as MeshInstance3D).get_aabb()
			caja = b if primera else caja.merge(b); primera = false
		n.position -= Vector3(caja.get_center().x, caja.position.y, caja.get_center().z)
		var col := i % 5; var fila := i / 5
		w.position = Vector3((col - 2) * 1.1, 0, (fila - 1.5) * 1.1)
		if LISTA[i][0] == "s_colchon":
			w.scale = Vector3.ONE * 0.45
	var cam := Camera3D.new(); add_child(cam); cam.position = Vector3(0, 1.5, 0.3); cam.look_at(Vector3(0, 0, -1.1)); cam.fov = 70
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/objetos_vista.png")
	print("VISTA OK")
	get_tree().quit()
